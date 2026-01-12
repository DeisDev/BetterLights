-- BetterLights Core
-- Provides centralized Think aggregator, entity tracking system, and utility functions for lighting modules

if CLIENT then
    BetterLights = BetterLights or {}

    local BL = BetterLights
    
    -- Version tracking
    BL.VERSION = "1.1.0"
    BL.VERSION_DATE = "2026-01-12"
    
    BL._thinks = BL._thinks or {}
    BL._classes = BL._classes or {}
    BL._tracked = BL._tracked or {}
    BL._removeHandlers = BL._removeHandlers or {}
    BL._tickers = BL._tickers or {}
    BL._attachCache = BL._attachCache or {}
    BL._networkHandlers = BL._networkHandlers or {}

    -- Network message constants (must match server)
    local NET_MUZZLE_FLASH = 1
    local NET_BULLET_IMPACT = 2
    
    -- Register a network message handler
    function BL.AddNetworkHandler(msgType, fn)
        if not isfunction(fn) then return end
        BL._networkHandlers[msgType] = fn
    end
    
    -- Consolidated network message receiver
    net.Receive("BetterLights_Event", function()
        local msgType = net.ReadUInt(4)
        local handler = BL._networkHandlers[msgType]
        if handler then
            handler()
        end
    end)
    
    -- Export constants for modules to use
    BL.NET_MUZZLE_FLASH = NET_MUZZLE_FLASH
    BL.NET_BULLET_IMPACT = NET_BULLET_IMPACT
    
    -- Memory pooling for flash tables
    BL._flashPool = BL._flashPool or {}
    BL._flashPoolSize = 0
    BL._flashPoolMax = 100 -- Max pooled objects
    
    -- Get a flash table from the pool or create new one
    function BL.GetFlashTable()
        if BL._flashPoolSize > 0 then
            local flash = BL._flashPool[BL._flashPoolSize]
            BL._flashPool[BL._flashPoolSize] = nil
            BL._flashPoolSize = BL._flashPoolSize - 1
            return flash
        end
        return {}
    end
    
    -- Return a flash table to the pool for reuse
    function BL.RecycleFlashTable(flash)
        if BL._flashPoolSize < BL._flashPoolMax then
            -- Clear the table
            for k in pairs(flash) do
                flash[k] = nil
            end
            BL._flashPoolSize = BL._flashPoolSize + 1
            BL._flashPool[BL._flashPoolSize] = flash
        end
    end
    
    -- Shared suppression tracking for flash deduplication
    BL._suppressionRecords = BL._suppressionRecords or {}
    
    -- Check if a flash at this position should be suppressed (too close to recent flash)
    -- Returns true if suppressed, false if allowed
    function BL.ShouldSuppressFlash(key, pos, minDistSq, maxAge)
        minDistSq = minDistSq or (40 * 40)
        maxAge = maxAge or 0.15
        
        local record = BL._suppressionRecords[key]
        if not record then
            record = {}
            BL._suppressionRecords[key] = record
        end
        
        local now = CurTime()
        
        -- Clean old entries and check for nearby recent flashes
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
    
    -- Record a flash position for future suppression checks
    function BL.RecordFlashPosition(key, pos)
        local record = BL._suppressionRecords[key]
        if not record then
            record = {}
            BL._suppressionRecords[key] = record
        end
        record[#record + 1] = { pos = pos, t = CurTime() }
    end
    
    -- Flash lifecycle management
    BL._activeFlashes = BL._activeFlashes or {}
    BL._flashIdCounter = BL._flashIdCounter or 0
    
    -- Create and register a timed flash effect
    function BL.CreateFlash(pos, r, g, b, size, brightness, duration, baseId)
        local now = CurTime()
        BL._flashIdCounter = (BL._flashIdCounter + 1) % 4096
        local flash = BL.GetFlashTable()
        flash.pos = pos
        flash.r = r
        flash.g = g
        flash.b = b
        flash.baseSize = size
        flash.baseBrightness = brightness
        flash.start = now
        flash.die = now + duration
        flash.id = (baseId or 60000) + BL._flashIdCounter
        table.insert(BL._activeFlashes, flash)
        return flash
    end
    
    -- Update all active flashes (call from Think hook)
    function BL.UpdateFlashes()
        if #BL._activeFlashes == 0 then return end
        local now = CurTime()
        for i = #BL._activeFlashes, 1, -1 do
            local f = BL._activeFlashes[i]
            if not f or now >= f.die then
                if f then BL.RecycleFlashTable(f) end
                table.remove(BL._activeFlashes, i)
            else
                local dur = math.max(0.001, f.die - f.start)
                local t = (f.die - now) / dur
                local brightness = f.baseBrightness * t
                local size = f.baseSize * (0.4 + 0.6 * t)
                
                local dl = DynamicLight(f.id)
                if dl then
                    dl.pos = f.pos
                    dl.r = f.r
                    dl.g = f.g
                    dl.b = f.b
                    dl.brightness = brightness
                    dl.decay = 0
                    dl.size = size
                    dl.minlight = 0
                    dl.noworld = false
                    dl.nomodel = false
                    dl.dietime = now + 0.05
                end
            end
        end
    end
    
    -- ConVar creation helper - creates a standard set of ConVars for a module
    function BL.CreateConVarSet(prefix, defaults)
        defaults = defaults or {}
        local cvars = {}
        
        if defaults.enable ~= nil then
            cvars.enable = CreateClientConVar(prefix .. "_enable", tostring(defaults.enable), true, false, defaults.enableDesc or "Enable this lighting effect")
        end
        
        if defaults.size then
            cvars.size = CreateClientConVar(prefix .. "_size", tostring(defaults.size), true, false, defaults.sizeDesc or "Light radius")
        end
        
        if defaults.brightness then
            cvars.brightness = CreateClientConVar(prefix .. "_brightness", tostring(defaults.brightness), true, false, defaults.brightnessDesc or "Light brightness")
        end
        
        if defaults.decay then
            cvars.decay = CreateClientConVar(prefix .. "_decay", tostring(defaults.decay), true, false, defaults.decayDesc or "Light decay")
        end
        
        if defaults.r and defaults.g and defaults.b then
            cvars.r = CreateClientConVar(prefix .. "_color_r", tostring(defaults.r), true, false, defaults.rDesc or "Red (0-255)")
            cvars.g = CreateClientConVar(prefix .. "_color_g", tostring(defaults.g), true, false, defaults.gDesc or "Green (0-255)")
            cvars.b = CreateClientConVar(prefix .. "_color_b", tostring(defaults.b), true, false, defaults.bDesc or "Blue (0-255)")
        end
        
        return cvars
    end
    
    -- Entity class checking helper
    function BL.IsEntityClass(ent, classes)
        if not IsValid(ent) then return false end
        if not ent.GetClass then return false end
        local cls = ent:GetClass()
        if type(classes) == "string" then
            return cls == classes
        elseif type(classes) == "table" then
            for _, checkClass in ipairs(classes) do
                if cls == checkClass then return true end
            end
        end
        return false
    end
    
    -- Model matching helper (case-insensitive substring match)
    function BL.MatchesModel(ent, pattern)
        if not IsValid(ent) then return false end
        if not ent.GetModel then return false end
        local mdl = string.lower(ent:GetModel() or "")
        return string.find(mdl, string.lower(pattern), 1, true) ~= nil
    end

    -- Register a Think function to be called every frame
    function BL.AddThink(name, fn)
        if not isfunction(fn) then return end
        BL._thinks[name] = fn
    end

    function BL.RemoveThink(name)
        BL._thinks[name] = nil
    end

    -- Throttle updates to a specific Hz (returns true if enough time has passed)
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

    -- Generate unique light indices to avoid collisions
    BL._idCounter = BL._idCounter or 0
    function BL.NewLightId(base)
        BL._idCounter = (BL._idCounter + 1) % 4096
        return (base or 60000) + BL._idCounter
    end

    -- Begin tracking entities of a specific class (enables BL.ForEach and OnEntityCreated/EntityRemoved hooks)
    function BL.TrackClass(classname)
        if type(classname) ~= "string" or classname == "" then return end
        if BL._classes[classname] then return end
        BL._classes[classname] = true
        BL._tracked[classname] = BL._tracked[classname] or {}
        timer.Simple(0, function()
            if not BL._classes[classname] then return end
            for _, ent in ipairs(ents.FindByClass(classname)) do
                if IsValid(ent) then BL._tracked[classname][ent] = true end
            end
        end)
    end

    -- Iterate over all tracked entities of a class (auto-cleans up invalid entities)
    function BL.ForEach(classname, fn)
        local set = BL._tracked[classname]
        if not set then return end
        for ent, _ in pairs(set) do
            if not IsValid(ent) then
                set[ent] = nil
            else
                fn(ent)
            end
        end
    end

    -- Register a callback for when entities of a class are removed
    function BL.AddRemoveHandler(classname, fn)
        if type(classname) ~= "string" or not isfunction(fn) then return end
        BL._removeHandlers[classname] = BL._removeHandlers[classname] or {}
        table.insert(BL._removeHandlers[classname], fn)
    end

    -- Get the center position of an entity (OBB center in world space)
    function BL.GetEntityCenter(ent)
        if not IsValid(ent) then return nil end
        if ent.LocalToWorld and ent.OBBCenter then
            return ent:LocalToWorld(ent:OBBCenter())
        elseif ent.WorldSpaceCenter then
            return ent:WorldSpaceCenter()
        else
            return ent:GetPos()
        end
    end

    -- Read and clamp RGB color values from ConVars
    function BL.GetColorFromCvars(r_cvar, g_cvar, b_cvar)
        return math.Clamp(math.floor(r_cvar:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(g_cvar:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(b_cvar:GetFloat() + 0.5), 0, 255)
    end

    -- Create a DynamicLight with standard settings (pass isElight=true for model-only lights)
    function BL.CreateDLight(index, pos, r, g, b, brightness, decay, size, isElight)
        local dl = DynamicLight(index, isElight or false)
        if dl then
            dl.pos = pos
            dl.r = r
            dl.g = g
            dl.b = b
            dl.brightness = brightness
            dl.decay = decay
            dl.size = size
            dl.minlight = 0
            if not isElight then
                dl.noworld = false
                dl.nomodel = false
            end
            dl.dietime = CurTime() + 0.1
        end
        return dl
    end

    -- Cache attachment lookups per model to avoid repeated LookupAttachment calls
    function BL.LookupAttachmentCached(ent, names)
        if not (IsValid(ent) and ent.LookupAttachment and ent.GetModel) then return nil end
        local mdl = ent:GetModel() or ""
        local cache = BL._attachCache[mdl]
        if not cache then
            cache = {}
            BL._attachCache[mdl] = cache
        end
        for i = 1, #names do
            local name = names[i]
            local id = cache[name]
            if id == nil then
                local lid = ent:LookupAttachment(name)
                cache[name] = lid or false
                id = cache[name]
            end
            if id and id ~= false and id > 0 then
                return id
            end
        end
        return nil
    end

    -- Get world position from first found attachment in a list
    function BL.GetAttachmentPos(ent, names)
        local id = BL.LookupAttachmentCached(ent, names)
        if id and ent.GetAttachment then
            local att = ent:GetAttachment(id)
            if att and att.Pos then return att.Pos end
        end
        return nil
    end

    -- Reusable trace table to reduce garbage collection (keyed by string for multiple concurrent traces)
    local _tracePools = {}
    function BL.TraceLineReuse(key, data)
        local t = _tracePools[key]
        if not t then
            t = {}
            _tracePools[key] = t
        end
        t.start = data.start
        t.endpos = data.endpos
        t.filter = data.filter
        t.mask = data.mask
        t.mins = data.mins
        t.maxs = data.maxs
        return util.TraceLine(t)
    end

    -- Check if the local player is holding a specific weapon class
    function BL.IsPlayerHoldingWeapon(weaponClass)
        local ply = LocalPlayer()
        if not IsValid(ply) then return false end
        local wep = ply:GetActiveWeapon()
        return IsValid(wep) and wep:GetClass() == weaponClass
    end

    -- Perform a trace from the player's eye position in the direction they're looking
    function BL.GetPlayerEyeTrace(distance, filter)
        local ply = LocalPlayer()
        if not IsValid(ply) then return nil end
        local start = ply:EyePos()
        local endpos = start + ply:EyeAngles():Forward() * (distance or 8192)
        return util.TraceLine({
            start = start,
            endpos = endpos,
            filter = filter or ply
        })
    end

    -- Linearly interpolate between two RGB colors
    function BL.LerpColor(r1, g1, b1, r2, g2, b2, t)
        t = math.Clamp(t, 0, 1)
        return math.floor(r1 + (r2 - r1) * t),
               math.floor(g1 + (g2 - g1) * t),
               math.floor(b1 + (b2 - b1) * t)
    end

    -- Calculate a natural-looking flicker effect using layered sine waves
    function BL.CreateFlickerEffect(baseValue, time, speed, amount, phase)
        phase = phase or 0
        local osc = 0.65 * math.sin(time * speed + phase) + 0.35 * math.sin(time * (speed * 1.7) + phase * 1.13)
        return math.max(0.1, baseValue * (1 + amount * osc))
    end

    -- Unified entity variant detection (for hacked, friendly, guardian variants, etc.)
    -- Returns true if entity matches any of the provided detection criteria
    function BL.DetectEntityVariant(ent, options)
        if not IsValid(ent) then return false end
        
        options = options or {}
        local debugName = options.debugName or "variant"
        local debugCvar = options.debugCvar
        
        -- 1) Check entity class matches
        if options.classes then
            local class = ent:GetClass()
            for _, checkClass in ipairs(options.classes) do
                if class == checkClass then
                    if debugCvar and debugCvar:GetBool() then
                        print(string.format("[BetterLights] Entity #%d detected as %s via class: %s", ent:EntIndex(), debugName, class))
                    end
                    return true
                end
            end
        end
        
        -- 2) Check NWBools
        if options.nwBools and ent.GetNWBool then
            for _, key in ipairs(options.nwBools) do
                if ent:GetNWBool(key, false) then
                    if debugCvar and debugCvar:GetBool() then
                        print(string.format("[BetterLights] Entity #%d detected as %s via NWBool: %s", ent:EntIndex(), debugName, key))
                    end
                    return true
                end
            end
        end
        
        -- 3) Check SaveTable flags
        if options.saveTableKeys and ent.GetSaveTable then
            local ok, st = pcall(ent.GetSaveTable, ent)
            if ok and st then
                for _, key in ipairs(options.saveTableKeys) do
                    if st[key] == true or st[key] == 1 then
                        if debugCvar and debugCvar:GetBool() then
                            print(string.format("[BetterLights] Entity #%d detected as %s via SaveTable: %s", ent:EntIndex(), debugName, key))
                        end
                        return true
                    end
                end
                
                -- Check for keyword in any SaveTable key
                if options.saveTableKeyword then
                    for k, v in pairs(st) do
                        local lk = tostring(k):lower()
                        if lk:find(options.saveTableKeyword, 1, true) and (v == true or v == 1) then
                            if debugCvar and debugCvar:GetBool() then
                                print(string.format("[BetterLights] Entity #%d detected as %s via SaveTable keyword '%s': %s", ent:EntIndex(), debugName, options.saveTableKeyword, k))
                            end
                            return true
                        end
                    end
                end
            end
        end
        
        -- 4) Check Disposition (relationship with player)
        if options.checkDisposition and ent.Disposition then
            local lp = LocalPlayer()
            if IsValid(lp) then
                local ok, disp = pcall(function() return ent:Disposition(lp) end)
                if ok and disp == D_LI then
                    if debugCvar and debugCvar:GetBool() then
                        print(string.format("[BetterLights] Entity #%d detected as %s via Disposition", ent:EntIndex(), debugName))
                    end
                    return true
                end
            end
        end
        
        -- 5) Check skin value
        if options.skin and ent.GetSkin then
            local ok, skin = pcall(ent.GetSkin, ent)
            if ok and type(skin) == "number" then
                if type(options.skin) == "number" then
                    if skin == options.skin then
                        if debugCvar and debugCvar:GetBool() then
                            print(string.format("[BetterLights] Entity #%d detected as %s via skin: %d", ent:EntIndex(), debugName, skin))
                        end
                        return true
                    end
                elseif type(options.skin) == "function" then
                    if options.skin(skin) then
                        if debugCvar and debugCvar:GetBool() then
                            print(string.format("[BetterLights] Entity #%d detected as %s via skin check: %d", ent:EntIndex(), debugName, skin))
                        end
                        return true
                    end
                end
            end
        end
        
        -- 6) Check targetname
        if options.targetname and ent.GetName then
            local ok, name = pcall(ent.GetName, ent)
            if ok and isstring(name) then
                local nm = string.lower(name)
                if nm:find(options.targetname, 1, true) then
                    if debugCvar and debugCvar:GetBool() then
                        print(string.format("[BetterLights] Entity #%d detected as %s via targetname: %s", ent:EntIndex(), debugName, name))
                    end
                    return true
                end
            end
        end
        
        return false
    end

    -- Get attachment position with cached lookup
    function BL.GetAttachmentPosById(ent, attachId)
        if not IsValid(ent) or not attachId or attachId == 0 then return nil end
        local data = ent:GetAttachment(attachId)
        return (data and data.Pos) or nil
    end
    
    -- Get bone position with fallback logic (tries GetBoneMatrix first, then GetBonePosition)
    function BL.GetBonePosition(ent, boneName)
        if not IsValid(ent) or not boneName then return nil end
        if not ent.LookupBone then return nil end
        
        local bone = ent:LookupBone(boneName)
        if not bone or bone < 0 then return nil end
        
        -- Try GetBoneMatrix first (more accurate)
        if ent.GetBoneMatrix then
            local m = ent:GetBoneMatrix(bone)
            if m then
                local pos = m:GetTranslation()
                if pos and pos ~= vector_origin then
                    return pos
                end
            end
        end
        
        -- Fallback to GetBonePosition
        if ent.GetBonePosition then
            local pos = ent:GetBonePosition(bone)
            if pos and pos ~= vector_origin then
                return pos
            end
        end
        
        return nil
    end
    
    -- Detect entity variant by skin value (common pattern for colored variants)
    function BL.DetectSkinVariant(ent, skinMap)
        if not IsValid(ent) or not skinMap then return nil end
        local skin = (ent.GetSkin and ent:GetSkin()) or 0
        return skinMap[skin]
    end
    
    -- Detect entity type by model pattern and optionally return skin-based variant
    function BL.DetectModelVariant(ent, modelPatterns)
        if not IsValid(ent) or not modelPatterns then return nil end
        local model = ent:GetModel() or ""
        local skin = (ent.GetSkin and ent:GetSkin()) or 0
        
        for _, pattern in ipairs(modelPatterns) do
            if BL.MatchesModel(ent, pattern.model) then
                if pattern.skinMap then
                    return pattern.skinMap[skin] or pattern.default
                end
                return pattern.default
            end
        end
        return nil
    end
    
    -- Create light from attachment (common pattern)
    function BL.CreateLightFromAttachment(ent, attachNames, r, g, b, brightness, decay, size, isElight)
        if not IsValid(ent) then return false end
        
        local attachId = BL.LookupAttachmentCached(ent, attachNames)
        if not attachId or attachId == 0 then return false end
        
        local pos = BL.GetAttachmentPosById(ent, attachId)
        if not pos then return false end
        
        BL.CreateDLight(ent:EntIndex(), pos, r, g, b, brightness, decay, size, isElight)
        return true
    end

    -- Core Think loop: executes all registered Think functions every frame
    hook.Add("Think", "BetterLights_CoreThink", function()
        -- Update global flash manager first
        BL.UpdateFlashes()
        
        -- Execute all registered Think functions
        for name, fn in pairs(BL._thinks) do
            local ok, err = pcall(fn)
            if not ok then
                BL._thinks[name] = nil
                if debug and debug.traceback then
                    MsgC(Color(255,100,100), "[BetterLights] Think '"..tostring(name).."' error: "..tostring(err).."\n")
                end
            end
        end
    end)

    -- Entity tracking: automatically register entities as they're created
    hook.Add("OnEntityCreated", "BetterLights_CoreTrackCreate", function(ent)
        timer.Simple(0, function()
            if not IsValid(ent) then return end
            local cls = (ent.GetClass and ent:GetClass()) or ""
            if BL._classes[cls] then
                BL._tracked[cls] = BL._tracked[cls] or {}
                BL._tracked[cls][ent] = true
            end
        end)
    end)

    -- Entity tracking: clean up and call removal handlers when entities are removed
    hook.Add("EntityRemoved", "BetterLights_CoreTrackRemove", function(ent, fullUpdate)
        if fullUpdate then return end
        if not ent then return end
        local cls = (ent.GetClass and ent:GetClass()) or nil
        if not cls then return end
        
        local set = BL._tracked[cls]
        if set and set[ent] then set[ent] = nil end
        
        local handlers = BL._removeHandlers[cls]
        if handlers then
            for _, fn in ipairs(handlers) do
                pcall(fn, ent)
            end
        end
    end)
end
