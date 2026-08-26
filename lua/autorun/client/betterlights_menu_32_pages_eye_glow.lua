if CLIENT then
    local MENU = BetterLights.Menu
    local phrase = MENU.Phrase
    local setupPage = MENU.SetupPage
    local addSection = MENU.AddSection
    local addHelpText = MENU.AddHelpText
    local addBulkToggleSection = MENU.AddBulkToggleSection
    local addLightControls = MENU.AddLightControls
    local addColorMixerControl = MENU.AddColorMixerControl
    local addResetButton = MENU.AddResetButton
    local beginControlGroup = MENU.BeginControlGroup

    local COMBINE_EYE_GLOW_DEFAULTS = {
        {
            titleKey = "combine_eye.elite",
            subtitleKey = "combine_eye.elite.desc",
            prefix = "bl_combine_soldier_elite",
            size = 40,
            brightness = 0.5,
            decay = 1500,
            r = 255,
            g = 72,
            b = 72
        },
        {
            titleKey = "combine_eye.prison_yellow",
            subtitleKey = "combine_eye.prison_yellow.desc",
            prefix = "bl_combine_soldier_prisonguard_yellow",
            size = 40,
            brightness = 0.5,
            decay = 1500,
            r = 255,
            g = 220,
            b = 70
        },
        {
            titleKey = "combine_eye.prison_red",
            subtitleKey = "combine_eye.prison_red.desc",
            prefix = "bl_combine_soldier_prisonguard_red",
            size = 40,
            brightness = 0.5,
            decay = 1500,
            r = 255,
            g = 72,
            b = 72
        },
        {
            titleKey = "combine_eye.standard_blue",
            subtitleKey = "combine_eye.standard_blue.desc",
            prefix = "bl_combine_soldier_standard_blue",
            size = 40,
            brightness = 0.5,
            decay = 1500,
            r = 95,
            g = 150,
            b = 255
        },
        {
            titleKey = "combine_eye.standard_orange",
            subtitleKey = "combine_eye.standard_orange.desc",
            prefix = "bl_combine_soldier_standard_orange",
            size = 40,
            brightness = 0.5,
            decay = 1500,
            r = 255,
            g = 155,
            b = 48
        }
    }

    local function buildPlayerEyeLightsPage(panel)
        setupPage(panel, "page.player_eye_glow.title", "page.player_eye_glow.desc")

        local behavior = addSection(panel, "section.player_eye_behavior", nil, true)
        behavior:CheckBox(phrase("control.enable"), "betterlights_player_eye_enable")
        behavior:CheckBox(phrase("control.show_other_players"), "betterlights_player_eye_other_players")
        behavior:CheckBox(phrase("control.show_in_first_person"), "betterlights_player_eye_first_person")
        addHelpText(behavior, phrase("help.player_eye_first_person"))

        local light = addSection(panel, "section.player_eye_light", nil, true)
        beginControlGroup(light, "betterlights_player_eye_enable")
        addLightControls(light, "betterlights_player_eye", {
            enableLabel = false,
            radiusMax = 400,
            modelElight = true,
            modelElightLabel = "control.add_model_elight"
        })
        addColorMixerControl(
            light,
            "control.color",
            "betterlights_player_eye_color_r",
            "betterlights_player_eye_color_g",
            "betterlights_player_eye_color_b",
            110,
            190,
            255
        )

        addResetButton(panel, {
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
    local function addCombineEyeGlowPanel(panel)
        setupPage(panel, "page.combine_eye.title", "page.combine_eye.desc")

        local resetDefaults = {}
        local enableCvars = {}

        for _, info in ipairs(COMBINE_EYE_GLOW_DEFAULTS) do
            enableCvars[#enableCvars + 1] = info.prefix .. "_enable"
        end

        addBulkToggleSection(panel, enableCvars)

        for _, info in ipairs(COMBINE_EYE_GLOW_DEFAULTS) do
            local prefix = info.prefix
            local form = addSection(panel, info.titleKey, info.subtitleKey, false)
            addLightControls(form, prefix, {
                radiusMax = 200
            })
            addColorMixerControl(form, "control.color", prefix .. "_color_r", prefix .. "_color_g", prefix .. "_color_b", info.r, info.g, info.b)

            resetDefaults[prefix .. "_enable"] = 1
            resetDefaults[prefix .. "_size"] = info.size
            resetDefaults[prefix .. "_brightness"] = info.brightness
            resetDefaults[prefix .. "_decay"] = info.decay
            resetDefaults[prefix .. "_color_r"] = info.r
            resetDefaults[prefix .. "_color_g"] = info.g
            resetDefaults[prefix .. "_color_b"] = info.b
        end

        addResetButton(panel, resetDefaults)
    end

    local pages = {}
    local function registerPage(category, id, titleKey, buildPanel, descriptionKey, options)
        local page = {}
        for key, value in pairs(options or {}) do
            page[key] = value
        end
        page.category = category
        page.id = id
        page.titleKey = titleKey
        page.buildPanel = buildPanel
        page.descriptionKey = descriptionKey
        pages[#pages + 1] = page
    end
    registerPage("Eye Glow", "BL_PlayerEyeGlow", "menu.player_eye_glow", buildPlayerEyeLightsPage)

        registerPage("Eye Glow", "BL_CombineSoldiers", "menu.combine_soldiers", function(panel)
            addCombineEyeGlowPanel(panel)
        end, "page.combine_eye.desc")

        registerPage("Eye Glow", "BL_DogEyeGlow", "menu.dog_eye_glow", function(panel)
            setupPage(panel, "page.dog_eye_glow.title", "page.dog_eye_glow.desc")

            local dog = addSection(panel, "section.dog_eyes", nil, true)
            addLightControls(dog, "betterlights_dog_eye", {
                radiusMax = 200
            })
            addColorMixerControl(dog, "control.color", "betterlights_dog_eye_color_r", "betterlights_dog_eye_color_g", "betterlights_dog_eye_color_b", 255, 60, 60)

            addResetButton(panel, {
                betterlights_dog_eye_enable = 1,
                betterlights_dog_eye_size = 70,
                betterlights_dog_eye_brightness = 0.4,
                betterlights_dog_eye_decay = 1500,
                betterlights_dog_eye_color_r = 255,
                betterlights_dog_eye_color_g = 60,
                betterlights_dog_eye_color_b = 60,
            })
        end)

    MENU.RegisterPages("BetterLights_Menu_EyeGlow", pages)
end
