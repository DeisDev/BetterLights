-- BetterLights Core
-- Provides centralized Think aggregator, entity tracking system, and utility functions for lighting modules
-- See README.md for full API documentation

if CLIENT then
    BetterLights = BetterLights or {}

    local BL = BetterLights
    BL._thinks = BL._thinks or {}
    BL._classes = BL._classes or {}
    BL._tracked = BL._tracked or {}
    BL._removeHandlers = BL._removeHandlers or {}
    BL._tickers = BL._tickers or {}
    BL._attachCache = BL._attachCache or {}

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

    -- Core Think loop: executes all registered Think functions every frame
    hook.Add("Think", "BetterLights_CoreThink", function()
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
