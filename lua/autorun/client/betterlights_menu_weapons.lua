if CLIENT then

    local MENU = BetterLights.Menu

    function MENU.RegisterWeaponPanels()
        local phrase = MENU.Phrase
        local setupPage = MENU.SetupPage
        local addColorMixerControl = MENU.AddColorMixerControl
        local addResetButton = MENU.AddResetButton
        local registerPage = MENU.RegisterPage

        registerPage("Weapons", "BL_CrossbowHeld", "menu.crossbow_held", function(panel)
            setupPage(panel, "page.crossbow_held.title", "page.crossbow_held.desc")
            panel:CheckBox(phrase("control.enable"), "betterlights_crossbow_hold_enable")
            panel:NumSlider(phrase("control.radius"), "betterlights_crossbow_hold_size", 0, 300, 0)
            panel:NumSlider(phrase("control.brightness"), "betterlights_crossbow_hold_brightness", 0, 5, 2)
            panel:NumSlider(phrase("control.decay"), "betterlights_crossbow_hold_decay", 0, 5000, 0)
            addColorMixerControl(panel, "control.color", "betterlights_crossbow_hold_color_r", "betterlights_crossbow_hold_color_g", "betterlights_crossbow_hold_color_b")
            addResetButton(panel, {
                betterlights_crossbow_hold_enable = 1,
                betterlights_crossbow_hold_size = 30,
                betterlights_crossbow_hold_brightness = 0.32,
                betterlights_crossbow_hold_decay = 2000,
                betterlights_crossbow_hold_color_r = 255,
                betterlights_crossbow_hold_color_g = 140,
                betterlights_crossbow_hold_color_b = 40,
            })
        end)

        registerPage("Weapons", "BL_Physgun", "menu.physgun", function(panel)
            setupPage(panel, "page.physgun.title", "page.physgun.desc")
            panel:CheckBox(phrase("control.enable"), "betterlights_physgun_enable")
            panel:NumSlider(phrase("control.radius"), "betterlights_physgun_size", 0, 300, 0)
            panel:NumSlider(phrase("control.brightness"), "betterlights_physgun_brightness", 0, 5, 2)
            panel:NumSlider(phrase("control.decay"), "betterlights_physgun_decay", 0, 5000, 0)
            panel:CheckBox(phrase("control.add_model_elight"), "betterlights_physgun_models_elight")
            panel:NumSlider(phrase("control.model_elight_radius"), "betterlights_physgun_models_elight_size_mult", 0, 3, 2)
            panel:CheckBox(phrase("control.override_weapon_color"), "betterlights_physgun_color_override")
            addColorMixerControl(panel, "control.override_color", "betterlights_physgun_color_r", "betterlights_physgun_color_g", "betterlights_physgun_color_b")
            addResetButton(panel, {
                betterlights_physgun_enable = 1,
                betterlights_physgun_size = 33,
                betterlights_physgun_brightness = 0.3,
                betterlights_physgun_decay = 2000,
                betterlights_physgun_models_elight = 1,
                betterlights_physgun_models_elight_size_mult = 1.0,
                betterlights_physgun_color_override = 0,
                betterlights_physgun_color_r = 70,
                betterlights_physgun_color_g = 130,
                betterlights_physgun_color_b = 255,
            })
        end)

        registerPage("Weapons", "BL_GravityGun", "menu.gravitygun", function(panel)
            setupPage(panel, "page.gravitygun.title", "page.gravitygun.desc")
            panel:CheckBox(phrase("control.enable"), "betterlights_gravitygun_enable")
            panel:NumSlider(phrase("control.radius"), "betterlights_gravitygun_size", 0, 300, 0)
            panel:NumSlider(phrase("control.brightness"), "betterlights_gravitygun_brightness", 0, 5, 2)
            panel:NumSlider(phrase("control.decay"), "betterlights_gravitygun_decay", 0, 5000, 0)
            panel:CheckBox(phrase("control.add_model_elight"), "betterlights_gravitygun_models_elight")
            panel:NumSlider(phrase("control.model_elight_radius"), "betterlights_gravitygun_models_elight_size_mult", 0, 3, 2)
            addColorMixerControl(panel, "control.color", "betterlights_gravitygun_color_r", "betterlights_gravitygun_color_g", "betterlights_gravitygun_color_b")
            addColorMixerControl(panel, "control.supercharged_color", "betterlights_gravitygun_super_color_r", "betterlights_gravitygun_super_color_g", "betterlights_gravitygun_super_color_b")
            addResetButton(panel, {
                betterlights_gravitygun_enable = 1,
                betterlights_gravitygun_size = 36,
                betterlights_gravitygun_brightness = 0.35,
                betterlights_gravitygun_decay = 2000,
                betterlights_gravitygun_models_elight = 1,
                betterlights_gravitygun_models_elight_size_mult = 1.0,
                betterlights_gravitygun_color_r = 255,
                betterlights_gravitygun_color_g = 140,
                betterlights_gravitygun_color_b = 40,
                betterlights_gravitygun_super_color_r = 40,
                betterlights_gravitygun_super_color_g = 140,
                betterlights_gravitygun_super_color_b = 255,
            })
        end)

        registerPage("Weapons", "BL_RPG_Held", "menu.rpg_held", function(panel)
            setupPage(panel, "page.rpg_held.title", "page.rpg_held.desc")
            panel:CheckBox(phrase("control.enable"), "betterlights_rpg_hold_enable")
            panel:NumSlider(phrase("control.radius"), "betterlights_rpg_hold_size", 0, 300, 0)
            panel:NumSlider(phrase("control.brightness"), "betterlights_rpg_hold_brightness", 0, 5, 2)
            panel:NumSlider(phrase("control.decay"), "betterlights_rpg_hold_decay", 0, 5000, 0)
            addColorMixerControl(panel, "control.color", "betterlights_rpg_hold_color_r", "betterlights_rpg_hold_color_g", "betterlights_rpg_hold_color_b")
            addResetButton(panel, {
                betterlights_rpg_hold_enable = 1,
                betterlights_rpg_hold_size = 24,
                betterlights_rpg_hold_brightness = 0.22,
                betterlights_rpg_hold_decay = 2000,
                betterlights_rpg_hold_color_r = 255,
                betterlights_rpg_hold_color_g = 60,
                betterlights_rpg_hold_color_b = 60,
            })
        end)

        registerPage("Weapons", "BL_ToolGun", "menu.toolgun", function(panel)
            setupPage(panel, "page.toolgun.title", "page.toolgun.desc")
            panel:CheckBox(phrase("control.enable"), "betterlights_toolgun_enable")
            panel:NumSlider(phrase("control.radius"), "betterlights_toolgun_size", 0, 300, 0)
            panel:NumSlider(phrase("control.brightness"), "betterlights_toolgun_brightness", 0, 5, 2)
            panel:NumSlider(phrase("control.decay"), "betterlights_toolgun_decay", 0, 5000, 0)
            panel:CheckBox(phrase("control.add_model_elight"), "betterlights_toolgun_models_elight")
            panel:NumSlider(phrase("control.model_elight_radius"), "betterlights_toolgun_models_elight_size_mult", 0, 3, 2)
            addColorMixerControl(panel, "control.color", "betterlights_toolgun_color_r", "betterlights_toolgun_color_g", "betterlights_toolgun_color_b")
            addResetButton(panel, {
                betterlights_toolgun_enable = 1,
                betterlights_toolgun_size = 28,
                betterlights_toolgun_brightness = 0.225,
                betterlights_toolgun_decay = 2000,
                betterlights_toolgun_models_elight = 1,
                betterlights_toolgun_models_elight_size_mult = 1.0,
                betterlights_toolgun_color_r = 255,
                betterlights_toolgun_color_g = 255,
                betterlights_toolgun_color_b = 255,
            })
        end)
    end
end
