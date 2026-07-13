if CLIENT then
    local BL = BetterLights
    local FL = BL.Flashlight

    local ARCCW_FLASHLIGHT_ATTACHMENT_NAMES = { "laser", "muzzle", "1" }
    local ARCCW_MUZZLE_ATTACHMENT_NAMES = { "muzzle", "1" }
    local MWBASE_ATTACHMENT_NAMES = { "muzzle", "tag_flash", "tag_muzzle", "tag_barrel", "tag_tip", "tip" }
    local M9K_ATTACHMENT_NAMES = { "1", "muzzle", "Muzzle" }
    local CW2_ATTACHMENT_NAMES = { "muzzle", "1" }
    local TFA_ATTACHMENT_NAMES = { "muzzle", "1" }
    local TFA_FLASHLIGHT_WRAPPER_VERSION = 1
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

    local function isCW2ViewOriginWeapon(weapon)
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

    local function isTFAMeleeWeapon(weapon)
        if not isTFAWeapon(weapon) then return false end
        if weapon.IsMelee == true or weapon.IsKnife == true then return true end

        local base = getWeaponBase(weapon)
        return base == "tfa_melee_base"
            or string.find(base, "tfa_melee", 1, true) ~= nil
            or string.find(base, "tfa_knife", 1, true) ~= nil
            or isBasedOn(weapon, "tfa_melee_base")
    end

    local function isTFAViewOriginWeapon(weapon)
        return isTFAMeleeWeapon(weapon)
            or (IsValid(weapon) and (weapon.IsGrenade == true or weapon.IsBow == true))
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

    local function readTFAStat(weapon, key, fallback)
        if not (IsValid(weapon) and isfunction(weapon.GetStatL)) then return fallback end

        local ok, value = pcall(weapon.GetStatL, weapon, key, fallback)
        if ok and value ~= nil then return value end
        return fallback
    end

    local function readTFARawStat(weapon, key)
        if not (IsValid(weapon) and isfunction(weapon.GetStatRaw)) then return nil end

        local ok, value = pcall(weapon.GetStatRaw, weapon, key, TFA and TFA.LatestDataVersion or nil)
        if ok then return value end
        return nil
    end

    local function getTFAElementModel(weapon, useViewModel)
        local commonName = readTFAStat(weapon, "Flashlight_Element", nil)
        local elementName = readTFAStat(weapon, useViewModel and "Flashlight_VElement" or "Flashlight_WElement", commonName)
        if not elementName then return nil end

        local elements = readTFARawStat(weapon, useViewModel and "ViewModelElements" or "WorldModelElements")
        local element = type(elements) == "table" and elements[elementName] or nil
        local model = type(element) == "table" and element.curmodel or nil
        if IsValid(model) then return model end
        return nil
    end

    local function getTFAFlashlightSource(ply, weapon, useViewModel)
        local elementModel = getTFAElementModel(weapon, useViewModel)
        if IsValid(elementModel) then return elementModel end

        if useViewModel then
            if IsValid(weapon.OwnerViewModel) then return weapon.OwnerViewModel end

            local viewModel = ply.GetViewModel and ply:GetViewModel() or nil
            if IsValid(viewModel) then return viewModel end
        end

        return weapon
    end

    local function reprojectTFAViewModelAngle(ply, weapon, attachment)
        if not (attachment and attachment.Ang) then return nil end

        local ang = Angle(attachment.Ang.p, attachment.Ang.y, attachment.Ang.r)
        local ironProgress = tonumber(weapon.CLIronSightsProgress) or 0
        if weapon.FlashlightISMovement and ironProgress > 0 then
            local ironAngle = readTFAStat(weapon, "IronSightsAngle", nil)
            if ironAngle then
                ang:RotateAroundAxis(ang:Right(), ironAngle.y * (weapon.ViewModelFlip and -1 or 1) * ironProgress)
                ang:RotateAroundAxis(ang:Up(), -ironAngle.x * ironProgress)
            end
        end

        local eyeAngles = EyeAngles()
        local _, localAngle = WorldToLocal(vector_origin, ang, vector_origin, eyeAngles)
        local viewModelFov = tonumber(weapon.ViewModelFOV) or 54
        local factor = viewModelFov ~= 0 and ply:GetFOV() / viewModelFov or 1
        localAngle.p = localAngle.p * factor
        localAngle.y = localAngle.y * factor
        local _, worldAngle = LocalToWorld(vector_origin, localAngle, vector_origin, eyeAngles)
        return worldAngle
    end

    local function getTFAAttachmentTransform(ply, localPlayer, activeWeapon)
        if not isTFAWeapon(activeWeapon) or isTFAViewOriginWeapon(activeWeapon) then return nil end

        local useViewModel = ply == localPlayer and not ply:ShouldDrawLocalPlayer()
        local source = getTFAFlashlightSource(ply, activeWeapon, useViewModel)
        local attachmentId
        local attachmentName

        if useViewModel then
            attachmentId = tonumber(readTFAStat(activeWeapon, "FlashlightAttachment", nil))
            attachmentName = readTFAStat(activeWeapon, "FlashlightAttachmentName", nil)
        else
            attachmentId = tonumber(readTFAStat(activeWeapon, "FlashlightAttachmentWorld", readTFAStat(activeWeapon, "FlashlightAttachment", nil)))
            attachmentName = readTFAStat(activeWeapon, "FlashlightAttachmentNameWorld", readTFAStat(activeWeapon, "FlashlightAttachmentName", nil))
        end

        local attachment = attachmentName and getAttachmentTransformByName(source, attachmentName) or nil
        attachment = attachment or BL.GetAttachmentTransformById(source, attachmentId)

        if not attachment and isfunction(activeWeapon.GetMuzzleAttachment) then
            local ok, muzzleId = pcall(activeWeapon.GetMuzzleAttachment, activeWeapon)
            if ok then attachment = BL.GetAttachmentTransformById(source, tonumber(muzzleId)) end
        end

        attachment = attachment or resolveAttachmentTransform(source, TFA_ATTACHMENT_NAMES)
        if not attachment then return nil end

        return {
            Pos = attachment.Pos,
            Ang = useViewModel and reprojectTFAViewModelAngle(ply, activeWeapon, attachment) or attachment.Ang,
            Bone = attachment.Bone
        }
    end

    local function getCW2AttachmentTransform(ply, localPlayer, activeWeapon)
        if not isCW2Weapon(activeWeapon) or isCW2ViewOriginWeapon(activeWeapon) then return nil end

        local useViewModel = ply == localPlayer and not ply:ShouldDrawLocalPlayer()
        local source
        local attachment

        if useViewModel then
            source = IsValid(activeWeapon.CW_VM) and activeWeapon.CW_VM or ply:GetViewModel()
            local attachmentName = activeWeapon.MuzzleAttachmentName or activeWeapon.MuzzleAttachment or "muzzle"
            attachment = getAttachmentTransformByName(source, attachmentName)
                or BL.GetAttachmentTransformById(source, tonumber(attachmentName))
        else
            source = IsValid(activeWeapon.WMEnt) and activeWeapon.WMEnt or activeWeapon
            attachment = BL.GetAttachmentTransformById(source, tonumber(activeWeapon.WorldMuzzleAttachmentID))
                or resolveAttachmentTransform(source, CW2_ATTACHMENT_NAMES)
        end

        if not attachment then return nil end

        return {
            Pos = attachment.Pos,
            Ang = getPlayerAimAngle(ply),
            Bone = attachment.Bone
        }
    end

    local function isArc9Throwable(weapon)
        if not (isArc9Weapon(weapon) and isfunction(weapon.GetProcessedValue)) then return false end

        local ok, throwable = pcall(weapon.GetProcessedValue, weapon, "Throwable", true)
        return ok and throwable == true
    end

    local function getArc9SubSlots(weapon)
        if not (isArc9Weapon(weapon) and isfunction(weapon.GetSubSlotList)) then return nil end

        local ok, slots = pcall(weapon.GetSubSlotList, weapon)
        if ok and type(slots) == "table" then return slots end
        return nil
    end

    local function getArc9FinalAttachmentTable(weapon, slot)
        if not isfunction(weapon.GetFinalAttTable) then return nil end

        local ok, attachment = pcall(weapon.GetFinalAttTable, weapon, slot)
        if ok and type(attachment) == "table" then return attachment end
        return nil
    end

    local function isVisibleArc9Flashlight(attachment)
        if not attachment or attachment.Flashlight ~= true then return false end

        local brightness = tonumber(attachment.FlashlightBrightness)
        return brightness == nil or brightness > 0
    end

    local function getActiveArc9FlashlightSlot(weapon)
        local slots = getArc9SubSlots(weapon)
        if not slots then return nil, nil, false end

        local hasFlashlight = false

        for i = 1, #slots do
            local slot = slots[i]
            if not slot.Installed then continue end

            local attachment = getArc9FinalAttachmentTable(weapon, slot)
            if isVisibleArc9Flashlight(attachment) then
                return slot, attachment, true
            end
            if not attachment then continue end
            if attachment.Flashlight == true then
                hasFlashlight = true
                continue
            end

            for _, toggle in ipairs(attachment.ToggleStats or {}) do
                if toggle.Flashlight == true then
                    hasFlashlight = true
                    break
                end
            end
        end

        return nil, nil, hasFlashlight
    end

    local function getArc9FlashlightAttachmentTransform(ply, localPlayer, activeWeapon)
        if not isArc9Weapon(activeWeapon) or isArc9Throwable(activeWeapon) then return nil end

        local slot, attachmentTable = getActiveArc9FlashlightSlot(activeWeapon)
        if not slot then return nil end

        local useViewModel = ply == localPlayer and not ply:ShouldDrawLocalPlayer()
        local model = useViewModel and slot.VModel or slot.WModel
        if not IsValid(model) then return nil end

        local attachmentId = tonumber(attachmentTable.FlashlightAttachment)
        local attachment = BL.GetAttachmentTransformById(model, attachmentId)
        if not attachment then
            return {
                Pos = model:GetPos(),
                Ang = model:GetAngles()
            }
        end

        local ang = Angle(attachment.Ang.p, attachment.Ang.y, attachment.Ang.r)
        ang:RotateAroundAxis(ang:Up(), 90)

        return {
            Pos = attachment.Pos,
            Ang = ang,
            Bone = attachment.Bone
        }
    end

    local function getArc9FlashlightState(_, activeWeapon)
        if isIntegrationFlashlightOverrideDisabled("arc9") then return nil end
        if not isArc9Weapon(activeWeapon) or isArc9Throwable(activeWeapon) then return nil end

        local slot, _, hasFlashlight = getActiveArc9FlashlightSlot(activeWeapon)
        if not hasFlashlight then return nil end

        return slot ~= nil
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

    local function shouldReplaceArc9Flashlights()
        if not ProjectedTexture then return false end
        if isIntegrationFlashlightOverrideDisabled("arc9") then return false end
        return BL.IsEnabled() and BL.GetEffectiveFlashlightBool("betterlights_flashlight_player_enable")
    end

    local function pruneArc9FlashlightPile(weapon)
        if not (ARC9 and type(ARC9.FlashlightPile) == "table") then return end

        local kept = {}
        for _, data in pairs(ARC9.FlashlightPile) do
            if type(data) == "table" and data.Weapon == weapon then
                removeProjectedTexture(data.ProjectedTexture)
            else
                kept[#kept + 1] = data
            end
        end

        ARC9.FlashlightPile = kept
    end

    local function clearArc9Flashlights(weapon)
        if not isArc9Weapon(weapon) then return end

        if isfunction(weapon.KillFlashlights) then
            pcall(weapon.KillFlashlights, weapon)
        elseif type(weapon.Flashlights) == "table" then
            for _, data in pairs(weapon.Flashlights) do
                if type(data) == "table" then
                    removeProjectedTexture(data.light)
                end
            end

            weapon.Flashlights = nil
        end

        pruneArc9FlashlightPile(weapon)
    end

    local function wrapArc9FlashlightFunction(weapon, name)
        local original = weapon[name]
        if not isfunction(original) then return end

        local marker = "BetterLightsArc9" .. name .. "Wrapped"
        local store = "BetterLightsArc9" .. name .. "Original"
        if weapon[marker] then return end

        weapon[marker] = true
        weapon[store] = original
        weapon[name] = function(self, ...)
            if shouldReplaceArc9Flashlights() then
                clearArc9Flashlights(self)
                return
            end

            return original(self, ...)
        end
    end

    local function wrapArc9Flashlights(weapon)
        if not isArc9Weapon(weapon) then return end

        wrapArc9FlashlightFunction(weapon, "CreateFlashlights")
        wrapArc9FlashlightFunction(weapon, "DrawFlashlightsVM")
        wrapArc9FlashlightFunction(weapon, "DrawFlashlightsWM")

        if shouldReplaceArc9Flashlights() then
            clearArc9Flashlights(weapon)
        end
    end

    local function shouldReplaceTFAFlashlights(weapon)
        if not ProjectedTexture then return false end
        local owner = IsValid(weapon) and weapon.GetOwner and weapon:GetOwner() or nil
        if IsValid(owner) and owner ~= LocalPlayer() then return false end
        if isIntegrationFlashlightOverrideDisabled("tfa") then return false end
        return BL.IsEnabled() and BL.GetEffectiveFlashlightBool("betterlights_flashlight_player_enable")
    end

    local function clearTFAFlashlight(weapon)
        if not isTFAWeapon(weapon) then return end

        if isfunction(weapon.CleanFlashlight) then
            pcall(weapon.CleanFlashlight, weapon)
            return
        end

        local owner = weapon.GetOwner and weapon:GetOwner() or nil
        if IsValid(owner) and IsValid(owner.TFAFlashlightGun) then
            owner.TFAFlashlightGun:Remove()
        end
    end

    local function wrapTFAToggleFlashlight(weapon)
        local current = weapon.ToggleFlashlight
        if not isfunction(current) then return end

        local previousWrapper = weapon.BetterLightsTFAToggleFlashlightWrapper
        if weapon.BetterLightsTFAToggleFlashlightVersion == TFA_FLASHLIGHT_WRAPPER_VERSION and current == previousWrapper then return end

        local original = current
        if current == previousWrapper and isfunction(weapon.BetterLightsTFAToggleFlashlightOriginal) then
            original = weapon.BetterLightsTFAToggleFlashlightOriginal
        end

        local wrapper = function(self, ...)
            if shouldReplaceTFAFlashlights(self) then return end

            return original(self, ...)
        end

        weapon.BetterLightsTFAToggleFlashlightVersion = TFA_FLASHLIGHT_WRAPPER_VERSION
        weapon.BetterLightsTFAToggleFlashlightOriginal = original
        weapon.BetterLightsTFAToggleFlashlightWrapper = wrapper
        weapon.ToggleFlashlight = wrapper
    end

    local function wrapTFAFlashlight(weapon)
        if not isTFAWeapon(weapon) then return end

        wrapTFAToggleFlashlight(weapon)

        local current = weapon.DrawFlashlight
        if not isfunction(current) then return end

        local previousWrapper = weapon.BetterLightsTFADrawFlashlightWrapper
        if weapon.BetterLightsTFADrawFlashlightVersion == TFA_FLASHLIGHT_WRAPPER_VERSION and current == previousWrapper then
            if shouldReplaceTFAFlashlights(weapon) then clearTFAFlashlight(weapon) end
            return
        end

        local original = current
        if current == previousWrapper and isfunction(weapon.BetterLightsTFADrawFlashlightOriginal) then
            original = weapon.BetterLightsTFADrawFlashlightOriginal
        end

        local wrapper = function(self, ...)
            if shouldReplaceTFAFlashlights(self) then
                clearTFAFlashlight(self)
                return
            end

            return original(self, ...)
        end

        weapon.BetterLightsTFADrawFlashlightVersion = TFA_FLASHLIGHT_WRAPPER_VERSION
        weapon.BetterLightsTFADrawFlashlightOriginal = original
        weapon.BetterLightsTFADrawFlashlightWrapper = wrapper
        weapon.DrawFlashlight = wrapper

        if shouldReplaceTFAFlashlights(weapon) then clearTFAFlashlight(weapon) end
    end

    local function scanFlashlightWeapons()
        for _, ent in ipairs(ents.GetAll()) do
            wrapArcCWFlashlights(ent)
            wrapArc9Flashlights(ent)
            wrapTFAFlashlight(ent)
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
        id = "tfa",
        priority = 130,
        GetAttachmentTransform = getTFAAttachmentTransform,
        UsesViewOrigin = function(_, _, activeWeapon)
            return isTFAViewOriginWeapon(activeWeapon)
        end
    })

    FL.RegisterIntegration({
        id = "arc9",
        priority = 120,
        GetAttachmentTransform = getArc9FlashlightAttachmentTransform,
        GetFlashlightState = getArc9FlashlightState,
        UsesViewOrigin = function(_, _, activeWeapon)
            return isArc9Throwable(activeWeapon)
        end
    })

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
        id = "cw2",
        priority = 95,
        GetAttachmentTransform = getCW2AttachmentTransform,
        UsesViewOrigin = function(_, _, activeWeapon)
            return isCW2ViewOriginWeapon(activeWeapon)
        end
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
                wrapArc9Flashlights(ent)
                wrapTFAFlashlight(ent)
            end
        end)
    end)

    cvars.AddChangeCallback("betterlights_flashlight_player_enable", scanFlashlightWeapons, "BetterLights_ArcCWFlashlightsPlayer")
    cvars.AddChangeCallback("betterlights_integration_arccw_disable_flashlight_override", scanFlashlightWeapons, "BetterLights_ArcCWFlashlightsIntegration")
    cvars.AddChangeCallback("betterlights_integration_arc9_disable_flashlight_override", scanFlashlightWeapons, "BetterLights_ARC9FlashlightsIntegration")
    cvars.AddChangeCallback("betterlights_integration_tfa_disable_flashlight_override", scanFlashlightWeapons, "BetterLights_TFAFlashlightsIntegration")

    hook.Add("BetterLights_EffectiveEnabledChanged", "BetterLights_ArcCWFlashlightsGlobal", scanFlashlightWeapons)
    hook.Add("BetterLights_ServerSettingsChanged", "BetterLights_ArcCWFlashlightsServerSettings", scanFlashlightWeapons)

    hook.Add("InitPostEntity", "BetterLights_Flashlight_ArcCW_Init_Client", scanFlashlightWeapons)
    timer.Create("BetterLights_Flashlight_ArcCW_Scan_Client", 2, 0, scanFlashlightWeapons)
end
