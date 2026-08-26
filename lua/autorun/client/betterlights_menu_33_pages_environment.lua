if CLIENT then
    local MENU = BetterLights.Menu
    local phrase = MENU.Phrase
    local setupPage = MENU.SetupPage
    local addSection = MENU.AddSection
    local addLightControls = MENU.AddLightControls
    local addColorMixerControl = MENU.AddColorMixerControl
    local addResetButton = MENU.AddResetButton
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
    registerPage("Environment", "BL_Fire", "menu.fire", function(panel)
            setupPage(panel, "page.fire.title", "page.fire.desc")
            panel:CheckBox(phrase("control.enable"), "betterlights_fire_enable")
            panel:NumSlider(phrase("control.radius"), "betterlights_fire_size", 0, 800, 0)
            panel:NumSlider(phrase("control.brightness"), "betterlights_fire_brightness", 0, 10, 2)
            panel:NumSlider(phrase("control.decay"), "betterlights_fire_decay", 0, 5000, 0)
            panel:CheckBox(phrase("control.add_model_elight"), "betterlights_fire_models_elight")
            panel:NumSlider(phrase("control.model_elight_radius"), "betterlights_fire_models_elight_size_mult", 0, 3, 2)
            addColorMixerControl(panel, "control.color", "betterlights_fire_color_r", "betterlights_fire_color_g", "betterlights_fire_color_b")
            panel:CheckBox(phrase("control.flicker"), "betterlights_fire_flicker_enable")
            panel:NumSlider(phrase("control.flicker_amount"), "betterlights_fire_flicker_amount", 0, 1, 2)
            panel:NumSlider(phrase("control.flicker_size_amount"), "betterlights_fire_flicker_size_amount", 0, 1, 2)
            panel:NumSlider(phrase("control.flicker_speed"), "betterlights_fire_flicker_speed", 0, 30, 1)
            addResetButton(panel, {
                betterlights_fire_enable = 1,
                betterlights_fire_size = 160,
                betterlights_fire_brightness = 5.2,
                betterlights_fire_decay = 2000,
                betterlights_fire_models_elight = 1,
                betterlights_fire_models_elight_size_mult = 1.0,
                betterlights_fire_color_r = 255,
                betterlights_fire_color_g = 170,
                betterlights_fire_color_b = 60,
                betterlights_fire_flicker_enable = 1,
                betterlights_fire_flicker_amount = 0.35,
                betterlights_fire_flicker_size_amount = 0.12,
                betterlights_fire_flicker_speed = 11.5,
            })
        end)

        registerPage("Environment", "BL_Chargers", "menu.chargers", function(panel)
                setupPage(panel, "page.chargers.title", "page.chargers.desc")
                local suit = addSection(panel, "section.suit_charger", nil, true)
                addLightControls(suit, "betterlights_suitcharger", {
                    enableLabel = "control.enable",
                    radiusMax = 300,
                    brightnessMax = 2,
                    modelElight = true,
                    modelElightLabel = "control.add_model_elight"
                })
                addColorMixerControl(suit, "control.suit_color", "betterlights_suitcharger_color_r", "betterlights_suitcharger_color_g", "betterlights_suitcharger_color_b")

                local health = addSection(panel, "section.health_charger", nil, true)
                addLightControls(health, "betterlights_healthcharger", {
                    enableLabel = "control.enable",
                    radiusMax = 300,
                    brightnessMax = 2,
                    modelElight = true,
                    modelElightLabel = "control.add_model_elight"
                })
                addColorMixerControl(health, "control.health_color", "betterlights_healthcharger_color_r", "betterlights_healthcharger_color_g", "betterlights_healthcharger_color_b")
                addResetButton(panel, {
                    betterlights_suitcharger_enable = 1,
                    betterlights_suitcharger_size = 75,
                    betterlights_suitcharger_brightness = 0.25,
                    betterlights_suitcharger_decay = 1800,
                    betterlights_suitcharger_models_elight = 1,
                    betterlights_suitcharger_models_elight_size_mult = 1.0,
                    betterlights_suitcharger_color_r = 255,
                    betterlights_suitcharger_color_g = 180,
                    betterlights_suitcharger_color_b = 80,
                    betterlights_healthcharger_enable = 1,
                    betterlights_healthcharger_size = 75,
                    betterlights_healthcharger_brightness = 0.25,
                    betterlights_healthcharger_decay = 1800,
                    betterlights_healthcharger_models_elight = 1,
                    betterlights_healthcharger_models_elight_size_mult = 1.0,
                    betterlights_healthcharger_color_r = 110,
                    betterlights_healthcharger_color_g = 190,
                    betterlights_healthcharger_color_b = 255,
                })
            end)

    MENU.RegisterPages("BetterLights_Menu_Environment", pages)
end
