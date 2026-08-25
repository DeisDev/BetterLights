if CLIENT then

    local MENU = BetterLights.Menu
    MENU.IntegrationPages = nil
    MENU.RegisterIntegrationPanels = nil

    function MENU.RegisterIntegrationPage(id, titleKey, buildPanel, priority)
        return MENU.RegisterPage({
            category = "Integrations",
            id = id,
            titleKey = titleKey,
            buildPanel = buildPanel,
            order = -(tonumber(priority) or 0)
        })
    end

    local function addFlashlightOverridePage(panel, pageTitleKey, pageDescKey, cvarName, labelKey)
        local phrase = MENU.Phrase

        MENU.SetupPage(panel, pageTitleKey, pageDescKey)

        local flashlight = MENU.AddSection(panel, "section.integration_flashlight_override", "section.integration_flashlight_override.desc", true)
        flashlight:CheckBox(phrase(labelKey), cvarName)
        MENU.AddHelpText(flashlight, phrase("help.integration_flashlight_override"))

        MENU.AddResetButton(panel, {
            [cvarName] = 0,
        })
    end

    MENU.RegisterPages("BetterLights_Menu_Integrations", {
        {
            category = "Integrations",
            id = "BL_Integration_MWBase",
            titleKey = "menu.integration_mwbase",
            order = -300,
            buildPanel = function(panel)
                addFlashlightOverridePage(
                    panel,
                    "page.integration_mwbase.title",
                    "page.integration_mwbase.desc",
                    "betterlights_integration_mwbase_disable_flashlight_override",
                    "control.use_mwbase_flashlight"
                )
            end
        },
        {
            category = "Integrations",
            id = "BL_Integration_ArcCW",
            titleKey = "menu.integration_arccw",
            order = -200,
            buildPanel = function(panel)
                addFlashlightOverridePage(
                    panel,
                    "page.integration_arccw.title",
                    "page.integration_arccw.desc",
                    "betterlights_integration_arccw_disable_flashlight_override",
                    "control.use_arccw_flashlight"
                )
            end
        },
        {
            category = "Integrations",
            id = "BL_Integration_ARC9",
            titleKey = "menu.integration_arc9",
            order = -100,
            buildPanel = function(panel)
                addFlashlightOverridePage(
                    panel,
                    "page.integration_arc9.title",
                    "page.integration_arc9.desc",
                    "betterlights_integration_arc9_disable_flashlight_override",
                    "control.use_arc9_flashlight"
                )
            end
        },
        {
            category = "Integrations",
            id = "BL_Integration_TFA",
            titleKey = "menu.integration_tfa",
            order = -50,
            buildPanel = function(panel)
                addFlashlightOverridePage(
                    panel,
                    "page.integration_tfa.title",
                    "page.integration_tfa.desc",
                    "betterlights_integration_tfa_disable_flashlight_override",
                    "control.use_tfa_flashlight"
                )
            end
        }
    })
end
