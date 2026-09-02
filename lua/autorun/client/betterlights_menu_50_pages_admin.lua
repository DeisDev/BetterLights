if CLIENT then
    local BL = BetterLights
    local MENU = BL.Menu

    local SECTION_ORDER = {
        "behavior",
        "position_first_person",
        "position_world",
        "world_spill",
        "beam",
        "advanced_shadows",
        "flare",
        "color",
        "texture"
    }

    local SECTION_DESCRIPTIONS = {
        position_first_person = "section.flashlight_position_first_person.desc",
        position_world = "section.flashlight_position_world.desc",
        world_spill = "section.flashlight_world_spill.desc",
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
    local SPILL_COLOR_NAMES = {
        r = "betterlights_flashlight_world_spill_color_r",
        g = "betterlights_flashlight_world_spill_color_g",
        b = "betterlights_flashlight_world_spill_color_b"
    }

    local TEXTURE_NAME = "betterlights_flashlight_texture"
    local PLAYER_ENABLE_NAME = "betterlights_flashlight_player_enable"
    local SPILL_ENABLED_DEPENDENCIES = {
        { name = "betterlights_flashlight_world_spill", expected = true }
    }
    local SPILL_CUSTOM_DEPENDENCIES = {
        { name = "betterlights_flashlight_world_spill", expected = true },
        { name = "betterlights_flashlight_world_spill_match", expected = false }
    }
    local SETTING_DEPENDENCIES = {
        betterlights_flashlight_attachment_offset = "betterlights_flashlight_weapon_attachment",
        betterlights_flashlight_flicker_amount = "betterlights_flashlight_flicker",
        betterlights_flashlight_sway_intensity = "betterlights_flashlight_sway",
        betterlights_flashlight_shadow_depth_bias = "betterlights_flashlight_shadows",
        betterlights_flashlight_shadow_slope_scale_depth_bias = "betterlights_flashlight_shadows",
        betterlights_flashlight_shadow_filter = "betterlights_flashlight_shadows",
        betterlights_flashlight_flare_others = "betterlights_flashlight_flare_enable",
        betterlights_flashlight_flare_size = "betterlights_flashlight_flare_enable",
        betterlights_flashlight_flare_opacity = "betterlights_flashlight_flare_enable",
        betterlights_flashlight_world_attachment_offset = "betterlights_flashlight_world_weapon_attachment",
        betterlights_flashlight_world_spill_match = SPILL_ENABLED_DEPENDENCIES,
        betterlights_flashlight_world_spill_size = SPILL_ENABLED_DEPENDENCIES,
        betterlights_flashlight_world_spill_brightness = SPILL_CUSTOM_DEPENDENCIES,
        betterlights_flashlight_world_spill_color_r = SPILL_CUSTOM_DEPENDENCIES,
        betterlights_flashlight_world_spill_color_g = SPILL_CUSTOM_DEPENDENCIES,
        betterlights_flashlight_world_spill_color_b = SPILL_CUSTOM_DEPENDENCIES
    }

    local function canChangeServerSettings()
        local ply = LocalPlayer()
        return game.SinglePlayer()
            or (IsValid(ply) and (ply:IsListenServerHost() or ply:IsAdmin()))
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
        return combo, title
    end

    local function countLogicalOverrides(state)
        local count = 0
        local countedColorGroups = {}

        for i = 1, #BL.FLASHLIGHT_SETTING_DEFS do
            local def = BL.FLASHLIGHT_SETTING_DEFS[i]
            if state.overrides[def.name] then
                if def.colorChannel then
                    local colorGroup = def.colorGroup or "flashlight"
                    if not countedColorGroups[colorGroup] then
                        countedColorGroups[colorGroup] = true
                        count = count + 1
                    end
                else
                    count = count + 1
                end
            end
        end

        return count
    end

    local function isForcedDisabled(staged, name)
        return staged.overrides[name] and not staged.values[name]
    end

    local function isSettingRelevant(staged, name)
        if name ~= PLAYER_ENABLE_NAME and isForcedDisabled(staged, PLAYER_ENABLE_NAME) then
            return false
        end

        local dependencies = SETTING_DEPENDENCIES[name]
        if not dependencies then return true end
        if isstring(dependencies) then return not isForcedDisabled(staged, dependencies) end

        for i = 1, #dependencies do
            local dependency = dependencies[i]
            if staged.overrides[dependency.name]
                and staged.values[dependency.name] ~= dependency.expected then
                return false
            end
        end

        return true
    end

    local function refreshControlStates(refreshers)
        for i = 1, #refreshers do
            refreshers[i]()
        end
    end

    local function hasFlashlightChanges(staged, baseline)
        for i = 1, #BL.FLASHLIGHT_SETTING_DEFS do
            local name = BL.FLASHLIGHT_SETTING_DEFS[i].name
            if staged.overrides[name] ~= baseline.overrides[name]
                or staged.values[name] ~= baseline.values[name] then
                return true
            end
        end

        return false
    end

    local function addBooleanSetting(section, def, staged, editable, refreshers, onChanged)
        local selected = BL.SERVER_MODE_PLAYER_CHOICE
        if staged.overrides[def.name] then
            selected = staged.values[def.name] and BL.SERVER_MODE_ENABLED or BL.SERVER_MODE_DISABLED
        end

        local settingLabel = MENU.Phrase(def.serverLabelKey or def.labelKey)
        local combo, label = addLabeledCombo(section, settingLabel, selected)
        refreshers[#refreshers + 1] = function()
            local enabled = editable and isSettingRelevant(staged, def.name)
            label:SetText(enabled and settingLabel or MENU.PhraseFormat("state.unavailable_label", settingLabel))
            MENU.SetControlLocked(label, not enabled)
            MENU.SetControlLocked(combo, not enabled)
        end
        combo.OnSelect = function(_, _, _, data)
            staged.overrides[def.name] = data ~= BL.SERVER_MODE_PLAYER_CHOICE
            if data ~= BL.SERVER_MODE_PLAYER_CHOICE then
                staged.values[def.name] = data == BL.SERVER_MODE_ENABLED
            end

            onChanged()
        end
    end

    local function addNumberSetting(section, def, staged, editable, refreshers, onChanged)
        local override = vgui.Create("DCheckBoxLabel")
        local overrideLabel = MENU.PhraseFormat("control.override_setting", MENU.Phrase(def.labelKey))
        local valueLabel = MENU.Phrase(def.labelKey)
        override:SetText(overrideLabel)
        override:SetValue(staged.overrides[def.name] and 1 or 0)
        override:SizeToContents()
        section:AddItem(override)

        local slider = vgui.Create("DNumSlider")
        slider:SetText(valueLabel)
        slider:SetMinMax(def.min, def.max)
        slider:SetDecimals(def.decimals or 0)
        slider:SetValue(tonumber(staged.values[def.name]) or def.default)
        section:AddItem(slider)

        refreshers[#refreshers + 1] = function()
            local relevant = isSettingRelevant(staged, def.name)
            local canOverride = editable and relevant
            local valueActive = canOverride and staged.overrides[def.name]
            override:SetText(canOverride and overrideLabel or MENU.PhraseFormat("state.unavailable_label", overrideLabel))
            override:SizeToContents()
            if not canOverride then
                slider:SetText(MENU.PhraseFormat("state.unavailable_label", valueLabel))
            elseif valueActive then
                slider:SetText(valueLabel)
            else
                slider:SetText(MENU.PhraseFormat("state.player_choice_label", valueLabel))
            end
            MENU.SetControlLocked(override, not canOverride)
            MENU.SetControlLocked(slider, not valueActive)
        end

        slider.OnValueChanged = function(_, value)
            staged.values[def.name] = tonumber(value) or def.default
            onChanged()
        end

        override.OnChange = function(_, value)
            staged.overrides[def.name] = value
            onChanged()
        end
    end

    local function addColorSetting(section, staged, editable, refreshers, onChanged, names, options)
        names = names or COLOR_NAMES
        options = options or {}

        local forced = staged.overrides[names.r]
            or staged.overrides[names.g]
            or staged.overrides[names.b]

        local override = vgui.Create("DCheckBoxLabel")
        local overrideLabel = MENU.Phrase(options.overrideLabelKey or "control.override_flashlight_color")
        local mixerLabel = MENU.Phrase(options.labelKey or "control.flashlight_color")
        override:SetText(overrideLabel)
        override:SetValue(forced and 1 or 0)
        override:SizeToContents()
        section:AddItem(override)

        local mixer = vgui.Create("DColorMixer")
        mixer:SetTall(220)
        mixer:SetLabel(mixerLabel)
        mixer:SetPalette(true)
        mixer:SetAlphaBar(false)
        mixer:SetWangs(true)
        mixer:SetColor(Color(
            tonumber(staged.values[names.r]) or options.defaultR or 255,
            tonumber(staged.values[names.g]) or options.defaultG or 245,
            tonumber(staged.values[names.b]) or options.defaultB or 225
        ))
        section:AddItem(mixer)

        refreshers[#refreshers + 1] = function()
            local relevant = isSettingRelevant(staged, names.r)
            local overridden = staged.overrides[names.r]
                or staged.overrides[names.g]
                or staged.overrides[names.b]
            local canOverride = editable and relevant
            local valueActive = canOverride and overridden
            override:SetText(canOverride and overrideLabel or MENU.PhraseFormat("state.unavailable_label", overrideLabel))
            override:SizeToContents()
            if not canOverride then
                mixer:SetLabel(MENU.PhraseFormat("state.unavailable_label", mixerLabel))
            elseif valueActive then
                mixer:SetLabel(mixerLabel)
            else
                mixer:SetLabel(MENU.PhraseFormat("state.player_choice_label", mixerLabel))
            end
            MENU.SetControlLocked(override, not canOverride)
            MENU.SetControlLocked(mixer, not valueActive)
        end

        mixer.ValueChanged = function(_, color)
            staged.values[names.r] = math.Clamp(math.Round(color.r), 0, 255)
            staged.values[names.g] = math.Clamp(math.Round(color.g), 0, 255)
            staged.values[names.b] = math.Clamp(math.Round(color.b), 0, 255)
            onChanged()
        end

        override.OnChange = function(_, value)
            for _, name in pairs(names) do
                staged.overrides[name] = value
            end

            onChanged()
        end
    end

    local function addTextureSetting(section, staged, editable, refreshers, onChanged, rebuild)
        local lastValidValue = tostring(staged.values[TEXTURE_NAME] or "")
        local override = vgui.Create("DCheckBoxLabel")
        local overrideLabel = MENU.Phrase("control.override_flashlight_texture")
        override:SetText(overrideLabel)
        override:SetValue(staged.overrides[TEXTURE_NAME] and 1 or 0)
        override:SizeToContents()
        section:AddItem(override)

        local entry = vgui.Create("DTextEntry")
        entry:SetText(tostring(staged.values[TEXTURE_NAME] or ""))
        entry:SetUpdateOnType(true)
        section:AddItem(entry)

        refreshers[#refreshers + 1] = function()
            local relevant = isSettingRelevant(staged, TEXTURE_NAME)
            local canOverride = editable and relevant
            override:SetText(canOverride and overrideLabel or MENU.PhraseFormat("state.unavailable_label", overrideLabel))
            override:SizeToContents()
            MENU.SetControlLocked(override, not canOverride)
            MENU.SetControlLocked(entry, not (canOverride and staged.overrides[TEXTURE_NAME]))
        end

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
                onChanged()
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

            onChanged()
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

            if not value and staged.textureInvalid then
                staged.textureInvalid = nil
                entry:SetText(lastValidValue)
            end

            onChanged()
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

    local function addGlobalSection(panel, sectionName, staged, editable, refreshers, onChanged)
        local definitions = getSectionDefinitions(sectionName)
        if #definitions == 0 then return end

        local section = MENU.AddSection(
            panel,
            definitions[1].sectionKey,
            SECTION_DESCRIPTIONS[sectionName],
            sectionName ~= "advanced_shadows"
        )

        if sectionName == "color" then
            addColorSetting(section, staged, editable, refreshers, onChanged, COLOR_NAMES)
            return
        end

        if sectionName == "texture" then
            addTextureSetting(section, staged, editable, refreshers, onChanged, function()
                buildGlobalFlashlightPage(panel, staged)
            end)
            return
        end

        for i = 1, #definitions do
            local def = definitions[i]
            if not def.colorChannel then
                if def.type == "bool" then
                    addBooleanSetting(section, def, staged, editable, refreshers, onChanged)
                elseif def.type == "number" then
                    addNumberSetting(section, def, staged, editable, refreshers, onChanged)
                end
            end
        end

        if sectionName == "world_spill" then
            addColorSetting(section, staged, editable, refreshers, onChanged, SPILL_COLOR_NAMES, {
                overrideLabelKey = "control.override_flashlight_world_spill_color",
                labelKey = "control.flashlight_world_spill_color",
                defaultR = 255,
                defaultG = 245,
                defaultB = 225
            })
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
        staged._baseline = staged._baseline or makeState(staged)
        local serverStateReady = hasServerSettingsState()
        local editable = serverStateReady and canChangeServerSettings()
        local controlRefreshers = {}
        local refreshPageState

        local function onStagedChanged()
            refreshControlStates(controlRefreshers)
            if refreshPageState then
                refreshPageState()
            end
        end

        MENU.SetupPage(panel, "page.global_flashlight.title", "page.global_flashlight.desc")

        local overview = MENU.AddSection(
            panel,
            "section.global_flashlight_overview",
            "section.global_flashlight_overview.desc",
            true
        )
        local summary = MENU.AddHelpText(
            overview,
            MENU.PhraseFormat("label.server_overrides_count", countLogicalOverrides(staged))
        )

        if not serverStateReady then
            MENU.AddStateNotice(overview, MENU.Phrase("help.server_settings_loading"), true)
        elseif not editable then
            MENU.AddStateNotice(overview, MENU.Phrase("help.server_settings_read_only"), true)
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

        for i = 1, #SECTION_ORDER do
            addGlobalSection(panel, SECTION_ORDER[i], staged, editable, controlRefreshers, onStagedChanged)
        end

        local applySection = MENU.AddSection(panel, "section.apply_server_settings", nil, true)
        MENU.AddHelpText(applySection, MENU.Phrase("help.server_settings_staged"))
        local pending = MENU.AddHelpText(applySection, MENU.Phrase("label.server_settings_unchanged"))

        local apply = MENU.AddStyledButton(applySection, MENU.Phrase("button.apply_server_settings"))
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

        refreshPageState = function()
            local count = countLogicalOverrides(staged)
            local changed = hasFlashlightChanges(staged, staged._baseline)

            summary:SetText(MENU.PhraseFormat("label.server_overrides_count", count))
            clearOverrides:SetEnabled(editable and count > 0)
            pending:SetText(MENU.Phrase(changed and "label.server_settings_pending" or "label.server_settings_unchanged"))
            apply:SetEnabled(editable and changed and not staged.textureInvalid)
        end

        onStagedChanged()
    end

    local function buildServerPolicyPage(panel)
        local serverStateReady = hasServerSettingsState()
        local editable = serverStateReady and canChangeServerSettings()
        local selectedMode = BL.GetServerMode and BL.GetServerMode() or BL.SERVER_MODE_PLAYER_CHOICE

        MENU.SetupPage(panel, "page.server_policy.title", "page.server_policy.desc")

        local policy = MENU.AddSection(panel, "section.server_policy", "section.server_policy.desc", true)
        if not serverStateReady then
            MENU.AddStateNotice(policy, MENU.Phrase("help.server_settings_loading"), true)
        elseif not editable then
            MENU.AddStateNotice(policy, MENU.Phrase("help.server_settings_read_only"), true)
        end

        local modeLabel = MENU.Phrase("control.addon_mode")
        local combo, label = addLabeledCombo(policy, modeLabel, selectedMode)
        if not editable then
            label:SetText(MENU.PhraseFormat("state.unavailable_label", modeLabel))
        end
        MENU.SetControlLocked(combo, not editable)
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

    MENU.RegisterServerPanels = nil
    MENU.RegisterPages("BetterLights_Menu_Server", {
        {
            category = "Admin",
            id = "BL_Admin",
            titleKey = "menu.server_policy",
            buildPanel = buildServerPolicyPage
        },
        {
            category = "Admin",
            id = "BL_GlobalFlashlight",
            titleKey = "menu.global_flashlight",
            buildPanel = function(panel)
                buildGlobalFlashlightPage(panel)
            end
        }
    })
end
