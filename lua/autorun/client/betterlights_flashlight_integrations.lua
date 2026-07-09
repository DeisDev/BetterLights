if CLIENT then
    local BL = BetterLights
    local FL = BL.Flashlight

    local ARCCW_FLASHLIGHT_ATTACHMENT_NAMES = { "laser", "muzzle", "1" }
    local ARCCW_MUZZLE_ATTACHMENT_NAMES = { "muzzle", "1" }
    local MWBASE_ATTACHMENT_NAMES = { "muzzle", "tag_flash", "tag_muzzle", "tag_barrel", "tag_tip", "tip" }
    local M9K_ATTACHMENT_NAMES = { "1", "muzzle", "Muzzle" }
    local M9K_BASES = {
        bobs_gun_base = true,
        bobs_scoped_base = true,
        bobs_shotty_base = true
    }
    local getWeaponBase = FL.GetWeaponBase

    local function isIntegrationFlashlightOverrideDisabled(id)
        local cvar = GetConVar("betterlights_integration_" .. id .. "_disable_flashlight_override")
        return cvar and cvar:GetBool()
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

    local function isM9KWeapon(weapon)
        if not IsValid(weapon) then return false end
        if M9K_BASES[getWeaponBase(weapon)] then return true end

        if weapon.GetClass then
            local className = weapon:GetClass()
            if string.StartWith(className, "m9k_") then return true end

            if className ~= "" and weapons and weapons.IsBasedOn then
                for base in pairs(M9K_BASES) do
                    if weapons.IsBasedOn(className, base) then return true end
                end
            end
        end

        return false
    end

    local function getMwBaseViewModel(weapon)
        if not (IsValid(weapon) and isfunction(weapon.GetViewModel)) then return nil end

        local ok, viewModel = pcall(weapon.GetViewModel, weapon)
        if ok and IsValid(viewModel) then return viewModel end
        return nil
    end

    local function getAttachmentTransformByName(ent, attachmentName)
        if not (IsValid(ent) and ent.LookupAttachment) then return nil end

        local attachmentId = ent:LookupAttachment(tostring(attachmentName))
        return BL.GetAttachmentTransformById(ent, attachmentId)
    end

    local function resolveAttachmentTransform(ent, attachmentNames)
        if not IsValid(ent) then return nil end

        for i = 1, #attachmentNames do
            local attachmentName = attachmentNames[i]
            local attachment = getAttachmentTransformByName(ent, attachmentName)

            if not attachment then
                attachment = BL.GetAttachmentTransformById(ent, tonumber(attachmentName))
            end

            if attachment then return attachment end
        end

        return nil
    end

    local function getPlayerAimAngle(ply)
        local aim = ply.GetAimVector and ply:GetAimVector() or nil
        if aim then return aim:Angle() end

        return ply:EyeAngles()
    end

    local function readArcCWBuffOverride(weapon, key, fallback)
        if not (IsValid(weapon) and isfunction(weapon.GetBuff_Override)) then return fallback end

        local ok, value = pcall(weapon.GetBuff_Override, weapon, key, fallback)
        if ok then return value end
        return fallback
    end

    local function readArcCWBuffStat(weapon, key, slot, fallback)
        if not (IsValid(weapon) and isfunction(weapon.GetBuff_Stat)) then return fallback end

        local ok, value = pcall(weapon.GetBuff_Stat, weapon, key, slot)
        if ok and value ~= nil then return value end
        return fallback
    end

    local function readArcCWMuzzleAttachmentId(weapon)
        local attachmentId = readArcCWBuffOverride(weapon, "Override_MuzzleEffectAttachment", weapon.MuzzleEffectAttachment or 1)
        attachmentId = tonumber(attachmentId)
        if attachmentId and attachmentId > 0 then return attachmentId end

        return 1
    end

    local function getArcCWMuzzleDevice(weapon, useViewModel)
        if not (IsValid(weapon) and isfunction(weapon.GetMuzzleDevice)) then return nil end

        local ok, muzzleDevice = pcall(weapon.GetMuzzleDevice, weapon, not useViewModel)
        if ok and IsValid(muzzleDevice) then return muzzleDevice end
        return nil
    end

    local function getArcCWAttachmentElementModel(activeWeapon, slot, useViewModel)
        local attachments = activeWeapon.Attachments
        if type(attachments) ~= "table" then return nil end

        local slotData = attachments[slot]
        if type(slotData) ~= "table" then return nil end

        local element = useViewModel and slotData.VElement or slotData.WElement
        local model = type(element) == "table" and element.Model or nil
        if IsValid(model) then return model end

        return nil
    end

    local function rotateArcCWFlashlightTransform(attachment)
        if not (attachment and attachment.Pos and attachment.Ang) then return nil end

        local ang = Angle(attachment.Ang.p, attachment.Ang.y, attachment.Ang.r)
        ang:RotateAroundAxis(ang:Up(), 90)

        return {
            Pos = attachment.Pos,
            Ang = ang,
            Bone = attachment.Bone
        }
    end

    local function getArcCWFlashlightAttachmentTransform(activeWeapon, useViewModel)
        local attachments = activeWeapon.Attachments
        if type(attachments) ~= "table" then return nil end

        for slot, _ in pairs(attachments) do
            if readArcCWBuffStat(activeWeapon, "Flashlight", slot, false) then
                local bone = readArcCWBuffStat(activeWeapon, "FlashlightBone", slot, "laser")
                local model = getArcCWAttachmentElementModel(activeWeapon, slot, useViewModel)
                local attachment = resolveAttachmentTransform(model, { bone, "muzzle" })

                if not attachment then
                    attachment = resolveAttachmentTransform(model, ARCCW_FLASHLIGHT_ATTACHMENT_NAMES)
                end

                attachment = rotateArcCWFlashlightTransform(attachment)
                if attachment then return attachment end
            end
        end

        return nil
    end

    local function getArcCWMuzzleAttachmentTransform(activeWeapon, useViewModel)
        local muzzleDevice = getArcCWMuzzleDevice(activeWeapon, useViewModel)
        local attachmentId = useViewModel and readArcCWMuzzleAttachmentId(activeWeapon) or 1
        local attachment = BL.GetAttachmentTransformById(muzzleDevice, attachmentId)
            or resolveAttachmentTransform(muzzleDevice, ARCCW_MUZZLE_ATTACHMENT_NAMES)

        if attachment then return attachment end

        return BL.GetAttachmentTransformById(activeWeapon, attachmentId)
            or resolveAttachmentTransform(activeWeapon, ARCCW_MUZZLE_ATTACHMENT_NAMES)
    end

    local function getArcCWAttachmentTransform(ply, localPlayer, activeWeapon)
        if not isArcCWWeapon(activeWeapon) then return nil end

        local useViewModel = ply == localPlayer and not ply:ShouldDrawLocalPlayer()
        local attachment = getArcCWFlashlightAttachmentTransform(activeWeapon, useViewModel)
        if attachment then return attachment end

        return getArcCWMuzzleAttachmentTransform(activeWeapon, useViewModel)
    end

    local function shouldReplaceArcCWFlashlights()
        if not ProjectedTexture then return false end
        if isIntegrationFlashlightOverrideDisabled("arccw") then return false end
        return BL.IsEnabled() and BL.GetEffectiveFlashlightBool("betterlights_flashlight_player_enable")
    end

    local function removeProjectedTexture(light)
        if IsValid(light) then
            light:Remove()
        end
    end

    local function pruneArcCWFlashlightPile(weapon)
        if not (ArcCW and type(ArcCW.FlashlightPile) == "table") then return end

        local kept = {}
        for _, data in pairs(ArcCW.FlashlightPile) do
            if type(data) == "table" and data.Weapon == weapon then
                removeProjectedTexture(data.ProjectedTexture)
            else
                kept[#kept + 1] = data
            end
        end

        ArcCW.FlashlightPile = kept
    end

    local function clearArcCWFlashlights(weapon)
        if not isArcCWWeapon(weapon) then return end

        if isfunction(weapon.KillFlashlightsVM) then
            pcall(weapon.KillFlashlightsVM, weapon)
        elseif type(weapon.Flashlights) == "table" then
            for _, data in pairs(weapon.Flashlights) do
                if type(data) == "table" then
                    removeProjectedTexture(data.light)
                end
            end

            weapon.Flashlights = nil
        end

        pruneArcCWFlashlightPile(weapon)
    end

    local function wrapArcCWFlashlightFunction(weapon, name)
        local original = weapon[name]
        if not isfunction(original) then return end

        local marker = "BetterLightsArcCW" .. name .. "Wrapped"
        local store = "BetterLightsArcCW" .. name .. "Original"
        if weapon[marker] then return end

        weapon[marker] = true
        weapon[store] = original
        weapon[name] = function(self, ...)
            if shouldReplaceArcCWFlashlights() then
                clearArcCWFlashlights(self)
                return
            end

            return original(self, ...)
        end
    end

    local function wrapArcCWFlashlights(weapon)
        if not isArcCWWeapon(weapon) then return end

        wrapArcCWFlashlightFunction(weapon, "CreateFlashlightsVM")
        wrapArcCWFlashlightFunction(weapon, "DrawFlashlightsVM")
        wrapArcCWFlashlightFunction(weapon, "DrawFlashlightsWM")

        if shouldReplaceArcCWFlashlights() then
            clearArcCWFlashlights(weapon)
        end
    end

    local function scanArcCWFlashlightWeapons()
        for _, ent in ipairs(ents.GetAll()) do
            wrapArcCWFlashlights(ent)
        end
    end

    local function getMwBaseFindAttachmentTransform(ent, attachmentName)
        if not (IsValid(ent) and isfunction(ent.FindAttachment)) then return nil end

        local ok, attachmentEnt, attachmentId = pcall(function()
            return ent:FindAttachment(tostring(attachmentName))
        end)

        if not ok then return nil end
        return BL.GetAttachmentTransformById(attachmentEnt, attachmentId)
    end

    local function resolveMwBaseAttachmentTransform(ent, attachmentNames, depth)
        if not IsValid(ent) then return nil end

        for i = 1, #attachmentNames do
            local attachmentName = attachmentNames[i]
            local attachment = getMwBaseFindAttachmentTransform(ent, attachmentName) or getAttachmentTransformByName(ent, attachmentName)

            if not attachment then
                attachment = BL.GetAttachmentTransformById(ent, tonumber(attachmentName))
            end

            if attachment then return attachment end
        end

        if depth >= 3 or not ent.GetChildren then return nil end

        for _, child in ipairs(ent:GetChildren()) do
            local attachment = resolveMwBaseAttachmentTransform(child, attachmentNames, depth + 1)
            if attachment then return attachment end
        end

        return nil
    end

    local function getMwBaseFlashlightAttachmentTransform(activeWeapon, useViewModel)
        if not isfunction(activeWeapon.GetFlashlightAttachment) then return nil end

        local ok, flashlightAttachment = pcall(activeWeapon.GetFlashlightAttachment, activeWeapon)
        if not (ok and type(flashlightAttachment) == "table") then return nil end
        if type(flashlightAttachment.Flashlight) ~= "table" then return nil end

        local attachmentName = flashlightAttachment.Flashlight.Attachment
        if not attachmentName then return nil end

        local model = useViewModel and flashlightAttachment.m_Model or flashlightAttachment.m_TpModel
        local attachment = resolveMwBaseAttachmentTransform(model, { attachmentName }, 0)
        if attachment then return attachment end

        local source = useViewModel and getMwBaseViewModel(activeWeapon) or activeWeapon
        return resolveMwBaseAttachmentTransform(source, { attachmentName }, 0)
    end

    local function getMwBaseAttachmentTransform(ply, localPlayer, activeWeapon)
        if not isMwBaseWeapon(activeWeapon) then return nil end

        local useViewModel = ply == localPlayer and not ply:ShouldDrawLocalPlayer()
        local attachment = getMwBaseFlashlightAttachmentTransform(activeWeapon, useViewModel)
        if attachment then return attachment end

        if useViewModel then
            return resolveMwBaseAttachmentTransform(getMwBaseViewModel(activeWeapon), MWBASE_ATTACHMENT_NAMES, 0)
        end

        return resolveMwBaseAttachmentTransform(activeWeapon, MWBASE_ATTACHMENT_NAMES, 0)
    end

    local function getM9KAttachmentTransform(ply, localPlayer, activeWeapon)
        if not isM9KWeapon(activeWeapon) then return nil end

        local useViewModel = ply == localPlayer and not ply:ShouldDrawLocalPlayer()
        local source = useViewModel and ply:GetViewModel() or activeWeapon
        local attachmentNames = {
            activeWeapon.MuzzleAttachment or "1",
            M9K_ATTACHMENT_NAMES[1],
            M9K_ATTACHMENT_NAMES[2],
            M9K_ATTACHMENT_NAMES[3]
        }
        local attachment = resolveAttachmentTransform(source, attachmentNames)
        if not attachment then return nil end

        return {
            Pos = attachment.Pos,
            Ang = getPlayerAimAngle(ply),
            Bone = attachment.Bone
        }
    end

    FL.RegisterIntegration({
        id = "arccw",
        priority = 110,
        GetAttachmentTransform = getArcCWAttachmentTransform
    })

    FL.RegisterIntegration({
        id = "mwbase",
        priority = 100,
        GetAttachmentTransform = getMwBaseAttachmentTransform
    })

    FL.RegisterIntegration({
        id = "m9k",
        priority = 90,
        GetAttachmentTransform = getM9KAttachmentTransform
    })

    hook.Add("OnEntityCreated", "BetterLights_Flashlight_ArcCW_Client", function(ent)
        timer.Simple(0, function()
            if IsValid(ent) then
                wrapArcCWFlashlights(ent)
            end
        end)
    end)

    cvars.AddChangeCallback("betterlights_flashlight_player_enable", scanArcCWFlashlightWeapons, "BetterLights_ArcCWFlashlightsPlayer")
    cvars.AddChangeCallback("betterlights_integration_arccw_disable_flashlight_override", scanArcCWFlashlightWeapons, "BetterLights_ArcCWFlashlightsIntegration")

    hook.Add("BetterLights_EffectiveEnabledChanged", "BetterLights_ArcCWFlashlightsGlobal", scanArcCWFlashlightWeapons)
    hook.Add("BetterLights_ServerSettingsChanged", "BetterLights_ArcCWFlashlightsServerSettings", scanArcCWFlashlightWeapons)

    hook.Add("InitPostEntity", "BetterLights_Flashlight_ArcCW_Init_Client", scanArcCWFlashlightWeapons)
    timer.Create("BetterLights_Flashlight_ArcCW_Scan_Client", 2, 0, scanArcCWFlashlightWeapons)
end
