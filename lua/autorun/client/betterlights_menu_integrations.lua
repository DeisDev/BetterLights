if CLIENT then

    local MENU = BetterLights.Menu

    MENU.IntegrationPages = MENU.IntegrationPages or {}

    local function registerIntegrationPage(id, titleKey, buildPanel, priority)
        if not (isstring(id) and id ~= "" and isstring(titleKey) and isfunction(buildPanel)) then return end

        MENU.IntegrationPages[id] = {
            id = id,
            titleKey = titleKey,
            buildPanel = buildPanel,
            priority = tonumber(priority) or 0
        }
    end

    function MENU.RegisterIntegrationPage(id, titleKey, buildPanel, priority)
        registerIntegrationPage(id, titleKey, buildPanel, priority)
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

    registerIntegrationPage("BL_Integration_MWBase", "menu.integration_mwbase", function(panel)
        addFlashlightOverridePage(
            panel,
            "page.integration_mwbase.title",
            "page.integration_mwbase.desc",
            "betterlights_integration_mwbase_disable_flashlight_override",
            "control.use_mwbase_flashlight"
        )
    end, 300)

    registerIntegrationPage("BL_Integration_ArcCW", "menu.integration_arccw", function(panel)
        addFlashlightOverridePage(
            panel,
            "page.integration_arccw.title",
            "page.integration_arccw.desc",
            "betterlights_integration_arccw_disable_flashlight_override",
            "control.use_arccw_flashlight"
        )
    end, 200)

    registerIntegrationPage("BL_Integration_ARC9", "menu.integration_arc9", function(panel)
        addFlashlightOverridePage(
            panel,
            "page.integration_arc9.title",
            "page.integration_arc9.desc",
            "betterlights_integration_arc9_disable_flashlight_override",
            "control.use_arc9_flashlight"
        )
    end, 100)

    registerIntegrationPage("BL_Integration_TFA", "menu.integration_tfa", function(panel)
        addFlashlightOverridePage(
            panel,
            "page.integration_tfa.title",
            "page.integration_tfa.desc",
            "betterlights_integration_tfa_disable_flashlight_override",
            "control.use_tfa_flashlight"
        )
    end, 50)

    function MENU.RegisterIntegrationPanels()
        local pages = {}

        for _, page in pairs(MENU.IntegrationPages) do
            pages[#pages + 1] = page
        end

        table.sort(pages, function(a, b)
            if a.priority ~= b.priority then return a.priority > b.priority end

            return a.id < b.id
        end)

        for i = 1, #pages do
            local page = pages[i]
            MENU.RegisterPage("Integrations", page.id, page.titleKey, page.buildPanel)
        end
    end
end
