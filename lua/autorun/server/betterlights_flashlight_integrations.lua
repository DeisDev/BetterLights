if SERVER then
    local BL = BetterLights
    local FL = BL.Flashlight

    local MWBASE_FLASHLIGHT_HOOK = "MW19_PlayerSwitchFlashlight"
    local getWeaponBase = FL.GetWeaponBase

    local function getActiveWeapon(ply)
        if not (IsValid(ply) and ply.GetActiveWeapon) then return nil end

        return ply:GetActiveWeapon()
    end

    local function isArc9Weapon(weapon)
        if not IsValid(weapon) then return false end
        if weapon.ARC9 == true then return true end

        local base = getWeaponBase(weapon)
        if base == "arc9_base" or string.find(base, "arc9", 1, true) ~= nil then return true end

        if weapons and weapons.IsBasedOn and weapon.GetClass then
            local className = weapon:GetClass()
            if className ~= "" and weapons.IsBasedOn(className, "arc9_base") then return true end
        end

        return false
    end

    local function isArcCWWeapon(weapon)
        if not IsValid(weapon) then return false end
        if weapon.ArcCW == true then return true end

        local base = getWeaponBase(weapon)
        if base == "arccw_base" or string.find(base, "arccw", 1, true) ~= nil then return true end

        if weapons and weapons.IsBasedOn and weapon.GetClass then
            local className = weapon:GetClass()
            if className ~= "" and weapons.IsBasedOn(className, "arccw_base") then return true end
        end

        return false
    end

    local function isMwBaseWeapon(weapon)
        if not IsValid(weapon) then return false end
        if getWeaponBase(weapon) == "mg_base" then return true end

        if weapons and weapons.IsBasedOn and weapon.GetClass then
            local className = weapon:GetClass()
            if className ~= "" and weapons.IsBasedOn(className, "mg_base") then return true end
        end

        return isfunction(weapon.GetStoredAttachment)
            and isfunction(weapon.PlayViewModelAnimation)
            and isfunction(weapon.GetAllAttachmentsInUse)
    end

    local function playerDisablesIntegrationFlashlight(ply, fieldName, matcher)
        if not (IsValid(ply) and ply[fieldName] == true) then return false end

        return matcher(getActiveWeapon(ply))
    end

    local function playerDisablesMwBaseFlashlight(ply)
        return playerDisablesIntegrationFlashlight(ply, "BetterLights_MWBaseFlashlightOverrideDisabled", isMwBaseWeapon)
    end

    local function playerDisablesArcCWFlashlight(ply)
        return playerDisablesIntegrationFlashlight(ply, "BetterLights_ArcCWFlashlightOverrideDisabled", isArcCWWeapon)
    end

    local function playerDisablesArc9Flashlight(ply)
        return playerDisablesIntegrationFlashlight(ply, "BetterLights_ARC9FlashlightOverrideDisabled", isArc9Weapon)
    end

    local function arc9HandlesFlashlightImpulse(ply)
        if playerDisablesArc9Flashlight(ply) then return false end

        local weapon = getActiveWeapon(ply)
        if not isArc9Weapon(weapon) then return false end

        if isfunction(weapon.GetCustomize) then
            local ok, customizing = pcall(weapon.GetCustomize, weapon)
            if ok and customizing == true then return true end
        end

        if not isfunction(weapon.CanToggleAllStatsOnF) then return false end

        local ok, count = pcall(weapon.CanToggleAllStatsOnF, weapon)
        count = ok and tonumber(count) or nil
        return count ~= nil and count > 0
    end

    local function hasMwBaseFlashlightAttachment(weapon)
        if not isMwBaseWeapon(weapon) then return false end
        if not isfunction(weapon.GetFlashlightAttachment) then return false end

        local ok, attachment = pcall(weapon.GetFlashlightAttachment, weapon)
        return ok and attachment ~= nil
    end

    local function clearMwBaseFlashlightFlag(weapon)
        if not hasMwBaseFlashlightAttachment(weapon) then return end
        if not isfunction(weapon.RemoveFlag) then return end

        pcall(weapon.RemoveFlag, weapon, "FlashlightOn")
    end

    local function clearActiveMwBaseFlashlightFlag(ply)
        if not (IsValid(ply) and ply.GetActiveWeapon) then return end

        clearMwBaseFlashlightFlag(ply:GetActiveWeapon())
    end

    local function shouldSuppressMwBaseFlashlightHook(ply, state)
        if playerDisablesMwBaseFlashlight(ply) then return false end
        if state ~= true then return false end
        if not (IsValid(ply) and ply.GetActiveWeapon) then return false end

        return hasMwBaseFlashlightAttachment(ply:GetActiveWeapon())
    end

    FL.RegisterIntegration({
        id = "mwbase",
        priority = 100,
        GetSuppressedPlayerSwitchFlashlightHooks = function(ply, state)
            if not shouldSuppressMwBaseFlashlightHook(ply, state) then return nil end

            return MWBASE_FLASHLIGHT_HOOK
        end,
        OnSetPlayerFlashlight = function(ply)
            if playerDisablesMwBaseFlashlight(ply) then return end

            clearActiveMwBaseFlashlightFlag(ply)
        end,
        IsFlashlightOverrideDisabled = function(ply)
            return playerDisablesMwBaseFlashlight(ply)
        end
    })

    FL.RegisterIntegration({
        id = "arccw",
        priority = 90,
        IsFlashlightOverrideDisabled = function(ply)
            return playerDisablesArcCWFlashlight(ply)
        end
    })

    FL.RegisterIntegration({
        id = "arc9",
        priority = 80,
        HandlesFlashlightImpulse = arc9HandlesFlashlightImpulse,
        IsFlashlightOverrideDisabled = function(ply)
            return playerDisablesArc9Flashlight(ply)
        end
    })

    hook.Add("FlashlightThink", "BetterLights_OxygenStaminaFlashlightBattery", function(ply, data)
        if not (IsValid(ply) and ply:GetNWBool("BetterLights_Flashlight", false)) then return end
        if type(data) ~= "table" then return end

        local battery = tonumber(data.battery)
        if not battery then return end

        local lastBattery = tonumber(data.last_battery)
        if lastBattery and battery < lastBattery then return end

        data.battery = math.max(0, battery - FrameTime())

        if data.battery <= 0 then
            ply:Flashlight(false)
        end
    end)
end
