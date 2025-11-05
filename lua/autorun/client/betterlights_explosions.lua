-- BetterLights: Generic Explosion Flashes (env_explosion, explosive barrels, etc.)
-- Client-side only

if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
    
    -- Feature toggles and tuning
    local cvar_enable = CreateClientConVar("betterlights_explosion_flash_enable", "1", true, false, "Enable generic explosion flashes (env_explosion, explosive barrels, etc.)")
    local cvar_size = CreateClientConVar("betterlights_explosion_flash_size", "380", true, false, "Generic explosion flash radius")
    local cvar_brightness = CreateClientConVar("betterlights_explosion_flash_brightness", "4.6", true, false, "Generic explosion flash brightness")
    local cvar_time = CreateClientConVar("betterlights_explosion_flash_time", "0.18", true, false, "Generic explosion flash duration (seconds)")
    -- Color config (incremental RGB support)
    local cvar_r = CreateClientConVar("betterlights_explosion_flash_color_r", "255", true, false, "Explosion flash color - red component (0-255)")
    local cvar_g = CreateClientConVar("betterlights_explosion_flash_color_g", "210", true, false, "Explosion flash color - green component (0-255)")
    local cvar_b = CreateClientConVar("betterlights_explosion_flash_color_b", "120", true, false, "Explosion flash color - blue component (0-255)")

    -- Detection toggles
    local cvar_detect_env = CreateClientConVar("betterlights_explosion_detect_env", "1", true, false, "Detect env_explosion/env_physexplosion/env_ar2explosion entities")
    local cvar_detect_barrel = CreateClientConVar("betterlights_explosion_detect_barrels", "1", true, false, "Detect explosive barrels by removal (oildrum001_explosive model)")
    local cvar_detect_scanner = CreateClientConVar("betterlights_explosion_detect_scanners", "1", true, false, "Detect scanner explosions (npc_cscanner, npc_clawscanner)")
    local cvar_detect_mine = CreateClientConVar("betterlights_explosion_detect_mines", "1", true, false, "Detect combine mine explosions (combine_mine)")

    local recent = recent or {}
    local flashes = flashes or {}

    local function shouldSuppress(pos)
        local now = CurTime()
        for i = #recent, 1, -1 do
            local e = recent[i]
            if not e or now - e.t > 0.15 then
                table.remove(recent, i)
            else
                if e.pos:DistToSqr(pos) < (40 * 40) then return true end
            end
        end
        return false
    end

    local function spawnFlashAt(pos)
        if not cvar_enable:GetBool() then return end
        local dur = math.max(0, cvar_time:GetFloat())
        if dur <= 0 then return end
        if shouldSuppress(pos) then return end
        local now = CurTime()
        table.insert(flashes, { pos = pos, start = now, die = now + dur, id = 61000 + (now * 1000 % 3000) })
        table.insert(recent, { pos = pos, t = now })
    end

    -- Detect env_* explosion entities as they spawn
    hook.Add("OnEntityCreated", "BetterLights_Explosion_OnCreated", function(ent)
        if not cvar_detect_env:GetBool() then return end
        timer.Simple(0, function()
            if not IsValid(ent) then return end
            local cls = ent.GetClass and ent:GetClass() or ""
            if cls == "env_explosion" or cls == "env_physexplosion" or cls == "env_ar2explosion" then
                local pos = ent.WorldSpaceCenter and ent:WorldSpaceCenter() or ent:GetPos()
                spawnFlashAt(pos)
            end
        end)
    end)

    -- Detect explosive barrels by removal
    local function isExplosiveBarrel(ent)
        if not IsValid(ent) then return false end
        if not ent.GetModel then return false end
        local m = string.lower(ent:GetModel() or "")
        return string.find(m, "oildrum001_explosive", 1, true) ~= nil
    end

    -- Detect scanners (they explode when destroyed)
    local function isScanner(ent)
        if not IsValid(ent) then return false end
        local cls = ent.GetClass and ent:GetClass() or ""
        return cls == "npc_cscanner" or cls == "npc_clawscanner"
    end

    -- Detect combine mines (they explode when triggered)
    local function isCombineMine(ent)
        if not IsValid(ent) then return false end
        local cls = ent.GetClass and ent:GetClass() or ""
        return cls == "combine_mine"
    end

    -- Track scanners and mines to detect when they're destroyed (not just removed)
    local trackedScanners = {}
    local trackedMines = {}
    
    hook.Add("OnEntityCreated", "BetterLights_Scanner_Track", function(ent)
        timer.Simple(0, function()
            if not IsValid(ent) then return end
            
            if cvar_detect_scanner:GetBool() and isScanner(ent) then
                trackedScanners[ent] = { pos = ent:GetPos() }
            end
            
            if cvar_detect_mine:GetBool() and isCombineMine(ent) then
                trackedMines[ent] = { pos = ent:GetPos() }
            end
        end)
    end)

    hook.Add("EntityRemoved", "BetterLights_Explosion_OnBarrelRemoved", function(ent, fullUpdate)
        if fullUpdate then return end
        if not IsValid(ent) then return end
        
        -- Check for explosive barrels
        if cvar_detect_barrel:GetBool() then
            local cls = ent.GetClass and ent:GetClass() or ""
            if (cls == "prop_physics" or cls == "prop_physics_multiplayer") and isExplosiveBarrel(ent) then
                local pos = ent.WorldSpaceCenter and ent:WorldSpaceCenter() or ent:GetPos()
                spawnFlashAt(pos)
            end
        end
        
        -- Check for scanner explosions
        if cvar_detect_scanner:GetBool() and isScanner(ent) then
            local tracked = trackedScanners[ent]
            if tracked then
                -- Use last known position
                local pos = ent.WorldSpaceCenter and ent:WorldSpaceCenter() or tracked.pos
                spawnFlashAt(pos)
                trackedScanners[ent] = nil
            end
        end
        
        -- Check for combine mine explosions
        if cvar_detect_mine:GetBool() and isCombineMine(ent) then
            local tracked = trackedMines[ent]
            if tracked then
                -- Use last known position
                local pos = ent.WorldSpaceCenter and ent:WorldSpaceCenter() or tracked.pos
                spawnFlashAt(pos)
                trackedMines[ent] = nil
            end
        end
    end)

    -- Render and decay flashes
    hook.Add("Think", "BetterLights_ExplosionFlash_Think", function()
        -- Update tracked scanner and mine positions
        if cvar_detect_scanner:GetBool() then
            for ent, data in pairs(trackedScanners) do
                if IsValid(ent) then
                    data.pos = ent:GetPos()
                else
                    trackedScanners[ent] = nil
                end
            end
        else
            -- Clear tracking if disabled
            trackedScanners = {}
        end
        
        if cvar_detect_mine:GetBool() then
            for ent, data in pairs(trackedMines) do
                if IsValid(ent) then
                    data.pos = ent:GetPos()
                else
                    trackedMines[ent] = nil
                end
            end
        else
            -- Clear tracking if disabled
            trackedMines = {}
        end
        
        if not cvar_enable:GetBool() then return end
        if not flashes or #flashes == 0 then return end
        
        local now = CurTime()
        local baseSize = math.max(0, cvar_size:GetFloat())
        local baseBright = math.max(0, cvar_brightness:GetFloat())
        
        -- Cache color once per frame
        local cr, cg, cb = BL.GetColorFromCvars(cvar_r, cvar_g, cvar_b)

        for i = #flashes, 1, -1 do
            local f = flashes[i]
            if not f or now >= f.die then
                table.remove(flashes, i)
            else
                local dur = math.max(0.001, f.die - f.start)
                local t = (f.die - now) / dur
                local b_eff = baseBright * t
                local s_eff = baseSize * (0.4 + 0.6 * t)
                local d = DynamicLight(f.id or (62000 + i))
                if d then
                    d.pos = f.pos
                    d.r = cr
                    d.g = cg
                    d.b = cb
                    d.brightness = b_eff
                    d.decay = 0
                    d.size = s_eff
                    d.minlight = 0
                    d.noworld = false
                    d.nomodel = false
                    d.dietime = now + 0.05
                end
            end
        end
    end)
end
