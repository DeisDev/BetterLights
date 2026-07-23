if CLIENT then

    local BL = BetterLights

    BL._thinks = BL._thinks or {}
    BL._thinkErrors = BL._thinkErrors or {}
    BL._tickers = BL._tickers or {}
    BL._flashPool = BL._flashPool or {}
    BL._flashPoolSize = 0
    BL._flashPoolMax = 100
    BL._suppressionRecords = BL._suppressionRecords or {}
    BL._activeFlashes = BL._activeFlashes or {}
    BL._activeFlashByKey = BL._activeFlashByKey or {}
    BL._activeFlashIds = BL._activeFlashIds or {}
    BL._activeDLightRecords = BL._activeDLightRecords or {}
    BL._flashKeyIds = BL._flashKeyIds or {}
    BL._flashIdCounter = BL._flashIdCounter or 0
    BL._idCounter = BL._idCounter or 0
    BL._nextDLightRecordPrune = BL._nextDLightRecordPrune or 0
    BL._dlightRequests = {}
    BL._elightRequests = {}
    BL._lightRequestsByKey = {}
    BL._lightRequestPool = BL._lightRequestPool or {}
    BL._lightBudgetPrevious = BL._lightBudgetPrevious or {
        dlight = {},
        elight = {}
    }
    BL._lightBudgetNext = BL._lightBudgetNext or {
        dlight = {},
        elight = {}
    }
    BL._lightBudgetScratch = BL._lightBudgetScratch or {
        dlight = {},
        elight = {},
        projected = {}
    }
    BL._lightBudgetStats = BL._lightBudgetStats or {
        dlight = {},
        elight = {},
        projected = {}
    }

    BL.LIGHT_PRIORITY_CORPSE = -2
    BL.LIGHT_PRIORITY_AMBIENT = 0
    BL.LIGHT_PRIORITY_GAMEPLAY = 1
    BL.LIGHT_PRIORITY_FLASH = 2
    BL.LIGHT_PRIORITY_LOCAL_PLAYER = 3
    BL.LIGHT_OPTIONS_GAMEPLAY = {
        priority = BL.LIGHT_PRIORITY_GAMEPLAY
    }

    local cvar_budget_enable = BL.CreateClientConVar(
        "betterlights_light_budget_enable",
        "1",
        true,
        false,
        "Limit and prioritize Better Lights light allocations",
        0,
        1
    )
    local cvar_budget_dlights = BL.CreateClientConVar(
        "betterlights_light_budget_dlight_limit",
        "28",
        true,
        false,
        "Maximum Better Lights world dynamic lights",
        0,
        32
    )
    local cvar_budget_elights = BL.CreateClientConVar(
        "betterlights_light_budget_elight_limit",
        "56",
        true,
        false,
        "Maximum Better Lights entity lights",
        0,
        64
    )
    local cvar_budget_projected = BL.CreateClientConVar(
        "betterlights_light_budget_projected_limit",
        "6",
        true,
        false,
        "Maximum Better Lights projected textures",
        0,
        32
    )
    local cvar_budget_max_distance = BL.CreateClientConVar(
        "betterlights_light_budget_max_distance",
        "0",
        true,
        false,
        "Maximum distance from the view to a Better Lights light; 0 disables distance culling",
        0,
        20000
    )
    local cvar_budget_fade_distance = BL.CreateClientConVar(
        "betterlights_light_budget_fade_distance",
        "512",
        true,
        false,
        "Distance over which lights fade before the maximum light distance",
        0,
        5000
    )
    local cvar_budget_offscreen = BL.CreateClientConVar(
        "betterlights_light_budget_offscreen_deprioritize",
        "1",
        true,
        false,
        "Prefer lights whose influence reaches the current view when the light budget is full",
        0,
        1
    )

    for key in pairs(BL._activeFlashByKey) do
        BL._activeFlashByKey[key] = nil
    end
    for id in pairs(BL._activeFlashIds) do
        BL._activeFlashIds[id] = nil
    end
    for key in pairs(BL._flashKeyIds) do
        BL._flashKeyIds[key] = nil
    end

    for _, flash in ipairs(BL._activeFlashes) do
        if flash and flash.id then
            BL._activeFlashIds[flash.id] = flash
        end

        if flash and flash.key then
            BL._activeFlashByKey[flash.key] = flash
            BL._flashKeyIds[flash.key] = flash.id
        end
    end

    local THINK_ERROR_DISABLE_COUNT = 3
    local LIGHT_REQUEST_POOL_MAX = 512
    local PREVIOUS_WINNER_MULTIPLIER = 1.2
    local OFFSCREEN_SCORE_MULTIPLIER = 0.15

    local function getDLightRecordKey(index, isElight)
        return (isElight and "e" or "d") .. tostring(index)
    end

    local function clearTable(values)
        for key in pairs(values) do
            values[key] = nil
        end
    end

    local function getViewPos()
        if MainEyePos then return MainEyePos() end
        if EyePos then return EyePos() end

        local ply = LocalPlayer()
        if IsValid(ply) and ply.EyePos then
            return ply:EyePos()
        end

        return vector_origin
    end

    local function getViewAngles()
        if MainEyeAngles then return MainEyeAngles() end
        if EyeAngles then return EyeAngles() end

        local ply = LocalPlayer()
        if IsValid(ply) and ply.EyeAngles then
            return ply:EyeAngles()
        end

        return angle_zero
    end

    local function getDistanceFade(candidate, viewPos)
        if not cvar_budget_enable:GetBool() then return 1 end

        local maxDistance = math.max(0, cvar_budget_max_distance:GetFloat())
        if maxDistance <= 0 then return 1 end

        local distance = math.sqrt(candidate.pos:DistToSqr(viewPos))
        local influenceDistance = math.max(0, distance - math.max(0, candidate.size or 0))
        if influenceDistance >= maxDistance then return 0 end

        local fadeDistance = math.Clamp(cvar_budget_fade_distance:GetFloat(), 0, maxDistance)
        if fadeDistance <= 0 then return 1 end

        local fadeStart = maxDistance - fadeDistance
        if influenceDistance <= fadeStart then return 1 end

        return math.Clamp((maxDistance - influenceDistance) / fadeDistance, 0, 1)
    end

    local function influenceReachesScreen(candidate, viewPos, viewAngles, distance)
        local size = math.max(0, candidate.size or 0)
        if distance <= size then return true end

        local fov = 90
        local ply = LocalPlayer()
        if IsValid(ply) and ply.GetFOV then
            fov = math.Clamp(ply:GetFOV(), 1, 179)
        end

        local offset = candidate.pos - viewPos
        local forwardDistance = offset:Dot(viewAngles:Forward())
        if forwardDistance < -size then return false end

        local horizontalScale = math.tan(math.rad(fov * 0.5))
        local aspect = math.max(0.1, ScrW() / math.max(1, ScrH()))
        local verticalScale = horizontalScale / aspect
        local projectedDistance = math.max(0, forwardDistance)

        return math.abs(offset:Dot(viewAngles:Right())) <= projectedDistance * horizontalScale + size
            and math.abs(offset:Dot(viewAngles:Up())) <= projectedDistance * verticalScale + size
    end

    local function getCandidateScore(candidate, viewPos, viewAngles, previous)
        local distSqr = candidate.pos:DistToSqr(viewPos)
        local distance = math.sqrt(distSqr)
        local size = math.max(1, candidate.size or 0)
        local sizeSqr = size * size
        local influence = sizeSqr / (distSqr + sizeSqr)
        local luminance = (
            0.2126 * math.Clamp(candidate.r or 255, 0, 255)
            + 0.7152 * math.Clamp(candidate.g or 255, 0, 255)
            + 0.0722 * math.Clamp(candidate.b or 255, 0, 255)
        ) / 255
        local priority = math.Clamp(tonumber(candidate.priority) or BL.LIGHT_PRIORITY_AMBIENT, -4, 4)
        local score = math.max(0.001, candidate.brightness or 0)
            * math.max(0.05, luminance)
            * math.max(0.01, influence)
            * math.sqrt(size)
            * math.max(0.001, candidate._budgetFade or 1)
            * (2 ^ priority)

        candidate._budgetOnScreen = influenceReachesScreen(candidate, viewPos, viewAngles, distance)
        if cvar_budget_offscreen:GetBool() and not candidate._budgetOnScreen then
            score = score * OFFSCREEN_SCORE_MULTIPLIER
        end

        if previous[candidate.key] then
            score = score * PREVIOUS_WINNER_MULTIPLIER
        end

        return score
    end

    function BL.IsLightBudgetEnabled()
        return cvar_budget_enable:GetBool()
    end

    function BL.GetLightBudgetLimit(kind)
        if kind == "elight" then
            return math.Clamp(cvar_budget_elights:GetInt(), 0, 64)
        elseif kind == "projected" then
            return math.Clamp(cvar_budget_projected:GetInt(), 0, 32)
        end

        return math.Clamp(cvar_budget_dlights:GetInt(), 0, 32)
    end

    function BL.SelectLightBudgetCandidates(kind, candidates, previous, nextSelected, scratch)
        candidates = candidates or {}
        previous = previous or {}
        nextSelected = nextSelected or {}
        scratch = scratch or {}

        clearTable(nextSelected)
        for i = #scratch, 1, -1 do
            scratch[i] = nil
        end

        local stats = BL._lightBudgetStats[kind] or {}
        BL._lightBudgetStats[kind] = stats
        stats.requested = #candidates
        stats.eligible = 0
        stats.admitted = 0
        stats.emitted = 0
        stats.distanceCulled = 0
        stats.budgetRejected = 0

        local viewPos = getViewPos()
        local viewAngles = getViewAngles()
        for i = 1, #candidates do
            local candidate = candidates[i]
            local fade = getDistanceFade(candidate, viewPos)
            candidate._budgetFade = fade
            candidate._budgetOnScreen = nil
            candidate._budgetScore = nil

            if fade > 0
                and (candidate.brightness or 0) > 0
                and (candidate.size or 0) > 0
            then
                scratch[#scratch + 1] = candidate
            elseif fade <= 0 then
                stats.distanceCulled = stats.distanceCulled + 1
            end
        end

        stats.eligible = #scratch

        local limit = #scratch
        if cvar_budget_enable:GetBool() then
            limit = math.min(BL.GetLightBudgetLimit(kind), #scratch)
        end

        if #scratch > limit then
            for i = 1, #scratch do
                local candidate = scratch[i]
                candidate._budgetScore = getCandidateScore(candidate, viewPos, viewAngles, previous)
            end

            table.sort(scratch, function(a, b)
                if a._budgetScore == b._budgetScore then
                    return tostring(a.key) < tostring(b.key)
                end

                return a._budgetScore > b._budgetScore
            end)
        end

        for i = 1, limit do
            nextSelected[scratch[i].key] = true
        end

        stats.admitted = limit
        stats.budgetRejected = math.max(0, #scratch - limit)
        return scratch, limit, stats
    end

    function BL.GetLightBudgetStats()
        return BL._lightBudgetStats
    end

    local function pruneDLightRecords(now)
        now = now or CurTime()

        for key, record in pairs(BL._activeDLightRecords) do
            if not record or not record.die or record.die <= now then
                BL._activeDLightRecords[key] = nil
            end
        end
    end

    local function recordDLight(index, pos, r, g, b, size, isElight, dieTime)
        if not index or not pos then return nil end

        local now = CurTime()
        if now >= BL._nextDLightRecordPrune then
            pruneDLightRecords(now)
            BL._nextDLightRecordPrune = now + 1
        end

        local key = getDLightRecordKey(index, isElight)
        local record = BL._activeDLightRecords[key]
        if not record then
            record = {}
            BL._activeDLightRecords[key] = record
        end

        record.id = index
        record.pos = pos
        record.r = r or 255
        record.g = g or 255
        record.b = b or 255
        record.size = size or 0
        record.elight = isElight == true
        record.die = dieTime or now

        return record
    end

    function BL.GetFlashTable()
        if BL._flashPoolSize > 0 then
            local flash = BL._flashPool[BL._flashPoolSize]
            BL._flashPool[BL._flashPoolSize] = nil
            BL._flashPoolSize = BL._flashPoolSize - 1
            return flash
        end
        return {}
    end

    function BL.RecycleFlashTable(flash)
        if BL._flashPoolSize < BL._flashPoolMax then
            for k in pairs(flash) do
                flash[k] = nil
            end
            BL._flashPoolSize = BL._flashPoolSize + 1
            BL._flashPool[BL._flashPoolSize] = flash
        end
    end

    function BL.ShouldSuppressFlash(key, pos, minDistSq, maxAge)
        minDistSq = minDistSq or (40 * 40)
        maxAge = maxAge or 0.15

        local record = BL._suppressionRecords[key]
        if not record then
            record = {}
            BL._suppressionRecords[key] = record
        end

        local now = CurTime()

        for i = #record, 1, -1 do
            local e = record[i]
            if now - e.t > maxAge then
                record[i] = record[#record]
                record[#record] = nil
            elseif e.pos:DistToSqr(pos) < minDistSq then
                return true
            end
        end

        return false
    end

    function BL.RecordFlashPosition(key, pos)
        local record = BL._suppressionRecords[key]
        if not record then
            record = {}
            BL._suppressionRecords[key] = record
        end
        record[#record + 1] = { pos = pos, t = CurTime() }
    end

    function BL.GetActiveDLightRecords()
        pruneDLightRecords()
        return BL._activeDLightRecords
    end

    local function getFlashId(baseId, key)
        if key then
            local id = BL._flashKeyIds[key]
            if id and not BL._activeFlashIds[id] then
                return id
            end
        end

        local id
        for _ = 1, 4096 do
            BL._flashIdCounter = (BL._flashIdCounter + 1) % 4096
            id = (baseId or 60000) + BL._flashIdCounter
            if not BL._activeFlashIds[id] then break end
        end

        if key then
            BL._flashKeyIds[key] = id
        end

        return id
    end

    function BL.CreateFlash(pos, r, g, b, size, brightness, duration, baseId, key)
        if not BL.IsEnabled() then return nil end

        local now = CurTime()
        local flash = key and BL._activeFlashByKey[key] or nil
        if flash and flash.key ~= key then
            BL._activeFlashByKey[key] = nil
            flash = nil
        end

        if not flash then
            flash = BL.GetFlashTable()
            flash.id = getFlashId(baseId, key)
            flash.key = key
            table.insert(BL._activeFlashes, flash)
            BL._activeFlashIds[flash.id] = flash

            if key then
                BL._activeFlashByKey[key] = flash
            end
        end

        flash.pos = pos
        flash.r = r
        flash.g = g
        flash.b = b
        flash.baseSize = size
        flash.baseBrightness = brightness
        flash.start = now
        flash.die = now + duration
        return flash
    end

    function BL.UpdateFlashes()
        if #BL._activeFlashes == 0 then return end

        local now = CurTime()
        for i = #BL._activeFlashes, 1, -1 do
            local f = BL._activeFlashes[i]
            if not f or now >= f.die then
                if f then
                    if f.key and BL._activeFlashByKey[f.key] == f then
                        BL._activeFlashByKey[f.key] = nil
                        BL._flashKeyIds[f.key] = nil
                    end

                    if BL._activeFlashIds[f.id] == f then
                        BL._activeFlashIds[f.id] = nil
                    end

                    BL.RecycleFlashTable(f)
                end
                BL._activeFlashes[i] = BL._activeFlashes[#BL._activeFlashes]
                BL._activeFlashes[#BL._activeFlashes] = nil
            else
                local dur = math.max(0.001, f.die - f.start)
                local t = (f.die - now) / dur
                local brightness = f.baseBrightness * t
                local size = f.baseSize * (0.4 + 0.6 * t)
                BL.CreateDLight(f.id, f.pos, f.r, f.g, f.b, brightness, 0, size, false, {
                    dietime = 0.05,
                    priority = BL.LIGHT_PRIORITY_FLASH
                })
            end
        end
    end

    function BL.AddThink(name, fn)
        if not isfunction(fn) then return end
        BL._thinks[name] = fn
        BL._thinkErrors[name] = nil
    end

    function BL.RemoveThink(name)
        BL._thinks[name] = nil
        BL._thinkErrors[name] = nil
    end

    function BL.ShouldTick(name, hz)
        if not hz or hz <= 0 then return true end

        local now = CurTime()
        local nextt = BL._tickers[name] or 0
        if now >= nextt then
            BL._tickers[name] = now + (1 / hz)
            return true
        end
        return false
    end

    function BL.NewLightId(base)
        BL._idCounter = (BL._idCounter + 1) % 4096
        return (base or 60000) + BL._idCounter
    end

    function BL.GetColorFromCvars(r_cvar, g_cvar, b_cvar)
        return math.Clamp(math.floor(r_cvar:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(g_cvar:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(b_cvar:GetFloat() + 0.5), 0, 255)
    end

    local function getLightRequest()
        local count = #BL._lightRequestPool
        if count <= 0 then return {} end

        local request = BL._lightRequestPool[count]
        BL._lightRequestPool[count] = nil
        return request
    end

    local function recycleLightRequest(request)
        for key in pairs(request) do
            request[key] = nil
        end

        if #BL._lightRequestPool < LIGHT_REQUEST_POOL_MAX then
            BL._lightRequestPool[#BL._lightRequestPool + 1] = request
        end
    end

    function BL.CreateDLight(index, pos, r, g, b, brightness, decay, size, isElight, options)
        if not BL.IsEnabled() then return nil end
        if not index or not pos then return nil end

        options = options or {}
        isElight = isElight == true

        local key = getDLightRecordKey(index, isElight)
        local request = BL._lightRequestsByKey[key]
        if not request then
            request = getLightRequest()
            request.key = key
            request.id = index
            request.elight = isElight
            BL._lightRequestsByKey[key] = request

            local requests = isElight and BL._elightRequests or BL._dlightRequests
            requests[#requests + 1] = request
        end

        request.pos = pos
        request.r = r
        request.g = g
        request.b = b
        request.brightness = brightness
        request.decay = decay
        request.size = size
        request.minlight = 0
        request.noworld = options.noworld == true
        request.nomodel = options.nomodel == true
        request.dietime = CurTime() + (options.dietime or 0.1)
        request.priority = tonumber(options.priority) or BL.LIGHT_PRIORITY_AMBIENT

        return request
    end

    local function emitDLightRequest(request)
        local dl = DynamicLight(request.id, request.elight)
        if dl then
            dl.pos = request.pos
            dl.r = request.r
            dl.g = request.g
            dl.b = request.b
            dl.brightness = request.brightness * (request._budgetFade or 1)
            dl.decay = request.decay
            dl.size = request.size
            dl.minlight = request.minlight
            if not request.elight then
                dl.noworld = request.noworld
                dl.nomodel = request.nomodel
            end
            dl.dietime = request.dietime
            recordDLight(
                request.id,
                request.pos,
                request.r,
                request.g,
                request.b,
                request.size,
                request.elight,
                request.dietime
            )
        end

        return dl
    end

    local function clearLightRequests(requests)
        for i = #requests, 1, -1 do
            local request = requests[i]
            BL._lightRequestsByKey[request.key] = nil
            requests[i] = nil
            recycleLightRequest(request)
        end
    end

    local function flushLightRequestKind(kind, requests)
        local previous = BL._lightBudgetPrevious[kind]
        local nextSelected = BL._lightBudgetNext[kind]
        local scratch = BL._lightBudgetScratch[kind]
        local selected, selectedCount, stats = BL.SelectLightBudgetCandidates(
            kind,
            requests,
            previous,
            nextSelected,
            scratch
        )

        for i = 1, selectedCount do
            if emitDLightRequest(selected[i]) then
                stats.emitted = stats.emitted + 1
            end
        end

        BL._lightBudgetPrevious[kind] = nextSelected
        BL._lightBudgetNext[kind] = previous
        clearLightRequests(requests)
    end

    function BL.FlushDLightRequests()
        flushLightRequestKind("dlight", BL._dlightRequests)
        flushLightRequestKind("elight", BL._elightRequests)
    end

    function BL.ClearDLightRequests()
        clearLightRequests(BL._dlightRequests)
        clearLightRequests(BL._elightRequests)
    end

    function BL.LerpColor(r1, g1, b1, r2, g2, b2, t)
        t = math.Clamp(t, 0, 1)
        return math.floor(r1 + (r2 - r1) * t),
               math.floor(g1 + (g2 - g1) * t),
               math.floor(b1 + (b2 - b1) * t)
    end

    function BL.CreateFlickerEffect(baseValue, time, speed, amount, phase)
        phase = phase or 0
        local osc = 0.65 * math.sin(time * speed + phase) + 0.35 * math.sin(time * (speed * 1.7) + phase * 1.13)
        return math.max(0, baseValue * (1 + amount * osc))
    end

    hook.Add("Think", "BetterLights_CoreThink", function()
        if not BL.IsEnabled() then
            BL.ClearDLightRequests()
            return
        end

        BL.UpdateFlashes()

        for name, fn in pairs(BL._thinks) do
            local ok, err = xpcall(fn, debug and debug.traceback or tostring)
            if ok then
                BL._thinkErrors[name] = nil
            else
                local errorCount = (BL._thinkErrors[name] or 0) + 1
                BL._thinkErrors[name] = errorCount

                MsgC(Color(255, 100, 100), "[BetterLights] Think '" .. tostring(name) .. "' error (" .. tostring(errorCount) .. "/" .. tostring(THINK_ERROR_DISABLE_COUNT) .. "): " .. tostring(err) .. "\n")

                if errorCount >= THINK_ERROR_DISABLE_COUNT then
                    BL._thinks[name] = nil
                    BL._thinkErrors[name] = nil
                    MsgC(Color(255, 100, 100), "[BetterLights] Disabled Think '" .. tostring(name) .. "' after repeated errors.\n")
                end
            end
        end

        BL.FlushDLightRequests()
    end)

    hook.Add("BetterLights_EffectiveEnabledChanged", "BetterLights_LightBudgetEffectiveEnable", function(enabled)
        if not enabled then
            BL.ClearDLightRequests()
        end
    end)

    concommand.Add("betterlights_print_light_budget", function()
        local stats = BL.GetLightBudgetStats()
        MsgC(Color(180, 220, 255), "[BetterLights] Light budget\n")

        for _, kind in ipairs({ "dlight", "elight", "projected" }) do
            local values = stats[kind] or {}
            MsgC(
                Color(220, 220, 220),
                string.format(
                    "  %s: requested=%d eligible=%d admitted=%d emitted=%d distance_culled=%d budget_rejected=%d\n",
                    kind,
                    values.requested or 0,
                    values.eligible or 0,
                    values.admitted or 0,
                    values.emitted or 0,
                    values.distanceCulled or 0,
                    values.budgetRejected or 0
                )
            )
        end
    end, nil, "Print Better Lights light budget usage")
end
