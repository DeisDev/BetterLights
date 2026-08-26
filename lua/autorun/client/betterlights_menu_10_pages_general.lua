if CLIENT then
    local MENU = BetterLights.Menu

    local activeClientPanels = setmetatable({}, { __mode = "k" })

    local function notify(key, kind, duration, ...)
        local text = select("#", ...) > 0 and MENU.PhraseFormat(key, ...) or MENU.Phrase(key)

        notification.AddLegacy(text, kind or NOTIFY_GENERIC, duration or 3)
        surface.PlaySound(kind == NOTIFY_ERROR and "buttons/button10.wav" or "buttons/button14.wav")
    end

    local function addClientPreferenceSection(panel)
        local phrase = MENU.Phrase
        local serverStateReady = BetterLights.HasServerSettingsState
            and BetterLights.HasServerSettingsState()
        local mode = BetterLights.GetServerMode and BetterLights.GetServerMode()
            or BetterLights.SERVER_MODE_PLAYER_CHOICE
        local preference = true
        if BetterLights.IsClientEnabledPreference then
            preference = BetterLights.IsClientEnabledPreference()
        end
        local canChange = false
        if serverStateReady then
            if BetterLights.CanChangeClientEnabledPreference then
                canChange = BetterLights.CanChangeClientEnabledPreference()
            else
                canChange = mode == BetterLights.SERVER_MODE_PLAYER_CHOICE
            end
        end

        local client = MENU.AddSection(panel, "section.client", "section.client.desc", true)
        local enabled = vgui.Create("DCheckBoxLabel")
        local enabledLabel = phrase("control.enable_better_lights_client")
        if not canChange then
            enabledLabel = MENU.PhraseFormat(
                serverStateReady and "state.server_controlled_label" or "state.locked_label",
                enabledLabel
            )
        end

        enabled:SetText(enabledLabel)
        enabled:SetValue(preference and 1 or 0)
        enabled:SizeToContents()
        MENU.SetControlLocked(enabled, not canChange)
        client:AddItem(enabled)

        enabled.OnChange = function(_, value)
            if BetterLights.SetClientEnabledPreference then
                BetterLights.SetClientEnabledPreference(value)
            else
                BetterLights.ApplyClientSetting("betterlights_client_enable", value and 1 or 0)
            end
        end

        if not serverStateReady then
            MENU.AddStateNotice(client, phrase("help.server_settings_loading"), true)
        elseif mode == BetterLights.SERVER_MODE_ENABLED then
            MENU.AddStateNotice(client, phrase("help.client_policy_enabled"), true)
        elseif mode == BetterLights.SERVER_MODE_DISABLED then
            MENU.AddStateNotice(client, phrase("help.client_policy_disabled"), true)
        else
            MENU.AddHelpText(client, phrase("help.client_policy_player_choice"))
        end

        if serverStateReady then
            local effectiveKey = BetterLights.IsEnabled and BetterLights.IsEnabled()
                and "help.client_effective_enabled"
                or "help.client_effective_disabled"
            MENU.AddHelpText(client, phrase(effectiveKey))
        end

        return client
    end

    MENU.AddClientPreferenceSection = addClientPreferenceSection

    function MENU.TrackClientSettingsPanel(panel, buildPanel)
        if not (IsValid(panel) and isfunction(buildPanel)) then return end
        activeClientPanels[panel] = buildPanel
    end

    local function buildClientPage(panel)
        MENU.TrackClientSettingsPanel(panel, buildClientPage)
        MENU.SetupPage(panel, "page.client.title", "page.client.desc")
        addClientPreferenceSection(panel)

        local phrase = MENU.Phrase

        local updates = MENU.AddSection(panel, "section.changelog_updates", "section.changelog_updates.desc", true)
        updates:CheckBox(phrase("control.auto_open_changelog"), "betterlights_changelog_auto_open")
        MENU.AddHelpText(updates, phrase("help.auto_open_changelog"))

        local maintenance = MENU.AddSection(panel, "section.personal_maintenance", "section.personal_maintenance.desc", false)
        local reset = MENU.AddStyledButton(maintenance, phrase("button.reset_personal_settings"))
        reset.DoClick = function()
            Derma_Query(
                phrase("dialog.reset_personal_settings.message"),
                phrase("dialog.reset_personal_settings.title"),
                phrase("button.reset_personal_settings"),
                function()
                    local flashlightCleared = BetterLights.Flashlight.ClearWeaponAttachmentBlacklist()
                    if not flashlightCleared then
                        notify("notice.flashlight_attachment_blacklist_save_failed", NOTIFY_ERROR, 4)
                        return
                    end

                    local cleared = BetterLights.MuzzleFlash.ClearWeaponBlacklist()
                    if not cleared then
                        notify("notice.muzzle_blacklist_save_failed", NOTIFY_ERROR, 4)
                        return
                    end

                    BetterLights.ResetRegisteredClientSettings()
                    BetterLights.ClearFlashlightRecentTextures()
                    BetterLights.ClearFlashlightKnownTextureCache()
                    notify("notice.personal_settings_reset", NOTIFY_GENERIC, 4)
                end,
                phrase("button.cancel")
            )
        end

        MENU.AddHelpText(maintenance, phrase("help.personal_reset_scope"))
    end

    local function buildPerformancePage(panel)
        local phrase = MENU.Phrase

        MENU.SetupPage(panel, "page.performance.title", "page.performance.desc")

        local limits = MENU.AddSection(panel, "section.light_budget", "section.light_budget.desc", true)
        limits:CheckBox(phrase("control.enable_light_budget"), "betterlights_light_budget_enable")
        limits:NumSlider(phrase("control.dlight_limit"), "betterlights_light_budget_dlight_limit", 0, 32, 0)
        limits:NumSlider(phrase("control.elight_limit"), "betterlights_light_budget_elight_limit", 0, 64, 0)
        limits:NumSlider(phrase("control.projected_light_limit"), "betterlights_light_budget_projected_limit", 0, 32, 0)
        MENU.AddHelpText(limits, phrase("help.light_budget_headroom"))

        local distance = MENU.AddSection(panel, "section.light_culling", "section.light_culling.desc", true)
        MENU.BeginControlGroup(distance, "betterlights_light_budget_enable")
        distance:NumSlider(phrase("control.maximum_light_distance"), "betterlights_light_budget_max_distance", 0, 20000, 0)
        distance:NumSlider(phrase("control.light_fade_distance"), "betterlights_light_budget_fade_distance", 0, 5000, 0)
        distance:CheckBox(phrase("control.deprioritize_offscreen_lights"), "betterlights_light_budget_offscreen_deprioritize")
        MENU.AddHelpText(distance, phrase("help.light_distance_disabled"))
        MENU.AddHelpText(distance, phrase("help.offscreen_light_ranking"))

        MENU.AddResetButton(panel, {
            betterlights_light_budget_enable = 1,
            betterlights_light_budget_dlight_limit = 28,
            betterlights_light_budget_elight_limit = 56,
            betterlights_light_budget_projected_limit = 6,
            betterlights_light_budget_max_distance = 0,
            betterlights_light_budget_fade_distance = 512,
            betterlights_light_budget_offscreen_deprioritize = 1,
        })
    end

    local function refreshClientSettingsPanels()
        timer.Simple(0, function()
            for panel, buildPanel in pairs(activeClientPanels) do
                if IsValid(panel) then
                    buildPanel(panel)
                end
            end
        end)
    end

    hook.Add("BetterLights_ClientEnabledPreferenceChanged", "BetterLights_RefreshClientSettingsPage", refreshClientSettingsPanels)
    hook.Add("BetterLights_ServerSettingsChanged", "BetterLights_RefreshClientSettingsPolicy", refreshClientSettingsPanels)


    MENU.RegisterGeneralPanel = nil
    MENU.RegisterPages("BetterLights_Menu_General", {
        {
            category = "General",
            id = "BL_Client",
            titleKey = "menu.client",
            buildPanel = buildClientPage,
            default = true
        },
        {
            category = "General",
            id = "BL_Performance",
            titleKey = "menu.performance",
            buildPanel = buildPerformancePage
        },
    })
end
