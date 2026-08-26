if CLIENT then

    local MENU = BetterLights.Menu

    local setupPage = MENU.SetupPage
    local addSection = MENU.AddSection
    local addLightControls = MENU.AddLightControls
    local addColorMixerControl = MENU.AddColorMixerControl
    local addResetButton = MENU.AddResetButton
    MENU.RegisterGunfirePanels = nil

    MENU.RegisterPages("BetterLights_Menu_Gunfire", {
        {
            category = "Gunfire",
            id = "BL_BulletImpacts",
            titleKey = "menu.bullet_impacts",
            buildPanel = function(panel)
            setupPage(panel, "page.bullet_impacts.title", "page.bullet_impacts.desc")
            local generic = addSection(panel, "section.generic_impacts", "section.generic_impacts.desc", true)
            addLightControls(generic, "betterlights_bullet_impact", {
                radiusMax = 300,
                brightnessMax = 2,
                decayLabel = false
            })
            addColorMixerControl(generic, "control.color", "betterlights_bullet_impact_color_r", "betterlights_bullet_impact_color_g", "betterlights_bullet_impact_color_b")

            local ar2 = addSection(panel, "section.ar2_impacts", "section.ar2_impacts.desc", true)
            addLightControls(ar2, "betterlights_bullet_impact_ar2", {
                enableLabel = "control.enable_ar2_tint",
                radiusLabel = "control.radius",
                radiusMax = 300,
                brightnessLabel = "control.brightness",
                brightnessMax = 2,
                decayLabel = false
            })
            addColorMixerControl(ar2, "control.color", "betterlights_bullet_impact_ar2_color_r", "betterlights_bullet_impact_ar2_color_g", "betterlights_bullet_impact_ar2_color_b")

            addResetButton(panel, {
                betterlights_bullet_impact_enable = 1,
                betterlights_bullet_impact_size = 60,
                betterlights_bullet_impact_brightness = 0.25,
                betterlights_bullet_impact_ar2_enable = 1,
                betterlights_bullet_impact_ar2_size = 70,
                betterlights_bullet_impact_ar2_brightness = 0.3,
                betterlights_bullet_impact_color_r = 255,
                betterlights_bullet_impact_color_g = 160,
                betterlights_bullet_impact_color_b = 60,
                betterlights_bullet_impact_ar2_color_r = 110,
                betterlights_bullet_impact_ar2_color_g = 190,
                betterlights_bullet_impact_ar2_color_b = 255,
            })
            end
        },

        {
            category = "Gunfire",
            id = "BL_MuzzleFlash",
            titleKey = "menu.muzzle_flash",
            buildPanel = function(panel)
            setupPage(panel, "page.muzzle_flash.title", "page.muzzle_flash.desc")
            local generic = addSection(panel, "section.generic_muzzle_flash", nil, true)
            generic:CheckBox(MENU.Phrase("control.enable"), "betterlights_muzzle_enable")
            generic:CheckBox(MENU.Phrase("control.show_other_muzzle_flashes"), "betterlights_muzzle_show_others")
            generic:NumSlider(MENU.Phrase("control.duration"), "betterlights_muzzle_time", 0, 1, 2)
            addLightControls(generic, "betterlights_muzzle", {
                enableLabel = false,
                radiusMax = 300,
                brightnessMax = 2,
                decayLabel = false
            })
            addColorMixerControl(generic, "control.color", "betterlights_muzzle_color_r", "betterlights_muzzle_color_g", "betterlights_muzzle_color_b")

            local ar2 = addSection(panel, "section.ar2_muzzle_flash", "section.ar2_muzzle_flash.desc", true)
            ar2:CheckBox(MENU.Phrase("control.enable_ar2_tint"), "betterlights_muzzle_ar2_enable")
            addLightControls(ar2, "betterlights_muzzle_ar2", {
                enableLabel = false,
                radiusMax = 300,
                brightnessMax = 2,
                decayLabel = false
            })
            addColorMixerControl(ar2, "control.color", "betterlights_muzzle_ar2_color_r", "betterlights_muzzle_ar2_color_g", "betterlights_muzzle_ar2_color_b")

            local blacklist = addSection(panel, "section.muzzle_blacklist", "section.muzzle_blacklist.desc", false)
            BetterLights.MuzzleFlash.BuildWeaponBlacklistEditor(blacklist)

            addResetButton(panel, {
                betterlights_muzzle_enable = 1,
                betterlights_muzzle_size = 250,
                betterlights_muzzle_brightness = 2.0,
                betterlights_muzzle_time = 0.08,
                betterlights_muzzle_show_others = 1,
                betterlights_muzzle_debug = 0,
                betterlights_muzzle_ar2_enable = 1,
                betterlights_muzzle_ar2_size = 250,
                betterlights_muzzle_ar2_brightness = 2.0,
                betterlights_muzzle_color_r = 255,
                betterlights_muzzle_color_g = 170,
                betterlights_muzzle_color_b = 90,
                betterlights_muzzle_ar2_color_r = 110,
                betterlights_muzzle_ar2_color_g = 190,
                betterlights_muzzle_ar2_color_b = 255,
            })
            end
        },
        {
            category = "Gunfire",
            id = "BL_StunStick",
            titleKey = "menu.stunstick",
            buildPanel = function(panel)
            setupPage(panel, "page.stunstick.title", "page.stunstick.desc")
            panel:CheckBox(MENU.Phrase("control.enable"), "betterlights_stunstick_impact_enable")
            panel:NumSlider(MENU.Phrase("control.radius"), "betterlights_stunstick_impact_size", 0, 400, 0)
            panel:NumSlider(MENU.Phrase("control.brightness"), "betterlights_stunstick_impact_brightness", 0, 5, 2)
            panel:NumSlider(MENU.Phrase("control.duration"), "betterlights_stunstick_impact_time", 0, 1, 2)
            addColorMixerControl(panel, "control.color", "betterlights_stunstick_impact_color_r", "betterlights_stunstick_impact_color_g", "betterlights_stunstick_impact_color_b")
            addResetButton(panel, {
                betterlights_stunstick_impact_enable = 1,
                betterlights_stunstick_impact_size = 120,
                betterlights_stunstick_impact_brightness = 1.6,
                betterlights_stunstick_impact_time = 0.14,
                betterlights_stunstick_impact_color_r = 120,
                betterlights_stunstick_impact_color_g = 190,
                betterlights_stunstick_impact_color_b = 255,
            })
            end
        }
    })
end
