if SERVER then
    local BL = BetterLights
    local MF = BL.MuzzleFlash

    local ARCCW_ATTACHMENTS = { "muzzle", "1" }
    local MWBASE_ATTACHMENTS = { "muzzle", "tag_flash", "tag_muzzle", "tag_barrel", "tag_tip", "tip" }
    local CW2_ATTACHMENTS = { "muzzle", "1" }
    local TFA_ATTACHMENTS = { "muzzle", "1" }
    local WEAPON_WRAPPER_VERSION = 1
    local getWeaponBase = MF.GetWeaponBase

    local function isArc9Weapon(weapon)
        if not IsValid(weapon) then return false end
        if weapon.ARC9 == true then return true end

        local base = getWeaponBase(weapon)
        return base == "arc9_base" or string.find(base, "arc9", 1, true) ~= nil
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

    local function isBasedOn(weapon, base)
        if not (IsValid(weapon) and weapons and weapons.IsBasedOn and weapon.GetClass) then return false end

        local className = weapon:GetClass()
        return className ~= "" and weapons.IsBasedOn(className, base)
    end

    local function isCW2Weapon(weapon)
        if not IsValid(weapon) then return false end
        if weapon.CW20Weapon == true then return true end

        return getWeaponBase(weapon) == "cw_base" or isBasedOn(weapon, "cw_base")
    end

    local function isCW2MeleeWeapon(weapon)
        if not isCW2Weapon(weapon) then return false end

        return getWeaponBase(weapon) == "cw_melee_base" or isBasedOn(weapon, "cw_melee_base")
    end

    local function isCW2NonFirearm(weapon)
        return isCW2MeleeWeapon(weapon)
            or (isCW2Weapon(weapon) and (getWeaponBase(weapon) == "cw_grenade_base" or isBasedOn(weapon, "cw_grenade_base")))
    end

    local function isTFAWeapon(weapon)
        if not IsValid(weapon) then return false end
        if weapon.IsTFAWeapon == true then return true end

        local base = getWeaponBase(weapon)
        return base == "tfa_gun_base"
            or base == "tfa_melee_base"
            or isBasedOn(weapon, "tfa_gun_base")
            or isBasedOn(weapon, "tfa_melee_base")
    end

    MF.RegisterAdapter("arc9", {
        matches = isArc9Weapon
    })

    MF.RegisterAdapter("arccw", {
        matches = isArcCWWeapon
    })

    MF.RegisterAdapter("mwbase", {
        matches = isMwBaseWeapon
    })

    MF.RegisterAdapter("cw2", {
        matches = isCW2Weapon,
        shouldHandleBullet = function(_, weapon)
            return not isCW2NonFirearm(weapon)
        end
    })

    MF.RegisterAdapter("tfa", {
        matches = isTFAWeapon,
        shouldHandleBullet = function()
            return false
        end
    })

    MF.RegisterWeaponRule({
        id = "builtin_mwbase",
        adapter = "mwbase",
        profile = "default",
        priority = -900,
        attachments = MWBASE_ATTACHMENTS,
        source = "builtin"
    })

    MF.RegisterWeaponRule({
        id = "builtin_arccw",
        adapter = "arccw",
        profile = "default",
        priority = -875,
        attachments = ARCCW_ATTACHMENTS,
        source = "builtin"
    })

    MF.RegisterWeaponRule({
        id = "builtin_cw2",
        adapter = "cw2",
        profile = "default",
        priority = -850,
        attachments = CW2_ATTACHMENTS,
        source = "builtin"
    })

    MF.RegisterWeaponRule({
        id = "builtin_tfa",
        adapter = "tfa",
        profile = "default",
        priority = -825,
        attachments = TFA_ATTACHMENTS,
        source = "builtin"
    })

    local function wrapArc9DoEffects(weapon)
        if not isArc9Weapon(weapon) then return end
        if weapon.BetterLightsArc9DoEffectsWrapped then return end
        if not isfunction(weapon.DoEffects) then return end

        local original = weapon.DoEffects
        weapon.BetterLightsArc9DoEffectsWrapped = true
        weapon.BetterLightsArc9DoEffectsOriginal = original
        weapon.DoEffects = function(self, ...)
            local ret = original(self, ...)
            MF.SendAdapterMuzzleFlash(self, "arc9")
            return ret
        end
    end

    local function wrapArcCWDoEffects(weapon)
        if not isArcCWWeapon(weapon) then return end
        if weapon.BetterLightsArcCWDoEffectsWrapped then return end
        if not isfunction(weapon.DoEffects) then return end

        local original = weapon.DoEffects
        weapon.BetterLightsArcCWDoEffectsWrapped = true
        weapon.BetterLightsArcCWDoEffectsOriginal = original
        weapon.DoEffects = function(self, ...)
            local ret = original(self, ...)
            MF.SendAdapterMuzzleFlash(self, "arccw")
            return ret
        end
    end

    local function wrapMwBaseProjectiles(weapon)
        if not isMwBaseWeapon(weapon) then return end
        if weapon.BetterLightsMwBaseProjectilesWrapped then return end
        if not isfunction(weapon.Projectiles) then return end

        local original = weapon.Projectiles
        weapon.BetterLightsMwBaseProjectilesWrapped = true
        weapon.BetterLightsMwBaseProjectilesOriginal = original
        weapon.Projectiles = function(self, ...)
            local ret = original(self, ...)
            MF.SendAdapterMuzzleFlash(self, "mwbase")
            return ret
        end
    end

    local function wrapCW2M203(weapon)
        if not isCW2Weapon(weapon) then return end

        local current = weapon.fireM203
        if not isfunction(current) then return end

        local previousWrapper = weapon.BetterLightsCW2FireM203Wrapper
        if weapon.BetterLightsCW2FireM203Version == WEAPON_WRAPPER_VERSION and current == previousWrapper then return end

        local original = current
        if current == previousWrapper and isfunction(weapon.BetterLightsCW2FireM203Original) then
            original = weapon.BetterLightsCW2FireM203Original
        end

        local wrapper = function(self, ...)
            local ret = original(self, ...)
            MF.SendAdapterMuzzleFlash(self, "cw2")
            return ret
        end

        weapon.BetterLightsCW2FireM203Version = WEAPON_WRAPPER_VERSION
        weapon.BetterLightsCW2FireM203Original = original
        weapon.BetterLightsCW2FireM203Wrapper = wrapper
        weapon.fireM203 = wrapper
    end

    local function scanAdapterWeapons()
        for _, ent in ipairs(ents.GetAll()) do
            wrapArc9DoEffects(ent)
            wrapArcCWDoEffects(ent)
            wrapMwBaseProjectiles(ent)
            wrapCW2M203(ent)
        end
    end

    hook.Add("OnEntityCreated", "BetterLights_MuzzleFlash_Adapters_Server", function(ent)
        timer.Simple(0, function()
            if IsValid(ent) then
                wrapArc9DoEffects(ent)
                wrapArcCWDoEffects(ent)
                wrapMwBaseProjectiles(ent)
                wrapCW2M203(ent)
            end
        end)
    end)

    hook.Add("TFA_MuzzleFlash", "BetterLights_MuzzleFlash_TFA_Server", function(weapon)
        if not isTFAWeapon(weapon) then return end

        MF.SendAdapterMuzzleFlash(weapon, "tfa")
    end)

    hook.Add("InitPostEntity", "BetterLights_MuzzleFlash_Adapters_Init_Server", scanAdapterWeapons)
    timer.Create("BetterLights_MuzzleFlash_Adapters_Scan_Server", 2, 0, scanAdapterWeapons)
end
