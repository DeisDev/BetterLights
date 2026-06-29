if CLIENT then

    local MENU = BetterLights.Menu

    function MENU.RegisterDeveloperPanel()
        local phrase = MENU.Phrase
        local setupPage = MENU.SetupPage
        local addSection = MENU.AddSection
        local addStyledButton = MENU.AddStyledButton
        local registerPage = MENU.RegisterPage
        local isDeveloperMode = MENU.IsDeveloperMode

        if not isDeveloperMode() then return end

        registerPage("Developer", "BL_DeveloperTools", "menu.developer_tools", function(panel)
            setupPage(panel, "page.developer_tools.title", "page.developer_tools.desc")

            local flashlightMessages = addSection(panel, "section.flashlight_messages", "section.flashlight_messages.desc", false)
            local testTip = addStyledButton(flashlightMessages, phrase("button.test_flashlight_tip"))
            testTip.DoClick = function()
                BetterLights.ShowFlashlightOnboardingTip(true)
            end
        end)
    end
end
