if CLIENT then
    local MENU = BetterLights.Menu
    local phrase = MENU.Phrase
    local setupPage = MENU.SetupPage
    local addSection = MENU.AddSection
    local addStyledButton = MENU.AddStyledButton
    local addResetButton = MENU.AddResetButton
    local refreshSettingsPanel = MENU.RefreshSettingsPanel
    MENU.RegisterDeveloperPanel = nil

    local function buildDeveloperToolsPanel(panel)
        setupPage(panel, "page.developer_tools.title", "page.developer_tools.desc")

        local settingsPanel = addSection(panel, "section.settings_panel", "section.settings_panel.desc", false)
        local refreshSettings = addStyledButton(settingsPanel, phrase("button.refresh_settings_panel"))
        refreshSettings.DoClick = function()
            refreshSettingsPanel()
        end

        local changelog = addSection(panel, "section.changelog_testing", "section.changelog_testing.desc", false)
        local simulateUpdate = addStyledButton(changelog, phrase("button.simulate_changelog_update"))
        simulateUpdate.DoClick = function()
            MENU._SimulateUpdatedChangelog()
        end

        local diagnostics = addSection(panel, "section.developer_diagnostics", "section.developer_diagnostics.desc", true)
        diagnostics:CheckBox(phrase("control.debug_muzzle_flash"), "betterlights_muzzle_debug")
        diagnostics:CheckBox(phrase("control.debug_combine_mine_detection"), "betterlights_combine_mine_debug")
        diagnostics:CheckBox(phrase("control.debug_antlion_guardian_detection"), "betterlights_antlion_guardian_debug")

        local lightOrigins = addSection(panel, "section.dynamic_light_origins", "section.dynamic_light_origins.desc", true)
        lightOrigins:CheckBox(phrase("control.show_light_origins"), "betterlights_debug_light_origins_enable")
        lightOrigins:NumSlider(phrase("control.origin_marker_size"), "betterlights_debug_light_origins_radius", 1, 64, 0)
        lightOrigins:CheckBox(phrase("control.show_model_lights"), "betterlights_debug_light_origins_elights")
        lightOrigins:CheckBox(phrase("control.hide_light_origins_behind_walls"), "betterlights_debug_light_origins_depth")

        local flashlightMessages = addSection(panel, "section.flashlight_messages", "section.flashlight_messages.desc", false)
        local testTip = addStyledButton(flashlightMessages, phrase("button.test_flashlight_tip"))
        testTip.DoClick = function()
            BetterLights.ShowFlashlightOnboardingTip(true)
        end

        addResetButton(panel, {
            betterlights_debug_light_origins_enable = 0,
            betterlights_debug_light_origins_radius = 8,
            betterlights_debug_light_origins_elights = 1,
            betterlights_debug_light_origins_depth = 0,
            betterlights_muzzle_debug = 0,
            betterlights_combine_mine_debug = 0,
            betterlights_antlion_guardian_debug = 0,
        })
    end

    MENU.RegisterPages("BetterLights_Menu_Developer", {
        {
            category = "Developer",
            id = "BL_DeveloperTools",
            titleKey = "menu.developer_tools",
            buildPanel = buildDeveloperToolsPanel
        }
    })
end
