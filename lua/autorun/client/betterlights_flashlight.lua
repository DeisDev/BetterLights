if CLIENT then
    if not ProjectedTexture then return end

    BetterLights = BetterLights or {}
    local BL = BetterLights

    local cvar_fov = CreateClientConVar("betterlights_flashlight_fov", "45", true, false, "Flashlight cone FOV")
    local cvar_shadows = CreateClientConVar("betterlights_flashlight_shadows", "1", true, false, "Enable flashlight shadows")
    local cvar_attachment = CreateClientConVar("betterlights_flashlight_weapon_attachment", "1", true, false, "Use weapon or viewmodel muzzle attachments when available")
    local cvar_flicker = CreateClientConVar("betterlights_flashlight_flicker", "0", true, false, "Enable subtle flashlight flicker")
    local cvar_sway = CreateClientConVar("betterlights_flashlight_sway", "1", true, false, "Enable subtle flashlight sway")
    local cvar_attachment_offset = CreateClientConVar("betterlights_flashlight_attachment_offset", "2", true, false, "Side offset for weapon-attached flashlights")
    local cvar_fallback_offset = CreateClientConVar("betterlights_flashlight_fallback_offset", "8", true, false, "Side offset for eye-position flashlights")

    local TEXTURE = "effects/flashlight001"
    local COLOR = Color(255, 245, 225)
    local MIN_FOV = 1
    local MAX_FOV = 100
    local WALL_FOV_SCALE = 0.95
    local WALL_SHRINK_DISTANCE = 32
    local CLOSE_WALL_BRIGHTNESS_SCALE = 0.96
    local DISTANCE = 1200
    local NEAR_Z = 4
    local BRIGHTNESS = 1.35
    local FLICKER_AMOUNT = 0.08
    local AIM_SMOOTHING = 18
    local ATTACHMENT_OFFSET_FORWARD = 1
    local ATTACHMENT_OFFSET_DOWN = 2
    local EYE_OFFSET_FORWARD = 12
    local EYE_OFFSET_DOWN = 3
    local ATTACHMENT_NAMES = { "muzzle", "Muzzle", "barrel", "muzzle_flash", "1" }

    local projectors = {}
    local projectorData = {}
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

    local function applyAttachmentOffset(pos, ang)
        return pos
            + ang:Forward() * ATTACHMENT_OFFSET_FORWARD
            + ang:Right() * cvar_attachment_offset:GetFloat()
            - ang:Up() * ATTACHMENT_OFFSET_DOWN
    end

    local function getAttachmentTransform(ply, localPlayer)
        if not cvar_attachment:GetBool() then return end

        local source
        if ply == localPlayer and not ply:ShouldDrawLocalPlayer() then
            source = ply:GetViewModel()
        else
            source = ply:GetActiveWeapon()
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
        local brightness = BRIGHTNESS * Lerp(t, CLOSE_WALL_BRIGHTNESS_SCALE, 1)

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

        lamp:SetTexture(TEXTURE)
        lamp:SetPos(pos)
        lamp:SetAngles(ang)
        lamp:SetNearZ(NEAR_Z)
        lamp:SetFarZ(DISTANCE)
        lamp:SetFOV(getFOV(wallDist))
        lamp:SetBrightness(getBrightness(ply, wallDist))
        lamp:SetColor(COLOR)
        lamp:SetEnableShadows(cvar_shadows:GetBool())
        lamp:Update()
    end

    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_PlayerFlashlights", function()
        local moduleCvar = GetConVar("betterlights_flashlight_enable")
        local enabled = not moduleCvar or moduleCvar:GetBool()
        local seen = {}

        if enabled then
            local localPlayer = LocalPlayer()

            for _, ply in ipairs(player.GetAll()) do
                if IsValid(ply) and ply:Alive() and ply:GetNWBool("BetterLights_Flashlight", false) then
                    seen[ply] = true
                    updateProjector(ply, localPlayer)
                end
            end
        end

        for ply in pairs(projectors) do
            if not seen[ply] then
                removeProjector(ply)
            end
        end
    end)

    hook.Add("ShutDown", "BetterLights_PlayerFlashlightsCleanup", function()
        for ply in pairs(projectors) do
            removeProjector(ply)
        end
    end)
end
