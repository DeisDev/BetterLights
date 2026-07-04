if CLIENT then
    local BL = BetterLights
    local MF = BL.MuzzleFlash

    local MWBASE_ATTACHMENTS = { "muzzle", "tag_flash", "tag_muzzle", "tag_barrel", "tag_tip", "tip" }

    local isVector = MF.IsVector
    local getAttachmentById = MF.GetAttachmentById
    local getAttachmentByName = MF.GetAttachmentByName
    local getFirstPersonAttachmentFallback = MF.GetFirstPersonAttachmentFallback
    local buildAttachmentCandidates = MF.BuildAttachmentCandidates
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

    local function arc9OwnLightEnabled(isLocal)
        local light = GetConVar("arc9_muzzle_light")
        if not (light and light:GetBool()) then return false end
        if isLocal then return true end

        local others = GetConVar("arc9_muzzle_others")
        return others and others:GetBool()
    end

    local function readArc9MuzzleDevice(weapon, isLocal)
        if not (IsValid(weapon) and isfunction(weapon.GetMuzzleDevice)) then return nil end

        local ok, device = pcall(function()
            return weapon:GetMuzzleDevice(not isLocal, 1)
        end)

        if ok then return device end
        return nil
    end

    local function arc9HasNoFlash(weapon, isLocal)
        if not IsValid(weapon) then return false end
        if weapon.NoMuzzleEffect == true or weapon.NoFlash == true then return true end

        local device = readArc9MuzzleDevice(weapon, isLocal)
        if type(device) == "table" then
            return device.NoMuzzleEffect == true or device.NoFlash == true or device.Silencer == true
        end

        return false
    end

    local function resolveArc9Muzzle(weapon, isLocal)
        if not IsValid(weapon) then return nil end

        if isLocal and isfunction(weapon.GetQCAMuzzle) then
            local ok, pos = pcall(function()
                return weapon:GetQCAMuzzle()
            end)

            if ok and isVector(pos) then return pos end
            if ok and type(pos) == "table" and isVector(pos.Pos) then return pos.Pos end
        end

        local device = readArc9MuzzleDevice(weapon, isLocal)
        if type(device) == "table" then
            if isVector(device.Pos) then return device.Pos end
            if IsValid(device) and device.GetPos then return device:GetPos() end
        elseif IsValid(device) and device.GetPos then
            return device:GetPos()
        end

        return nil
    end

    local function buildMwBaseAttachmentCandidates(attachments)
        local out = buildAttachmentCandidates(attachments)

        for i = 1, #MWBASE_ATTACHMENTS do
            out[#out + 1] = MWBASE_ATTACHMENTS[i]
        end

        return out
    end

    local function getMwBaseFindAttachmentPos(ent, attachmentName)
        if not (IsValid(ent) and isfunction(ent.FindAttachment)) then return nil end

        local ok, attachmentEnt, attachmentId = pcall(function()
            return ent:FindAttachment(tostring(attachmentName))
        end)

        if not (ok and IsValid(attachmentEnt)) then return nil end
        return getAttachmentById(attachmentEnt, attachmentId)
    end

    local function resolveMwBaseAttachment(ent, candidates, depth)
        if not IsValid(ent) then return nil end

        for i = 1, #candidates do
            local candidate = candidates[i]
            local pos

            if type(candidate) == "number" then
                pos = getAttachmentById(ent, candidate)
            else
                pos = getMwBaseFindAttachmentPos(ent, candidate) or getAttachmentByName(ent, candidate)
                if not pos then
                    pos = getAttachmentById(ent, tonumber(candidate))
                end
            end

            if pos then return pos end
        end

        if depth >= 3 or not ent.GetChildren then return nil end

        for _, child in ipairs(ent:GetChildren()) do
            local pos = resolveMwBaseAttachment(child, candidates, depth + 1)
            if pos then return pos end
        end

        return nil
    end

    local function getMwBaseViewModel(weapon)
        if not (IsValid(weapon) and weapon.GetViewModel) then return nil end

        local viewModel = weapon:GetViewModel()
        if IsValid(viewModel) then return viewModel end
        return nil
    end

    local function resolveMwBaseMuzzle(payload)
        local candidates = buildMwBaseAttachmentCandidates(payload.attachments)
        local viewModel = getMwBaseViewModel(payload.weapon)
        local firstPersonFallback = getFirstPersonAttachmentFallback(payload.shooter)

        if firstPersonFallback then
            if resolveMwBaseAttachment(viewModel, candidates, 0) or resolveMwBaseAttachment(payload.weapon, candidates, 0) then
                return firstPersonFallback
            end

            return nil
        end

        local pos = resolveMwBaseAttachment(payload.weapon, candidates, 0)
        if pos then return pos end

        return resolveMwBaseAttachment(viewModel, candidates, 0)
    end

    MF.RegisterAdapter("arc9", {
        matches = isArc9Weapon,
        suppress = function(payload)
            local isLocal = payload.shooter == LocalPlayer()
            if arc9OwnLightEnabled(isLocal) then return true end
            return arc9HasNoFlash(payload.weapon, isLocal)
        end,
        resolve = function(payload)
            return resolveArc9Muzzle(payload.weapon, payload.shooter == LocalPlayer())
        end
    })

    MF.RegisterAdapter("mwbase", {
        matches = isMwBaseWeapon,
        resolve = resolveMwBaseMuzzle
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
            MF.HandleAdapterShot(self, "arc9")
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
            if IsFirstTimePredicted and not IsFirstTimePredicted() then return ret end
            MF.HandleAdapterShot(self, "mwbase")
            return ret
        end
    end

    local function scanAdapterWeapons()
        for _, ent in ipairs(ents.GetAll()) do
            wrapArc9DoEffects(ent)
            wrapMwBaseProjectiles(ent)
        end
    end

    hook.Add("OnEntityCreated", "BetterLights_MuzzleFlash_Adapters_Client", function(ent)
        timer.Simple(0, function()
            if IsValid(ent) then
                wrapArc9DoEffects(ent)
                wrapMwBaseProjectiles(ent)
            end
        end)
    end)

    hook.Add("InitPostEntity", "BetterLights_MuzzleFlash_Adapters_Init_Client", scanAdapterWeapons)
    timer.Create("BetterLights_MuzzleFlash_Adapters_Scan_Client", 2, 0, scanAdapterWeapons)
end
