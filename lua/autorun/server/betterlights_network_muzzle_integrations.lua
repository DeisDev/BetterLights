if SERVER then
    local BL = BetterLights
    local MF = BL.MuzzleFlash

    local MWBASE_ATTACHMENTS = { "muzzle", "tag_flash", "tag_muzzle", "tag_barrel", "tag_tip", "tip" }
    local getWeaponBase = MF.GetWeaponBase

    local function isArc9Weapon(weapon)
        if not IsValid(weapon) then return false end
        if weapon.ARC9 == true then return true end

        local base = getWeaponBase(weapon)
        return base == "arc9_base" or string.find(base, "arc9", 1, true) ~= nil
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

    MF.RegisterAdapter("arc9", {
        matches = isArc9Weapon
    })

    MF.RegisterAdapter("mwbase", {
        matches = isMwBaseWeapon
    })

    MF.RegisterWeaponRule({
        id = "builtin_mwbase",
        adapter = "mwbase",
        profile = "default",
        priority = -900,
        attachments = MWBASE_ATTACHMENTS,
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

    local function scanAdapterWeapons()
        for _, ent in ipairs(ents.GetAll()) do
            wrapArc9DoEffects(ent)
            wrapMwBaseProjectiles(ent)
        end
    end

    hook.Add("OnEntityCreated", "BetterLights_MuzzleFlash_Adapters_Server", function(ent)
        timer.Simple(0, function()
            if IsValid(ent) then
                wrapArc9DoEffects(ent)
                wrapMwBaseProjectiles(ent)
            end
        end)
    end)

    hook.Add("InitPostEntity", "BetterLights_MuzzleFlash_Adapters_Init_Server", scanAdapterWeapons)
    timer.Create("BetterLights_MuzzleFlash_Adapters_Scan_Server", 2, 0, scanAdapterWeapons)
end
