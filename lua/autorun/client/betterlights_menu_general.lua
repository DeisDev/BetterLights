if CLIENT then

    local MENU = BetterLights.Menu
    local activeClientPanel

    local function notify(key, kind, duration, ...)
        local text = select("#", ...) > 0 and MENU.PhraseFormat(key, ...) or MENU.Phrase(key)

        notification.AddLegacy(text, kind or NOTIFY_GENERIC, duration or 3)
        surface.PlaySound(kind == NOTIFY_ERROR and "buttons/button10.wav" or "buttons/button14.wav")
    end

    local function formatProfileTime(timestamp)
        timestamp = tonumber(timestamp) or 0
        if timestamp <= 0 then return "" end

        return os.date("%Y-%m-%d %H:%M", timestamp)
    end

    local function getProfileVersion(profile)
        local version = string.Trim(tostring(profile.addonVersion or ""))
        if version == "" then return MENU.Phrase("label.unknown") end

        return version
    end

    local function getSelectedProfile(list)
        local selected = list:GetSelectedLine()
        if not selected then
            notify("notice.profile_select_first", NOTIFY_ERROR, 3)
            return nil
        end

        local row = list:GetLine(selected)
        if not row then
            notify("notice.profile_select_first", NOTIFY_ERROR, 3)
            return nil
        end

        local profile = BetterLights.Profiles.GetById(row.BetterLightsProfileId)
        if not profile then
            notify("notice.profile_missing", NOTIFY_ERROR, 3)
            return nil
        end

        return profile
    end

    local function refreshProfileList(list)
        list:Clear()

        local profiles = BetterLights.Profiles.GetSorted()
        for i = 1, #profiles do
            local profile = profiles[i]
            local row = list:AddLine(profile.name, getProfileVersion(profile), formatProfileTime(profile.updatedAt))
            row.BetterLightsProfileId = profile.id
        end
    end

    local function requestProfileName(titleKey, messageKey, defaultValue, onConfirm)
        Derma_StringRequest(
            MENU.Phrase(titleKey),
            MENU.Phrase(messageKey),
            defaultValue or "",
            function(text)
                local name, errorKey = BetterLights.Profiles.NormalizeName(text)
                if not name then
                    notify(errorKey, NOTIFY_ERROR, 4)
                    return
                end

                onConfirm(name)
            end
        )
    end

    local function notifyProfileLoadResult(result)
        if result.skippedUnknown and result.skippedUnknown > 0 then
            notify("notice.profile_loaded_with_skips", NOTIFY_GENERIC, 4, result.skippedUnknown)
        else
            notify("notice.profile_loaded", NOTIFY_GENERIC, 3)
        end

        if result.flashlightTextureUnavailable then
            notify("notice.profile_flashlight_texture_unavailable", NOTIFY_ERROR, 5)
        end
    end

    local function loadProfile(profile)
        local result, errorKey = BetterLights.Profiles.Apply(profile)
        if not result then
            notify(errorKey, NOTIFY_ERROR, 4)
            return
        end

        notifyProfileLoadResult(result)
    end

    local function copyProfileText(text, successKey)
        if SetClipboardText then
            SetClipboardText(text)
            notify(successKey, NOTIFY_GENERIC, 3)
            return
        end

        notify("notice.profile_clipboard_unavailable", NOTIFY_ERROR, 4)
    end

    local function openProfileTextWindow(title, shareCode, rawJson)
        copyProfileText(shareCode, "notice.profile_export_code_copied")

        local frame = vgui.Create("DFrame")
        frame:SetTitle(title)
        frame:SetSize(math.min(ScrW() - 80, 720), math.min(ScrH() - 80, 360))
        frame:Center()
        frame:MakePopup()

        local entry = vgui.Create("DTextEntry", frame)
        entry:Dock(FILL)
        entry:DockMargin(10, 10, 10, 8)
        entry:SetMultiline(true)
        entry:SetText(shareCode)

        local footer = vgui.Create("DPanel", frame)
        footer:Dock(BOTTOM)
        footer:DockMargin(10, 0, 10, 10)
        footer:SetTall(30)
        footer.Paint = nil

        local close = MENU.StyleButton(vgui.Create("DButton", footer))
        close:Dock(RIGHT)
        close:SetWide(90)
        close:SetText(MENU.Phrase("button.close"))
        close.DoClick = function()
            frame:Close()
        end

        local copy = MENU.StyleButton(vgui.Create("DButton", footer))
        copy:Dock(RIGHT)
        copy:DockMargin(0, 0, 8, 0)
        copy:SetWide(110)
        copy:SetText(MENU.Phrase("button.copy_profile_code"))

        local showingRawJson = false
        copy.DoClick = function()
            if showingRawJson then
                copyProfileText(rawJson, "notice.profile_export_copied")
                return
            end

            copyProfileText(shareCode, "notice.profile_export_code_copied")
        end

        local toggleFormat = MENU.StyleButton(vgui.Create("DButton", footer))
        toggleFormat:Dock(RIGHT)
        toggleFormat:DockMargin(0, 0, 8, 0)
        toggleFormat:SetWide(110)
        toggleFormat:SetText(MENU.Phrase("button.show_profile_json"))
        toggleFormat.DoClick = function()
            showingRawJson = not showingRawJson

            if showingRawJson then
                entry:SetText(rawJson)
                copy:SetText(MENU.Phrase("button.copy_profile_json"))
                toggleFormat:SetText(MENU.Phrase("button.show_profile_code"))
                return
            end

            entry:SetText(shareCode)
            copy:SetText(MENU.Phrase("button.copy_profile_code"))
            toggleFormat:SetText(MENU.Phrase("button.show_profile_json"))
        end
    end

    local function exportProfile(profile)
        local shareCode, rawJsonOrError = BetterLights.Profiles.ExportProfileShareCode(profile)
        if not shareCode then
            notify(rawJsonOrError, NOTIFY_ERROR, 4)
            return
        end

        openProfileTextWindow(
            MENU.PhraseFormat("window.profile_export_title", profile.name),
            shareCode,
            rawJsonOrError
        )
    end

    local function exportCurrentSettings()
        requestProfileName("dialog.profile_export_current.title", "dialog.profile_export_current.message", "", function(name)
            local shareCode, rawJsonOrError = BetterLights.Profiles.ExportShareCode(
                name,
                BetterLights.Profiles.CaptureSettings(),
                BetterLights.VERSION
            )
            if not shareCode then
                notify(rawJsonOrError, NOTIFY_ERROR, 4)
                return
            end

            openProfileTextWindow(
                MENU.PhraseFormat("window.profile_export_title", name),
                shareCode,
                rawJsonOrError
            )
        end)
    end

    local function askLoadImportedProfile(profile)
        Derma_Query(
            MENU.PhraseFormat("dialog.profile_import_load.message", profile.name),
            MENU.Phrase("dialog.profile_import_load.title"),
            MENU.Phrase("button.load_profile"),
            function()
                loadProfile(profile)
            end,
            MENU.Phrase("button.cancel")
        )
    end

    local function saveImportedProfile(imported, existing, list, frame)
        local profile, errorKey

        if existing then
            profile, errorKey = BetterLights.Profiles.Overwrite(existing.id, imported.name, imported.settings, imported.addonVersion)
        else
            profile, errorKey = BetterLights.Profiles.Create(imported.name, imported.settings, imported.addonVersion)
        end

        if not profile then
            notify(errorKey, NOTIFY_ERROR, 4)
            return
        end

        refreshProfileList(list)
        notify("notice.profile_imported", NOTIFY_GENERIC, 3)

        if IsValid(frame) then
            frame:Close()
        end

        askLoadImportedProfile(profile)
    end

    local function openImportWindow(list)
        local frame = vgui.Create("DFrame")
        frame:SetTitle(MENU.Phrase("window.profile_import_title"))
        frame:SetSize(math.min(ScrW() - 80, 720), math.min(ScrH() - 80, 360))
        frame:Center()
        frame:MakePopup()

        local entry = vgui.Create("DTextEntry", frame)
        entry:Dock(FILL)
        entry:DockMargin(10, 10, 10, 8)
        entry:SetMultiline(true)
        entry:SetPlaceholderText(MENU.Phrase("placeholder.profile_json"))

        local footer = vgui.Create("DPanel", frame)
        footer:Dock(BOTTOM)
        footer:DockMargin(10, 0, 10, 10)
        footer:SetTall(30)
        footer.Paint = nil

        local cancel = MENU.StyleButton(vgui.Create("DButton", footer))
        cancel:Dock(RIGHT)
        cancel:SetWide(90)
        cancel:SetText(MENU.Phrase("button.cancel"))
        cancel.DoClick = function()
            frame:Close()
        end

        local import = MENU.StyleButton(vgui.Create("DButton", footer))
        import:Dock(RIGHT)
        import:DockMargin(0, 0, 8, 0)
        import:SetWide(110)
        import:SetText(MENU.Phrase("button.import_profile"))
        import.DoClick = function()
            local imported, errorKey = BetterLights.Profiles.DecodeExport(entry:GetText())
            if not imported then
                notify(errorKey, NOTIFY_ERROR, 4)
                return
            end

            local existing = BetterLights.Profiles.FindByName(imported.name)
            if existing then
                Derma_Query(
                    MENU.PhraseFormat("dialog.profile_import_duplicate.message", imported.name),
                    MENU.Phrase("dialog.profile_import_duplicate.title"),
                    MENU.Phrase("button.overwrite_profile"),
                    function()
                        saveImportedProfile(imported, existing, list, frame)
                    end,
                    MENU.Phrase("button.cancel")
                )
                return
            end

            saveImportedProfile(imported, nil, list, frame)
        end
    end

    local function saveCurrentSettings(list)
        requestProfileName("dialog.profile_save_name.title", "dialog.profile_save_name.message", "", function(name)
            local existing = BetterLights.Profiles.FindByName(name)
            if existing then
                Derma_Query(
                    MENU.PhraseFormat("dialog.profile_duplicate_save.message", name),
                    MENU.Phrase("dialog.profile_duplicate_save.title"),
                    MENU.Phrase("button.overwrite_profile"),
                    function()
                        local profile, errorKey = BetterLights.Profiles.Overwrite(existing.id, name)
                        if not profile then
                            notify(errorKey, NOTIFY_ERROR, 4)
                            return
                        end

                        refreshProfileList(list)
                        notify("notice.profile_overwritten", NOTIFY_GENERIC, 3)
                    end,
                    MENU.Phrase("button.cancel")
                )
                return
            end

            Derma_Query(
                MENU.PhraseFormat("dialog.profile_save.message", name),
                MENU.Phrase("dialog.profile_save.title"),
                MENU.Phrase("button.save_profile"),
                function()
                    local profile, errorKey = BetterLights.Profiles.Create(name)
                    if not profile then
                        notify(errorKey, NOTIFY_ERROR, 4)
                        return
                    end

                    refreshProfileList(list)
                    notify("notice.profile_saved", NOTIFY_GENERIC, 3)
                end,
                MENU.Phrase("button.cancel")
            )
        end)
    end

    local function buildProfilesPage(panel)
        local phrase = MENU.Phrase
        local setupPage = MENU.SetupPage
        local addSection = MENU.AddSection
        local addStyledButton = MENU.AddStyledButton
        local addHelpText = MENU.AddHelpText

        setupPage(panel, "page.profiles.title", "page.profiles.desc")

        local profilesSection = addSection(panel, "section.profiles", "section.profiles.desc", true)
        local list = vgui.Create("DListView")
        list:SetTall(168)
        list:SetMultiSelect(false)
        list:SetSortable(false)
        list:AddColumn(phrase("label.profile_name"))
        list:AddColumn(phrase("label.saved_version"))
        list:AddColumn(phrase("label.updated"))
        profilesSection:AddItem(list)
        addHelpText(profilesSection, phrase("help.profile_selection"))
        refreshProfileList(list)

        local profileActions = addSection(panel, "section.profile_actions", nil, true)

        local save = addStyledButton(profileActions, phrase("button.save_current_profile"))
        save.DoClick = function()
            saveCurrentSettings(list)
        end

        local load = addStyledButton(profileActions, phrase("button.load_selected_profile"))
        load.DoClick = function()
            local profile = getSelectedProfile(list)
            if not profile then return end

            Derma_Query(
                MENU.PhraseFormat("dialog.profile_load.message", profile.name),
                MENU.Phrase("dialog.profile_load.title"),
                MENU.Phrase("button.load_profile"),
                function()
                    loadProfile(profile)
                end,
                MENU.Phrase("button.cancel")
            )
        end

        local overwrite = addStyledButton(profileActions, phrase("button.overwrite_selected_profile"))
        overwrite.DoClick = function()
            local profile = getSelectedProfile(list)
            if not profile then return end

            Derma_Query(
                MENU.PhraseFormat("dialog.profile_overwrite.message", profile.name),
                MENU.Phrase("dialog.profile_overwrite.title"),
                MENU.Phrase("button.overwrite_profile"),
                function()
                    local updated, errorKey = BetterLights.Profiles.Overwrite(profile.id, profile.name)
                    if not updated then
                        notify(errorKey, NOTIFY_ERROR, 4)
                        return
                    end

                    refreshProfileList(list)
                    notify("notice.profile_overwritten", NOTIFY_GENERIC, 3)
                end,
                MENU.Phrase("button.cancel")
            )
        end

        local rename = addStyledButton(profileActions, phrase("button.rename_profile"))
        rename.DoClick = function()
            local profile = getSelectedProfile(list)
            if not profile then return end

            requestProfileName("dialog.profile_rename.title", "dialog.profile_rename.message", profile.name, function(name)
                local existing = BetterLights.Profiles.FindByName(name, profile.id)
                if existing then
                    notify("notice.profile_duplicate_name", NOTIFY_ERROR, 4)
                    return
                end

                local updated, errorKey = BetterLights.Profiles.Rename(profile.id, name)
                if not updated then
                    notify(errorKey, NOTIFY_ERROR, 4)
                    return
                end

                refreshProfileList(list)
                notify("notice.profile_renamed", NOTIFY_GENERIC, 3)
            end)
        end

        local delete = addStyledButton(profileActions, phrase("button.delete_profile"))
        delete.DoClick = function()
            local profile = getSelectedProfile(list)
            if not profile then return end

            Derma_Query(
                MENU.PhraseFormat("dialog.profile_delete.message", profile.name),
                MENU.Phrase("dialog.profile_delete.title"),
                MENU.Phrase("button.delete_profile"),
                function()
                    local ok, errorKey = BetterLights.Profiles.Delete(profile.id)
                    if not ok then
                        notify(errorKey, NOTIFY_ERROR, 4)
                        return
                    end

                    refreshProfileList(list)
                    notify("notice.profile_deleted", NOTIFY_GENERIC, 3)
                end,
                MENU.Phrase("button.cancel")
            )
        end

        local sharing = addSection(panel, "section.profile_sharing", nil, true)

        local exportSelected = addStyledButton(sharing, phrase("button.export_selected_profile"))
        exportSelected.DoClick = function()
            local profile = getSelectedProfile(list)
            if not profile then return end

            exportProfile(profile)
        end

        local exportCurrent = addStyledButton(sharing, phrase("button.export_current_profile"))
        exportCurrent.DoClick = exportCurrentSettings

        local importProfile = addStyledButton(sharing, phrase("button.import_profile"))
        importProfile.DoClick = function()
            openImportWindow(list)
        end

    end

    local function buildClientPage(panel)
        activeClientPanel = panel

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

        MENU.SetupPage(panel, "page.client.title", "page.client.desc")

        local client = MENU.AddSection(panel, "section.client", "section.client.desc", true)
        local enabled = vgui.Create("DCheckBoxLabel")
        enabled:SetText(phrase("control.enable_better_lights_client"))
        enabled:SetValue(preference and 1 or 0)
        enabled:SizeToContents()
        enabled:SetEnabled(canChange)
        client:AddItem(enabled)

        enabled.OnChange = function(_, value)
            if BetterLights.SetClientEnabledPreference then
                BetterLights.SetClientEnabledPreference(value)
            else
                BetterLights.ApplyClientSetting("betterlights_client_enable", value and 1 or 0)
            end
        end

        if not serverStateReady then
            MENU.AddHelpText(client, phrase("help.server_settings_loading"))
        elseif mode == BetterLights.SERVER_MODE_ENABLED then
            MENU.AddHelpText(client, phrase("help.client_policy_enabled"))
        elseif mode == BetterLights.SERVER_MODE_DISABLED then
            MENU.AddHelpText(client, phrase("help.client_policy_disabled"))
        else
            MENU.AddHelpText(client, phrase("help.client_policy_player_choice"))
        end

        if serverStateReady then
            local effectiveKey = BetterLights.IsEnabled and BetterLights.IsEnabled()
                and "help.client_effective_enabled"
                or "help.client_effective_disabled"
            MENU.AddHelpText(client, phrase(effectiveKey))
        end
        MENU.AddHelpText(client, phrase("help.optional_bind"))

        local maintenance = MENU.AddSection(panel, "section.personal_maintenance", "section.personal_maintenance.desc", true)
        local reset = MENU.AddStyledButton(maintenance, phrase("button.reset_personal_settings"))
        reset.DoClick = function()
            Derma_Query(
                phrase("dialog.reset_personal_settings.message"),
                phrase("dialog.reset_personal_settings.title"),
                phrase("button.reset_personal_settings"),
                function()
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

    hook.Add("BetterLights_ClientEnabledPreferenceChanged", "BetterLights_RefreshClientSettingsPage", function()
        timer.Simple(0, function()
            if IsValid(activeClientPanel) then
                buildClientPage(activeClientPanel)
            end
        end)
    end)

    function MENU.RegisterGeneralPanel()
        local registerPage = MENU.RegisterPage

        registerPage("General", "BL_Client", "menu.client", buildClientPage)
        MENU.RegisterServerPanels()

        registerPage("Profiles", "BL_Profiles", "page.profiles.title", buildProfilesPage)
    end
end
