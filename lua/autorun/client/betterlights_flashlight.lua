if CLIENT then
    local BL = BetterLights
    local FL = BL.Flashlight

    local cvar_player_enable = BL.CreateClientConVar("betterlights_flashlight_player_enable", "0", true, false, "Enable BetterLights flashlight replacement for your player")
    local cvar_custom_sounds = BL.CreateClientConVar("betterlights_flashlight_custom_sounds", "1", true, false, "Use BetterLights flashlight on/off sounds instead of vanilla flashlight sound events")
    local cvar_mwbase_flashlight_override_disabled = BL.CreateClientConVar("betterlights_integration_mwbase_disable_flashlight_override", "0", true, false, "Use MW Base flashlight handling while MW Base weapons are active")
    local cvar_arccw_flashlight_override_disabled = BL.CreateClientConVar("betterlights_integration_arccw_disable_flashlight_override", "0", true, false, "Use ArcCW flashlight handling while ArcCW weapons are active")
    local cvar_arc9_flashlight_override_disabled = BL.CreateClientConVar("betterlights_integration_arc9_disable_flashlight_override", "0", true, false, "Use ARC9 flashlight handling while ARC9 weapons are active")
    local cvar_tfa_flashlight_override_disabled = BL.CreateClientConVar("betterlights_integration_tfa_disable_flashlight_override", "0", true, false, "Use TFA flashlight handling while TFA weapons are active")
    local refreshThinkRegistration
    local ONBOARDING_COOKIE = "betterlights_flashlight_onboarding_seen"

    local function phrase(key)
        return language.GetPhrase("betterlights." .. key)
    end

    local function syncFlashlightSettings()
        if not IsValid(LocalPlayer()) then return end

        net.Start(BL.NET_FLASHLIGHT_CLIENT_SETTINGS)
            net.WriteBool(BL.IsClientEnabledPreference())
            net.WriteBool(cvar_player_enable:GetBool())
            net.WriteBool(cvar_custom_sounds:GetBool())
            net.WriteBool(cvar_mwbase_flashlight_override_disabled:GetBool())
            net.WriteBool(cvar_arccw_flashlight_override_disabled:GetBool())
            net.WriteBool(cvar_arc9_flashlight_override_disabled:GetBool())
            net.WriteBool(cvar_tfa_flashlight_override_disabled:GetBool())
        net.SendToServer()
    end

    local function queueFlashlightSettingsSync()
        syncFlashlightSettings()
        timer.Simple(1, syncFlashlightSettings)
        timer.Simple(3, syncFlashlightSettings)
    end

    local function showOnboardingTip(force)
        if not force and cookie.GetString(ONBOARDING_COOKIE, "") == "1" then return end

        if not force then
            cookie.Set(ONBOARDING_COOKIE, "1")
        end

        timer.Simple(force and 0 or 4, function()
            if not force and BL.GetEffectiveFlashlightBool("betterlights_flashlight_player_enable") then return end
            notification.AddLegacy(phrase("notice.flashlight_onboarding"), NOTIFY_GENERIC, 6)
            surface.PlaySound("buttons/button15.wav")
        end)
    end

    function BL.ShowFlashlightOnboardingTip(force)
        showOnboardingTip(force)
    end

    hook.Add("InitPostEntity", "BetterLights_FlashlightSyncSettings", function()
        queueFlashlightSettingsSync()
        showOnboardingTip(false)
    end)

    cvars.AddChangeCallback("betterlights_flashlight_player_enable", function()
        queueFlashlightSettingsSync()
        if refreshThinkRegistration then
            refreshThinkRegistration()
        end
    end, "BetterLights_FlashlightPlayerEnable")

    cvars.AddChangeCallback("betterlights_flashlight_custom_sounds", function()
        queueFlashlightSettingsSync()
    end, "BetterLights_FlashlightCustomSounds")

    cvars.AddChangeCallback("betterlights_client_enable", function()
        queueFlashlightSettingsSync()
    end, "BetterLights_ClientEnableFlashlightSync")

    local function queueIntegrationFlashlightSettingsSync()
        queueFlashlightSettingsSync()
        if refreshThinkRegistration then
            refreshThinkRegistration()
        end
    end

    cvars.AddChangeCallback("betterlights_integration_mwbase_disable_flashlight_override", queueIntegrationFlashlightSettingsSync, "BetterLights_MWBaseFlashlightOverride")
    cvars.AddChangeCallback("betterlights_integration_arccw_disable_flashlight_override", queueIntegrationFlashlightSettingsSync, "BetterLights_ArcCWFlashlightOverride")
    cvars.AddChangeCallback("betterlights_integration_arc9_disable_flashlight_override", queueIntegrationFlashlightSettingsSync, "BetterLights_ARC9FlashlightOverride")
    cvars.AddChangeCallback("betterlights_integration_tfa_disable_flashlight_override", queueIntegrationFlashlightSettingsSync, "BetterLights_TFAFlashlightOverride")

    hook.Add("OnReloaded", "BetterLights_FlashlightSyncSettingsReload", function()
        queueFlashlightSettingsSync()
    end)

    if IsValid(LocalPlayer()) then
        queueFlashlightSettingsSync()
        showOnboardingTip(false)
    end

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
    local cvar_view_origin_offset = BL.CreateClientConVar("betterlights_flashlight_fallback_offset", "0", true, false, "Side offset for view-origin flashlights")
    local cvar_world_attachment = BL.CreateClientConVar("betterlights_flashlight_world_weapon_attachment", "1", true, false, "Use world weapon muzzle attachments for third-person and other-player flashlights", 0, 1)
    local cvar_world_forward_offset = BL.CreateClientConVar("betterlights_flashlight_world_forward_offset", "16", true, false, "Extra forward offset for third-person and other-player flashlight beams", -32, 96)
    local cvar_world_attachment_offset = BL.CreateClientConVar("betterlights_flashlight_world_attachment_offset", "2", true, false, "Side offset for world-weapon-attached flashlights", -24, 24)
    local cvar_world_view_origin_offset = BL.CreateClientConVar("betterlights_flashlight_world_fallback_offset", "0", true, false, "Side offset for third-person and other-player view-origin flashlights", -24, 24)
    local cvar_world_spill = BL.CreateClientConVar("betterlights_flashlight_world_spill", "0", true, false, "Add a point light at third-person and other-player flashlight sources", 0, 1)
    local cvar_world_spill_match = BL.CreateClientConVar("betterlights_flashlight_world_spill_match", "1", true, false, "Match spill light color and brightness to the flashlight beam", 0, 1)
    local cvar_world_spill_size = BL.CreateClientConVar("betterlights_flashlight_world_spill_size", "128", true, false, "Flashlight spill light radius", 32, 512)
    local cvar_world_spill_brightness = BL.CreateClientConVar("betterlights_flashlight_world_spill_brightness", "0.47", true, false, "Custom flashlight spill light brightness", 0.1, 5)
    local cvar_world_spill_color_r = BL.CreateClientConVar("betterlights_flashlight_world_spill_color_r", "255", true, false, "Custom flashlight spill light color - red (0-255)", 0, 255)
    local cvar_world_spill_color_g = BL.CreateClientConVar("betterlights_flashlight_world_spill_color_g", "245", true, false, "Custom flashlight spill light color - green (0-255)", 0, 255)
    local cvar_world_spill_color_b = BL.CreateClientConVar("betterlights_flashlight_world_spill_color_b", "225", true, false, "Custom flashlight spill light color - blue (0-255)", 0, 255)
    local cvar_brightness = BL.CreateClientConVar("betterlights_flashlight_brightness", "1.35", true, false, "Flashlight brightness")
    local cvar_color_r = BL.CreateClientConVar("betterlights_flashlight_color_r", "255", true, false, "Flashlight color - red (0-255)")
    local cvar_color_g = BL.CreateClientConVar("betterlights_flashlight_color_g", "245", true, false, "Flashlight color - green (0-255)")
    local cvar_color_b = BL.CreateClientConVar("betterlights_flashlight_color_b", "225", true, false, "Flashlight color - blue (0-255)")
    local cvar_texture = BL.CreateClientConVar("betterlights_flashlight_texture", "effects/flashlight001", true, false, "Flashlight texture material path")
    local cvar_flare = BL.CreateClientConVar("betterlights_flashlight_flare_enable", "1", true, false, "Show a visible lens flare at the flashlight source", 0, 1)
    local cvar_flare_others = BL.CreateClientConVar("betterlights_flashlight_flare_others", "1", true, false, "Show flashlight lens flares on other players", 0, 1)
    local cvar_flare_size = BL.CreateClientConVar("betterlights_flashlight_flare_size", "1", true, false, "Flashlight lens flare size", 0.25, 3)
    local cvar_flare_opacity = BL.CreateClientConVar("betterlights_flashlight_flare_opacity", "90", true, false, "Flashlight lens flare opacity", 0, 255)
    local cvar_shadow_depth_bias = BL.CreateClientConVar("betterlights_flashlight_shadow_depth_bias", "0.001", true, false, "Flashlight shadow depth bias")
    local cvar_shadow_slope_scale_depth_bias = BL.CreateClientConVar("betterlights_flashlight_shadow_slope_scale_depth_bias", "4", true, false, "Flashlight shadow slope scale depth bias")
    local cvar_shadow_filter = BL.CreateClientConVar("betterlights_flashlight_shadow_filter", "1.25", true, false, "Flashlight shadow filter size")

    local function getEffectiveBool(cvar)
        return BL.GetEffectiveFlashlightBool(cvar:GetName(), cvar:GetBool())
    end

    local function getEffectiveNumber(cvar)
        return BL.GetEffectiveFlashlightNumber(cvar:GetName(), cvar:GetFloat())
    end

    local function getEffectiveString(cvar)
        return BL.GetEffectiveFlashlightString(cvar:GetName(), cvar:GetString())
    end

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
    local MIN_DISTANCE = 128
    local MAX_DISTANCE = 4096
    -- The beam leaves a lens of this radius, so its spot shrinks toward the lens size instead of a point.
    local LENS_RADIUS = 1
    -- Nothing this close in front of the lens is lit or casts shadows, so the holder's own model and weapon never block the beam.
    -- The clearance shrinks when a surface is closer, so a lens pressed against a wall still lights it.
    local LENS_CLEARANCE = 4
    local SURFACE_GAP = 0.5
    local CONTACT_HULL_SIZE = 1
    local CONTACT_MASK = bit.bor(MASK_OPAQUE_AND_NPCS, CONTENTS_WINDOW)
    -- The engine keeps projected light at full strength within 100 units, then fades it by 1/distance.
    -- Raising that cap lets the shrinking spot keep getting brighter as it closes in, up to this many times.
    local FULL_BRIGHTNESS_DISTANCE = 100
    local CLOSE_BRIGHTNESS_MAX = 8
    local PREDICTION_TIMEOUT = 1
    local FLASHLIGHT_SOUNDS = BL.FLASHLIGHT_SOUNDS
    local MIN_BRIGHTNESS = 0.1
    local MAX_BRIGHTNESS = 5
    local MIN_FORWARD_OFFSET = -32
    local MAX_FORWARD_OFFSET = 96
    local MAX_FLICKER_AMOUNT = 0.3
    local AIM_SMOOTHING = 18
    local MAX_SWAY_INTENSITY = 3
    local FLARE_MATERIAL = Material("sprites/light_ignorez")
    local FLARE_PIXVIS_SIZE = 16
    local FLARE_MIN_DISTANCE = 16
    local FLARE_MIN_SIZE = 32
    local FLARE_MAX_SIZE = 384
    local FLARE_CORE_SCALE = 0.32
    local FLARE_MAX_FADE_DISTANCE = 2048
    local ATTACHMENT_OFFSET_FORWARD = 1
    local ATTACHMENT_OFFSET_DOWN = 2
    local VEHICLE_OFFSET_FORWARD = 18
    local VEHICLE_OFFSET_DOWN = 1
    local MIN_WORLD_SPILL_SIZE = 32
    local MAX_WORLD_SPILL_SIZE = 512
    local MIN_WORLD_SPILL_BRIGHTNESS = 0.1
    local MAX_WORLD_SPILL_BRIGHTNESS = 5
    local WORLD_SPILL_BRIGHTNESS_SCALE = 0.35
    local WORLD_SPILL_LIGHT_OPTIONS = {
        priority = BL.LIGHT_PRIORITY_AMBIENT
    }
    -- Common SWEP attachment conventions. This list is intentionally broad for flashlight compatibility.
    local ATTACHMENT_NAMES = { "muzzle", "Muzzle", "barrel", "muzzle_flash", "1" }
    local PLAYER_EYE_ATTACHMENT_NAMES = { "eyes" }
    local FIRST_PERSON_PLACEMENT = {
        attachment = cvar_attachment,
        forwardOffset = cvar_forward_offset,
        attachmentOffset = cvar_attachment_offset,
        viewOriginOffset = cvar_view_origin_offset
    }
    local WORLD_PLACEMENT = {
        attachment = cvar_world_attachment,
        forwardOffset = cvar_world_forward_offset,
        attachmentOffset = cvar_world_attachment_offset,
        viewOriginOffset = cvar_world_view_origin_offset
    }

    local projectors = {}
    local projectorData = {}
    local flarePixVis = {}
    BL._flashlightWorldSpillLightIds = BL._flashlightWorldSpillLightIds or {}
    setmetatable(BL._flashlightWorldSpillLightIds, { __mode = "k" })
    local knownTextureCache
    local contactFilter = {}
    local contactTraceData = {
        mins = Vector(-CONTACT_HULL_SIZE, -CONTACT_HULL_SIZE, -CONTACT_HULL_SIZE),
        maxs = Vector(CONTACT_HULL_SIZE, CONTACT_HULL_SIZE, CONTACT_HULL_SIZE),
        mask = CONTACT_MASK,
        filter = contactFilter
    }
    local clearanceTraceData = {
        mask = CONTACT_MASK,
        filter = contactFilter
    }
    local beamSettings = {}
    local predictedToggle
    local lastPredictedCommand
    local viewModelHiddenLamp
    local viewModelHiddenBrightness

    BL.RegisterProjectedTextureStore(projectors, projectorData)

    local function removeAllProjectors()
        BL.ClearProjectedTextures(projectors, projectorData)
    end

    local function clearFlareHandles()
        for ply in pairs(flarePixVis) do
            flarePixVis[ply] = nil
        end
    end

    local function removeStaleFlareHandles(seen)
        for ply in pairs(flarePixVis) do
            if not seen[ply] then
                flarePixVis[ply] = nil
            end
        end
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
        local path = normalizeTexturePath(getEffectiveString(cvar_texture))
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

    local function isFirstPersonView(ply, localPlayer)
        return ply == localPlayer and not ply:ShouldDrawLocalPlayer()
    end

    local function getPlacementSettings(ply, localPlayer)
        return isFirstPersonView(ply, localPlayer) and FIRST_PERSON_PLACEMENT or WORLD_PLACEMENT
    end

    local function applyAttachmentOffset(pos, ang, settings)
        return pos
            + ang:Forward() * (ATTACHMENT_OFFSET_FORWARD + math.Clamp(getEffectiveNumber(settings.forwardOffset), MIN_FORWARD_OFFSET, MAX_FORWARD_OFFSET))
            + ang:Right() * getEffectiveNumber(settings.attachmentOffset)
            - ang:Up() * ATTACHMENT_OFFSET_DOWN
    end

    local function isFirstPersonZooming(ply, localPlayer)
        if not isFirstPersonView(ply, localPlayer) then return false end
        if not ply.KeyDown or not ply:KeyDown(IN_ZOOM) then return false end
        if not ply.GetCanZoom then return true end

        return ply:GetCanZoom()
    end

    local function getWeaponAttachmentSource(ply, localPlayer, activeWeapon)
        if isFirstPersonView(ply, localPlayer) then
            return ply:GetViewModel()
        end

        return activeWeapon
    end

    local function getIntegrationAttachmentTransform(ply, localPlayer, activeWeapon)
        for _, integration in ipairs(FL.GetIntegrations()) do
            local getAttachmentTransform = integration.GetAttachmentTransform
            if isfunction(getAttachmentTransform) then
                local attachment = getAttachmentTransform(ply, localPlayer, activeWeapon)
                if attachment then return attachment end
            end
        end

        return nil
    end

    local function integrationUsesViewOrigin(ply, localPlayer, activeWeapon)
        for _, integration in ipairs(FL.GetIntegrations()) do
            local usesViewOrigin = integration.UsesViewOrigin
            if isfunction(usesViewOrigin) and usesViewOrigin(ply, localPlayer, activeWeapon) == true then
                return true
            end
        end

        return false
    end

    local function getSlabExit(reach, origin, dir, low, high)
        if dir > 0 then return math.min(reach, (high - origin) / dir) end
        if dir < 0 then return math.min(reach, (low - origin) / dir) end
        return reach
    end

    -- Distance from the eye to the front of the player's collision hull, capped at its horizontal corner.
    local function getBodyReach(ply, eyePos, dir)
        local mins, maxs
        if ply:Crouching() then
            mins, maxs = ply:GetHullDuck()
        else
            mins, maxs = ply:GetHull()
        end

        local base = ply:GetPos()
        local reach = math.min(maxs.x, maxs.y, -mins.x, -mins.y) * math.sqrt(2)
        reach = getSlabExit(reach, eyePos.x, dir.x, base.x + mins.x, base.x + maxs.x)
        reach = getSlabExit(reach, eyePos.y, dir.y, base.y + mins.y, base.y + maxs.y)
        reach = getSlabExit(reach, eyePos.z, dir.z, base.z + mins.z, base.z + maxs.z)

        return math.max(0, reach)
    end

    -- Viewmodel depth is not physical, so pull the lens toward the eye until it sits no farther ahead than the body.
    -- Scaling along the eye ray keeps it on the muzzle on screen.
    local function limitToBodyReach(ply, lensPos, viewPos, viewAng)
        local forward = viewAng:Forward()
        local offset = lensPos - viewPos
        local depth = offset:Dot(forward)
        local reach = getBodyReach(ply, viewPos, forward)
        if depth <= reach then return lensPos end

        return viewPos + offset * (reach / depth)
    end

    local function getWeaponAttachmentTransform(ply, localPlayer, settings, viewPos, viewAng)
        if not getEffectiveBool(settings.attachment) then return end
        if ply.InVehicle and ply:InVehicle() then return end
        if isFirstPersonZooming(ply, localPlayer) then return end

        local activeWeapon = ply:GetActiveWeapon()
        if not IsValid(activeWeapon) then return end
        if FL.IsWeaponAttachmentBlacklisted(activeWeapon) then return end
        if integrationUsesViewOrigin(ply, localPlayer, activeWeapon) then return end

        local attachment = getIntegrationAttachmentTransform(ply, localPlayer, activeWeapon)
        if not attachment then
            local source = getWeaponAttachmentSource(ply, localPlayer, activeWeapon)
            attachment = BL.GetAttachmentTransform(source, ATTACHMENT_NAMES)
        end

        if not (attachment and attachment.Pos and attachment.Ang) then return end

        local lensPos = applyAttachmentOffset(attachment.Pos, attachment.Ang, settings)
        if isFirstPersonView(ply, localPlayer) then
            lensPos = limitToBodyReach(ply, lensPos, viewPos, viewAng)
        end

        -- Keep projector offsets separate so the visible flare stays on the attachment.
        return lensPos, attachment.Ang, attachment.Pos, attachment.Ang
    end

    local function getViewOriginTransform(ply, localPlayer, settings, viewPos, viewAng)
        local useMainView = isFirstPersonView(ply, localPlayer)
        local ang = useMainView and Angle(viewAng.p, viewAng.y, viewAng.r) or ply:GetAimVector():Angle()
        local pos = useMainView and viewPos or ply:EyePos()
        local inVehicle = ply.InVehicle and ply:InVehicle()
        local forwardOffset = inVehicle and VEHICLE_OFFSET_FORWARD or 0
        local downOffset = inVehicle and VEHICLE_OFFSET_DOWN or 0

        if useMainView and not inVehicle then
            forwardOffset = getBodyReach(ply, pos, ang:Forward())
        end

        pos = pos
            + ang:Forward() * (forwardOffset + math.Clamp(getEffectiveNumber(settings.forwardOffset), MIN_FORWARD_OFFSET, MAX_FORWARD_OFFSET))
            + ang:Right() * getEffectiveNumber(settings.viewOriginOffset)
            - ang:Up() * downOffset

        if not inVehicle and not useMainView then
            ang = ang + ply:GetViewPunchAngles()
        end

        local eyeAttachment = BL.GetAttachmentTransform(ply, PLAYER_EYE_ATTACHMENT_NAMES)
        if eyeAttachment and eyeAttachment.Pos then
            return pos, ang, eyeAttachment.Pos, eyeAttachment.Ang or ang
        end

        return pos, ang
    end

    local function getFlashlightOriginTransform(ply, localPlayer, viewPos, viewAng)
        local settings = getPlacementSettings(ply, localPlayer)
        local pos, ang, flarePos, flareAng = getWeaponAttachmentTransform(ply, localPlayer, settings, viewPos, viewAng)
        if pos then return pos, ang, flarePos, flareAng end

        return getViewOriginTransform(ply, localPlayer, settings, viewPos, viewAng)
    end

    local function addContactFilter(count, ent)
        if not IsValid(ent) then return count end

        count = count + 1
        contactFilter[count] = ent
        return count
    end

    local function setContactFilter(ply)
        local count = addContactFilter(0, ply)
        count = addContactFilter(count, ply:GetActiveWeapon())
        count = addContactFilter(count, ply:GetVehicle())

        for i = #contactFilter, count + 1, -1 do
            contactFilter[i] = nil
        end
    end

    -- Slide the lens back toward the eye until it sits in open space, so it never lights through walls.
    local function keepLensInOpenSpace(eyePos, lensPos)
        contactTraceData.start = eyePos
        contactTraceData.endpos = lensPos

        local tr = util.TraceHull(contactTraceData)
        if tr.StartSolid then return eyePos end

        return tr.HitPos
    end

    local function getLensClearance(lensPos, dir)
        clearanceTraceData.start = lensPos
        clearanceTraceData.endpos = lensPos + dir * LENS_CLEARANCE

        local tr = util.TraceLine(clearanceTraceData)
        if tr.StartSolid then return LENS_CLEARANCE end

        return math.Clamp(tr.Fraction * LENS_CLEARANCE - SURFACE_GAP, 0, LENS_CLEARANCE)
    end

    local function getFlashlightColor()
        return Color(
            math.Clamp(getEffectiveNumber(cvar_color_r), 0, 255),
            math.Clamp(getEffectiveNumber(cvar_color_g), 0, 255),
            math.Clamp(getEffectiveNumber(cvar_color_b), 0, 255)
        )
    end

    local function getWorldSpillLightId(ply)
        local id = BL._flashlightWorldSpillLightIds[ply]
        if id then return id end

        id = BL.NewLightId(90000)
        BL._flashlightWorldSpillLightIds[ply] = id
        return id
    end

    local function updateWorldSpillLight(ply, localPlayer, pos, color, brightness)
        if isFirstPersonView(ply, localPlayer) then return end
        if not getEffectiveBool(cvar_world_spill) then return end

        local r = color.r
        local g = color.g
        local b = color.b
        local spillBrightness = brightness * WORLD_SPILL_BRIGHTNESS_SCALE

        if not getEffectiveBool(cvar_world_spill_match) then
            r = math.Clamp(getEffectiveNumber(cvar_world_spill_color_r), 0, 255)
            g = math.Clamp(getEffectiveNumber(cvar_world_spill_color_g), 0, 255)
            b = math.Clamp(getEffectiveNumber(cvar_world_spill_color_b), 0, 255)
            spillBrightness = math.Clamp(
                getEffectiveNumber(cvar_world_spill_brightness),
                MIN_WORLD_SPILL_BRIGHTNESS,
                MAX_WORLD_SPILL_BRIGHTNESS
            )
        end

        BL.CreateDLight(
            getWorldSpillLightId(ply),
            pos,
            r,
            g,
            b,
            spillBrightness,
            0,
            math.Clamp(getEffectiveNumber(cvar_world_spill_size), MIN_WORLD_SPILL_SIZE, MAX_WORLD_SPILL_SIZE),
            false,
            WORLD_SPILL_LIGHT_OPTIONS
        )
    end

    local function getSmoothedAngle(data, ang)
        if not getEffectiveBool(cvar_sway) then
            data.smoothAng = nil
            return ang
        end

        local intensity = math.Clamp(getEffectiveNumber(cvar_sway_intensity), 0, MAX_SWAY_INTENSITY)
        if intensity <= 0 then
            data.smoothAng = nil
            return ang
        end

        local smoothAng = data.smoothAng
        if not smoothAng then
            smoothAng = Angle(ang.p, ang.y, ang.r)
            data.smoothAng = smoothAng
            return smoothAng
        end

        local t = 1 - math.exp(-FrameTime() * AIM_SMOOTHING / intensity)
        smoothAng.p = math.NormalizeAngle(smoothAng.p + math.AngleDifference(ang.p, smoothAng.p) * t)
        smoothAng.y = math.NormalizeAngle(smoothAng.y + math.AngleDifference(ang.y, smoothAng.y) * t)
        smoothAng.r = math.NormalizeAngle(smoothAng.r + math.AngleDifference(ang.r, smoothAng.r) * t)

        return smoothAng
    end

    local function getBrightness(ply, baseBrightness)
        if not beamSettings.flicker then return baseBrightness end

        local phase = ply:EntIndex() * 0.731
        local wave = math.sin(CurTime() * 22 + phase) * 0.65 + math.sin(CurTime() * 47 + phase * 1.7) * 0.35
        return math.max(0, baseBrightness * (1 + wave * beamSettings.flickerAmount))
    end

    local function refreshBeamSettings()
        beamSettings.texture = getTexturePath()
        beamSettings.color = getFlashlightColor()
        beamSettings.fov = math.Clamp(getEffectiveNumber(cvar_fov), MIN_FOV, MAX_FOV)
        beamSettings.distance = math.Clamp(getEffectiveNumber(cvar_distance), MIN_DISTANCE, MAX_DISTANCE)
        beamSettings.brightness = math.Clamp(getEffectiveNumber(cvar_brightness), MIN_BRIGHTNESS, MAX_BRIGHTNESS)
        beamSettings.flicker = getEffectiveBool(cvar_flicker)
        beamSettings.flickerAmount = math.Clamp(getEffectiveNumber(cvar_flicker_amount), 0, MAX_FLICKER_AMOUNT)
        beamSettings.shadows = getEffectiveBool(cvar_shadows)
        beamSettings.shadowDepthBias = math.max(0, getEffectiveNumber(cvar_shadow_depth_bias))
        beamSettings.shadowSlopeScaleDepthBias = math.max(0, getEffectiveNumber(cvar_shadow_slope_scale_depth_bias))
        beamSettings.shadowFilter = math.max(0, getEffectiveNumber(cvar_shadow_filter))
    end

    -- Runs once the main view is set up, so placement matches this frame's camera and viewmodel.
    local function resolveProjectorPlacement(ply, data, options, viewPos, viewAng)
        if not IsValid(ply) then return end

        local localPlayer = LocalPlayer()
        local lensPos, ang, flarePos, flareAng = getFlashlightOriginTransform(ply, localPlayer, viewPos, viewAng)
        local eyePos = isFirstPersonView(ply, localPlayer) and viewPos or ply:EyePos()

        setContactFilter(ply)
        lensPos = keepLensInOpenSpace(eyePos, lensPos)
        ang = getSmoothedAngle(data, ang)

        -- A cone through a lens of LENS_RADIUS has its apex this far behind the lens.
        local apexDistance = LENS_RADIUS / math.tan(math.rad(options.fov * 0.5))
        local forward = ang:Forward()

        options.pos = lensPos - forward * apexDistance
        options.ang = ang
        options.nearZ = apexDistance + getLensClearance(lensPos, forward)
        options.farZ = data.distance + apexDistance

        data.flarePos = flarePos or lensPos
        data.flareAng = flareAng or ang
    end

    local function updateProjector(ply, localPlayer)
        local lamp = BL.GetOrCreateProjectedTexture(projectors, ply)
        if not lamp then return end

        local data = projectorData[ply]
        if not data then
            data = {}
            data.options = {
                pos = ply:EyePos(),
                ang = ply:EyeAngles(),
                nearZ = LENS_CLEARANCE,
                farZ = beamSettings.distance,
                prepare = function(options, viewPos, viewAng)
                    resolveProjectorPlacement(ply, data, options, viewPos, viewAng)
                end
            }
            projectorData[ply] = data
        end

        local options = data.options
        local brightness = getBrightness(ply, beamSettings.brightness)
        data.distance = beamSettings.distance
        data.flashlightColor = beamSettings.color

        if data.flarePos then
            updateWorldSpillLight(ply, localPlayer, data.flarePos, beamSettings.color, brightness)
        end

        options.texture = beamSettings.texture
        options.fov = beamSettings.fov
        options.brightness = brightness
        options.brightnessGain = CLOSE_BRIGHTNESS_MAX
        options.linearAttenuation = FULL_BRIGHTNESS_DISTANCE / CLOSE_BRIGHTNESS_MAX
        options.color = beamSettings.color
        options.shadows = beamSettings.shadows
        options.shadowDepthBias = beamSettings.shadowDepthBias
        options.shadowSlopeScaleDepthBias = beamSettings.shadowSlopeScaleDepthBias
        options.shadowFilter = beamSettings.shadowFilter
        options.priority = ply == localPlayer and BL.LIGHT_PRIORITY_LOCAL_PLAYER or BL.LIGHT_PRIORITY_GAMEPLAY

        BL.UpdateProjectedTexture(lamp, options)
    end

    local function isRendererEnabled()
        return BL.IsEnabled() and getEffectiveBool(cvar_player_enable)
    end

    local function getIntegrationFlashlightState(ply)
        local activeWeapon = ply:GetActiveWeapon()
        if not IsValid(activeWeapon) then return nil end

        for _, integration in ipairs(FL.GetIntegrations()) do
            local getFlashlightState = integration.GetFlashlightState
            if isfunction(getFlashlightState) then
                local state = getFlashlightState(ply, activeWeapon)
                if state ~= nil then return state == true end
            end
        end

        return nil
    end

    local function readNetworkedToggle(ply)
        local packed = ply:GetNWInt(BL.NW_FLASHLIGHT_TOGGLE, 0)
        return math.floor(packed / 2), packed % 2 == 1
    end

    -- Holds the predicted state until the server reports handling that many toggle inputs.
    local function getLocalFlashlightState(ply)
        local inputCount, state = readNetworkedToggle(ply)
        local predicted = predictedToggle
        if not predicted then return state end

        if inputCount >= predicted.inputCount or RealTime() > predicted.expires then
            predictedToggle = nil
            return state
        end

        return predicted.state
    end

    local function isPlayerFlashlightActive(ply)
        local integrationState = getIntegrationFlashlightState(ply)
        if integrationState ~= nil then return integrationState end

        if ply == LocalPlayer() then
            return getLocalFlashlightState(ply)
        end

        return ply:GetNWBool("BetterLights_Flashlight", false)
    end

    local function integrationClaimsFlashlightInput(ply)
        for _, integration in ipairs(FL.GetIntegrations()) do
            local handlesImpulse = integration.HandlesFlashlightImpulse
            if isfunction(handlesImpulse) and handlesImpulse(ply) == true then return true end

            local overrideDisabled = integration.IsFlashlightOverrideDisabled
            if isfunction(overrideDisabled) and overrideDisabled(ply) == true then return true end
        end

        return false
    end

    local function canPredictToggle(ply)
        if not isRendererEnabled() then return false end
        if not ply:Alive() then return false end

        local mpFlashlight = GetConVar("mp_flashlight")
        if mpFlashlight and not mpFlashlight:GetBool() then return false end
        if getIntegrationFlashlightState(ply) ~= nil then return false end

        return not integrationClaimsFlashlightInput(ply)
    end

    local function playPredictedToggleSound(ply, state)
        local useCustomSounds = getEffectiveBool(cvar_custom_sounds)
        local soundName
        if useCustomSounds then
            soundName = state and FLASHLIGHT_SOUNDS.customOn or FLASHLIGHT_SOUNDS.customOff
        else
            soundName = state and FLASHLIGHT_SOUNDS.defaultOn or FLASHLIGHT_SOUNDS.defaultOff
        end

        local soundLevel = useCustomSounds and FLASHLIGHT_SOUNDS.customLevel or FLASHLIGHT_SOUNDS.defaultLevel
        EmitSound(soundName, ply:GetPos(), -1, CHAN_AUTO, 1, soundLevel, 0, 100, 1)
    end

    -- StartCommand runs clientside when each command is created, so the toggle shows without waiting a round trip.
    hook.Add("StartCommand", "BetterLights_FlashlightPredictToggle", function(ply, cmd)
        if cmd:GetImpulse() ~= 100 then return end

        local commandNumber = cmd:CommandNumber()
        if commandNumber == 0 or commandNumber == lastPredictedCommand then return end
        if ply ~= LocalPlayer() or not canPredictToggle(ply) then return end

        lastPredictedCommand = commandNumber

        local state = not getLocalFlashlightState(ply)
        local inputCount = predictedToggle and predictedToggle.inputCount or readNetworkedToggle(ply)

        predictedToggle = {
            inputCount = inputCount + 1,
            state = state,
            expires = RealTime() + PREDICTION_TIMEOUT + ply:Ping() / 1000 * 2
        }

        playPredictedToggleSound(ply, state)
    end)

    local function shouldDrawFlare(ply, localPlayer)
        if not getEffectiveBool(cvar_flare) then return false end
        if not IsValid(ply) or not ply:Alive() then return false end
        if not isPlayerFlashlightActive(ply) then return false end

        if ply ~= localPlayer then
            return getEffectiveBool(cvar_flare_others)
        end

        return ply:ShouldDrawLocalPlayer()
    end

    local function getFlareHandle(ply)
        local record = flarePixVis[ply]
        if record then return record end

        record = {
            handle = util.GetPixelVisibleHandle(),
            frame = -1
        }
        flarePixVis[ply] = record
        return record
    end

    local function drawFlareForPlayer(ply, localPlayer, frameNumber)
        if not shouldDrawFlare(ply, localPlayer) then return end

        local data = projectorData[ply]
        if not (data and data.flarePos and data.flareAng) then return end

        local record = getFlareHandle(ply)
        if record.frame == frameNumber then return end
        record.frame = frameNumber

        local pos = data.flarePos
        local ang = data.flareAng
        local viewNormal = pos - EyePos()
        local dist = viewNormal:Length()
        if dist <= FLARE_MIN_DISTANCE then return end

        viewNormal:Normalize()

        local facing = viewNormal:Dot(ang:Forward() * -1)
        if facing <= 0 then return end

        local visible = util.PixelVisible(pos, FLARE_PIXVIS_SIZE, record.handle)
        if visible <= 0 then return end

        local fadeDistance = math.Clamp(getEffectiveNumber(cvar_distance), MIN_DISTANCE, FLARE_MAX_FADE_DISTANCE)
        local distanceFade = 1 - math.Clamp((dist - FLARE_MIN_DISTANCE) / fadeDistance, 0, 1)
        if distanceFade <= 0 then return end

        local sizeScale = math.Clamp(getEffectiveNumber(cvar_flare_size), 0.25, 3)
        local spriteSize = math.Clamp(dist * visible * facing * 0.7 * sizeScale, FLARE_MIN_SIZE * sizeScale, FLARE_MAX_SIZE * sizeScale)
        local spriteAlpha = math.Clamp(getEffectiveNumber(cvar_flare_opacity) * visible * facing * distanceFade, 0, 255)
        if spriteAlpha <= 0 then return end

        local flashlightColor = data.flashlightColor
        if not flashlightColor then return end

        local spriteColor = Color(flashlightColor.r, flashlightColor.g, flashlightColor.b, spriteAlpha)

        render.DrawSprite(pos, spriteSize, spriteSize, spriteColor)

        spriteColor.a = math.Clamp(spriteAlpha * 2, 0, 255)
        render.DrawSprite(pos, spriteSize * FLARE_CORE_SCALE, spriteSize * FLARE_CORE_SCALE, spriteColor)
    end

    local function drawFlashlightFlares()
        if FLARE_MATERIAL:IsError() then return end
        if not isRendererEnabled() then return end

        local localPlayer = LocalPlayer()
        if not IsValid(localPlayer) then return end

        render.SetMaterial(FLARE_MATERIAL)

        local frameNumber = FrameNumber()
        for ply in pairs(projectorData) do
            drawFlareForPlayer(ply, localPlayer, frameNumber)
        end
    end

    local function runFlashlightThink()
        local seen = {}

        local localPlayer = LocalPlayer()
        refreshBeamSettings()

        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:Alive() and not ply:IsDormant() and isPlayerFlashlightActive(ply) then
                seen[ply] = true
                updateProjector(ply, localPlayer)
            end
        end

        BL.RemoveStaleProjectedTextures(projectors, seen, nil, projectorData)
        removeStaleFlareHandles(seen)
    end

    refreshThinkRegistration = function()
        if isRendererEnabled() then
            BL.AddThink(THINK_NAME, runFlashlightThink)
        else
            BL.RemoveThink(THINK_NAME)
            removeAllProjectors()
            clearFlareHandles()
        end
    end

    hook.Add("BetterLights_EffectiveEnabledChanged", "BetterLights_GlobalEnableFlashlight", refreshThinkRegistration)
    hook.Add("BetterLights_ServerSettingsChanged", "BetterLights_ServerSettingsFlashlight", refreshThinkRegistration)

    refreshThinkRegistration()

    hook.Add("ShutDown", "BetterLights_PlayerFlashlightsCleanup", function()
        removeAllProjectors()
        clearFlareHandles()
    end)

    -- A weapon-mounted light does not light the weapon or hands holding it, so darken the local lamp for the viewmodel pass.
    hook.Add("PreDrawViewModels", "BetterLights_FlashlightSkipViewModels", function()
        local lamp = projectors[LocalPlayer()]
        if not IsValid(lamp) then return end

        viewModelHiddenLamp = lamp
        viewModelHiddenBrightness = lamp:GetBrightness()
        lamp:SetBrightness(0)
        lamp:Update()
    end)

    -- PreDrawEffects runs after every viewmodel has drawn.
    hook.Add("PreDrawEffects", "BetterLights_FlashlightSkipViewModels", function()
        local lamp = viewModelHiddenLamp
        if not lamp then return end

        viewModelHiddenLamp = nil
        if not IsValid(lamp) then return end

        lamp:SetBrightness(viewModelHiddenBrightness)
        lamp:Update()
    end)

    hook.Add("PostDrawTranslucentRenderables", "BetterLights_PlayerFlashlightFlares", function(isDrawingDepth, isDrawingSkybox)
        if isDrawingSkybox then return end
        if not BL.IsMainViewRender(isDrawingDepth) then return end

        drawFlashlightFlares()
    end)
end
