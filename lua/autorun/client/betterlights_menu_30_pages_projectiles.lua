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
        registerPage("Projectiles", "BL_CombineBall", "menu.combine_ball", function(panel)
            setupPage(panel, "page.combine_ball.title", "page.combine_ball.desc")
            panel:CheckBox(phrase("control.enable"), "betterlights_combineball_enable")
            panel:NumSlider(phrase("control.radius"), "betterlights_combineball_size", 0, 800, 0)
            panel:NumSlider(phrase("control.brightness"), "betterlights_combineball_brightness", 0, 10, 2)
            panel:NumSlider(phrase("control.decay"), "betterlights_combineball_decay", 0, 5000, 0)
            addColorMixerControl(panel, "control.color", "betterlights_combineball_color_r", "betterlights_combineball_color_g", "betterlights_combineball_color_b")

            local targets = addSection(panel, "section.lighting_targets", "section.lighting_targets.desc", false)
            targets.BetterLightsSkipAutoState = true
            targets:CheckBox(phrase("control.light_world"), "betterlights_combineball_world_light_enable")
            targets:CheckBox(phrase("control.light_models"), "betterlights_combineball_model_light_enable")
            targets:CheckBox(phrase("control.use_entity_light_for_models"), "betterlights_combineball_models_elight")
            targets:NumSlider(phrase("control.model_elight_radius"), "betterlights_combineball_models_elight_size_mult", 0, 3, 2)

            addResetButton(panel, {
                betterlights_combineball_enable = 1,
                betterlights_combineball_size = 320,
                betterlights_combineball_brightness = 2.5,
                betterlights_combineball_decay = 2000,
                betterlights_combineball_world_light_enable = 1,
                betterlights_combineball_model_light_enable = 1,
                betterlights_combineball_models_elight = 0,
                betterlights_combineball_models_elight_size_mult = 1.0,
                betterlights_combineball_color_r = 80,
                betterlights_combineball_color_g = 180,
                betterlights_combineball_color_b = 255,
            })
        end)

    registerPage("Projectiles", "BL_Bolt", "menu.crossbow_bolt", function(panel)
            setupPage(panel, "page.crossbow_bolt.title", "page.crossbow_bolt.desc")
            panel:CheckBox(phrase("control.enable"), "betterlights_bolt_enable")
            panel:NumSlider(phrase("control.radius"), "betterlights_bolt_size", 0, 800, 0)
            panel:NumSlider(phrase("control.brightness"), "betterlights_bolt_brightness", 0, 10, 2)
            panel:NumSlider(phrase("control.decay"), "betterlights_bolt_decay", 0, 5000, 0)
            addColorMixerControl(panel, "control.color", "betterlights_bolt_color_r", "betterlights_bolt_color_g", "betterlights_bolt_color_b")
            addResetButton(panel, {
                betterlights_bolt_enable = 1,
                betterlights_bolt_size = 220,
                betterlights_bolt_brightness = 0.96,
                betterlights_bolt_decay = 2000,
                betterlights_bolt_color_r = 255,
                betterlights_bolt_color_g = 140,
                betterlights_bolt_color_b = 40,
            })
        end)

    registerPage("Projectiles", "BL_RPG", "menu.rpg_rocket", function(panel)
            setupPage(panel, "page.rpg_rocket.title", "page.rpg_rocket.desc")
            panel:CheckBox(phrase("control.enable"), "betterlights_rpg_enable")
            panel:NumSlider(phrase("control.radius"), "betterlights_rpg_size", 0, 800, 0)
            panel:NumSlider(phrase("control.brightness"), "betterlights_rpg_brightness", 0, 10, 2)
            panel:NumSlider(phrase("control.decay"), "betterlights_rpg_decay", 0, 5000, 0)
            addColorMixerControl(panel, "control.color", "betterlights_rpg_color_r", "betterlights_rpg_color_g", "betterlights_rpg_color_b")

            local flash = addSection(panel, "section.explosion_flash", nil, true)
            flash:CheckBox(phrase("control.flash_on_explosion"), "betterlights_rpg_flash_enable")
            flash:NumSlider(phrase("control.radius"), "betterlights_rpg_flash_size", 0, 800, 0)
            flash:NumSlider(phrase("control.brightness"), "betterlights_rpg_flash_brightness", 0, 10, 2)
            flash:NumSlider(phrase("control.duration"), "betterlights_rpg_flash_time", 0, 1, 2)
            addColorMixerControl(flash, "control.flash_color", "betterlights_rpg_flash_color_r", "betterlights_rpg_flash_color_g", "betterlights_rpg_flash_color_b")

            addResetButton(panel, {
                betterlights_rpg_enable = 1,
                betterlights_rpg_size = 280,
                betterlights_rpg_brightness = 2.2,
                betterlights_rpg_decay = 2000,
                betterlights_rpg_color_r = 255,
                betterlights_rpg_color_g = 170,
                betterlights_rpg_color_b = 60,
                betterlights_rpg_flash_enable = 1,
                betterlights_rpg_flash_size = 340,
                betterlights_rpg_flash_brightness = 4.8,
                betterlights_rpg_flash_time = 0.18,
                betterlights_rpg_flash_color_r = 255,
                betterlights_rpg_flash_color_g = 210,
                betterlights_rpg_flash_color_b = 120,
            })
        end)

    registerPage("Projectiles", "BL_Explosions", "menu.explosion_flash", function(panel)
        setupPage(panel, "page.explosion_flash.title", "page.explosion_flash.desc")
        panel:CheckBox(phrase("control.enable"), "betterlights_explosion_flash_enable")
        panel:NumSlider(phrase("control.radius"), "betterlights_explosion_flash_size", 0, 800, 0)
        panel:NumSlider(phrase("control.brightness"), "betterlights_explosion_flash_brightness", 0, 10, 2)
        panel:NumSlider(phrase("control.duration_seconds"), "betterlights_explosion_flash_time", 0, 1, 2)
        addColorMixerControl(panel, "control.color", "betterlights_explosion_flash_color_r", "betterlights_explosion_flash_color_g", "betterlights_explosion_flash_color_b")
        addResetButton(panel, {
            betterlights_explosion_flash_enable = 1,
            betterlights_explosion_flash_size = 460,
            betterlights_explosion_flash_brightness = 4.6,
            betterlights_explosion_flash_time = 0.18,
            betterlights_explosion_flash_color_r = 255,
            betterlights_explosion_flash_color_g = 210,
            betterlights_explosion_flash_color_b = 120,
        })
    end)

    registerPage("Projectiles", "BL_Grenade", "menu.frag_grenade", function(panel)
            setupPage(panel, "page.frag_grenade.title", "page.frag_grenade.desc")
            panel:CheckBox(phrase("control.enable"), "betterlights_grenade_enable")
            panel:NumSlider(phrase("control.radius"), "betterlights_grenade_size", 0, 400, 0)
            panel:NumSlider(phrase("control.brightness"), "betterlights_grenade_brightness", 0, 5, 2)
            panel:NumSlider(phrase("control.decay"), "betterlights_grenade_decay", 0, 5000, 0)
            panel:CheckBox(phrase("control.add_model_elight"), "betterlights_grenade_models_elight")
            panel:NumSlider(phrase("control.model_elight_radius"), "betterlights_grenade_models_elight_size_mult", 0, 3, 2)
            addColorMixerControl(panel, "control.color", "betterlights_grenade_color_r", "betterlights_grenade_color_g", "betterlights_grenade_color_b")
            addResetButton(panel, {
                betterlights_grenade_enable = 1,
                betterlights_grenade_size = 80,
                betterlights_grenade_brightness = 0.9,
                betterlights_grenade_decay = 1800,
                betterlights_grenade_models_elight = 1,
                betterlights_grenade_models_elight_size_mult = 1.0,
                betterlights_grenade_color_r = 255,
                betterlights_grenade_color_g = 40,
                betterlights_grenade_color_b = 40,
            })
        end)

    registerPage("Projectiles", "BL_HeliBomb", "menu.heli_bomb", function(panel)
            setupPage(panel, "page.heli_bomb.title", "page.heli_bomb.desc")
            local glow = addSection(panel, "section.bomb_glow", nil, true)
            addLightControls(glow, "betterlights_heli_bomb", {
                radiusMax = 400,
                modelElight = true,
                modelElightLabel = "control.add_model_elight"
            })
            addColorMixerControl(glow, "control.glow_color", "betterlights_heli_bomb_color_r", "betterlights_heli_bomb_color_g", "betterlights_heli_bomb_color_b")

            local flash = addSection(panel, "section.explosion_flash", nil, true)
            flash:CheckBox(phrase("control.flash_on_explosion"), "betterlights_heli_bomb_flash_enable")
            flash:NumSlider(phrase("control.radius"), "betterlights_heli_bomb_flash_size", 0, 800, 0)
            flash:NumSlider(phrase("control.brightness"), "betterlights_heli_bomb_flash_brightness", 0, 10, 2)
            flash:NumSlider(phrase("control.duration"), "betterlights_heli_bomb_flash_time", 0, 1, 2)
            addColorMixerControl(flash, "control.flash_color", "betterlights_heli_bomb_flash_color_r", "betterlights_heli_bomb_flash_color_g", "betterlights_heli_bomb_flash_color_b")
            addResetButton(panel, {
                betterlights_heli_bomb_enable = 1,
                betterlights_heli_bomb_size = 140,
                betterlights_heli_bomb_brightness = 1.4,
                betterlights_heli_bomb_decay = 2000,
                betterlights_heli_bomb_models_elight = 1,
                betterlights_heli_bomb_models_elight_size_mult = 1.0,
                betterlights_heli_bomb_color_r = 255,
                betterlights_heli_bomb_color_g = 60,
                betterlights_heli_bomb_color_b = 60,
                betterlights_heli_bomb_flash_enable = 1,
                betterlights_heli_bomb_flash_size = 320,
                betterlights_heli_bomb_flash_brightness = 5.0,
                betterlights_heli_bomb_flash_time = 0.18,
                betterlights_heli_bomb_flash_color_r = 255,
                betterlights_heli_bomb_flash_color_g = 210,
                betterlights_heli_bomb_flash_color_b = 120,
            })
        end)

    registerPage("Projectiles", "BL_Magnusson", "menu.magnusson", function(panel)
            setupPage(panel, "page.magnusson.title", "page.magnusson.desc")
            local glow = addSection(panel, "section.device_glow", nil, true)
            addLightControls(glow, "betterlights_magnusson", {
                radiusMax = 400,
                modelElight = true,
                modelElightLabel = "control.add_model_elight"
            })
            addColorMixerControl(glow, "control.glow_color", "betterlights_magnusson_color_r", "betterlights_magnusson_color_g", "betterlights_magnusson_color_b")

            local flash = addSection(panel, "section.explosion_flash", nil, true)
            flash:CheckBox(phrase("control.flash_on_explosion"), "betterlights_magnusson_flash_enable")
            flash:NumSlider(phrase("control.radius"), "betterlights_magnusson_flash_size", 0, 800, 0)
            flash:NumSlider(phrase("control.brightness"), "betterlights_magnusson_flash_brightness", 0, 10, 2)
            flash:NumSlider(phrase("control.duration"), "betterlights_magnusson_flash_time", 0, 1, 2)
            addColorMixerControl(flash, "control.flash_color", "betterlights_magnusson_flash_color_r", "betterlights_magnusson_flash_color_g", "betterlights_magnusson_flash_color_b")
            addResetButton(panel, {
                betterlights_magnusson_enable = 1,
                betterlights_magnusson_size = 130,
                betterlights_magnusson_brightness = 0.48,
                betterlights_magnusson_decay = 2000,
                betterlights_magnusson_models_elight = 1,
                betterlights_magnusson_models_elight_size_mult = 1.0,
                betterlights_magnusson_color_r = 130,
                betterlights_magnusson_color_g = 180,
                betterlights_magnusson_color_b = 255,
                betterlights_magnusson_flash_enable = 1,
                betterlights_magnusson_flash_size = 360,
                betterlights_magnusson_flash_brightness = 2.2,
                betterlights_magnusson_flash_time = 2.0,
                betterlights_magnusson_flash_color_r = 180,
                betterlights_magnusson_flash_color_g = 220,
                betterlights_magnusson_flash_color_b = 255,
            })
        end)

    MENU.RegisterPages("BetterLights_Menu_Projectiles", pages)
end
