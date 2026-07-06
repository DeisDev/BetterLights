if CLIENT then

    local MENU = BetterLights.Menu

    function MENU.RegisterDeveloperPanel()
        local phrase = MENU.Phrase
        local setupPage = MENU.SetupPage
        local addSection = MENU.AddSection
        local addStyledButton = MENU.AddStyledButton
        local registerPage = MENU.RegisterPage
        local refreshSettingsPanel = MENU.RefreshSettingsPanel
        local isDeveloperMode = MENU.IsDeveloperMode

        if not isDeveloperMode() then return end

        local function buildDeveloperToolsPanel(panel)
            setupPage(panel, "page.developer_tools.title", "page.developer_tools.desc")

            local settingsPanel = addSection(panel, "section.settings_panel", "section.settings_panel.desc", false)
            local refreshSettings = addStyledButton(settingsPanel, phrase("button.refresh_settings_panel"))
            refreshSettings.DoClick = function()
                refreshSettingsPanel()
            end

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
        end

        registerPage("Developer", "BL_DeveloperTools", "menu.developer_tools", buildDeveloperToolsPanel)
    end
end
