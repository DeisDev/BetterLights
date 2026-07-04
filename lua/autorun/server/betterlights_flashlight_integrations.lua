if SERVER then
    local BL = BetterLights
    local FL = BL.Flashlight

    local MWBASE_FLASHLIGHT_HOOK = "MW19_PlayerSwitchFlashlight"
    local getWeaponBase = FL.GetWeaponBase

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
            clearActiveMwBaseFlashlightFlag(ply)
        end
    })
end
