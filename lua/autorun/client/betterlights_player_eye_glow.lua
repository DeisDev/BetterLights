if CLIENT then
    local BL = BetterLights

    local EYE_ATTACHMENT = { "eyes" }
    local cvar_enable = BL.CreateClientConVar(
        "betterlights_player_eye_enable",
        "0",
        true,
        false,
        "Enable eye lights on player models",
        0,
        1
    )
    local cvar_other_players = BL.CreateClientConVar(
        "betterlights_player_eye_other_players",
        "1",
        true,
        false,
        "Show player eye lights on other players",
        0,
        1
    )
    local cvar_first_person = BL.CreateClientConVar(
        "betterlights_player_eye_first_person",
        "0",
        true,
        false,
        "Keep the local player eye light active when the playermodel is not visible",
        0,
        1
    )
    local cvar_size = BL.CreateClientConVar(
        "betterlights_player_eye_size",
        "55",
        true,
        false,
        "Player eye light radius",
        0,
        400
    )
    local cvar_brightness = BL.CreateClientConVar(
        "betterlights_player_eye_brightness",
        "0.35",
        true,
        false,
        "Player eye light brightness",
        0,
        5
    )
    local cvar_decay = BL.CreateClientConVar(
        "betterlights_player_eye_decay",
        "1500",
        true,
        false,
        "Player eye light decay",
        0,
        5000
    )
    local cvar_models_elight = BL.CreateClientConVar(
        "betterlights_player_eye_models_elight",
        "0",
        true,
        false,
        "Also add an entity light to light player models directly",
        0,
        1
    )
    local cvar_models_elight_size_mult = BL.CreateClientConVar(
        "betterlights_player_eye_models_elight_size_mult",
        "1",
        true,
        false,
        "Multiplier for player eye entity light radius",
        0,
        3
    )
    local cvar_r = BL.CreateClientConVar(
        "betterlights_player_eye_color_r",
        "110",
        true,
        false,
        "Player eye light color - red",
        0,
        255
    )
    local cvar_g = BL.CreateClientConVar(
        "betterlights_player_eye_color_g",
        "190",
        true,
        false,
        "Player eye light color - green",
        0,
        255
    )
    local cvar_b = BL.CreateClientConVar(
        "betterlights_player_eye_color_b",
        "255",
        true,
        false,
        "Player eye light color - blue",
        0,
        255
    )

    local LOCAL_PLAYER_LIGHT_OPTIONS = {
        priority = BL.LIGHT_PRIORITY_LOCAL_PLAYER
    }
    BL._playerEyeLightIds = BL._playerEyeLightIds or {}
    setmetatable(BL._playerEyeLightIds, { __mode = "k" })

    local function getLightId(ply)
        local id = BL._playerEyeLightIds[ply]
        if id then return id end

        id = BL.NewLightId(85000)
        BL._playerEyeLightIds[ply] = id
        return id
    end

    local function shouldLightPlayer(ply, localPlayer)
        if not (IsValid(ply) and ply:IsPlayer() and ply:Alive()) then return false end
        if ply.GetNoDraw and ply:GetNoDraw() then return false end
        if ply.IsDormant and ply:IsDormant() then return false end

        if ply ~= localPlayer then
            return cvar_other_players:GetBool()
        end

        if cvar_first_person:GetBool() then return true end
        return ply.ShouldDrawLocalPlayer and ply:ShouldDrawLocalPlayer()
    end

    BL.TrackClass("player")
    BL.AddThink("BetterLights_PlayerEyeGlow", function()
        if not cvar_enable:GetBool() then return end

        local localPlayer = LocalPlayer()
        if not IsValid(localPlayer) then return end

        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())
        local elight = cvar_models_elight:GetBool()
        local elightMult = math.max(0, cvar_models_elight_size_mult:GetFloat())
        local r, g, b = BL.GetColorFromCvars(cvar_r, cvar_g, cvar_b)

        BL.ForEach("player", function(ply)
            if not shouldLightPlayer(ply, localPlayer) then return end

            local pos = BL.GetAttachmentPos(ply, EYE_ATTACHMENT)
            if not pos then return end

            local lightId = getLightId(ply)
            local options = ply == localPlayer and LOCAL_PLAYER_LIGHT_OPTIONS or nil
            BL.CreateDLight(lightId, pos, r, g, b, brightness, decay, size, false, options)

            if elight then
                BL.CreateDLight(lightId, pos, r, g, b, brightness, decay, size * elightMult, true, options)
            end
        end)
    end)
end
