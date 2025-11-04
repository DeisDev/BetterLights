-- BetterLights Core: central Think aggregator and entity class tracking
-- Loads early (00_) so other modules can register safely

if CLIENT then
    BetterLights = BetterLights or {}

    local BL = BetterLights
    BL._thinks = BL._thinks or {}
    BL._classes = BL._classes or {}      -- set of classnames to track
    BL._tracked = BL._tracked or {}      -- classname -> set { [ent]=true }
    BL._removeHandlers = BL._removeHandlers or {} -- classname -> { fn, ... }
    BL._tickers = BL._tickers or {}              -- name -> next time
    BL._attachCache = BL._attachCache or {}      -- model -> { [name]=id }
    BL._pixHandles = BL._pixHandles or {}        -- key -> pixelvis handle

    -- Global culling controls
    local cvar_cull_enable   = CreateClientConVar("betterlights_cull_enable", "1", true, false, "Cull lights that are not visible in the player's view")
    local cvar_cull_maxdist  = CreateClientConVar("betterlights_cull_maxdist", "2200", true, false, "Maximum distance at which lights are updated (units)")
    local cvar_cull_minfrac  = CreateClientConVar("betterlights_cull_minfrac", "0.025", true, false, "Minimum util.PixelVisible fraction to consider a light visible")
    -- -1 allows behind; 0 = only in front hemisphere; 0.2 = narrower cone
    local cvar_cull_fov_cos  = CreateClientConVar("betterlights_cull_fov_cos", "0.0", true, false, "Minimum dot(viewForward, dirToLight) required (-1..1)")

    function BL.AddThink(name, fn)
        if not isfunction(fn) then return end
        BL._thinks[name] = fn
    end

    function BL.RemoveThink(name)
        BL._thinks[name] = nil
    end

    -- Throttle helper: return true when it's time to update again
    -- hz > 0 means updates per second; hz <= 0 updates every frame
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

    -- Attachment helpers with per-model id cache to avoid repeated string lookups
    -- names: array of possible attachment names to try in order
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

    function BL.GetAttachmentPos(ent, names)
        local id = BL.LookupAttachmentCached(ent, names)
        if id and ent.GetAttachment then
            local att = ent:GetAttachment(id)
            if att and att.Pos then return att.Pos end
        end
        return nil
    end

    -- Lightweight trace builder that reuses a table per key to reduce GC
    local _tracePools = {}
    function BL.TraceLineReuse(key, data)
        local t = _tracePools[key]
        if not t then
            t = {}
            _tracePools[key] = t
        end
        -- manual copy (avoid table.clear to be safe in Lua 5.1)
        t.start = data.start
        t.endpos = data.endpos
        t.filter = data.filter
        t.mask = data.mask
        t.mins = data.mins
        t.maxs = data.maxs
        return util.TraceLine(t)
    end

    -- Visibility culling helper
    -- key: stable identifier per light stream (string/number)
    -- pos: Vector of light position; radius: approximate light radius
    function BL.ShouldRenderAt(key, pos, radius)
        if not cvar_cull_enable:GetBool() then return true end
        if not pos then return true end
        local lp = LocalPlayer()
        if not IsValid(lp) then return true end
        local eye = lp:EyePos()
        local to = pos - eye
        local distSqr = to:LengthSqr()
        local maxd = cvar_cull_maxdist:GetFloat()
        if maxd > 0 and distSqr > (maxd * maxd) then return false end
        local fwd = lp:EyeAngles():Forward()
        local fovCos = math.Clamp(cvar_cull_fov_cos:GetFloat(), -1, 1)
        local dot = to:GetNormalized():Dot(fwd)
        if dot < fovCos then return false end
        -- Pixel visibility test (occlusion-aware)
        local k = tostring(key)
        local handle = BL._pixHandles[k]
        if not handle and util.GetPixelVisibleHandle then
            handle = util.GetPixelVisibleHandle()
            BL._pixHandles[k] = handle
        end
        -- Heuristic: skip expensive pixel visibility for elights (model-only) using the ":e" suffix convention
        local isElightKey = string.sub(k, -2) == ":e"
        if (not isElightKey) and handle and util.PixelVisible then
            local r = math.max(4, (tonumber(radius) or 0) * 0.25)
            local frac = util.PixelVisible(pos, r, handle) or 0
            if frac < cvar_cull_minfrac:GetFloat() then return false end
        end
        return true
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
