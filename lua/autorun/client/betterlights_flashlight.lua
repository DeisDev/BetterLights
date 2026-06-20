if CLIENT then
    local cvar_player_enable = CreateClientConVar("betterlights_flashlight_player_enable", "0", true, false, "Enable BetterLights flashlight replacement for your player")
    local cvar_custom_sounds = CreateClientConVar("betterlights_flashlight_custom_sounds", "1", true, false, "Use BetterLights flashlight on/off sounds instead of vanilla flashlight sound events")
    local refreshThinkRegistration
    local CUSTOM_SOUND_ON = "betterlights/flashlight_on.wav"
    local CUSTOM_SOUND_OFF = "betterlights/flashlight_off.wav"
    local DEFAULT_SOUND_ON = "HL2Player.FlashLightOn"
    local DEFAULT_SOUND_OFF = "HL2Player.FlashLightOff"
    local CUSTOM_SOUND_LEVEL = 77

    local function syncPlayerEnable()
        if not IsValid(LocalPlayer()) then return end

        net.Start("BetterLights_FlashlightClientEnable")
            net.WriteBool(cvar_player_enable:GetBool())
        net.SendToServer()
    end

    local function queuePlayerEnableSync()
        syncPlayerEnable()
        timer.Simple(1, syncPlayerEnable)
        timer.Simple(3, syncPlayerEnable)
    end

    hook.Add("InitPostEntity", "BetterLights_FlashlightSyncPlayerEnable", function()
        queuePlayerEnableSync()
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
    end

    net.Receive("BetterLights_FlashlightSound", function()
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

    BetterLights = BetterLights or {}
    local BL = BetterLights
    local THINK_NAME = "BetterLights_PlayerFlashlights"

    local cvar_fov = CreateClientConVar("betterlights_flashlight_fov", "45", true, false, "Flashlight cone FOV")
    local cvar_shadows = CreateClientConVar("betterlights_flashlight_shadows", "1", true, false, "Enable flashlight shadows")
    local cvar_attachment = CreateClientConVar("betterlights_flashlight_weapon_attachment", "1", true, false, "Use weapon or viewmodel muzzle attachments when available")
    local cvar_flicker = CreateClientConVar("betterlights_flashlight_flicker", "0", true, false, "Enable subtle flashlight flicker")
    local cvar_sway = CreateClientConVar("betterlights_flashlight_sway", "1", true, false, "Enable subtle flashlight sway")
    local cvar_distance = CreateClientConVar("betterlights_flashlight_distance", "1200", true, false, "Flashlight beam length")
    local cvar_attachment_offset = CreateClientConVar("betterlights_flashlight_attachment_offset", "2", true, false, "Side offset for weapon-attached flashlights")
    local cvar_fallback_offset = CreateClientConVar("betterlights_flashlight_fallback_offset", "8", true, false, "Side offset for eye-position flashlights")
    local cvar_brightness = CreateClientConVar("betterlights_flashlight_brightness", "1.35", true, false, "Flashlight brightness")
    local cvar_texture = CreateClientConVar("betterlights_flashlight_texture", "effects/flashlight001", true, false, "Flashlight texture material path")

    local DEFAULT_TEXTURE = "effects/flashlight001"
    local RECENT_TEXTURE_COOKIE = "betterlights_flashlight_recent_textures"
    local MAX_RECENT_TEXTURES = 12
    local TEXTURE_ROOTS = {
        "effects/lightspill/",
        "effects/flashlight/",
        "effects/flashlights/",
        "models/flashlight/"
    }
    local COLOR = Color(255, 245, 225)
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
    local FLICKER_AMOUNT = 0.08
    local AIM_SMOOTHING = 18
    local ATTACHMENT_OFFSET_FORWARD = 1
    local ATTACHMENT_OFFSET_DOWN = 2
    local EYE_OFFSET_FORWARD = 12
    local EYE_OFFSET_DOWN = 3
    local ATTACHMENT_NAMES = { "muzzle", "Muzzle", "barrel", "muzzle_flash", "1" }
    local EYE_FALLBACK_WEAPONS = {
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

    local function removeProjector(ply)
        local lamp = projectors[ply]
        if lamp and lamp.IsValid and lamp:IsValid() then
            lamp:Remove()
        end

        projectors[ply] = nil
        projectorData[ply] = nil
    end

    local function removeAllProjectors()
        for ply in pairs(projectors) do
            removeProjector(ply)
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

        RunConsoleCommand("betterlights_flashlight_texture", path)
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
            + ang:Forward() * ATTACHMENT_OFFSET_FORWARD
            + ang:Right() * cvar_attachment_offset:GetFloat()
            - ang:Up() * ATTACHMENT_OFFSET_DOWN
    end

    local function isFirstPersonZooming(ply, localPlayer)
        if ply ~= localPlayer or ply:ShouldDrawLocalPlayer() then return false end
        if not ply.KeyDown or not ply:KeyDown(IN_ZOOM) then return false end
        if not ply.GetCanZoom then return true end

        return ply:GetCanZoom()
    end

    local function getAttachmentTransform(ply, localPlayer)
        if not cvar_attachment:GetBool() then return end
        if isFirstPersonZooming(ply, localPlayer) then return end

        local activeWeapon = ply:GetActiveWeapon()
        if IsValid(activeWeapon) and EYE_FALLBACK_WEAPONS[activeWeapon:GetClass()] then return end

        local source
        if ply == localPlayer and not ply:ShouldDrawLocalPlayer() then
            source = ply:GetViewModel()
        else
            source = activeWeapon
        end

        if not IsValid(source) or not source.LookupAttachment then return end

        for i = 1, #ATTACHMENT_NAMES do
            local id = source:LookupAttachment(ATTACHMENT_NAMES[i])
            if id and id > 0 then
                local attachment = source:GetAttachment(id)
                if attachment and attachment.Pos and attachment.Ang then
                    return applyAttachmentOffset(attachment.Pos, attachment.Ang), attachment.Ang
                end
            end
        end
    end

    local function getEyeTransform(ply)
        local ang = ply:EyeAngles()
        local pos = ply:EyePos()

        pos = pos
            + ang:Forward() * EYE_OFFSET_FORWARD
            + ang:Right() * cvar_fallback_offset:GetFloat()
            - ang:Up() * EYE_OFFSET_DOWN

        if ply.GetViewPunchAngles then
            ang = ang + ply:GetViewPunchAngles()
        end

        return pos, ang
    end

    local function getWallDistance(ply, pos, ang)
        traceData.filter = ply
        traceData.start = pos
        traceData.endpos = pos + ang:Forward() * WALL_SHRINK_DISTANCE

        local wallTrace = util.TraceHull(traceData)
        return wallTrace.StartPos:Distance(wallTrace.HitPos)
    end

    local function getSmoothedAngle(data, ang)
        if not cvar_sway:GetBool() then
            data.smoothAng = nil
            return ang
        end

        data.smoothAng = data.smoothAng or Angle(ang.p, ang.y, ang.r)
        data.smoothAng = LerpAngle(math.Clamp(FrameTime() * AIM_SMOOTHING, 0, 1), data.smoothAng, ang)

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
        return math.max(0, brightness * (1 + wave * FLICKER_AMOUNT))
    end

    local function updateProjector(ply, localPlayer)
        local lamp = projectors[ply]
        if not lamp or not lamp:IsValid() then
            lamp = ProjectedTexture()
            if not lamp then return end
            projectors[ply] = lamp
        end

        local data = projectorData[ply] or {}
        projectorData[ply] = data

        local pos, ang = getAttachmentTransform(ply, localPlayer)
        if not pos then
            pos, ang = getEyeTransform(ply)
        end

        ang = getSmoothedAngle(data, ang)
        local wallDist = getWallDistance(ply, pos, ang)
        local distance = math.Clamp(cvar_distance:GetFloat(), MIN_DISTANCE, MAX_DISTANCE)

        lamp:SetTexture(getTexturePath())
        lamp:SetPos(pos)
        lamp:SetAngles(ang)
        lamp:SetNearZ(NEAR_Z)
        lamp:SetFarZ(distance)
        lamp:SetFOV(getFOV(wallDist))
        lamp:SetBrightness(getBrightness(ply, wallDist))
        lamp:SetColor(COLOR)
        lamp:SetEnableShadows(cvar_shadows:GetBool())
        lamp:Update()
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

        for ply in pairs(projectors) do
            if not seen[ply] then
                removeProjector(ply)
            end
        end
    end

    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    local RemoveThink = BL.RemoveThink or function(name) hook.Remove("Think", name) end

    refreshThinkRegistration = function()
        if isRendererEnabled() then
            AddThink(THINK_NAME, runFlashlightThink)
        else
            RemoveThink(THINK_NAME)
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
