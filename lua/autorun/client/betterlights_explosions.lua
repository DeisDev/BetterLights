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

    local function spawnFlashAt(pos)
        if not cvar_enable:GetBool() then return end
        local dur = math.max(0, cvar_time:GetFloat())
        if dur <= 0 then return end
        if BL.ShouldSuppressFlash("explosion", pos) then return end
        
        local r, g, b = BL.GetColorFromCvars(cvar_r, cvar_g, cvar_b)
        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        
        BL.CreateFlash(pos, r, g, b, size, brightness, dur, 61000)
        BL.RecordFlashPosition("explosion", pos)
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
        return BL.MatchesModel(ent, "oildrum001_explosive")
    end

    -- Detect scanners (they explode when destroyed)
    local function isScanner(ent)
        return BL.IsEntityClass(ent, {"npc_cscanner", "npc_clawscanner"})
    end

    -- Detect combine mines (they explode when triggered)
    local function isCombineMine(ent)
        return BL.IsEntityClass(ent, "combine_mine")
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
            if BL.IsEntityClass(ent, {"prop_physics", "prop_physics_multiplayer"}) and isExplosiveBarrel(ent) then
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

    -- Update tracked entity positions using BL.AddThink
    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_Explosion_Track", function()
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
    end)
end
