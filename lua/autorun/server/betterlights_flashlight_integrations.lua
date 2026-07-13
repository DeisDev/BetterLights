if SERVER then
    local BL = BetterLights
    local FL = BL.Flashlight

    local MWBASE_FLASHLIGHT_HOOK = "MW19_PlayerSwitchFlashlight"
    local TFA_FLASHLIGHT_HOOK = "tfa_toggleflashlight"
    local TFA_TOGGLE_WRAPPER_VERSION = 1
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

    local function isTFAWeapon(weapon)
        if not IsValid(weapon) then return false end
        if weapon.IsTFAWeapon == true then return true end

        local base = getWeaponBase(weapon)
        if base == "tfa_gun_base" or base == "tfa_melee_base" then return true end

        if weapons and weapons.IsBasedOn and weapon.GetClass then
            local className = weapon:GetClass()
            if className ~= "" and (weapons.IsBasedOn(className, "tfa_gun_base") or weapons.IsBasedOn(className, "tfa_melee_base")) then
                return true
            end
        end

        return false
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

    local function playerDisablesTFAFlashlight(ply)
        return playerDisablesIntegrationFlashlight(ply, "BetterLights_TFAFlashlightOverrideDisabled", isTFAWeapon)
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

    local function readTFAStat(weapon, key, fallback)
        if not (IsValid(weapon) and isfunction(weapon.GetStatL)) then return fallback end

        local ok, value = pcall(weapon.GetStatL, weapon, key, fallback)
        if ok and value ~= nil then return value end
        return fallback
    end

    local function hasTFAFlashlightAttachment(weapon)
        if not isTFAWeapon(weapon) then return false end

        local attachmentName = readTFAStat(weapon, "FlashlightAttachmentName", nil)
        if attachmentName ~= nil and attachmentName ~= "" then return true end

        return (tonumber(readTFAStat(weapon, "FlashlightAttachment", 0)) or 0) > 0
    end

    local function shouldSuppressTFAFlashlightHook(ply, state)
        if playerDisablesTFAFlashlight(ply) then return false end
        if state ~= true then return false end
        if not (IsValid(ply) and ply.GetActiveWeapon) then return false end

        return hasTFAFlashlightAttachment(ply:GetActiveWeapon())
    end

    local function clearActiveTFAFlashlightFlag(ply)
        if playerDisablesTFAFlashlight(ply) then return end
        if not (IsValid(ply) and ply.GetActiveWeapon) then return end

        local weapon = ply:GetActiveWeapon()
        if not hasTFAFlashlightAttachment(weapon) then return end
        if not isfunction(weapon.SetFlashlightEnabled) then return end

        pcall(weapon.SetFlashlightEnabled, weapon, false)
    end

    local function betterLightsOwnsTFAFlashlight(ply)
        return IsValid(ply)
            and BL.IsEnabledForPlayer(ply)
            and BL.GetEffectiveServerFlashlightBool("betterlights_flashlight_player_enable", ply.BetterLights_FlashlightEnabled)
            and not playerDisablesTFAFlashlight(ply)
    end

    local function finishTFADeployFlashlightGuard(weapon, ply)
        if not IsValid(ply) then return end
        if ply.BetterLights_TFADeployPreserveFlashlight ~= weapon then return end

        ply.BetterLights_TFADeployPreserveFlashlight = nil
        if IsValid(weapon) and isfunction(weapon.SetFlashlightEnabled) then
            pcall(weapon.SetFlashlightEnabled, weapon, false)
        end
    end

    local function wrapTFAToggleFlashlight(weapon)
        local current = IsValid(weapon) and weapon.ToggleFlashlight or nil
        if not isfunction(current) then return end

        local previousWrapper = weapon.BetterLightsTFAToggleFlashlightWrapper
        if weapon.BetterLightsTFAToggleFlashlightVersion == TFA_TOGGLE_WRAPPER_VERSION and current == previousWrapper then return end

        local original = current
        if current == previousWrapper and isfunction(weapon.BetterLightsTFAToggleFlashlightOriginal) then
            original = weapon.BetterLightsTFAToggleFlashlightOriginal
        end

        local wrapper = function(self, state, ...)
            local owner = self.GetOwner and self:GetOwner() or nil
            if state == true and IsValid(owner) and owner.BetterLights_TFADeployPreserveFlashlight == self then return end

            return original(self, state, ...)
        end

        weapon.BetterLightsTFAToggleFlashlightVersion = TFA_TOGGLE_WRAPPER_VERSION
        weapon.BetterLightsTFAToggleFlashlightOriginal = original
        weapon.BetterLightsTFAToggleFlashlightWrapper = wrapper
        weapon.ToggleFlashlight = wrapper
    end

    hook.Add("TFA_PreDeploy", "BetterLights_TFAFlashlightDeploy_Pre", function(weapon)
        if not hasTFAFlashlightAttachment(weapon) then return end

        local ply = weapon.GetOwner and weapon:GetOwner() or nil
        if not betterLightsOwnsTFAFlashlight(ply) then return end
        if not ply:GetNWBool("BetterLights_Flashlight", false) then return end

        wrapTFAToggleFlashlight(weapon)
        ply.BetterLights_TFADeployPreserveFlashlight = weapon
        timer.Simple(0, function()
            finishTFADeployFlashlightGuard(weapon, ply)
        end)
    end)

    hook.Add("TFA_Deploy", "BetterLights_TFAFlashlightDeploy_Post", function(weapon)
        local ply = IsValid(weapon) and weapon.GetOwner and weapon:GetOwner() or nil
        finishTFADeployFlashlightGuard(weapon, ply)
    end)

    FL.RegisterIntegration({
        id = "tfa",
        priority = 110,
        GetSuppressedPlayerSwitchFlashlightHooks = function(ply, state)
            if not shouldSuppressTFAFlashlightHook(ply, state) then return nil end

            return TFA_FLASHLIGHT_HOOK
        end,
        OnSetPlayerFlashlight = clearActiveTFAFlashlightFlag,
        IsFlashlightOverrideDisabled = function(ply)
            return playerDisablesTFAFlashlight(ply)
        end
    })

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
