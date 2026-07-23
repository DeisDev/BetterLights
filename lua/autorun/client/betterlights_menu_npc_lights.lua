if CLIENT then
    local MENU = BetterLights.Menu

    local function buildNPCRagdollLightsPage(panel)
        local phrase = MENU.Phrase

        MENU.SetupPage(panel, "page.npc_remains.title", "page.npc_remains.desc")

        local persistence = MENU.AddSection(panel, "section.npc_remains", "section.npc_remains.desc", true)
        persistence:CheckBox(
            phrase("control.keep_npc_eye_lights_after_death"),
            "betterlights_npc_ragdoll_eye_lights_enable"
        )
        persistence:CheckBox(
            phrase("control.keep_npc_ambient_lights_after_death"),
            "betterlights_npc_ragdoll_ambient_lights_enable"
        )
        persistence:NumSlider(
            phrase("control.maximum_lit_remains"),
            "betterlights_npc_ragdoll_max_lit_remains",
            0,
            32,
            0
        )
        MENU.AddHelpText(persistence, phrase("help.npc_remains_supported"))
        MENU.AddHelpText(persistence, phrase("help.npc_remains_budget"))

        MENU.AddResetButton(panel, {
            betterlights_npc_ragdoll_eye_lights_enable = 0,
            betterlights_npc_ragdoll_ambient_lights_enable = 0,
            betterlights_npc_ragdoll_max_lit_remains = 8,
        })
    end

    local function buildPlayerEyeLightsPage(panel)
        local phrase = MENU.Phrase

        MENU.SetupPage(panel, "page.player_eye_glow.title", "page.player_eye_glow.desc")

        local behavior = MENU.AddSection(panel, "section.player_eye_behavior", nil, true)
        behavior:CheckBox(phrase("control.enable"), "betterlights_player_eye_enable")
        behavior:CheckBox(phrase("control.show_other_players"), "betterlights_player_eye_other_players")
        behavior:CheckBox(phrase("control.show_in_first_person"), "betterlights_player_eye_first_person")
        MENU.AddHelpText(behavior, phrase("help.player_eye_first_person"))

        local light = MENU.AddSection(panel, "section.player_eye_light", nil, true)
        MENU.AddLightControls(light, "betterlights_player_eye", {
            enableLabel = false,
            radiusMax = 400,
            modelElight = true,
            modelElightLabel = "control.add_model_elight"
        })
        MENU.AddColorMixerControl(
            light,
            "control.color",
            "betterlights_player_eye_color_r",
            "betterlights_player_eye_color_g",
            "betterlights_player_eye_color_b",
            110,
            190,
            255
        )

        MENU.AddResetButton(panel, {
            betterlights_player_eye_enable = 0,
            betterlights_player_eye_other_players = 1,
            betterlights_player_eye_first_person = 0,
            betterlights_player_eye_size = 55,
            betterlights_player_eye_brightness = 0.35,
            betterlights_player_eye_decay = 1500,
            betterlights_player_eye_models_elight = 0,
            betterlights_player_eye_models_elight_size_mult = 1,
            betterlights_player_eye_color_r = 110,
            betterlights_player_eye_color_g = 190,
            betterlights_player_eye_color_b = 255,
        })
    end

    function MENU.RegisterNPCLightPanels()
        MENU.RegisterPage("NPCs", "BL_NPCRemains", "menu.npc_remains", buildNPCRagdollLightsPage)
        MENU.RegisterPage("Eye Glow", "BL_PlayerEyeGlow", "menu.player_eye_glow", buildPlayerEyeLightsPage)
    end
end
