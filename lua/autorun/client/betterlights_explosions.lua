if CLIENT then
    local BL = BetterLights

    local cvar_enable = BL.CreateClientConVar("betterlights_explosion_flash_enable", "1", true, false, "Enable generic explosion flashes (env_explosion, explosive barrels, etc.)")
    local cvar_size = BL.CreateClientConVar("betterlights_explosion_flash_size", "380", true, false, "Generic explosion flash radius")
    local cvar_brightness = BL.CreateClientConVar("betterlights_explosion_flash_brightness", "4.6", true, false, "Generic explosion flash brightness")
    local cvar_time = BL.CreateClientConVar("betterlights_explosion_flash_time", "0.18", true, false, "Generic explosion flash duration (seconds)")
    local cvar_r = BL.CreateClientConVar("betterlights_explosion_flash_color_r", "255", true, false, "Explosion flash color - red component (0-255)")
    local cvar_g = BL.CreateClientConVar("betterlights_explosion_flash_color_g", "210", true, false, "Explosion flash color - green component (0-255)")
    local cvar_b = BL.CreateClientConVar("betterlights_explosion_flash_color_b", "120", true, false, "Explosion flash color - blue component (0-255)")

    local cvar_detect_env = BL.CreateClientConVar("betterlights_explosion_detect_env", "1", true, false, "Detect env_explosion/env_physexplosion/env_ar2explosion entities")
    local cvar_detect_barrel = BL.CreateClientConVar("betterlights_explosion_detect_barrels", "1", true, false, "Detect explosive barrels by removal (oildrum001_explosive model)")
    local cvar_detect_scanner = BL.CreateClientConVar("betterlights_explosion_detect_scanners", "1", true, false, "Detect scanner explosions (npc_cscanner, npc_clawscanner)")
    local cvar_detect_mine = BL.CreateClientConVar("betterlights_explosion_detect_mines", "1", true, false, "Detect combine mine explosions (combine_mine)")

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

    local function isExplosiveBarrel(ent)
        return BL.MatchesModel(ent, "oildrum001_explosive")
    end

    local function isScanner(ent)
        return BL.IsEntityClass(ent, {"npc_cscanner", "npc_clawscanner"})
    end

    local function isCombineMine(ent)
        return BL.IsEntityClass(ent, "combine_mine")
    end

    local trackedScanners = {}
    local trackedMines = {}

    hook.Add("OnEntityCreated", "BetterLights_Scanner_Track", function(ent)
        timer.Simple(0, function()
            if not IsValid(ent) then return end

            if cvar_detect_scanner:GetBool() and isScanner(ent) then
                trackedScanners[ent] = ent:GetPos()
            end

            if cvar_detect_mine:GetBool() and isCombineMine(ent) then
                trackedMines[ent] = ent:GetPos()
            end
        end)
    end)

    hook.Add("EntityRemoved", "BetterLights_Explosion_OnBarrelRemoved", function(ent, fullUpdate)
        if fullUpdate then return end

        if cvar_detect_barrel:GetBool() and IsValid(ent) and BL.IsEntityClass(ent, {"prop_physics", "prop_physics_multiplayer"}) and isExplosiveBarrel(ent) then
            local pos = ent.WorldSpaceCenter and ent:WorldSpaceCenter() or ent:GetPos()
            spawnFlashAt(pos)
        end

        if cvar_detect_scanner:GetBool() then
            local lastPos = trackedScanners[ent]
            if lastPos then
                local pos = IsValid(ent) and ent.WorldSpaceCenter and ent:WorldSpaceCenter() or lastPos
                spawnFlashAt(pos)
                trackedScanners[ent] = nil
            end
        end

        if cvar_detect_mine:GetBool() then
            local lastPos = trackedMines[ent]
            if lastPos then
                local pos = IsValid(ent) and ent.WorldSpaceCenter and ent:WorldSpaceCenter() or lastPos
                spawnFlashAt(pos)
                trackedMines[ent] = nil
            end
        end
    end)
    BL.AddThink("BetterLights_Explosion_Track", function()
        if cvar_detect_scanner:GetBool() then
            for ent, _ in pairs(trackedScanners) do
                if IsValid(ent) then
                    trackedScanners[ent] = ent:GetPos()
                else
                    trackedScanners[ent] = nil
                end
            end
        else
            trackedScanners = {}
        end

        if cvar_detect_mine:GetBool() then
            for ent, _ in pairs(trackedMines) do
                if IsValid(ent) then
                    trackedMines[ent] = ent:GetPos()
                else
                    trackedMines[ent] = nil
                end
            end
        else
            trackedMines = {}
        end
    end)
end
