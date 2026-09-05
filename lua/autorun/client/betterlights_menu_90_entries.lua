if CLIENT then
    local MENU = BetterLights.Menu
    local MENU_COMMAND = "betterlights_menu"
    local WIDGET_ICON = "betterlights/icon64/lightbulb.png"
    local SPAWNMENU_TAB_ID = "Utilities"
    local SPAWNMENU_CATEGORY_ID = "BetterLights"
    local bindListenerKey = KEY_NONE
    local bindListenerArmed = false
    local suppressBindToggleUntilRelease = false

    local function phrase(key)
        return MENU.Phrase(key)
    end

    local function normalizeBinding(binding)
        return string.lower(string.Trim(tostring(binding or "")))
    end

    local function getMenuBindingKey()
        local keyName = input.LookupBinding(MENU_COMMAND, true)
        if not isstring(keyName) or keyName == "" then return KEY_NONE end

        local keyCode = input.GetKeyCode(keyName)
        if not isnumber(keyCode) or keyCode < 0 then return KEY_NONE end
        return keyCode
    end

    local function resetBindListener()
        bindListenerKey = KEY_NONE
        bindListenerArmed = false
        suppressBindToggleUntilRelease = false
    end

    MENU.ResetSettingsBindListener = resetBindListener

    local function refreshBinder(binder)
        timer.Simple(0, function()
            if not IsValid(binder) then return end

            binder.BetterLightsUpdating = true
            binder:SetSelectedNumber(getMenuBindingKey())
            binder.BetterLightsUpdating = false
        end)
    end

    local function applyMenuBinding(keyCode, binder)
        local previousKey = input.LookupBinding(MENU_COMMAND, true)
        local nextKey = keyCode ~= KEY_NONE and input.GetKeyName(keyCode) or nil

        if isstring(previousKey) and previousKey ~= ""
            and normalizeBinding(previousKey) ~= normalizeBinding(nextKey) then
            RunConsoleCommand("unbind", previousKey)
        end

        if isstring(nextKey) and nextKey ~= "" then
            RunConsoleCommand("bind", nextKey, MENU_COMMAND)
        end

        refreshBinder(binder)
    end

    local function configureBinder(binder)
        binder:SetSelectedNumber(getMenuBindingKey())

        binder.OnChange = function(self, keyCode)
            if self.BetterLightsUpdating then return end

            keyCode = tonumber(keyCode) or KEY_NONE
            if keyCode == KEY_NONE then
                applyMenuBinding(KEY_NONE, self)
                return
            end

            local existing = string.Trim(tostring(input.LookupKeyBinding(keyCode) or ""))
            if existing == "" or normalizeBinding(existing) == MENU_COMMAND then
                applyMenuBinding(keyCode, self)
                return
            end

            refreshBinder(self)

            local keyName = language.GetPhrase(input.GetKeyName(keyCode) or tostring(keyCode))
            Derma_Query(
                MENU.PhraseFormat("dialog.menu_bind_conflict.message", keyName, existing),
                phrase("dialog.menu_bind_conflict.title"),
                phrase("button.replace_bind"),
                function()
                    if not IsValid(self) then return end
                    applyMenuBinding(keyCode, self)
                end,
                phrase("button.cancel"),
                function()
                    if not IsValid(self) then return end
                    refreshBinder(self)
                end
            )
        end
    end

    local function addOpenSettingsButton(panel)
        local open = MENU.AddStyledButton(
            panel,
            phrase("button.open_settings"),
            phrase("tooltip.open_settings")
        )
        open.DoClick = function()
            MENU.ToggleSettings()
        end
        return open
    end

    function MENU.AddSettingsAccessControls(panel, options)
        options = options or {}

        local access = MENU.AddSection(
            panel,
            "section.settings_access",
            "section.settings_access.desc",
            options.expanded ~= false
        )
        if options.showOpenButton ~= false then
            addOpenSettingsButton(access)
        end

        local label = vgui.Create("DLabel")
        label:SetText(phrase("control.open_menu_key"))
        label:SetDark(true)
        label:SetTall(18)
        label:SetContentAlignment(4)
        access:AddItem(label)

        local binder = vgui.Create("DBinder")
        binder:SetTall(24)
        configureBinder(binder)
        access:AddItem(binder)

        MENU.AddHelpText(access, phrase("help.optional_bind"))
        MENU.AddHelpText(access, phrase("help.menu_console_command"))
        return access
    end

    function MENU.BuildQuickSettingsPanel(panel)
        MENU.TrackClientSettingsPanel(panel, MENU.BuildQuickSettingsPanel)
        MENU.SetupPage(panel, "page.quick_settings.title", "page.quick_settings.desc")

        MENU.AddClientPreferenceSection(panel)

        local settings = MENU.AddSection(panel, "section.full_settings", "section.full_settings.desc", true)
        addOpenSettingsButton(settings)

        MENU.AddSettingsAccessControls(panel, {
            showOpenButton = false,
            expanded = false
        })
    end

    local function registerCategories()
        spawnmenu.AddToolCategory(SPAWNMENU_TAB_ID, SPAWNMENU_CATEGORY_ID, phrase("addon.name"))
    end

    concommand.Remove(MENU_COMMAND)
    concommand.Add(MENU_COMMAND, function(_, _, args)
        local pageId = args and args[1] or nil
        if isstring(pageId) and pageId ~= "" then
            MENU.OpenSettings(pageId)
            return
        end

        if suppressBindToggleUntilRelease then return end
        MENU.ToggleSettings()
    end)

    hook.Add("Think", "BetterLights_SettingsMenuBindListener", function()
        local frame = MENU._settingsFrame
        if not MENU.UpdateSettingsWindowKeyboard(frame) then
            if suppressBindToggleUntilRelease
                and bindListenerKey ~= KEY_NONE
                and input.IsKeyDown(bindListenerKey) then
                return
            end

            resetBindListener()
            return
        end

        local keyCode = getMenuBindingKey()
        if keyCode == KEY_NONE then
            resetBindListener()
            return
        end

        local keyDown = input.IsKeyDown(keyCode)
        local focus = vgui.GetKeyboardFocus()
        if not frame:IsActive() or input.IsKeyTrapping()
            or (IsValid(focus) and isfunction(focus.IsEditing) and focus:IsEditing()) then
            bindListenerKey = keyCode
            bindListenerArmed = false
            return
        end

        if bindListenerKey ~= keyCode then
            bindListenerKey = keyCode
            bindListenerArmed = not keyDown
            return
        end

        if not bindListenerArmed then
            bindListenerArmed = not keyDown
            return
        end

        if not keyDown then return end

        bindListenerArmed = false
        suppressBindToggleUntilRelease = true
        frame:Close()
    end)

    hook.Add("OnReloaded", "BetterLights_RefreshSettingsRegistration", function()
        if engine.ActiveGamemode() == "sandbox" then
            RunConsoleCommand("spawnmenu_reload")
        end

        MENU.RefreshSettingsWindow()
    end)

    list.Set("DesktopWindows", "BetterLightsSettings", {
        title = phrase("widget.settings.title"),
        icon = WIDGET_ICON,
        width = 960,
        height = 700,
        onewindow = true,
        init = function(_, window)
            if IsValid(window) then
                window:Close()
            end

            MENU.ToggleSettings()
        end
    })

    hook.Remove("AddToolMenuTabs", "BetterLights_AddTab")

    hook.Add("AddToolMenuCategories", "BetterLights_AddCategories", function()
        registerCategories()
    end)

    hook.Add("PopulateToolMenu", "BetterLights_Populate", function()
        spawnmenu.AddToolMenuOption(
            SPAWNMENU_TAB_ID,
            SPAWNMENU_CATEGORY_ID,
            "BL_QuickSettings",
            phrase("menu.quick_settings"),
            "",
            "",
            MENU.BuildQuickSettingsPanel
        )
    end)
end
