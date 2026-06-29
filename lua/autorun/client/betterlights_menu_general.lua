if CLIENT then

    local MENU = BetterLights.Menu

    function MENU.RegisterGeneralPanel()
        local phrase = MENU.Phrase
        local setupPage = MENU.SetupPage
        local addSection = MENU.AddSection
        local addStyledButton = MENU.AddStyledButton
        local addHelpText = MENU.AddHelpText
        local addServerBoolCheckbox = MENU.AddServerBoolCheckbox
        local addServerBoolResetButton = MENU.AddServerBoolResetButton
        local resetAllSettings = MENU.ResetAllSettings
        local registerPage = MENU.RegisterPage

        registerPage("General", "BL_Admin", "menu.admin", function(panel)
            setupPage(panel, "page.admin.title", "page.admin.desc")

            local server = addSection(panel, "section.server", "section.server.desc", true)
            addServerBoolCheckbox(server, phrase("control.enable_better_lights"), "betterlights_enable")
            addServerBoolResetButton(server, {
                betterlights_enable = 1,
            })

            local maintenance = addSection(panel, "section.maintenance", "section.maintenance.desc", true)
            local resetAllBtn = addStyledButton(maintenance, phrase("button.reset_all_settings"))
            resetAllBtn.DoClick = resetAllSettings
            addHelpText(maintenance, phrase("help.optional_bind"))
        end)
    end
end
