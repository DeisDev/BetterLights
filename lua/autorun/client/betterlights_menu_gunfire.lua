if CLIENT then

    local MENU = BetterLights.Menu

    function MENU.RegisterGunfirePanels()
        local setupPage = MENU.SetupPage
        local addSection = MENU.AddSection
        local addLightControls = MENU.AddLightControls
        local addColorMixerControl = MENU.AddColorMixerControl
        local addResetButton = MENU.AddResetButton
        local registerPage = MENU.RegisterPage

        registerPage("Gunfire", "BL_BulletImpacts", "menu.bullet_impacts", function(panel)
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
        end)

        registerPage("Gunfire", "BL_MuzzleFlash", "menu.muzzle_flash", function(panel)
            setupPage(panel, "page.muzzle_flash.title", "page.muzzle_flash.desc")
            local generic = addSection(panel, "section.generic_muzzle_flash", nil, true)
            addLightControls(generic, "betterlights_muzzle", {
                radiusMax = 300,
                brightnessMax = 2,
                decayLabel = false
            })
            addColorMixerControl(generic, "control.color", "betterlights_muzzle_color_r", "betterlights_muzzle_color_g", "betterlights_muzzle_color_b")

            local ar2 = addSection(panel, "section.ar2_muzzle_flash", "section.ar2_muzzle_flash.desc", true)
            addLightControls(ar2, "betterlights_muzzle_ar2", {
                enableLabel = "control.enable_ar2_tint",
                radiusMax = 300,
                brightnessMax = 2,
                decayLabel = false
            })
            addColorMixerControl(ar2, "control.color", "betterlights_muzzle_ar2_color_r", "betterlights_muzzle_ar2_color_g", "betterlights_muzzle_ar2_color_b")
            addResetButton(panel, {
                betterlights_muzzle_enable = 1,
                betterlights_muzzle_size = 250,
                betterlights_muzzle_brightness = 2.0,
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
        end)
    end
end
