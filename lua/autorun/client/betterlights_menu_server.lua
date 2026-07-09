if CLIENT then
    local BL = BetterLights
    local MENU = BL.Menu

    local SECTION_ORDER = {
        "behavior",
        "position",
        "beam",
        "advanced_shadows",
        "flare",
        "color",
        "texture"
    }

    local SECTION_DESCRIPTIONS = {
        beam = "section.beam.desc",
        advanced_shadows = "section.advanced_shadows.desc",
        flare = "section.flare.desc",
        color = "section.color.desc",
        texture = "section.texture.desc"
    }

    local COLOR_NAMES = {
        r = "betterlights_flashlight_color_r",
        g = "betterlights_flashlight_color_g",
        b = "betterlights_flashlight_color_b"
    }

    local TEXTURE_NAME = "betterlights_flashlight_texture"

    local function canChangeServerSettings()
        return game.SinglePlayer() or (IsValid(LocalPlayer()) and LocalPlayer():IsAdmin())
    end

    local function hasServerSettingsState()
        return BL.HasServerSettingsState and BL.HasServerSettingsState() or false
    end

    local function notify(key, kind, duration)
        notification.AddLegacy(MENU.Phrase(key), kind or NOTIFY_GENERIC, duration or 3)
        surface.PlaySound(kind == NOTIFY_ERROR and "buttons/button10.wav" or "buttons/button14.wav")
    end

    local function makeState(source)
        source = source or {}

        local state = {
            mode = source.mode or BL.SERVER_MODE_PLAYER_CHOICE,
            overrides = {},
            values = {}
        }

        for i = 1, #BL.FLASHLIGHT_SETTING_DEFS do
            local def = BL.FLASHLIGHT_SETTING_DEFS[i]
            state.overrides[def.name] = source.overrides and source.overrides[def.name] == true or false

            local value = source.values and source.values[def.name]
            if value == nil then
                value = def.default
            end

            state.values[def.name] = value
        end

        return state
    end

    local function getServerState()
        if BL.GetServerSettingsState then
            return makeState(BL.GetServerSettingsState())
        end

        return makeState()
    end

    local function submitState(state)
        if not hasServerSettingsState() or not BL.SubmitServerSettings then
            notify("notice.server_settings_unavailable", NOTIFY_ERROR, 4)
            return false
        end

        local ok = BL.SubmitServerSettings(state)
        if not ok then
            notify("notice.server_settings_invalid", NOTIFY_ERROR, 4)
            return false
        end

        notify("notice.server_settings_submitted", NOTIFY_GENERIC, 3)
        return true
    end

    local function addModeChoices(combo, selected)
        combo:SetSortItems(false)

        local choices = {
            { label = MENU.Phrase("option.player_choice"), value = BL.SERVER_MODE_PLAYER_CHOICE },
            { label = MENU.Phrase("option.enabled"), value = BL.SERVER_MODE_ENABLED },
            { label = MENU.Phrase("option.disabled"), value = BL.SERVER_MODE_DISABLED }
        }

        for i = 1, #choices do
            local choice = choices[i]
            combo:AddChoice(choice.label, choice.value, choice.value == selected)
        end
    end

    local function addLabeledCombo(section, label, selected)
        local row = vgui.Create("DPanel")
        row:SetTall(50)
        row.Paint = nil

        local title = vgui.Create("DLabel", row)
        title:Dock(TOP)
        title:SetTall(20)
        title:SetText(label)
        title:SetDark(true)

        local combo = vgui.Create("DComboBox", row)
        combo:Dock(FILL)
        addModeChoices(combo, selected)

        section:AddItem(row)
        return combo
    end

    local function countLogicalOverrides(state)
        local count = 0
        local countedColor = false

        for i = 1, #BL.FLASHLIGHT_SETTING_DEFS do
            local def = BL.FLASHLIGHT_SETTING_DEFS[i]
            if state.overrides[def.name] then
                if def.colorChannel then
                    if not countedColor then
                        countedColor = true
                        count = count + 1
                    end
                else
                    count = count + 1
                end
            end
        end

        return count
    end

    local function addBooleanSetting(section, def, staged, editable)
        local selected = BL.SERVER_MODE_PLAYER_CHOICE
        if staged.overrides[def.name] then
            selected = staged.values[def.name] and BL.SERVER_MODE_ENABLED or BL.SERVER_MODE_DISABLED
        end

        local combo = addLabeledCombo(section, MENU.Phrase(def.serverLabelKey or def.labelKey), selected)
        combo:SetEnabled(editable)
        combo.OnSelect = function(_, _, _, data)
            staged.overrides[def.name] = data ~= BL.SERVER_MODE_PLAYER_CHOICE
            if data ~= BL.SERVER_MODE_PLAYER_CHOICE then
                staged.values[def.name] = data == BL.SERVER_MODE_ENABLED
            end
        end
    end

    local function addNumberSetting(section, def, staged, editable)
        local override = vgui.Create("DCheckBoxLabel")
        override:SetText(MENU.PhraseFormat("control.override_setting", MENU.Phrase(def.labelKey)))
        override:SetValue(staged.overrides[def.name] and 1 or 0)
        override:SizeToContents()
        override:SetEnabled(editable)
        section:AddItem(override)

        local slider = vgui.Create("DNumSlider")
        slider:SetText(MENU.Phrase(def.labelKey))
        slider:SetMinMax(def.min, def.max)
        slider:SetDecimals(def.decimals or 0)
        slider:SetValue(tonumber(staged.values[def.name]) or def.default)
        slider:SetEnabled(editable and staged.overrides[def.name])
        section:AddItem(slider)

        slider.OnValueChanged = function(_, value)
            staged.values[def.name] = tonumber(value) or def.default
        end

        override.OnChange = function(_, value)
            staged.overrides[def.name] = value
            slider:SetEnabled(editable and value)
        end
    end

    local function addColorSetting(section, staged, editable)
        local forced = staged.overrides[COLOR_NAMES.r]
            or staged.overrides[COLOR_NAMES.g]
            or staged.overrides[COLOR_NAMES.b]

        local override = vgui.Create("DCheckBoxLabel")
        override:SetText(MENU.Phrase("control.override_flashlight_color"))
        override:SetValue(forced and 1 or 0)
        override:SizeToContents()
        override:SetEnabled(editable)
        section:AddItem(override)

        local mixer = vgui.Create("DColorMixer")
        mixer:SetTall(220)
        mixer:SetLabel(MENU.Phrase("control.flashlight_color"))
        mixer:SetPalette(true)
        mixer:SetAlphaBar(false)
        mixer:SetWangs(true)
        mixer:SetColor(Color(
            tonumber(staged.values[COLOR_NAMES.r]) or 255,
            tonumber(staged.values[COLOR_NAMES.g]) or 245,
            tonumber(staged.values[COLOR_NAMES.b]) or 225
        ))
        mixer:SetEnabled(editable and forced)
        section:AddItem(mixer)

        mixer.ValueChanged = function(_, color)
            staged.values[COLOR_NAMES.r] = math.Clamp(math.Round(color.r), 0, 255)
            staged.values[COLOR_NAMES.g] = math.Clamp(math.Round(color.g), 0, 255)
            staged.values[COLOR_NAMES.b] = math.Clamp(math.Round(color.b), 0, 255)
        end

        override.OnChange = function(_, value)
            for _, name in pairs(COLOR_NAMES) do
                staged.overrides[name] = value
            end

            mixer:SetEnabled(editable and value)
        end
    end

    local function addTextureSetting(section, staged, editable, rebuild)
        local lastValidValue = tostring(staged.values[TEXTURE_NAME] or "")
        local override = vgui.Create("DCheckBoxLabel")
        override:SetText(MENU.Phrase("control.override_flashlight_texture"))
        override:SetValue(staged.overrides[TEXTURE_NAME] and 1 or 0)
        override:SizeToContents()
        override:SetEnabled(editable)
        section:AddItem(override)

        local entry = vgui.Create("DTextEntry")
        entry:SetText(tostring(staged.values[TEXTURE_NAME] or ""))
        entry:SetUpdateOnType(true)
        entry:SetEnabled(editable and staged.overrides[TEXTURE_NAME])
        section:AddItem(entry)

        local validation = vgui.Create("DLabel")
        validation:SetWrap(true)
        validation:SetAutoStretchVertical(true)
        validation:SetDark(true)
        section:AddItem(validation)

        local function validateEntry()
            local raw = entry:GetText()
            local normalized = BL.ValidateServerFlashlightSettingValue(TEXTURE_NAME, raw)

            if not normalized then
                staged.textureInvalid = true
                validation:SetText(MENU.Phrase("label.texture_path_invalid"))
                return false
            end

            staged.textureInvalid = nil
            lastValidValue = normalized
            staged.values[TEXTURE_NAME] = normalized
            if BL.IsValidFlashlightTexturePath and not BL.IsValidFlashlightTexturePath(normalized) then
                validation:SetText(MENU.Phrase("label.texture_path_unavailable"))
            else
                validation:SetText(MENU.Phrase("label.texture_path_valid"))
            end

            return true
        end

        entry.OnChange = validateEntry
        entry.OnEnter = function()
            if validateEntry() then
                rebuild()
            end
        end
        validateEntry()

        MENU.AddCurrentTexturePreview(section, tostring(staged.values[TEXTURE_NAME] or ""), "label.texture_preview")
        MENU.AddHelpText(section, MENU.Phrase("help.server_texture_preview"))
        MENU.AddHelpText(section, MENU.Phrase("help.server_texture_distribution"))

        override.OnChange = function(_, value)
            staged.overrides[TEXTURE_NAME] = value
            entry:SetEnabled(editable and value)

            if not value and staged.textureInvalid then
                staged.textureInvalid = nil
                entry:SetText(lastValidValue)
            end
        end
    end

    local function getSectionDefinitions(sectionName)
        local definitions = {}

        for i = 1, #BL.FLASHLIGHT_SETTING_DEFS do
            local def = BL.FLASHLIGHT_SETTING_DEFS[i]
            if def.section == sectionName then
                definitions[#definitions + 1] = def
            end
        end

        return definitions
    end

    local buildGlobalFlashlightPage

    local function addGlobalSection(panel, sectionName, staged, editable)
        local definitions = getSectionDefinitions(sectionName)
        if #definitions == 0 then return end

        local section = MENU.AddSection(
            panel,
            definitions[1].sectionKey,
            SECTION_DESCRIPTIONS[sectionName],
            sectionName ~= "advanced_shadows"
        )

        if sectionName == "color" then
            addColorSetting(section, staged, editable)
            return
        end

        if sectionName == "texture" then
            addTextureSetting(section, staged, editable, function()
                buildGlobalFlashlightPage(panel, staged)
            end)
            return
        end

        for i = 1, #definitions do
            local def = definitions[i]
            if def.type == "bool" then
                addBooleanSetting(section, def, staged, editable)
            elseif def.type == "number" then
                addNumberSetting(section, def, staged, editable)
            end
        end
    end

    local function populateFromPersonalSettings(staged)
        staged.textureInvalid = nil

        for i = 1, #BL.FLASHLIGHT_SETTING_DEFS do
            local def = BL.FLASHLIGHT_SETTING_DEFS[i]
            local cvar = GetConVar(def.name)

            if cvar then
                local value
                if def.type == "bool" then
                    value = cvar:GetBool()
                elseif def.type == "number" then
                    value = math.Clamp(cvar:GetFloat(), def.min, def.max)
                    value = math.Round(value, def.decimals or 0)
                else
                    value = cvar:GetString()
                end

                local validated = BL.ValidateServerFlashlightSettingValue(def.name, value)
                if validated ~= nil then
                    staged.values[def.name] = validated
                end
            end
        end
    end

    local function makeFlashlightPayload(staged)
        local payload = getServerState()

        for i = 1, #BL.FLASHLIGHT_SETTING_DEFS do
            local name = BL.FLASHLIGHT_SETTING_DEFS[i].name
            payload.overrides[name] = staged.overrides[name]
            payload.values[name] = staged.values[name]
        end

        return payload
    end

    buildGlobalFlashlightPage = function(panel, staged)
        staged = staged or getServerState()
        local serverStateReady = hasServerSettingsState()
        local editable = serverStateReady and canChangeServerSettings()

        MENU.SetupPage(panel, "page.global_flashlight.title", "page.global_flashlight.desc")

        local overview = MENU.AddSection(panel, "section.global_flashlight_overview", nil, true)
        local summary = MENU.AddHelpText(
            overview,
            MENU.PhraseFormat("label.server_overrides_count", countLogicalOverrides(staged))
        )

        if not serverStateReady then
            MENU.AddHelpText(overview, MENU.Phrase("help.server_settings_loading"))
        elseif not editable then
            MENU.AddHelpText(overview, MENU.Phrase("help.server_settings_read_only"))
        end

        local usePersonal = MENU.AddStyledButton(overview, MENU.Phrase("button.use_personal_flashlight_values"))
        usePersonal:SetEnabled(editable)
        usePersonal.DoClick = function()
            populateFromPersonalSettings(staged)
            buildGlobalFlashlightPage(panel, staged)
        end

        local clearOverrides = MENU.AddStyledButton(overview, MENU.Phrase("button.clear_all_overrides"))
        clearOverrides:SetEnabled(editable and countLogicalOverrides(staged) > 0)
        clearOverrides.DoClick = function()
            for i = 1, #BL.FLASHLIGHT_SETTING_DEFS do
                staged.overrides[BL.FLASHLIGHT_SETTING_DEFS[i].name] = false
            end

            staged.textureInvalid = nil
            buildGlobalFlashlightPage(panel, staged)
        end

        local lastCount = countLogicalOverrides(staged)
        summary.Think = function()
            local count = countLogicalOverrides(staged)
            if count == lastCount then return end

            lastCount = count
            summary:SetText(MENU.PhraseFormat("label.server_overrides_count", count))
            clearOverrides:SetEnabled(editable and count > 0)
        end

        for i = 1, #SECTION_ORDER do
            addGlobalSection(panel, SECTION_ORDER[i], staged, editable)
        end

        local applySection = MENU.AddSection(panel, "section.apply_server_settings", nil, true)
        MENU.AddHelpText(applySection, MENU.Phrase("help.server_settings_staged"))

        local apply = MENU.AddStyledButton(applySection, MENU.Phrase("button.apply_server_settings"))
        apply:SetEnabled(editable)
        apply.DoClick = function()
            if staged.textureInvalid then
                notify("notice.server_texture_invalid", NOTIFY_ERROR, 4)
                return
            end

            submitState(makeFlashlightPayload(staged))
        end

        local reset = MENU.AddStyledButton(applySection, MENU.Phrase("button.reset_server_flashlight_settings"))
        reset:SetEnabled(editable)
        reset.DoClick = function()
            Derma_Query(
                MENU.Phrase("dialog.reset_server_flashlight.message"),
                MENU.Phrase("dialog.reset_server_flashlight.title"),
                MENU.Phrase("button.reset_server_flashlight_settings"),
                function()
                    local resetState = getServerState()

                    for i = 1, #BL.FLASHLIGHT_SETTING_DEFS do
                        local def = BL.FLASHLIGHT_SETTING_DEFS[i]
                        resetState.overrides[def.name] = false
                        resetState.values[def.name] = def.default
                    end

                    submitState(resetState)
                end,
                MENU.Phrase("button.cancel")
            )
        end
    end

    local function buildServerPolicyPage(panel)
        local serverStateReady = hasServerSettingsState()
        local editable = serverStateReady and canChangeServerSettings()
        local selectedMode = BL.GetServerMode and BL.GetServerMode() or BL.SERVER_MODE_PLAYER_CHOICE

        MENU.SetupPage(panel, "page.server_policy.title", "page.server_policy.desc")

        local policy = MENU.AddSection(panel, "section.server_policy", "section.server_policy.desc", true)
        if not serverStateReady then
            MENU.AddHelpText(policy, MENU.Phrase("help.server_settings_loading"))
        elseif not editable then
            MENU.AddHelpText(policy, MENU.Phrase("help.server_settings_read_only"))
        end

        local combo = addLabeledCombo(policy, MENU.Phrase("control.addon_mode"), selectedMode)
        combo:SetEnabled(editable)
        combo.OnSelect = function(_, _, _, data)
            selectedMode = data
        end

        local apply = MENU.AddStyledButton(policy, MENU.Phrase("button.apply_server_mode"))
        apply:SetEnabled(editable)
        apply.DoClick = function()
            local state = getServerState()
            state.mode = selectedMode
            submitState(state)
        end

        local maintenance = MENU.AddSection(panel, "section.server_maintenance", "section.server_maintenance.desc", true)
        local reset = MENU.AddStyledButton(maintenance, MENU.Phrase("button.reset_server_mode"))
        reset:SetEnabled(editable)
        reset.DoClick = function()
            Derma_Query(
                MENU.Phrase("dialog.reset_server_mode.message"),
                MENU.Phrase("dialog.reset_server_mode.title"),
                MENU.Phrase("button.reset_server_mode"),
                function()
                    local state = getServerState()
                    state.mode = BL.SERVER_MODE_PLAYER_CHOICE
                    submitState(state)
                end,
                MENU.Phrase("button.cancel")
            )
        end
    end

    function MENU.RegisterServerPanels()
        MENU.RegisterPage("Admin", "BL_Admin", "menu.server_policy", buildServerPolicyPage)
        MENU.RegisterPage("Admin", "BL_GlobalFlashlight", "menu.global_flashlight", buildGlobalFlashlightPage)
    end
end
