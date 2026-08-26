if CLIENT then
    local MENU = BetterLights.Menu
    local phrase = MENU.Phrase
    local phraseFormat = MENU.PhraseFormat

    local function getClientDefault(cvarName, fallback)
        return BetterLights.GetClientConVarDefault(cvarName, fallback)
    end

    local function styleButton(btn)
        return btn
    end

    local function addStyledButton(panel, label, tooltip)
        local btn = styleButton(vgui.Create("DButton"))
        btn:SetTall(30)
        btn:SetText(label)

        if tooltip then
            btn:SetTooltip(tooltip)
        end

        panel:AddItem(btn)
        return btn
    end

    MENU.StyleButton = styleButton
    MENU.AddStyledButton = addStyledButton

    local function spaceHelpText(label, leftMargin, rightMargin)
        if not IsValid(label) then return nil end

        label:DockMargin(leftMargin or 8, 4, rightMargin or 8, 12)
        return label
    end

    local function addHelpText(panel, text)
        if panel.ControlHelp then
            return spaceHelpText(panel:ControlHelp(text), 32, 32)
        end

        if panel.Help then
            return spaceHelpText(panel:Help(text), 8, 8)
        end

        local label = vgui.Create("DLabel")
        label:SetText(text)
        label:SetWrap(true)
        label:SetAutoStretchVertical(true)
        label:SetDark(true)
        label:DockMargin(8, 4, 8, 12)
        panel:AddItem(label)
        return label
    end

    MENU.AddHelpText = addHelpText

    local controlStateWatches = {}

    local function getControlStateWatch(cvarName)
        local watch = controlStateWatches[cvarName]
        if watch then return watch end

        watch = {
            controls = setmetatable({}, { __mode = "k" }),
            listeners = setmetatable({}, { __mode = "k" })
        }
        controlStateWatches[cvarName] = watch

        local callbackId = "BetterLights_MenuControlState_" .. cvarName
        cvars.RemoveChangeCallback(cvarName, callbackId)
        cvars.AddChangeCallback(cvarName, function()
            timer.Simple(0, function()
                for control in pairs(watch.controls) do
                    if IsValid(control) and control.BetterLightsRefreshEnabledState then
                        control:BetterLightsRefreshEnabledState()
                    else
                        watch.controls[control] = nil
                    end
                end

                for owner, callback in pairs(watch.listeners) do
                    if IsValid(owner) then
                        callback()
                    else
                        watch.listeners[owner] = nil
                    end
                end
            end)
        end, callbackId)

        return watch
    end

    local function getConVarBool(cvarName)
        local cvar = GetConVar(cvarName)
        return not cvar or cvar:GetBool()
    end

    local function refreshControlEnabledState(control)
        if not IsValid(control) then return end

        local enabled = control.BetterLightsControlLocked ~= true
        local rules = control.BetterLightsControlStateRules

        if enabled and rules then
            for i = 1, #rules do
                if not rules[i].predicate() then
                    enabled = false
                    break
                end
            end
        end

        control:SetEnabled(enabled)
    end

    local function bindControlTreeToState(control, cvarName, predicate)
        if not IsValid(control) then return end

        control.BetterLightsControlStateRules = control.BetterLightsControlStateRules or {}
        control.BetterLightsControlStateRules[#control.BetterLightsControlStateRules + 1] = {
            cvarName = cvarName,
            predicate = predicate
        }
        control.BetterLightsRefreshEnabledState = refreshControlEnabledState
        getControlStateWatch(cvarName).controls[control] = true
        refreshControlEnabledState(control)

        for _, child in ipairs(control:GetChildren()) do
            bindControlTreeToState(child, cvarName, predicate)
        end
    end

    local function bindControlToConVar(control, cvarName, predicate)
        if not isstring(cvarName) or cvarName == "" then return control end

        predicate = predicate or function()
            return getConVarBool(cvarName)
        end
        bindControlTreeToState(control, cvarName, predicate)
        return control
    end

    local function setControlTreeLocked(control, locked)
        if not IsValid(control) then return end

        control.BetterLightsControlLocked = locked == true
        refreshControlEnabledState(control)

        for _, child in ipairs(control:GetChildren()) do
            setControlTreeLocked(child, locked)
        end
    end

    local function addStateNotice(panel, text, highlighted)
        local label = vgui.Create("DLabel")
        label:SetTall(30)
        label:SetText(text)
        label:SetFont("DermaDefaultBold")
        label:SetWrap(true)
        label:SetAutoStretchVertical(true)
        label:SetDark(true)
        label:SetHighlight(highlighted == true)
        label:DockMargin(8, 4, 8, 8)
        label.BetterLightsAlwaysEnabled = true
        panel:AddItem(label)
        return label
    end

    local function watchControlState(cvarName, owner, callback)
        if not (isstring(cvarName) and IsValid(owner) and isfunction(callback)) then return end

        getControlStateWatch(cvarName).listeners[owner] = callback
    end

    local function refreshControlGroup(group)
        if not (group and IsValid(group.container)) then return end

        local enabled = group.predicate()
        if IsValid(group.notice) then
            group.notice:SetVisible(not enabled)
        end

        if group.container.BetterLightsBaseName then
            group.container:SetName(phraseFormat(
                enabled and "state.section_enabled" or group.disabledTitleKey,
                group.container.BetterLightsBaseName
            ))
        end

        group.container:InvalidateLayout(true)
    end

    local function beginControlGroup(container, cvarName, predicate, options)
        if not (IsValid(container) and isstring(cvarName) and cvarName ~= "") then return end

        options = options or {}
        predicate = predicate or function()
            return getConVarBool(cvarName)
        end

        container.BetterLightsAddingStateNotice = true
        local notice = addStateNotice(
            container,
            phrase(options.disabledHelpKey or "state.feature_disabled_help"),
            options.highlighted == true
        )
        container.BetterLightsAddingStateNotice = nil

        local group = {
            container = container,
            cvarName = cvarName,
            predicate = predicate,
            notice = notice,
            disabledTitleKey = options.disabledTitleKey or "state.section_disabled"
        }
        container.BetterLightsActiveControlGroup = group
        container.BetterLightsHasFeatureGroup = true

        watchControlState(cvarName, notice, function()
            refreshControlGroup(group)
        end)
        refreshControlGroup(group)
        return group
    end

    local function endControlGroup(container)
        if IsValid(container) then
            container.BetterLightsActiveControlGroup = nil
        end
    end

    local function getAutomaticDependency(cvarName)
        local prefix = string.match(cvarName, "^(.*)_models_elight_size_mult$")
        if prefix then return prefix .. "_models_elight" end

        prefix = string.match(cvarName, "^(.*)_pulse_amount$")
            or string.match(cvarName, "^(.*)_pulse_speed$")
        if prefix then return prefix .. "_pulse_enable" end

        prefix = string.match(cvarName, "^(.*)_flicker_amount$")
            or string.match(cvarName, "^(.*)_flicker_size_amount$")
            or string.match(cvarName, "^(.*)_flicker_speed$")
        if prefix and GetConVar(prefix .. "_flicker_enable") then
            return prefix .. "_flicker_enable"
        end
    end

    local function prepareControlContainer(panel)
        if not IsValid(panel) then return end

        panel.BetterLightsActiveControlGroup = nil
        panel.BetterLightsHasFeatureGroup = nil
        if panel.BetterLightsTracksControlState then return end

        panel.BetterLightsTracksControlState = true
        local originalAddItem = panel.AddItem
        panel.AddItem = function(self, left, right)
            originalAddItem(self, left, right)

            local group = self.BetterLightsActiveControlGroup
            if not group or self.BetterLightsAddingStateNotice then return end

            if IsValid(left) and not left.BetterLightsAlwaysEnabled then
                bindControlToConVar(left, group.cvarName, group.predicate)
            end

            if IsValid(right) and not right.BetterLightsAlwaysEnabled then
                bindControlToConVar(right, group.cvarName, group.predicate)
            end
        end

        local originalCheckBox = panel.CheckBox
        if originalCheckBox then
            panel.CheckBox = function(self, label, cvarName)
                local checkbox = originalCheckBox(self, label, cvarName)
                checkbox.BetterLightsConVarName = cvarName

                if not self.BetterLightsSkipAutoState
                    and not self.BetterLightsHasFeatureGroup
                    and isstring(cvarName)
                    and string.EndsWith(cvarName, "_enable") then
                    beginControlGroup(self, cvarName)
                end

                return checkbox
            end
        end

        local originalNumSlider = panel.NumSlider
        if originalNumSlider then
            panel.NumSlider = function(self, label, cvarName, minimum, maximum, decimals)
                local slider = originalNumSlider(self, label, cvarName, minimum, maximum, decimals)
                slider.BetterLightsConVarName = cvarName

                local dependency = isstring(cvarName) and getAutomaticDependency(cvarName)
                if dependency then
                    bindControlToConVar(slider, dependency)
                end

                return slider
            end
        end
    end

    MENU.AddStateNotice = addStateNotice
    MENU.BindControlToConVar = bindControlToConVar
    MENU.SetControlLocked = setControlTreeLocked
    MENU.WatchControlState = watchControlState
    MENU.BeginControlGroup = beginControlGroup

    local function addResetButton(panel, defaults, label)
        endControlGroup(panel)
        local btn = addStyledButton(panel, label or phrase("button.reset_defaults"), phrase("tooltip.reset_defaults"))
        btn.DoClick = function()
            local resetDefaults = BetterLights.ResolveClientResetDefaults(defaults)
            BetterLights.ApplyClientSettings(resetDefaults)
            notification.AddLegacy(phrase("notice.page_settings_reset"), NOTIFY_GENERIC, 3)
            surface.PlaySound("buttons/button14.wav")
        end
    end

    MENU.AddResetButton = addResetButton

    local function setupPage(panel, titleKey, subtitleKey)
        panel:Clear()
        panel.BetterLightsHasServerControlledHelp = nil
        panel.BetterLightsSkipAutoState = nil
        prepareControlContainer(panel)

        local titleLabel = vgui.Create("DLabel")
        titleLabel:SetTall(20)
        titleLabel:SetText(phrase(titleKey))
        titleLabel:SetFont("DermaDefaultBold")
        titleLabel:SetDark(true)
        panel:AddItem(titleLabel)

        if subtitleKey and subtitleKey ~= "" then
            addHelpText(panel, phrase(subtitleKey))
        end
    end

    MENU.SetupPage = setupPage

    local function addSection(panel, titleKey, subtitleKey, expanded)
        endControlGroup(panel)
        local form = vgui.Create("DForm")
        form.BetterLightsBaseName = phrase(titleKey)
        form:SetName(form.BetterLightsBaseName)
        form:SetExpanded(expanded ~= false)
        prepareControlContainer(form)

        if subtitleKey and subtitleKey ~= "" then
            addHelpText(form, phrase(subtitleKey))
        end

        panel:AddItem(form)
        return form
    end

    MENU.AddSection = addSection

    local function addRawSection(panel, title, subtitle, expanded)
        endControlGroup(panel)
        local form = vgui.Create("DForm")
        form.BetterLightsBaseName = title
        form:SetName(form.BetterLightsBaseName)
        form:SetExpanded(expanded ~= false)
        prepareControlContainer(form)

        if subtitle and subtitle ~= "" then
            addHelpText(form, subtitle)
        end

        panel:AddItem(form)
        return form
    end

    MENU.AddRawSection = addRawSection

    local function addBulkToggleSection(panel, cvarNames, titleKey, subtitleKey)
        if not istable(cvarNames) or #cvarNames == 0 then return end

        local section = addSection(
            panel,
            titleKey or "section.quick_controls",
            subtitleKey or "section.quick_controls.desc",
            true
        )
        section.BetterLightsSkipAutoState = true

        local summary = addHelpText(section, "")
        local actions = vgui.Create("DPanel")
        actions:SetTall(30)
        actions.Paint = nil

        local enableAll = styleButton(vgui.Create("DButton", actions))
        enableAll:Dock(LEFT)
        enableAll:SetText(phrase("button.enable_all"))

        local disableAll = styleButton(vgui.Create("DButton", actions))
        disableAll:Dock(FILL)
        disableAll:DockMargin(6, 0, 0, 0)
        disableAll:SetText(phrase("button.disable_all"))

        actions.PerformLayout = function(_, width)
            enableAll:SetWide(math.floor((width - 6) * 0.5))
        end
        section:AddItem(actions)

        local function refresh()
            local enabledCount = 0
            for i = 1, #cvarNames do
                if getConVarBool(cvarNames[i]) then
                    enabledCount = enabledCount + 1
                end
            end

            summary:SetText(phraseFormat("status.features_enabled_count", enabledCount, #cvarNames))
            enableAll:SetEnabled(enabledCount < #cvarNames)
            disableAll:SetEnabled(enabledCount > 0)
        end

        local function apply(value)
            local settings = {}
            for i = 1, #cvarNames do
                settings[cvarNames[i]] = value
            end

            BetterLights.ApplyClientSettings(settings)
            refresh()
        end

        enableAll.DoClick = function()
            apply(1)
        end
        disableAll.DoClick = function()
            apply(0)
        end

        for i = 1, #cvarNames do
            watchControlState(cvarNames[i], section, refresh)
        end

        refresh()
        return section
    end

    MENU.AddBulkToggleSection = addBulkToggleSection

    local function addModelElightControls(panel, prefix, labelKey)
        panel:CheckBox(labelKey and phrase(labelKey) or phrase("control.add_model_elight"), prefix .. "_models_elight")
        panel:NumSlider(phrase("control.model_elight_radius"), prefix .. "_models_elight_size_mult", 0, 3, 2)
    end

    local function addLightControls(panel, prefix, options)
        options = options or {}

        if options.enableLabel ~= false then
            panel:CheckBox(options.enableLabel and phrase(options.enableLabel) or phrase("control.enable"), prefix .. "_enable")
        end

        if options.radiusCvar or options.radiusLabel ~= false then
            panel:NumSlider(options.radiusLabel and phrase(options.radiusLabel) or phrase("control.radius"), options.radiusCvar or prefix .. "_size", options.radiusMin or 0, options.radiusMax or 400, options.radiusDecimals or 0)
        end

        if options.brightnessCvar or options.brightnessLabel ~= false then
            panel:NumSlider(options.brightnessLabel and phrase(options.brightnessLabel) or phrase("control.brightness"), options.brightnessCvar or prefix .. "_brightness", options.brightnessMin or 0, options.brightnessMax or 5, options.brightnessDecimals or 2)
        end

        if options.decayLabel ~= false then
            panel:NumSlider(options.decayLabel and phrase(options.decayLabel) or phrase("control.decay"), prefix .. "_decay", options.decayMin or 0, options.decayMax or 5000, options.decayDecimals or 0)
        end

        if options.modelElight then
            addModelElightControls(panel, prefix, options.modelElightLabel)
        end
    end

    MENU.AddLightControls = addLightControls

    local function addColorMixerControl(panel, labelKey, rCvar, gCvar, bCvar, defaultR, defaultG, defaultB, dependencyCvar)
        local mixer = vgui.Create("DColorMixer")
        mixer:SetTall(220)
        mixer:SetLabel(labelKey and labelKey ~= "" and phrase(labelKey) or nil)
        mixer:SetPalette(true)
        mixer:SetAlphaBar(false)
        mixer:SetWangs(true)
        mixer:SetConVarR(rCvar)
        mixer:SetConVarG(gCvar)
        mixer:SetConVarB(bCvar)

        local currentR = GetConVar(rCvar)
        local currentG = GetConVar(gCvar)
        local currentB = GetConVar(bCvar)
        mixer:SetColor(Color(
            currentR and currentR:GetInt() or getClientDefault(rCvar, defaultR or 255),
            currentG and currentG:GetInt() or getClientDefault(gCvar, defaultG or 255),
            currentB and currentB:GetInt() or getClientDefault(bCvar, defaultB or 255)
        ))

        panel:AddItem(mixer)

        local reset = styleButton(vgui.Create("DButton"))
        reset:SetTall(26)
        reset:SetText(phrase("button.reset_color"))
        reset:SetTooltip(phrase("tooltip.reset_color"))
        reset.DoClick = function()
            BetterLights.ApplyClientSetting(rCvar, getClientDefault(rCvar, defaultR or 255))
            BetterLights.ApplyClientSetting(gCvar, getClientDefault(gCvar, defaultG or 255))
            BetterLights.ApplyClientSetting(bCvar, getClientDefault(bCvar, defaultB or 255))
        end

        panel:AddItem(reset)

        if dependencyCvar then
            bindControlToConVar(mixer, dependencyCvar)
            bindControlToConVar(reset, dependencyCvar)
        end

        return mixer, reset
    end

    MENU.AddColorMixerControl = addColorMixerControl

    local function copyText(text)
        if not SetClipboardText then return end

        SetClipboardText(text)
        notification.AddLegacy(phrase("notice.copied_texture_path"), NOTIFY_GENERIC, 3)
        surface.PlaySound("buttons/button14.wav")
    end

    MENU.CopyText = copyText

    local function addCurrentTexturePreview(panel, path, titleKey)
        local preview = vgui.Create("DPanel")
        preview:SetTall(118)
        preview.Paint = nil

        local image = vgui.Create("DPanel", preview)
        image:Dock(LEFT)
        image:SetWide(112)

        local mat = Material(path)
        image.Paint = function(_, w, h)
            surface.SetDrawColor(32, 32, 32, 255)
            surface.DrawRect(8, 8, w - 16, h - 16)
            surface.SetMaterial(mat)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(18, 14, w - 36, h - 28)
        end

        local details = vgui.Create("DPanel", preview)
        details:Dock(FILL)
        details:DockMargin(8, 8, 8, 8)
        details.Paint = nil

        local title = vgui.Create("DLabel", details)
        title:Dock(TOP)
        title:SetTall(20)
        title:SetText(phrase(titleKey or "label.current_texture"))
        title:SetDark(true)

        local value = vgui.Create("DLabel", details)
        value:Dock(FILL)
        value:SetWrap(true)
        value:SetText(path)
        value:SetDark(true)

        local copy = styleButton(vgui.Create("DButton", details))
        copy:Dock(BOTTOM)
        copy:SetTall(24)
        copy:SetText(phrase("button.copy_path"))
        copy.DoClick = function()
            copyText(path)
        end

        panel:AddItem(preview)
        return preview
    end

    MENU.AddCurrentTexturePreview = addCurrentTexturePreview

    local function addTextureTile(layout, path, allowUse)
        local tile = vgui.Create("DPanel")
        tile:SetSize(132, 164)
        tile.Paint = nil

        local preview = vgui.Create("DButton", tile)
        preview:SetText("")
        preview:Dock(TOP)
        preview:SetTall(96)

        local mat = Material(path)
        preview.Paint = function(_, w, h)
            surface.SetDrawColor(32, 32, 32, 255)
            surface.DrawRect(0, 0, w, h)
            surface.SetMaterial(mat)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(18, 8, w - 36, h - 16)
        end

        preview.DoClick = function()
            if BetterLights.SetFlashlightTexturePath(path) then
                notification.AddLegacy(phrase("notice.flashlight_texture_changed"), NOTIFY_GENERIC, 3)
                surface.PlaySound("buttons/button15.wav")
            end
        end

        preview.DoRightClick = function()
            copyText(path)
        end
        preview:SetEnabled(allowUse ~= false)

        local label = vgui.Create("DLabel", tile)
        label:Dock(TOP)
        label:SetTall(36)
        label:SetWrap(true)
        label:SetText(path)
        label:SetDark(true)

        local buttons = vgui.Create("DPanel", tile)
        buttons:Dock(BOTTOM)
        buttons:SetTall(28)
        buttons.Paint = nil

        local use = styleButton(vgui.Create("DButton", buttons))
        use:Dock(LEFT)
        use:SetWide(64)
        use:SetText(phrase("button.use"))
        use.DoClick = preview.DoClick
        use:SetEnabled(allowUse ~= false)

        local copy = styleButton(vgui.Create("DButton", buttons))
        copy:Dock(RIGHT)
        copy:SetWide(64)
        copy:SetText(phrase("button.copy"))
        copy.DoClick = function()
            copyText(path)
        end

        layout:Add(tile)
    end

    local function addTextureGrid(parent, paths, allowUse)
        local layout = vgui.Create("DIconLayout")
        layout:SetSpaceX(8)
        layout:SetSpaceY(8)
        layout:SetTall(172)
        layout:SetStretchHeight(true)

        for _, path in ipairs(paths) do
            addTextureTile(layout, path, allowUse)
        end

        parent:AddItem(layout)
    end

    MENU.AddTextureGrid = addTextureGrid

    local SPILL_CUSTOM_DEPENDENCY = {
        name = "betterlights_flashlight_world_spill_match",
        expected = false
    }
    local FLASHLIGHT_CONTROL_DEPENDENCIES = {
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
        betterlights_flashlight_world_spill_brightness = SPILL_CUSTOM_DEPENDENCY,
        betterlights_flashlight_world_spill_color_r = SPILL_CUSTOM_DEPENDENCY,
        betterlights_flashlight_world_spill_color_g = SPILL_CUSTOM_DEPENDENCY,
        betterlights_flashlight_world_spill_color_b = SPILL_CUSTOM_DEPENDENCY
    }

    local function isFlashlightSettingForced(cvarName)
        return BetterLights.IsFlashlightSettingForced and BetterLights.IsFlashlightSettingForced(cvarName) or false
    end

    local function getEffectiveFlashlightBool(cvarName)
        local cvar = GetConVar(cvarName)
        local fallback = cvar and cvar:GetBool() or false

        if BetterLights.GetEffectiveFlashlightBool then
            return BetterLights.GetEffectiveFlashlightBool(cvarName, fallback)
        end

        return fallback
    end

    local function getEffectiveFlashlightNumber(cvarName)
        local cvar = GetConVar(cvarName)
        local fallback = cvar and cvar:GetFloat() or 0

        if BetterLights.GetEffectiveFlashlightNumber then
            return BetterLights.GetEffectiveFlashlightNumber(cvarName, fallback)
        end

        return fallback
    end

    local function getEffectiveFlashlightString(cvarName)
        local cvar = GetConVar(cvarName)
        local fallback = cvar and cvar:GetString() or ""

        if BetterLights.GetEffectiveFlashlightString then
            return BetterLights.GetEffectiveFlashlightString(cvarName, fallback)
        end

        return fallback
    end

    local function addServerControlledHelp(panel)
        if panel.BetterLightsHasServerControlledHelp then return end

        panel.BetterLightsHasServerControlledHelp = true
        return addStateNotice(panel, phrase("help.controlled_by_server"), true)
    end

    local function bindFlashlightDependency(control, cvarName)
        local dependency = FLASHLIGHT_CONTROL_DEPENDENCIES[cvarName]
        if not dependency then return control end

        local dependencyName = isstring(dependency) and dependency or dependency.name
        local expected = isstring(dependency) or dependency.expected ~= false
        return bindControlToConVar(control, dependencyName, function()
            return getEffectiveFlashlightBool(dependencyName) == expected
        end)
    end

    local function addFlashlightCheckbox(panel, label, cvarName)
        if not isFlashlightSettingForced(cvarName) then
            return bindFlashlightDependency(panel:CheckBox(label, cvarName), cvarName)
        end

        local row = vgui.Create("DCheckBoxLabel")
        row:SetText(phraseFormat("state.server_controlled_label", label))
        row:SetValue(getEffectiveFlashlightBool(cvarName) and 1 or 0)
        row:SizeToContents()
        row:SetTooltip(phrase("help.controlled_by_server"))
        setControlTreeLocked(row, true)
        panel:AddItem(row)
        addServerControlledHelp(panel)

        if not panel.BetterLightsHasFeatureGroup and string.EndsWith(cvarName, "_enable") then
            beginControlGroup(panel, cvarName, function()
                return getEffectiveFlashlightBool(cvarName)
            end, {
                disabledHelpKey = "state.feature_disabled_by_server",
                disabledTitleKey = "state.section_disabled_by_server",
                highlighted = true
            })
        end

        bindFlashlightDependency(row, cvarName)
        return row
    end

    local function addFlashlightSlider(panel, label, cvarName, minimum, maximum, decimals)
        if not isFlashlightSettingForced(cvarName) then
            return bindFlashlightDependency(
                panel:NumSlider(label, cvarName, minimum, maximum, decimals),
                cvarName
            )
        end

        local slider = vgui.Create("DNumSlider")
        slider:SetText(phraseFormat("state.server_controlled_label", label))
        slider:SetMinMax(minimum, maximum)
        slider:SetDecimals(decimals)
        slider:SetValue(getEffectiveFlashlightNumber(cvarName))
        slider:SetTooltip(phrase("help.controlled_by_server"))
        setControlTreeLocked(slider, true)
        panel:AddItem(slider)
        addServerControlledHelp(panel)
        bindFlashlightDependency(slider, cvarName)
        return slider
    end

    local function addFlashlightColorMixer(panel, labelKey, rCvar, gCvar, bCvar, defaultR, defaultG, defaultB)
        local forced = isFlashlightSettingForced(rCvar)
            or isFlashlightSettingForced(gCvar)
            or isFlashlightSettingForced(bCvar)

        if not forced then
            local mixer, reset = addColorMixerControl(
                panel,
                labelKey,
                rCvar,
                gCvar,
                bCvar,
                defaultR or 255,
                defaultG or 245,
                defaultB or 225
            )
            bindFlashlightDependency(mixer, rCvar)
            bindFlashlightDependency(reset, rCvar)
            return mixer
        end

        local mixer = vgui.Create("DColorMixer")
        mixer:SetTall(220)
        mixer:SetLabel(phraseFormat("state.server_controlled_label", phrase(labelKey)))
        mixer:SetPalette(true)
        mixer:SetAlphaBar(false)
        mixer:SetWangs(true)
        mixer:SetColor(Color(
            getEffectiveFlashlightNumber(rCvar),
            getEffectiveFlashlightNumber(gCvar),
            getEffectiveFlashlightNumber(bCvar)
        ))
        mixer:SetTooltip(phrase("help.controlled_by_server"))
        setControlTreeLocked(mixer, true)
        panel:AddItem(mixer)
        addServerControlledHelp(panel)
        bindFlashlightDependency(mixer, rCvar)
        return mixer
    end

    local function addFlashlightResetButton(panel, defaults, label)
        local resettable = {}
        local forcedColorGroups = {}

        for i = 1, #BetterLights.FLASHLIGHT_SETTING_DEFS do
            local def = BetterLights.FLASHLIGHT_SETTING_DEFS[i]
            if def.colorChannel and isFlashlightSettingForced(def.name) then
                forcedColorGroups[def.colorGroup or "flashlight"] = true
            end
        end

        for cvarName, value in pairs(defaults) do
            local def = BetterLights.FLASHLIGHT_SETTING_BY_NAME[cvarName]
            local colorForced = def
                and def.colorChannel
                and forcedColorGroups[def.colorGroup or "flashlight"]

            if not isFlashlightSettingForced(cvarName) and not colorForced then
                resettable[cvarName] = value
            end
        end

        local btn = addStyledButton(panel, label or phrase("button.reset_defaults"), phrase("tooltip.reset_defaults"))
        btn:SetEnabled(next(resettable) ~= nil)
        btn.DoClick = function()
            BetterLights.ApplyClientSettings(BetterLights.ResolveClientResetDefaults(resettable))
            notification.AddLegacy(phrase("notice.page_settings_reset"), NOTIFY_GENERIC, 3)
            surface.PlaySound("buttons/button14.wav")
        end
        return btn
    end

    MENU.IsFlashlightSettingForced = isFlashlightSettingForced
    MENU.GetEffectiveFlashlightBool = getEffectiveFlashlightBool
    MENU.GetEffectiveFlashlightNumber = getEffectiveFlashlightNumber
    MENU.GetEffectiveFlashlightString = getEffectiveFlashlightString
    MENU.AddServerControlledHelp = addServerControlledHelp
    MENU.AddFlashlightCheckbox = addFlashlightCheckbox
    MENU.AddFlashlightSlider = addFlashlightSlider
    MENU.AddFlashlightColorMixer = addFlashlightColorMixer
    MENU.AddFlashlightResetButton = addFlashlightResetButton

    hook.Add("BetterLights_ServerSettingsChanged", "BetterLights_RefreshForcedSettingsMenu", function()
        MENU.RefreshSettingsPanel()
    end)

    hook.Add("BetterLights_ClientEnabledChangeBlocked", "BetterLights_NotifyClientEnableBlocked", function()
        notification.AddLegacy(phrase("notice.client_enable_controlled_by_server"), NOTIFY_ERROR, 4)
        surface.PlaySound("buttons/button10.wav")
    end)
end
