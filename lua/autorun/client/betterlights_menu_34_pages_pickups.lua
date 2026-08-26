if CLIENT then
    local MENU = BetterLights.Menu
    local phrase = MENU.Phrase
    local setupPage = MENU.SetupPage
    local addSection = MENU.AddSection
    local addRawSection = MENU.AddRawSection
    local addBulkToggleSection = MENU.AddBulkToggleSection
    local addLightControls = MENU.AddLightControls
    local addColorMixerControl = MENU.AddColorMixerControl
    local addResetButton = MENU.AddResetButton
    local function addWorldWeaponPanel(panel)
        setupPage(panel, "page.world_weapons.title", "page.world_weapons.desc")
        local resetDefaults = {}

        local defs = BetterLights.GetWorldWeaponLightDefinitions()
        local enableCvars = {}

        for _, info in ipairs(defs) do
            enableCvars[#enableCvars + 1] = "betterlights_world_weapon_" .. info.slug .. "_enable"
        end

        addBulkToggleSection(panel, enableCvars)

        for _, info in ipairs(defs) do
            local prefix = "betterlights_world_weapon_" .. info.slug
            local form = info.nameKey and addSection(panel, info.nameKey, nil, false) or addRawSection(panel, info.name, nil, false)
            addLightControls(form, prefix, {
                radiusMax = 300,
                brightnessMax = 2,
                modelElight = true,
                modelElightLabel = "control.add_model_elight"
            })

            addColorMixerControl(form, "control.color", prefix .. "_color_r", prefix .. "_color_g", prefix .. "_color_b", info.r, info.g, info.b)

            resetDefaults[prefix .. "_enable"] = 1
            resetDefaults[prefix .. "_size"] = info.size
            resetDefaults[prefix .. "_brightness"] = info.brightness
            resetDefaults[prefix .. "_decay"] = info.decay
            resetDefaults[prefix .. "_models_elight"] = info.elight
            resetDefaults[prefix .. "_models_elight_size_mult"] = info.elightMult
            resetDefaults[prefix .. "_color_r"] = info.r
            resetDefaults[prefix .. "_color_g"] = info.g
            resetDefaults[prefix .. "_color_b"] = info.b
        end

        addResetButton(panel, resetDefaults)
    end

    local function addAmmoPickupPanel(panel)
        setupPage(panel, "page.ammo_pickups.title", "page.ammo_pickups.desc")

        local resetDefaults = {}
        local defs = BetterLights.GetAmmoPickupLightDefinitions()
        local enableCvars = {}

        for _, info in ipairs(defs) do
            enableCvars[#enableCvars + 1] = "betterlights_ammo_" .. info.slug .. "_enable"
        end

        addBulkToggleSection(panel, enableCvars, "section.ammo_quick_controls", "section.ammo_quick_controls.desc")

        for _, info in ipairs(defs) do
            local prefix = "betterlights_ammo_" .. info.slug
            local form = info.nameKey and addSection(panel, info.nameKey, nil, false)
                or addRawSection(panel, info.name, nil, false)
            addLightControls(form, prefix, {
                radiusMax = 300,
                brightnessMax = 2,
                modelElight = true,
                modelElightLabel = "control.add_model_elight"
            })
            addColorMixerControl(form, "control.color", prefix .. "_color_r", prefix .. "_color_g", prefix .. "_color_b", info.r, info.g, info.b)

            resetDefaults[prefix .. "_enable"] = info.enable
            resetDefaults[prefix .. "_size"] = info.size
            resetDefaults[prefix .. "_brightness"] = info.brightness
            resetDefaults[prefix .. "_decay"] = info.decay
            resetDefaults[prefix .. "_models_elight"] = info.elight
            resetDefaults[prefix .. "_models_elight_size_mult"] = info.elightMult
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
    registerPage("Pickups", "BL_WorldWeapons", "menu.world_weapons", function(panel)
            addWorldWeaponPanel(panel)
        end)

    registerPage("Pickups", "BL_AmmoPickups", "menu.ammo_pickups", function(panel)
            addAmmoPickupPanel(panel)
        end)

    registerPage("Pickups", "BL_Pickup_Battery", "menu.battery", function(panel)
            setupPage(panel, "page.battery.title", "page.battery.desc")
            panel:CheckBox(phrase("control.enable"), "betterlights_item_battery_enable")
            panel:NumSlider(phrase("control.radius"), "betterlights_item_battery_size", 0, 300, 0)
            panel:NumSlider(phrase("control.brightness"), "betterlights_item_battery_brightness", 0, 2, 2)
            panel:NumSlider(phrase("control.decay"), "betterlights_item_battery_decay", 0, 5000, 0)
            panel:CheckBox(phrase("control.add_model_elight"), "betterlights_item_battery_models_elight")
            panel:NumSlider(phrase("control.elight_radius"), "betterlights_item_battery_models_elight_size_mult", 0, 3, 2)
            addColorMixerControl(panel, "control.color", "betterlights_item_battery_color_r", "betterlights_item_battery_color_g", "betterlights_item_battery_color_b")
            addResetButton(panel, {
                betterlights_item_battery_enable = 1,
                betterlights_item_battery_size = 55,
                betterlights_item_battery_brightness = 0.2,
                betterlights_item_battery_decay = 1800,
                betterlights_item_battery_models_elight = 1,
                betterlights_item_battery_models_elight_size_mult = 1.0,
                betterlights_item_battery_color_r = 110,
                betterlights_item_battery_color_g = 190,
                betterlights_item_battery_color_b = 255,
            })
        end)

    registerPage("Pickups", "BL_Pickup_Vial", "menu.health_vial", function(panel)
            setupPage(panel, "page.health_vial.title", "page.health_vial.desc")
            panel:CheckBox(phrase("control.enable"), "betterlights_item_healthvial_enable")
            panel:NumSlider(phrase("control.radius"), "betterlights_item_healthvial_size", 0, 300, 0)
            panel:NumSlider(phrase("control.brightness"), "betterlights_item_healthvial_brightness", 0, 2, 2)
            panel:NumSlider(phrase("control.decay"), "betterlights_item_healthvial_decay", 0, 5000, 0)
            panel:CheckBox(phrase("control.add_model_elight"), "betterlights_item_healthvial_models_elight")
            panel:NumSlider(phrase("control.elight_radius"), "betterlights_item_healthvial_models_elight_size_mult", 0, 3, 2)
            addColorMixerControl(panel, "control.color", "betterlights_item_healthvial_color_r", "betterlights_item_healthvial_color_g", "betterlights_item_healthvial_color_b")
            addResetButton(panel, {
                betterlights_item_healthvial_enable = 1,
                betterlights_item_healthvial_size = 45,
                betterlights_item_healthvial_brightness = 0.18,
                betterlights_item_healthvial_decay = 1800,
                betterlights_item_healthvial_models_elight = 1,
                betterlights_item_healthvial_models_elight_size_mult = 1.0,
                betterlights_item_healthvial_color_r = 150,
                betterlights_item_healthvial_color_g = 255,
                betterlights_item_healthvial_color_b = 150,
            })
        end)

    registerPage("Pickups", "BL_Pickup_HealthKit", "menu.health_kit", function(panel)
            setupPage(panel, "page.health_kit.title", "page.health_kit.desc")
            panel:CheckBox(phrase("control.enable"), "betterlights_item_healthkit_enable")
            panel:NumSlider(phrase("control.radius"), "betterlights_item_healthkit_size", 0, 300, 0)
            panel:NumSlider(phrase("control.brightness"), "betterlights_item_healthkit_brightness", 0, 2, 2)
            panel:NumSlider(phrase("control.decay"), "betterlights_item_healthkit_decay", 0, 5000, 0)
            panel:CheckBox(phrase("control.add_model_elight"), "betterlights_item_healthkit_models_elight")
            panel:NumSlider(phrase("control.elight_radius"), "betterlights_item_healthkit_models_elight_size_mult", 0, 3, 2)
            addColorMixerControl(panel, "control.color", "betterlights_item_healthkit_color_r", "betterlights_item_healthkit_color_g", "betterlights_item_healthkit_color_b")
            addResetButton(panel, {
                betterlights_item_healthkit_enable = 1,
                betterlights_item_healthkit_size = 55,
                betterlights_item_healthkit_brightness = 0.2,
                betterlights_item_healthkit_decay = 1800,
                betterlights_item_healthkit_models_elight = 1,
                betterlights_item_healthkit_models_elight_size_mult = 1.0,
                betterlights_item_healthkit_color_r = 150,
                betterlights_item_healthkit_color_g = 255,
                betterlights_item_healthkit_color_b = 150,
            })
        end)

    MENU.RegisterPages("BetterLights_Menu_Pickups", pages)
end
