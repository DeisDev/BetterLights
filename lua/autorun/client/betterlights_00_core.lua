-- BetterLights Core: central Think aggregator and entity class tracking
-- Loads early (00_) so other modules can register safely

if CLIENT then
    BetterLights = BetterLights or {}

    local BL = BetterLights
    BL._thinks = BL._thinks or {}
    BL._classes = BL._classes or {}      -- set of classnames to track
    BL._tracked = BL._tracked or {}      -- classname -> set { [ent]=true }
    BL._removeHandlers = BL._removeHandlers or {} -- classname -> { fn, ... }

    function BL.AddThink(name, fn)
        if not isfunction(fn) then return end
        BL._thinks[name] = fn
    end

    function BL.RemoveThink(name)
        BL._thinks[name] = nil
    end

    -- Utility unique light id for ephemeral flashes
    BL._idCounter = BL._idCounter or 0
    function BL.NewLightId(base)
        BL._idCounter = (BL._idCounter + 1) % 4096
        return (base or 60000) + BL._idCounter
    end

    -- Track a classname's instances via OnEntityCreated + initial seed
    function BL.TrackClass(classname)
        if type(classname) ~= "string" or classname == "" then return end
        if BL._classes[classname] then return end
        BL._classes[classname] = true
        BL._tracked[classname] = BL._tracked[classname] or {}
        -- seed existing
        timer.Simple(0, function()
            if not BL._classes[classname] then return end
            for _, ent in ipairs(ents.FindByClass(classname)) do
                if IsValid(ent) then BL._tracked[classname][ent] = true end
            end
        end)
    end

    -- Iterate tracked instances
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

    -- Register an on-remove handler for a specific classname
    function BL.AddRemoveHandler(classname, fn)
        if type(classname) ~= "string" or not isfunction(fn) then return end
        BL._removeHandlers[classname] = BL._removeHandlers[classname] or {}
        table.insert(BL._removeHandlers[classname], fn)
    end

    -- Utility for safe center position of an entity
    function BL.SafeCenter(ent)
        if not IsValid(ent) then return nil end
        if ent.LocalToWorld and ent.OBBCenter then
            return ent:LocalToWorld(ent:OBBCenter())
        elseif ent.WorldSpaceCenter then
            return ent:WorldSpaceCenter()
        else
            return ent:GetPos()
        end
    end

    -- Single aggregator Think
    hook.Add("Think", "BetterLights_CoreThink", function()
        for name, fn in pairs(BL._thinks) do
            local ok, err = pcall(fn)
            if not ok then
                -- Prevent hard error loops; drop faulty think until reload
                BL._thinks[name] = nil
                if debug and debug.traceback then
                    MsgC(Color(255,100,100), "[BetterLights] Think '"..tostring(name).."' error: "..tostring(err).."\n")
                end
            end
        end
    end)

    -- Single class-aware OnEntityCreated
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

    -- Single cleanup + per-class removal dispatch
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
                local ok = xpcall(function() fn(ent) end, debug.traceback)
                if not ok then
                    -- ignore handler errors
                end
            end
        end
    end)
end
