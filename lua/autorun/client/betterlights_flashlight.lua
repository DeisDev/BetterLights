if CLIENT then
    local BL = BetterLights

    local cvar_player_enable = BL.CreateClientConVar("betterlights_flashlight_player_enable", "0", true, false, "Enable BetterLights flashlight replacement for your player")
    local cvar_custom_sounds = BL.CreateClientConVar("betterlights_flashlight_custom_sounds", "1", true, false, "Use BetterLights flashlight on/off sounds instead of vanilla flashlight sound events")
    local refreshThinkRegistration
    local CUSTOM_SOUND_ON = "betterlights/flashlight_on.wav"
    local CUSTOM_SOUND_OFF = "betterlights/flashlight_off.wav"
    local DEFAULT_SOUND_ON = "HL2Player.FlashLightOn"
    local DEFAULT_SOUND_OFF = "HL2Player.FlashLightOff"
    local CUSTOM_SOUND_LEVEL = 77
    local ONBOARDING_COOKIE = "betterlights_flashlight_onboarding_seen"

    local function phrase(key)
        return language.GetPhrase("betterlights." .. key)
    end

    local function syncPlayerEnable()
        if not IsValid(LocalPlayer()) then return end

        net.Start(BL.NET_FLASHLIGHT_CLIENT_ENABLE)
            net.WriteBool(cvar_player_enable:GetBool())
        net.SendToServer()
    end

    local function queuePlayerEnableSync()
        syncPlayerEnable()
        timer.Simple(1, syncPlayerEnable)
        timer.Simple(3, syncPlayerEnable)
    end

    local function showOnboardingTip(force)
        if not force and cookie.GetString(ONBOARDING_COOKIE, "") == "1" then return end

        if not force then
            cookie.Set(ONBOARDING_COOKIE, "1")
        end

        timer.Simple(force and 0 or 4, function()
            if not force and cvar_player_enable:GetBool() then return end
            notification.AddLegacy(phrase("notice.flashlight_onboarding"), NOTIFY_GENERIC, 6)
            surface.PlaySound("buttons/button15.wav")
        end)
    end

    function BL.ShowFlashlightOnboardingTip(force)
        showOnboardingTip(force)
    end

    hook.Add("InitPostEntity", "BetterLights_FlashlightSyncPlayerEnable", function()
        queuePlayerEnableSync()
        showOnboardingTip(false)
    end)

    cvars.AddChangeCallback("betterlights_flashlight_player_enable", function()
        queuePlayerEnableSync()
        if refreshThinkRegistration then
            refreshThinkRegistration()
        end
    end, "BetterLights_FlashlightPlayerEnable")

    hook.Add("OnReloaded", "BetterLights_FlashlightSyncPlayerEnableReload", function()
        queuePlayerEnableSync()
    end)

    if IsValid(LocalPlayer()) then
        queuePlayerEnableSync()
        showOnboardingTip(false)
    end

    net.Receive(BL.NET_FLASHLIGHT_SOUND, function()
        local ply = net.ReadEntity()
        local state = net.ReadBool()
        if not IsValid(ply) then return end

        if cvar_custom_sounds:GetBool() then
            ply:EmitSound(state and CUSTOM_SOUND_ON or CUSTOM_SOUND_OFF, CUSTOM_SOUND_LEVEL)
        else
            ply:EmitSound(state and DEFAULT_SOUND_ON or DEFAULT_SOUND_OFF)
        end
    end)

    if not ProjectedTexture then return end

    local THINK_NAME = "BetterLights_PlayerFlashlights"

    local cvar_fov = BL.CreateClientConVar("betterlights_flashlight_fov", "45", true, false, "Flashlight cone FOV")
    local cvar_shadows = BL.CreateClientConVar("betterlights_flashlight_shadows", "1", true, false, "Enable flashlight shadows")
    local cvar_attachment = BL.CreateClientConVar("betterlights_flashlight_weapon_attachment", "1", true, false, "Use weapon or viewmodel muzzle attachments when available")
    local cvar_flicker = BL.CreateClientConVar("betterlights_flashlight_flicker", "0", true, false, "Enable subtle flashlight flicker")
    local cvar_flicker_amount = BL.CreateClientConVar("betterlights_flashlight_flicker_amount", "0.05", true, false, "Flashlight flicker intensity")
    local cvar_sway = BL.CreateClientConVar("betterlights_flashlight_sway", "1", true, false, "Enable subtle flashlight sway")
    local cvar_sway_intensity = BL.CreateClientConVar("betterlights_flashlight_sway_intensity", "1", true, false, "Flashlight sway strength")
    local cvar_distance = BL.CreateClientConVar("betterlights_flashlight_distance", "1200", true, false, "Flashlight beam length")
    local cvar_forward_offset = BL.CreateClientConVar("betterlights_flashlight_forward_offset", "0", true, false, "Extra forward offset for the flashlight beam")
    local cvar_attachment_offset = BL.CreateClientConVar("betterlights_flashlight_attachment_offset", "2", true, false, "Side offset for weapon-attached flashlights")
    local cvar_view_origin_offset = BL.CreateClientConVar("betterlights_flashlight_fallback_offset", "8", true, false, "Side offset for view-origin flashlights")
    local cvar_brightness = BL.CreateClientConVar("betterlights_flashlight_brightness", "1.35", true, false, "Flashlight brightness")
    local cvar_color_r = BL.CreateClientConVar("betterlights_flashlight_color_r", "255", true, false, "Flashlight color - red (0-255)")
    local cvar_color_g = BL.CreateClientConVar("betterlights_flashlight_color_g", "245", true, false, "Flashlight color - green (0-255)")
    local cvar_color_b = BL.CreateClientConVar("betterlights_flashlight_color_b", "225", true, false, "Flashlight color - blue (0-255)")
    local cvar_texture = BL.CreateClientConVar("betterlights_flashlight_texture", "effects/flashlight001", true, false, "Flashlight texture material path")

    local DEFAULT_TEXTURE = "effects/flashlight001"
    local RECENT_TEXTURE_COOKIE = "betterlights_flashlight_recent_textures"
    local MAX_RECENT_TEXTURES = 12
    local TEXTURE_ROOTS = {
        "effects/lightspill/",
        "effects/flashlight/",
        "effects/flashlights/",
        "models/flashlight/"
    }
    local MIN_FOV = 10
    local MAX_FOV = 120
    local WALL_FOV_SCALE = 0.95
    local WALL_SHRINK_DISTANCE = 32
    local CLOSE_WALL_BRIGHTNESS_SCALE = 0.96
    local MIN_DISTANCE = 128
    local MAX_DISTANCE = 4096
    local NEAR_Z = 4
    local MIN_BRIGHTNESS = 0.1
    local MAX_BRIGHTNESS = 5
    local MIN_FORWARD_OFFSET = -32
    local MAX_FORWARD_OFFSET = 96
    local MAX_FLICKER_AMOUNT = 0.3
    local AIM_SMOOTHING = 18
    local MAX_SWAY_INTENSITY = 3
    local ATTACHMENT_OFFSET_FORWARD = 1
    local ATTACHMENT_OFFSET_DOWN = 2
    local EYE_OFFSET_FORWARD = 26
    local EYE_OFFSET_DOWN = 3
    local VEHICLE_OFFSET_FORWARD = 18
    local VEHICLE_OFFSET_DOWN = 1
    -- Common SWEP attachment conventions. This list is intentionally broad for flashlight compatibility.
    local ATTACHMENT_NAMES = { "muzzle", "Muzzle", "barrel", "muzzle_flash", "1" }
    local MWBASE_ATTACHMENT_NAMES = { "muzzle", "tag_flash", "tag_muzzle", "tag_barrel", "tag_tip", "tip" }
    local VIEW_ORIGIN_WEAPONS = {
        weapon_crowbar = true
    }

    local projectors = {}
    local projectorData = {}
    local knownTextureCache
    local traceData = {
        mins = Vector(-4, -4, -4),
        maxs = Vector(4, 4, 4),
        mask = MASK_SHOT_HULL
    }

    local function removeAllProjectors()
        BL.ClearProjectedTextures(projectors, projectorData)
    end

    local function normalizeTexturePath(path)
        path = string.Trim(tostring(path or ""))
        path = string.Replace(path, "\\", "/")
        path = string.gsub(path, "^materials/", "")
        path = string.gsub(path, "%.vmt$", "")
        path = string.gsub(path, "%.vtf$", "")
        path = string.gsub(path, "^/+", "")
        return path
    end

    local function isValidTexturePath(path)
        path = normalizeTexturePath(path)
        if path == "" then return false end

        local mat = Material(path)
        return mat and mat.IsError and not mat:IsError()
    end

    local function getTexturePath()
        local path = normalizeTexturePath(cvar_texture:GetString())
        if path == "" or not isValidTexturePath(path) then
            return DEFAULT_TEXTURE
        end

        return path
    end

    local function getRecentTextures()
        local raw = cookie.GetString(RECENT_TEXTURE_COOKIE, "")
        local textures = {}
        local seen = {}

        for path in string.gmatch(raw, "([^|]+)") do
            path = normalizeTexturePath(path)
            if path ~= "" and not seen[path] then
                textures[#textures + 1] = path
                seen[path] = true
            end
        end

        return textures
    end

    local function saveRecentTextures(textures)
        cookie.Set(RECENT_TEXTURE_COOKIE, table.concat(textures, "|"))
    end

    local function rememberTexture(path)
        path = normalizeTexturePath(path)
        if path == "" or not isValidTexturePath(path) then return false end

        local recent = getRecentTextures()

        for i = #recent, 1, -1 do
            if recent[i] == path then
                table.remove(recent, i)
            end
        end

        table.insert(recent, 1, path)

        while #recent > MAX_RECENT_TEXTURES do
            table.remove(recent)
        end

        saveRecentTextures(recent)
        return true
    end

    local function addKnownTexture(path, output, seen)
        path = normalizeTexturePath(path)
        if seen[path] or not isValidTexturePath(path) then return end

        output[#output + 1] = path
        seen[path] = true
    end

    local function findTexturesInRoot(root, output, seen, depth)
        if depth > 3 then return end

        local files, dirs = file.Find("materials/" .. root .. "*", "GAME")

        for _, fileName in ipairs(files or {}) do
            if string.match(fileName, "%.vmt$") or string.match(fileName, "%.vtf$") then
                addKnownTexture(root .. fileName, output, seen)
            end
        end

        for _, dirName in ipairs(dirs or {}) do
            findTexturesInRoot(root .. dirName .. "/", output, seen, depth + 1)
        end
    end

    local function getKnownTextures()
        if knownTextureCache then return knownTextureCache end

        local textures = {}
        local seen = {}

        addKnownTexture(DEFAULT_TEXTURE, textures, seen)

        for _, root in ipairs(TEXTURE_ROOTS) do
            findTexturesInRoot(root, textures, seen, 0)
        end

        table.sort(textures)
        knownTextureCache = textures
        return knownTextureCache
    end

    local function setTexturePath(path)
        path = normalizeTexturePath(path)
        if not isValidTexturePath(path) then return false end

        if cvar_texture:GetString() ~= path then
            cvar_texture:SetString(path)
        end

        rememberTexture(path)
        return true
    end

    function BL.NormalizeFlashlightTexturePath(path)
        return normalizeTexturePath(path)
    end

    function BL.IsValidFlashlightTexturePath(path)
        return isValidTexturePath(path)
    end

    function BL.SetFlashlightTexturePath(path)
        return setTexturePath(path)
    end

    function BL.GetFlashlightTexturePath()
        return getTexturePath()
    end

    function BL.GetFlashlightRecentTextures()
        return getRecentTextures()
    end

    function BL.GetFlashlightKnownTextures()
        return getKnownTextures()
    end

    function BL.ClearFlashlightKnownTextureCache()
        knownTextureCache = nil
    end

    function BL.ClearFlashlightRecentTextures()
        cookie.Set(RECENT_TEXTURE_COOKIE, "")
    end

    cvars.AddChangeCallback("betterlights_flashlight_texture", function(_, _, new)
        local path = normalizeTexturePath(new)
        if path ~= "" and isValidTexturePath(path) then
            rememberTexture(path)
        end
    end, "BetterLights_FlashlightTextureRecent")

    local function applyAttachmentOffset(pos, ang)
        return pos
            + ang:Forward() * (ATTACHMENT_OFFSET_FORWARD + math.Clamp(cvar_forward_offset:GetFloat(), MIN_FORWARD_OFFSET, MAX_FORWARD_OFFSET))
            + ang:Right() * cvar_attachment_offset:GetFloat()
            - ang:Up() * ATTACHMENT_OFFSET_DOWN
    end

    local function isFirstPersonZooming(ply, localPlayer)
        if ply ~= localPlayer or ply:ShouldDrawLocalPlayer() then return false end
        if not ply.KeyDown or not ply:KeyDown(IN_ZOOM) then return false end
        if not ply.GetCanZoom then return true end

        return ply:GetCanZoom()
    end

    local function getWeaponAttachmentSource(ply, localPlayer, activeWeapon)
        if ply == localPlayer and not ply:ShouldDrawLocalPlayer() then
            return ply:GetViewModel()
        end

        return activeWeapon
    end

    local function getWeaponBase(weapon)
        if not IsValid(weapon) then return "" end

        local base = weapon.Base
        if base == nil and weapon.GetTable then
            local tab = weapon:GetTable()
            base = tab and tab.Base
        end

        return string.lower(tostring(base or ""))
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

    local function getWeaponAttachmentTransform(ply, localPlayer)
        if not cvar_attachment:GetBool() then return end
        if ply.InVehicle and ply:InVehicle() then return end
        if isFirstPersonZooming(ply, localPlayer) then return end

        local activeWeapon = ply:GetActiveWeapon()
        if not IsValid(activeWeapon) then return end
        if VIEW_ORIGIN_WEAPONS[activeWeapon:GetClass()] then return end

        local attachment = getMwBaseAttachmentTransform(ply, localPlayer, activeWeapon)
        if not attachment then
            local source = getWeaponAttachmentSource(ply, localPlayer, activeWeapon)
            attachment = BL.GetAttachmentTransform(source, ATTACHMENT_NAMES)
        end

        if not (attachment and attachment.Pos and attachment.Ang) then return end

        return applyAttachmentOffset(attachment.Pos, attachment.Ang), attachment.Ang
    end

    local function getViewOriginTransform(ply)
        local aim = ply.GetAimVector and ply:GetAimVector() or nil
        local ang = aim and aim:Angle() or ply:EyeAngles()
        local pos = ply:EyePos()
        local inVehicle = ply.InVehicle and ply:InVehicle()
        local forwardOffset = inVehicle and VEHICLE_OFFSET_FORWARD or EYE_OFFSET_FORWARD
        local downOffset = inVehicle and VEHICLE_OFFSET_DOWN or EYE_OFFSET_DOWN

        pos = pos
            + ang:Forward() * (forwardOffset + math.Clamp(cvar_forward_offset:GetFloat(), MIN_FORWARD_OFFSET, MAX_FORWARD_OFFSET))
            + ang:Right() * cvar_view_origin_offset:GetFloat()
            - ang:Up() * downOffset

        if not inVehicle and ply.GetViewPunchAngles then
            ang = ang + ply:GetViewPunchAngles()
        end

        return pos, ang
    end

    local function getFlashlightOriginTransform(ply, localPlayer)
        local pos, ang = getWeaponAttachmentTransform(ply, localPlayer)
        if pos then return pos, ang end

        return getViewOriginTransform(ply)
    end

    local function getWallDistance(ply, pos, ang)
        traceData.filter = ply
        traceData.start = pos
        traceData.endpos = pos + ang:Forward() * WALL_SHRINK_DISTANCE

        local wallTrace = util.TraceHull(traceData)
        return wallTrace.StartPos:Distance(wallTrace.HitPos)
    end

    local function getFlashlightColor()
        return Color(
            math.Clamp(cvar_color_r:GetInt(), 0, 255),
            math.Clamp(cvar_color_g:GetInt(), 0, 255),
            math.Clamp(cvar_color_b:GetInt(), 0, 255)
        )
    end

    local function getSmoothedAngle(data, ang)
        if not cvar_sway:GetBool() then
            data.smoothAng = nil
            return ang
        end

        local intensity = math.Clamp(cvar_sway_intensity:GetFloat(), 0, MAX_SWAY_INTENSITY)
        if intensity <= 0 then
            data.smoothAng = nil
            return ang
        end

        data.smoothAng = data.smoothAng or Angle(ang.p, ang.y, ang.r)
        data.smoothAng = LerpAngle(math.Clamp(FrameTime() * AIM_SMOOTHING / intensity, 0, 1), data.smoothAng, ang)

        return data.smoothAng
    end

    local function getFOV(wallDist)
        local fov = math.Clamp(cvar_fov:GetFloat(), MIN_FOV, MAX_FOV)
        local minWallFov = math.max(MIN_FOV, fov * WALL_FOV_SCALE)
        local t = math.Clamp(wallDist / WALL_SHRINK_DISTANCE, 0, 1)
        return Lerp(t, minWallFov, fov)
    end

    local function getBrightness(ply, wallDist)
        local t = math.Clamp(wallDist / WALL_SHRINK_DISTANCE, 0, 1)
        local baseBrightness = math.Clamp(cvar_brightness:GetFloat(), MIN_BRIGHTNESS, MAX_BRIGHTNESS)
        local brightness = baseBrightness * Lerp(t, CLOSE_WALL_BRIGHTNESS_SCALE, 1)

        if not cvar_flicker:GetBool() then return brightness end

        local phase = ply:EntIndex() * 0.731
        local wave = math.sin(CurTime() * 22 + phase) * 0.65 + math.sin(CurTime() * 47 + phase * 1.7) * 0.35
        local amount = math.Clamp(cvar_flicker_amount:GetFloat(), 0, MAX_FLICKER_AMOUNT)
        return math.max(0, brightness * (1 + wave * amount))
    end

    local function updateProjector(ply, localPlayer)
        local lamp = BL.GetOrCreateProjectedTexture(projectors, ply)
        if not lamp then return end

        local data = projectorData[ply] or {}
        projectorData[ply] = data

        local pos, ang = getFlashlightOriginTransform(ply, localPlayer)

        ang = getSmoothedAngle(data, ang)
        local wallDist = getWallDistance(ply, pos, ang)
        local distance = math.Clamp(cvar_distance:GetFloat(), MIN_DISTANCE, MAX_DISTANCE)

        BL.UpdateProjectedTexture(lamp, {
            texture = getTexturePath(),
            pos = pos,
            ang = ang,
            nearZ = NEAR_Z,
            farZ = distance,
            fov = getFOV(wallDist),
            brightness = getBrightness(ply, wallDist),
            color = getFlashlightColor(),
            shadows = cvar_shadows:GetBool()
        })
    end

    local function isRendererEnabled()
        local globalCvar = GetConVar("betterlights_enable")
        return (not globalCvar or globalCvar:GetBool()) and cvar_player_enable:GetBool()
    end

    local function runFlashlightThink()
        local seen = {}

        local localPlayer = LocalPlayer()

        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:Alive() and ply:GetNWBool("BetterLights_Flashlight", false) then
                seen[ply] = true
                updateProjector(ply, localPlayer)
            end
        end

        BL.RemoveStaleProjectedTextures(projectors, seen, nil, projectorData)
    end

    refreshThinkRegistration = function()
        if isRendererEnabled() then
            BL.AddThink(THINK_NAME, runFlashlightThink)
        else
            BL.RemoveThink(THINK_NAME)
            removeAllProjectors()
        end
    end

    cvars.AddChangeCallback("betterlights_enable", function()
        refreshThinkRegistration()
    end, "BetterLights_GlobalEnableFlashlight")

    refreshThinkRegistration()

    hook.Add("ShutDown", "BetterLights_PlayerFlashlightsCleanup", function()
        removeAllProjectors()
    end)
end
