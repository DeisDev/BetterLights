if CLIENT then
    local SPAWNMENU_TAB_ID = "Utilities"
    local SPAWNMENU_CATEGORY_ID = "BetterLights"
    BetterLights.Menu = BetterLights.Menu or {}
    local MENU = BetterLights.Menu
    local registeredPages = {}
    local registeredPagesById = {}
    local registeringPages = false
    local addClientPanels

    local function isDeveloperMode()
        local developer = GetConVar("developer")
        return developer and developer:GetInt() >= 1
    end

    local CATEGORY_DEFS = {
        { "General", "category.general", icon = "icon16/cog.png" },
        { "Appearance", "category.appearance", icon = "icon16/application_view_tile.png" },
        { "Profiles", "category.profiles", icon = "icon16/disk.png" },
        { "Flashlight", "category.flashlight", icon = "icon16/lightbulb.png" },
        { "Weapons", "category.weapons", icon = "icon16/gun.png" },
        { "Gunfire", "category.gunfire", icon = "icon16/bomb.png" },
        { "Projectiles", "category.projectiles", icon = "icon16/bullet_go.png" },
        { "NPCs", "category.npcs", icon = "icon16/group.png" },
        { "Eye Glow", "category.eye_glow", icon = "icon16/eye.png" },
        { "Environment", "category.environment", icon = "icon16/world.png" },
        { "Pickups", "category.pickups", icon = "icon16/box.png" },
        { "Integrations", "category.integrations", icon = "icon16/plugin.png" },
        { "Admin", "category.admin", icon = "icon16/shield.png" },
        { "Developer", "category.developer", icon = "icon16/wrench.png", developer = true },
        { "About", "category.about", icon = "icon16/information.png" }
    }

    local function phrase(key)
        return language.GetPhrase("betterlights." .. key)
    end

    local function phraseFormat(key, ...)
        return string.format(phrase(key), ...)
    end

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

    MENU.Phrase = phrase
    MENU.PhraseFormat = phraseFormat
    MENU.StyleButton = styleButton
    MENU.AddStyledButton = addStyledButton
    MENU.IsDeveloperMode = isDeveloperMode

    local function inferPageDescriptionKey(titleKey)
        local pageKey = string.match(titleKey, "^(page%..+)%.title$")
        if pageKey then return pageKey .. ".desc" end

        local menuKey = string.match(titleKey, "^menu%.(.+)$")
        if menuKey then return "page." .. menuKey .. ".desc" end
    end

    function MENU.RegisterPage(category, id, titleKey, buildPanel, descriptionKey)
        if not (isstring(category) and isstring(id) and isstring(titleKey) and isfunction(buildPanel)) then return end

        local page = registeredPagesById[id]
        if page then
            page.category = category
            page.titleKey = titleKey
            page.buildPanel = buildPanel
            page.descriptionKey = descriptionKey or inferPageDescriptionKey(titleKey)
            return page
        end

        page = {
            category = category,
            id = id,
            titleKey = titleKey,
            buildPanel = buildPanel,
            descriptionKey = descriptionKey or inferPageDescriptionKey(titleKey)
        }
        registeredPagesById[id] = page
        registeredPages[#registeredPages + 1] = page
        return page
    end

    function MENU.RefreshSettingsPanel()
        timer.Simple(0, function()
            MENU.RefreshSettingsWindow()
        end)
    end

    function MENU.GetCategoryDefinitions()
        return CATEGORY_DEFS
    end

    function MENU.EnsurePagesRegistered()
        if registeringPages then return registeredPages end

        registeringPages = true
        MENU.RegisterGeneralPanel()
        MENU.RegisterAppearancePanel()
        MENU.RegisterGunfirePanels()
        MENU.RegisterWeaponPanels()
        addClientPanels()
        MENU.RegisterNPCLightPanels()
        MENU.RegisterIntegrationPanels()
        MENU.RegisterDeveloperPanel()
        MENU.RegisterAboutPanel()
        registeringPages = false

        return registeredPages
    end

    function MENU.GetRegisteredPages()
        return MENU.EnsurePagesRegistered()
    end

    function MENU.GetRegisteredPage(id)
        MENU.EnsurePagesRegistered()
        return registeredPagesById[id]
    end

    local function registerPage(category, id, titleKey, buildPanel, descriptionKey)
        MENU.RegisterPage(category, id, titleKey, buildPanel, descriptionKey)
    end

    local function registerCategories()
        spawnmenu.AddToolCategory(SPAWNMENU_TAB_ID, SPAWNMENU_CATEGORY_ID, phrase("addon.name"))
    end

    local function buildAboutPanel(panel)
        local page = MENU.GetRegisteredPage("BL_About")
        if not page then return end

        page.buildPanel(panel)
    end

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

    local populateFlashlightVisualPanel
    local activeFlashlightVisualPanel
    local activeFlashlightVisualFilter
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
    MENU.GetEffectiveFlashlightString = getEffectiveFlashlightString
    MENU.AddFlashlightCheckbox = addFlashlightCheckbox
    MENU.AddFlashlightSlider = addFlashlightSlider
    MENU.AddFlashlightColorMixer = addFlashlightColorMixer
    MENU.AddFlashlightResetButton = addFlashlightResetButton

    populateFlashlightVisualPanel = function(panel, filterText)
        setupPage(panel, "page.flashlight_visuals.title", "page.flashlight_visuals.desc")
        activeFlashlightVisualPanel = panel
        activeFlashlightVisualFilter = filterText

        local beam = addSection(panel, "section.beam", "section.beam.desc", true)
        addFlashlightCheckbox(beam, phrase("control.cast_shadows"), "betterlights_flashlight_shadows")
        addFlashlightCheckbox(beam, phrase("control.flicker"), "betterlights_flashlight_flicker")
        addFlashlightSlider(beam, phrase("control.flicker_amount"), "betterlights_flashlight_flicker_amount", 0, 0.3, 2)
        addFlashlightCheckbox(beam, phrase("control.flashlight_sway"), "betterlights_flashlight_sway")
        addFlashlightSlider(beam, phrase("control.sway_intensity"), "betterlights_flashlight_sway_intensity", 0, 3, 2)
        addFlashlightSlider(beam, phrase("control.brightness"), "betterlights_flashlight_brightness", 0.1, 5, 2)
        addFlashlightSlider(beam, phrase("control.fov"), "betterlights_flashlight_fov", 10, 120, 0)
        addFlashlightSlider(beam, phrase("control.beam_length"), "betterlights_flashlight_distance", 128, 4096, 0)

        local advancedShadows = addSection(panel, "section.advanced_shadows", "section.advanced_shadows.desc", false)
        local shadowsForced = isFlashlightSettingForced("betterlights_flashlight_shadows")
        beginControlGroup(advancedShadows, "betterlights_flashlight_shadows", function()
            return getEffectiveFlashlightBool("betterlights_flashlight_shadows")
        end, shadowsForced and {
            disabledHelpKey = "state.feature_disabled_by_server",
            disabledTitleKey = "state.section_disabled_by_server",
            highlighted = true
        } or nil)
        addHelpText(advancedShadows, phrase("help.advanced_shadow_settings"))
        addFlashlightSlider(advancedShadows, phrase("control.shadow_depth_bias"), "betterlights_flashlight_shadow_depth_bias", 0, 0.005, 5)
        addFlashlightSlider(advancedShadows, phrase("control.shadow_slope_scale_depth_bias"), "betterlights_flashlight_shadow_slope_scale_depth_bias", 0, 8, 2)
        addFlashlightSlider(advancedShadows, phrase("control.shadow_filter"), "betterlights_flashlight_shadow_filter", 0, 4, 2)

        local flare = addSection(panel, "section.flare", "section.flare.desc", true)
        addFlashlightCheckbox(flare, phrase("control.flashlight_flare"), "betterlights_flashlight_flare_enable")
        addFlashlightCheckbox(flare, phrase("control.show_other_flashlight_flares"), "betterlights_flashlight_flare_others")
        addHelpText(flare, phrase("help.show_other_flashlight_flares"))
        addFlashlightSlider(flare, phrase("control.flare_size"), "betterlights_flashlight_flare_size", 0.25, 3, 2)
        addFlashlightSlider(flare, phrase("control.flare_opacity"), "betterlights_flashlight_flare_opacity", 0, 255, 0)

        local colorSection = addSection(panel, "section.color", "section.color.desc", true)
        addFlashlightColorMixer(colorSection, "control.flashlight_color", "betterlights_flashlight_color_r", "betterlights_flashlight_color_g", "betterlights_flashlight_color_b")

        local texture = addSection(panel, "section.texture", "section.texture.desc", true)

        local currentCvar = GetConVar("betterlights_flashlight_texture")
        local textureForced = isFlashlightSettingForced("betterlights_flashlight_texture")
        local typedPath = textureForced and getEffectiveFlashlightString("betterlights_flashlight_texture")
            or (currentCvar and currentCvar:GetString() or "effects/flashlight001")
        local currentPath = BetterLights.GetFlashlightTexturePath()

        addHelpText(texture, phraseFormat("help.current_texture", currentPath))
        if textureForced then
            addServerControlledHelp(texture)
        end
        addCurrentTexturePreview(texture, currentPath)

        local manualEntry = vgui.Create("DTextEntry")
        manualEntry:SetText(typedPath)
        manualEntry:SetUpdateOnType(false)
        manualEntry:SetEnabled(not textureForced)
        texture:AddItem(manualEntry)

        local manualButtons = vgui.Create("DPanel")
        manualButtons:SetTall(28)
        manualButtons.Paint = nil

        local useManual = styleButton(vgui.Create("DButton", manualButtons))
        useManual:Dock(LEFT)
        useManual:SetWide(76)
        useManual:SetText(phrase("button.use"))
        useManual:SetEnabled(not textureForced)
        useManual.DoClick = function()
            local path = BetterLights.NormalizeFlashlightTexturePath(manualEntry:GetText())
            if BetterLights.SetFlashlightTexturePath(path) then
                notification.AddLegacy(phrase("notice.flashlight_texture_changed"), NOTIFY_GENERIC, 3)
                surface.PlaySound("buttons/button15.wav")
                return
            end

            notification.AddLegacy(phrase("notice.texture_not_found"), NOTIFY_ERROR, 4)
            surface.PlaySound("buttons/button10.wav")
        end

        local copyCurrent = styleButton(vgui.Create("DButton", manualButtons))
        copyCurrent:Dock(LEFT)
        copyCurrent:DockMargin(6, 0, 0, 0)
        copyCurrent:SetWide(76)
        copyCurrent:SetText(phrase("button.copy"))
        copyCurrent.DoClick = function()
            copyText(currentPath)
        end

        local useDefault = styleButton(vgui.Create("DButton", manualButtons))
        useDefault:Dock(LEFT)
        useDefault:DockMargin(6, 0, 0, 0)
        useDefault:SetWide(76)
        useDefault:SetText(phrase("button.default"))
        useDefault:SetEnabled(not textureForced)
        useDefault.DoClick = function()
            BetterLights.SetFlashlightTexturePath("effects/flashlight001")
        end

        texture:AddItem(manualButtons)

        local recent = BetterLights.GetFlashlightRecentTextures()
        if #recent > 0 then
            local recentSection = addSection(panel, "section.recent_textures", nil, false)
            addTextureGrid(recentSection, recent, not textureForced)

            local clearRecent = addStyledButton(recentSection, phrase("button.clear_recent_textures"))
            clearRecent.DoClick = function()
                BetterLights.ClearFlashlightRecentTextures()

                populateFlashlightVisualPanel(panel, filterText)
            end
        end

        local knownSection = addSection(panel, "section.known_textures", "section.known_textures.desc", false)

        local refreshTextures = addStyledButton(knownSection, phrase("button.refresh_textures"))
        refreshTextures.DoClick = function()
            BetterLights.ClearFlashlightKnownTextureCache()

            populateFlashlightVisualPanel(panel, filterText)
        end

        local filterRow = vgui.Create("DPanel")
        filterRow:SetTall(28)
        filterRow.Paint = nil

        local filter = vgui.Create("DTextEntry", filterRow)
        filter:Dock(FILL)
        filter:SetPlaceholderText(phrase("placeholder.search_texture_paths"))
        filter:SetText(filterText or "")

        local applyFilter = styleButton(vgui.Create("DButton", filterRow))
        applyFilter:Dock(RIGHT)
        applyFilter:SetWide(72)
        applyFilter:SetText(phrase("button.search"))
        applyFilter.DoClick = function()
            populateFlashlightVisualPanel(panel, filter:GetText())
        end

        filter.OnEnter = applyFilter.DoClick
        knownSection:AddItem(filterRow)

        local known = BetterLights.GetFlashlightKnownTextures()
        local filtered = {}
        local needle = string.lower(string.Trim(filterText or ""))

        for _, path in ipairs(known) do
            if needle == "" or string.find(string.lower(path), needle, 1, true) then
                filtered[#filtered + 1] = path
            end
        end

        if #filtered > 0 then
            addTextureGrid(knownSection, filtered, not textureForced)
        else
            addHelpText(knownSection, phrase("help.no_matching_textures"))
        end

        addFlashlightResetButton(panel, {
            betterlights_flashlight_brightness = 1.35,
            betterlights_flashlight_fov = 45,
            betterlights_flashlight_distance = 1200,
            betterlights_flashlight_shadows = 1,
            betterlights_flashlight_flicker = 0,
            betterlights_flashlight_flicker_amount = 0.05,
            betterlights_flashlight_sway = 1,
            betterlights_flashlight_sway_intensity = 1,
            betterlights_flashlight_flare_enable = 1,
            betterlights_flashlight_flare_others = 1,
            betterlights_flashlight_flare_size = 1,
            betterlights_flashlight_flare_opacity = 90,
            betterlights_flashlight_shadow_depth_bias = 0.001,
            betterlights_flashlight_shadow_slope_scale_depth_bias = 4,
            betterlights_flashlight_shadow_filter = 1.25,
            betterlights_flashlight_color_r = 255,
            betterlights_flashlight_color_g = 245,
            betterlights_flashlight_color_b = 225,
            betterlights_flashlight_texture = "effects/flashlight001",
        }, phrase("button.reset_visual_settings"))
    end

    cvars.AddChangeCallback("betterlights_flashlight_texture", function()
        timer.Simple(0, function()
            if not IsValid(activeFlashlightVisualPanel) then return end
            populateFlashlightVisualPanel(activeFlashlightVisualPanel, activeFlashlightVisualFilter)
        end)
    end, "BetterLights_FlashlightVisualRefresh")

    hook.Add("BetterLights_ServerSettingsChanged", "BetterLights_RefreshForcedSettingsMenu", function()
        MENU.RefreshSettingsPanel()
    end)

    hook.Add("BetterLights_ClientEnabledChangeBlocked", "BetterLights_NotifyClientEnableBlocked", function()
        notification.AddLegacy(phrase("notice.client_enable_controlled_by_server"), NOTIFY_ERROR, 4)
        surface.PlaySound("buttons/button10.wav")
    end)

    local function addWorldWeaponPanel(panel)
        setupPage(panel, "page.world_weapons.title", "page.world_weapons.desc")
        local resetDefaults = {}

        local defs = BetterLights.GetWorldWeaponLightDefinitions()
        local enableCvars = {}

        for _, info in ipairs(defs) do
            enableCvars[#enableCvars + 1] = "betterlights_world_weapon_" .. info.slug .. "_enable"
        end

        addBulkToggleSection(panel, enableCvars)

        for _, info in ipairs(defs) do
            local prefix = "betterlights_world_weapon_" .. info.slug
            local form = info.nameKey and addSection(panel, info.nameKey, nil, false) or addRawSection(panel, info.name, nil, false)
            addLightControls(form, prefix, {
                radiusMax = 300,
                brightnessMax = 2,
                modelElight = true,
                modelElightLabel = "control.add_model_elight"
            })

            addColorMixerControl(form, "control.color", prefix .. "_color_r", prefix .. "_color_g", prefix .. "_color_b", info.r, info.g, info.b)

            resetDefaults[prefix .. "_enable"] = 1
            resetDefaults[prefix .. "_size"] = info.size
            resetDefaults[prefix .. "_brightness"] = info.brightness
            resetDefaults[prefix .. "_decay"] = info.decay
            resetDefaults[prefix .. "_models_elight"] = info.elight
            resetDefaults[prefix .. "_models_elight_size_mult"] = info.elightMult
            resetDefaults[prefix .. "_color_r"] = info.r
            resetDefaults[prefix .. "_color_g"] = info.g
            resetDefaults[prefix .. "_color_b"] = info.b
        end

        addResetButton(panel, resetDefaults)
    end

    local function addAmmoPickupPanel(panel)
        setupPage(panel, "page.ammo_pickups.title", "page.ammo_pickups.desc")

        local resetDefaults = {}
        local defs = BetterLights.GetAmmoPickupLightDefinitions()
        local enableCvars = {}

        for _, info in ipairs(defs) do
            enableCvars[#enableCvars + 1] = "betterlights_ammo_" .. info.slug .. "_enable"
        end

        addBulkToggleSection(panel, enableCvars, "section.ammo_quick_controls", "section.ammo_quick_controls.desc")

        for _, info in ipairs(defs) do
            local prefix = "betterlights_ammo_" .. info.slug
            local form = info.nameKey and addSection(panel, info.nameKey, nil, false)
                or addRawSection(panel, info.name, nil, false)
            addLightControls(form, prefix, {
                radiusMax = 300,
                brightnessMax = 2,
                modelElight = true,
                modelElightLabel = "control.add_model_elight"
            })
            addColorMixerControl(form, "control.color", prefix .. "_color_r", prefix .. "_color_g", prefix .. "_color_b", info.r, info.g, info.b)

            resetDefaults[prefix .. "_enable"] = info.enable
            resetDefaults[prefix .. "_size"] = info.size
            resetDefaults[prefix .. "_brightness"] = info.brightness
            resetDefaults[prefix .. "_decay"] = info.decay
            resetDefaults[prefix .. "_models_elight"] = info.elight
            resetDefaults[prefix .. "_models_elight_size_mult"] = info.elightMult
            resetDefaults[prefix .. "_color_r"] = info.r
            resetDefaults[prefix .. "_color_g"] = info.g
            resetDefaults[prefix .. "_color_b"] = info.b
        end

        addResetButton(panel, resetDefaults)
    end

    local COMBINE_EYE_GLOW_DEFAULTS = {
        {
            titleKey = "combine_eye.elite",
            subtitleKey = "combine_eye.elite.desc",
            prefix = "bl_combine_soldier_elite",
            size = 40,
            brightness = 0.5,
            decay = 1500,
            r = 255,
            g = 72,
            b = 72
        },
        {
            titleKey = "combine_eye.prison_yellow",
            subtitleKey = "combine_eye.prison_yellow.desc",
            prefix = "bl_combine_soldier_prisonguard_yellow",
            size = 40,
            brightness = 0.5,
            decay = 1500,
            r = 255,
            g = 220,
            b = 70
        },
        {
            titleKey = "combine_eye.prison_red",
            subtitleKey = "combine_eye.prison_red.desc",
            prefix = "bl_combine_soldier_prisonguard_red",
            size = 40,
            brightness = 0.5,
            decay = 1500,
            r = 255,
            g = 72,
            b = 72
        },
        {
            titleKey = "combine_eye.standard_blue",
            subtitleKey = "combine_eye.standard_blue.desc",
            prefix = "bl_combine_soldier_standard_blue",
            size = 40,
            brightness = 0.5,
            decay = 1500,
            r = 95,
            g = 150,
            b = 255
        },
        {
            titleKey = "combine_eye.standard_orange",
            subtitleKey = "combine_eye.standard_orange.desc",
            prefix = "bl_combine_soldier_standard_orange",
            size = 40,
            brightness = 0.5,
            decay = 1500,
            r = 255,
            g = 155,
            b = 48
        }
    }

    local function addCombineEyeGlowPanel(panel)
        setupPage(panel, "page.combine_eye.title", "page.combine_eye.desc")

        local resetDefaults = {}
        local enableCvars = {}

        for _, info in ipairs(COMBINE_EYE_GLOW_DEFAULTS) do
            enableCvars[#enableCvars + 1] = info.prefix .. "_enable"
        end

        addBulkToggleSection(panel, enableCvars)

        for _, info in ipairs(COMBINE_EYE_GLOW_DEFAULTS) do
            local prefix = info.prefix
            local form = addSection(panel, info.titleKey, info.subtitleKey, false)
            addLightControls(form, prefix, {
                radiusMax = 200
            })
            addColorMixerControl(form, "control.color", prefix .. "_color_r", prefix .. "_color_g", prefix .. "_color_b", info.r, info.g, info.b)

            resetDefaults[prefix .. "_enable"] = 1
            resetDefaults[prefix .. "_size"] = info.size
            resetDefaults[prefix .. "_brightness"] = info.brightness
            resetDefaults[prefix .. "_decay"] = info.decay
            resetDefaults[prefix .. "_color_r"] = info.r
            resetDefaults[prefix .. "_color_g"] = info.g
            resetDefaults[prefix .. "_color_b"] = info.b
        end

        addResetButton(panel, resetDefaults)
    end

    local function addRollerminePanel(panel)
        setupPage(panel, "page.rollermines.title", "page.rollermines.desc")

        addBulkToggleSection(panel, {
            "betterlights_rollermine_enable",
            "betterlights_rollermine_hacked_enable"
        })

        local standard = addSection(
            panel,
            "section.rollermine_standard",
            "section.rollermine_standard.desc",
            true
        )
        addLightControls(standard, "betterlights_rollermine", {
            radiusMax = 400,
            modelElight = true,
            modelElightLabel = "control.add_model_elight"
        })
        addColorMixerControl(
            standard,
            "rollermine.default",
            "betterlights_rollermine_color_r",
            "betterlights_rollermine_color_g",
            "betterlights_rollermine_color_b",
            110,
            190,
            255
        )
        local hacked = addSection(
            panel,
            "section.rollermine_hacked",
            "section.rollermine_hacked.desc",
            true
        )
        addLightControls(hacked, "betterlights_rollermine_hacked", {
            radiusMax = 400,
            modelElight = true,
            modelElightLabel = "control.add_model_elight"
        })
        addColorMixerControl(
            hacked,
            "rollermine.hacked",
            "betterlights_rollermine_skin1_color_r",
            "betterlights_rollermine_skin1_color_g",
            "betterlights_rollermine_skin1_color_b",
            255,
            220,
            60
        )
        addColorMixerControl(
            hacked,
            "rollermine.power_down",
            "betterlights_rollermine_skin2_color_r",
            "betterlights_rollermine_skin2_color_g",
            "betterlights_rollermine_skin2_color_b",
            255,
            80,
            80
        )

        addResetButton(panel, {
            betterlights_rollermine_enable = 1,
            betterlights_rollermine_size = 110,
            betterlights_rollermine_brightness = 0.6,
            betterlights_rollermine_decay = 2000,
            betterlights_rollermine_models_elight = 1,
            betterlights_rollermine_models_elight_size_mult = 1.0,
            betterlights_rollermine_hacked_enable = 1,
            betterlights_rollermine_hacked_size = 110,
            betterlights_rollermine_hacked_brightness = 0.6,
            betterlights_rollermine_hacked_decay = 2000,
            betterlights_rollermine_hacked_models_elight = 1,
            betterlights_rollermine_hacked_models_elight_size_mult = 1.0,
            betterlights_rollermine_color_r = 110,
            betterlights_rollermine_color_g = 190,
            betterlights_rollermine_color_b = 255,
            betterlights_rollermine_skin1_color_r = 255,
            betterlights_rollermine_skin1_color_g = 220,
            betterlights_rollermine_skin1_color_b = 60,
            betterlights_rollermine_skin2_color_r = 255,
            betterlights_rollermine_skin2_color_g = 80,
            betterlights_rollermine_skin2_color_b = 80,
        })
    end

    local function addAntlionPanel(panel)
        setupPage(panel, "page.antlions.title", "page.antlions.desc")

        local grub = addSection(panel, "page.antlion_grub.title", "page.antlion_grub.desc", true)
        grub:CheckBox(phrase("control.enable"), "betterlights_antlion_grub_enable")
        grub:NumSlider(phrase("control.radius"), "betterlights_antlion_grub_size", 0, 400, 0)
        grub:NumSlider(phrase("control.brightness"), "betterlights_antlion_grub_brightness", 0, 5, 2)
        grub:NumSlider(phrase("control.decay"), "betterlights_antlion_grub_decay", 0, 5000, 0)
        addColorMixerControl(grub, "control.color", "betterlights_antlion_grub_color_r", "betterlights_antlion_grub_color_g", "betterlights_antlion_grub_color_b")

        local squashedGrub = addSection(panel, "section.squashed_body_glow", nil, false)
        squashedGrub:CheckBox(phrase("control.enable"), "betterlights_antlion_grub_squashed_enable")
        squashedGrub:NumSlider(phrase("control.radius"), "betterlights_antlion_grub_squashed_size", 0, 200, 0)
        squashedGrub:NumSlider(phrase("control.brightness"), "betterlights_antlion_grub_squashed_brightness", 0, 1, 2)
        squashedGrub:NumSlider(phrase("control.decay"), "betterlights_antlion_grub_squashed_decay", 0, 5000, 0)

        local guardian = addSection(panel, "page.antlion_guardian.title", "page.antlion_guardian.desc", true)
        guardian:CheckBox(phrase("control.enable"), "betterlights_antlion_guardian_enable")
        guardian:NumSlider(phrase("control.radius"), "betterlights_antlion_guardian_size", 0, 800, 0)
        guardian:NumSlider(phrase("control.brightness"), "betterlights_antlion_guardian_brightness", 0, 5, 2)
        guardian:NumSlider(phrase("control.decay"), "betterlights_antlion_guardian_decay", 0, 5000, 0)
        addColorMixerControl(guardian, "control.color", "betterlights_antlion_guardian_color_r", "betterlights_antlion_guardian_color_g", "betterlights_antlion_guardian_color_b")

        local worker = addSection(panel, "page.antlion_worker.title", "page.antlion_worker.desc", true)
        worker:CheckBox(phrase("control.enable"), "betterlights_antlion_worker_enable")
        worker:NumSlider(phrase("control.radius"), "betterlights_antlion_worker_size", 0, 800, 0)
        worker:NumSlider(phrase("control.brightness"), "betterlights_antlion_worker_brightness", 0, 5, 2)
        worker:NumSlider(phrase("control.decay"), "betterlights_antlion_worker_decay", 0, 5000, 0)
        addColorMixerControl(worker, "control.color", "betterlights_antlion_worker_color_r", "betterlights_antlion_worker_color_g", "betterlights_antlion_worker_color_b")

        local spitGlow = addSection(panel, "section.spit_projectile", "section.spit_projectile.desc", true)
        spitGlow:CheckBox(phrase("control.enable_glow"), "betterlights_antlion_spit_enable")
        spitGlow:NumSlider(phrase("control.radius"), "betterlights_antlion_spit_size", 0, 400, 0)
        spitGlow:NumSlider(phrase("control.brightness"), "betterlights_antlion_spit_brightness", 0, 5, 2)
        spitGlow:NumSlider(phrase("control.decay"), "betterlights_antlion_spit_decay", 0, 5000, 0)
        addColorMixerControl(spitGlow, "control.glow_color", "betterlights_antlion_spit_color_r", "betterlights_antlion_spit_color_g", "betterlights_antlion_spit_color_b")

        local spitFlash = addSection(panel, "section.impact_flash", nil, true)
        spitFlash:CheckBox(phrase("control.flash_on_impact"), "betterlights_antlion_spit_flash_enable")
        spitFlash:NumSlider(phrase("control.radius"), "betterlights_antlion_spit_flash_size", 0, 800, 0)
        spitFlash:NumSlider(phrase("control.brightness"), "betterlights_antlion_spit_flash_brightness", 0, 10, 2)
        spitFlash:NumSlider(phrase("control.duration"), "betterlights_antlion_spit_flash_time", 0, 1, 2)
        addColorMixerControl(spitFlash, "control.flash_color", "betterlights_antlion_spit_flash_color_r", "betterlights_antlion_spit_flash_color_g", "betterlights_antlion_spit_flash_color_b")

        addResetButton(panel, {
            betterlights_antlion_grub_enable = 1,
            betterlights_antlion_grub_size = 70,
            betterlights_antlion_grub_brightness = 0.35,
            betterlights_antlion_grub_decay = 2000,
            betterlights_antlion_grub_color_r = 120,
            betterlights_antlion_grub_color_g = 255,
            betterlights_antlion_grub_color_b = 120,
            betterlights_antlion_grub_squashed_enable = 1,
            betterlights_antlion_grub_squashed_size = 42,
            betterlights_antlion_grub_squashed_brightness = 0.08,
            betterlights_antlion_grub_squashed_decay = 2000,
            betterlights_antlion_guardian_enable = 1,
            betterlights_antlion_guardian_size = 180,
            betterlights_antlion_guardian_brightness = 0.6,
            betterlights_antlion_guardian_decay = 2000,
            betterlights_antlion_guardian_color_r = 120,
            betterlights_antlion_guardian_color_g = 255,
            betterlights_antlion_guardian_color_b = 140,
            betterlights_antlion_worker_enable = 1,
            betterlights_antlion_worker_size = 120,
            betterlights_antlion_worker_brightness = 0.55,
            betterlights_antlion_worker_decay = 2000,
            betterlights_antlion_worker_color_r = 180,
            betterlights_antlion_worker_color_g = 240,
            betterlights_antlion_worker_color_b = 120,
            betterlights_antlion_spit_enable = 1,
            betterlights_antlion_spit_size = 100,
            betterlights_antlion_spit_brightness = 1.0,
            betterlights_antlion_spit_decay = 1800,
            betterlights_antlion_spit_color_r = 120,
            betterlights_antlion_spit_color_g = 255,
            betterlights_antlion_spit_color_b = 140,
            betterlights_antlion_spit_flash_enable = 1,
            betterlights_antlion_spit_flash_size = 160,
            betterlights_antlion_spit_flash_brightness = 1.5,
            betterlights_antlion_spit_flash_time = 1.0,
            betterlights_antlion_spit_flash_color_r = 180,
            betterlights_antlion_spit_flash_color_g = 255,
            betterlights_antlion_spit_flash_color_b = 120,
        })
    end

    addClientPanels = function()
        registerPage("Projectiles", "BL_CombineBall", "menu.combine_ball", function(panel)
            setupPage(panel, "page.combine_ball.title", "page.combine_ball.desc")
            panel:CheckBox(phrase("control.enable"), "betterlights_combineball_enable")
            panel:NumSlider(phrase("control.radius"), "betterlights_combineball_size", 0, 800, 0)
            panel:NumSlider(phrase("control.brightness"), "betterlights_combineball_brightness", 0, 10, 2)
            panel:NumSlider(phrase("control.decay"), "betterlights_combineball_decay", 0, 5000, 0)
            addColorMixerControl(panel, "control.color", "betterlights_combineball_color_r", "betterlights_combineball_color_g", "betterlights_combineball_color_b")

            local targets = addSection(panel, "section.lighting_targets", "section.lighting_targets.desc", false)
            targets.BetterLightsSkipAutoState = true
            targets:CheckBox(phrase("control.light_world"), "betterlights_combineball_world_light_enable")
            targets:CheckBox(phrase("control.light_models"), "betterlights_combineball_model_light_enable")
            targets:CheckBox(phrase("control.use_entity_light_for_models"), "betterlights_combineball_models_elight")
            targets:NumSlider(phrase("control.model_elight_radius"), "betterlights_combineball_models_elight_size_mult", 0, 3, 2)

            addResetButton(panel, {
                betterlights_combineball_enable = 1,
                betterlights_combineball_size = 320,
                betterlights_combineball_brightness = 2.5,
                betterlights_combineball_decay = 2000,
                betterlights_combineball_world_light_enable = 1,
                betterlights_combineball_model_light_enable = 1,
                betterlights_combineball_models_elight = 0,
                betterlights_combineball_models_elight_size_mult = 1.0,
                betterlights_combineball_color_r = 80,
                betterlights_combineball_color_g = 180,
                betterlights_combineball_color_b = 255,
            })
        end)

    registerPage("Projectiles", "BL_Bolt", "menu.crossbow_bolt", function(panel)
            setupPage(panel, "page.crossbow_bolt.title", "page.crossbow_bolt.desc")
            panel:CheckBox(phrase("control.enable"), "betterlights_bolt_enable")
            panel:NumSlider(phrase("control.radius"), "betterlights_bolt_size", 0, 800, 0)
            panel:NumSlider(phrase("control.brightness"), "betterlights_bolt_brightness", 0, 10, 2)
            panel:NumSlider(phrase("control.decay"), "betterlights_bolt_decay", 0, 5000, 0)
            addColorMixerControl(panel, "control.color", "betterlights_bolt_color_r", "betterlights_bolt_color_g", "betterlights_bolt_color_b")
            addResetButton(panel, {
                betterlights_bolt_enable = 1,
                betterlights_bolt_size = 220,
                betterlights_bolt_brightness = 0.96,
                betterlights_bolt_decay = 2000,
                betterlights_bolt_color_r = 255,
                betterlights_bolt_color_g = 140,
                betterlights_bolt_color_b = 40,
            })
        end)

    registerPage("Pickups", "BL_WorldWeapons", "menu.world_weapons", function(panel)
            addWorldWeaponPanel(panel)
        end)

    registerPage("Pickups", "BL_AmmoPickups", "menu.ammo_pickups", function(panel)
            addAmmoPickupPanel(panel)
        end)

    registerPage("Projectiles", "BL_RPG", "menu.rpg_rocket", function(panel)
            setupPage(panel, "page.rpg_rocket.title", "page.rpg_rocket.desc")
            panel:CheckBox(phrase("control.enable"), "betterlights_rpg_enable")
            panel:NumSlider(phrase("control.radius"), "betterlights_rpg_size", 0, 800, 0)
            panel:NumSlider(phrase("control.brightness"), "betterlights_rpg_brightness", 0, 10, 2)
            panel:NumSlider(phrase("control.decay"), "betterlights_rpg_decay", 0, 5000, 0)
            addColorMixerControl(panel, "control.color", "betterlights_rpg_color_r", "betterlights_rpg_color_g", "betterlights_rpg_color_b")

            local flash = addSection(panel, "section.explosion_flash", nil, true)
            flash:CheckBox(phrase("control.flash_on_explosion"), "betterlights_rpg_flash_enable")
            flash:NumSlider(phrase("control.radius"), "betterlights_rpg_flash_size", 0, 800, 0)
            flash:NumSlider(phrase("control.brightness"), "betterlights_rpg_flash_brightness", 0, 10, 2)
            flash:NumSlider(phrase("control.duration"), "betterlights_rpg_flash_time", 0, 1, 2)
            addColorMixerControl(flash, "control.flash_color", "betterlights_rpg_flash_color_r", "betterlights_rpg_flash_color_g", "betterlights_rpg_flash_color_b")

            addResetButton(panel, {
                betterlights_rpg_enable = 1,
                betterlights_rpg_size = 280,
                betterlights_rpg_brightness = 2.2,
                betterlights_rpg_decay = 2000,
                betterlights_rpg_color_r = 255,
                betterlights_rpg_color_g = 170,
                betterlights_rpg_color_b = 60,
                betterlights_rpg_flash_enable = 1,
                betterlights_rpg_flash_size = 340,
                betterlights_rpg_flash_brightness = 4.8,
                betterlights_rpg_flash_time = 0.18,
                betterlights_rpg_flash_color_r = 255,
                betterlights_rpg_flash_color_g = 210,
                betterlights_rpg_flash_color_b = 120,
            })
        end)

    registerPage("NPCs", "BL_Strider", "menu.strider", function(panel)
            setupPage(panel, "page.strider.title", "page.strider.desc")

            local muzzle = addSection(panel, "section.muzzle_flash", nil, true)
            muzzle:CheckBox(phrase("control.flash_on_fire"), "betterlights_strider_muzzle_flash_enable")
            muzzle:NumSlider(phrase("control.radius"), "betterlights_strider_muzzle_flash_size", 0, 1000, 0)
            muzzle:NumSlider(phrase("control.brightness"), "betterlights_strider_muzzle_flash_brightness", 0, 10, 2)
            muzzle:NumSlider(phrase("control.duration"), "betterlights_strider_muzzle_flash_time", 0, 1, 2)
            addColorMixerControl(muzzle, "control.flash_color", "betterlights_strider_muzzle_flash_color_r", "betterlights_strider_muzzle_flash_color_g", "betterlights_strider_muzzle_flash_color_b")

            local impact = addSection(panel, "section.impact_flash", nil, true)
            impact:CheckBox(phrase("control.flash_on_impact"), "betterlights_strider_bullet_impact_enable")
            impact:NumSlider(phrase("control.radius"), "betterlights_strider_bullet_impact_size", 0, 400, 0)
            impact:NumSlider(phrase("control.brightness"), "betterlights_strider_bullet_impact_brightness", 0, 5, 2)
            impact:NumSlider(phrase("control.duration"), "betterlights_strider_bullet_impact_time", 0, 1, 2)
            addColorMixerControl(impact, "control.flash_color", "betterlights_strider_bullet_impact_color_r", "betterlights_strider_bullet_impact_color_g", "betterlights_strider_bullet_impact_color_b")

            addResetButton(panel, {
                betterlights_strider_muzzle_flash_enable = 1,
                betterlights_strider_muzzle_flash_size = 320,
                betterlights_strider_muzzle_flash_brightness = 2.4,
                betterlights_strider_muzzle_flash_time = 0.08,
                betterlights_strider_muzzle_flash_color_r = 80,
                betterlights_strider_muzzle_flash_color_g = 210,
                betterlights_strider_muzzle_flash_color_b = 255,
                betterlights_strider_bullet_impact_enable = 1,
                betterlights_strider_bullet_impact_size = 90,
                betterlights_strider_bullet_impact_brightness = 0.45,
                betterlights_strider_bullet_impact_time = 0.14,
                betterlights_strider_bullet_impact_color_r = 80,
                betterlights_strider_bullet_impact_color_g = 210,
                betterlights_strider_bullet_impact_color_b = 255,
            })
        end)

    registerPage("NPCs", "BL_Hunter", "menu.hunter", function(panel)
            setupPage(panel, "page.hunter.title", "page.hunter.desc")

            local body = addSection(panel, "section.body_glow", nil, true)
            addLightControls(body, "betterlights_hunter", {
                radiusMax = 400,
                modelElight = true,
                modelElightLabel = "control.add_model_elight"
            })
            addColorMixerControl(body, "control.glow_color", "betterlights_hunter_color_r", "betterlights_hunter_color_g", "betterlights_hunter_color_b")

            local projectile = addSection(panel, "section.flechette_glow", "section.flechette_glow.desc", true)
            projectile:CheckBox(phrase("control.enable_glow"), "betterlights_hunter_flechette_enable")
            projectile:NumSlider(phrase("control.radius"), "betterlights_hunter_flechette_size", 0, 400, 0)
            projectile:NumSlider(phrase("control.brightness"), "betterlights_hunter_flechette_brightness", 0, 5, 2)
            projectile:NumSlider(phrase("control.decay"), "betterlights_hunter_flechette_decay", 0, 5000, 0)
            addColorMixerControl(projectile, "control.glow_color", "betterlights_hunter_flechette_color_r", "betterlights_hunter_flechette_color_g", "betterlights_hunter_flechette_color_b")

            local muzzle = addSection(panel, "section.muzzle_flash", nil, true)
            muzzle:CheckBox(phrase("control.flash_on_fire"), "betterlights_hunter_muzzle_flash_enable")
            muzzle:NumSlider(phrase("control.radius"), "betterlights_hunter_muzzle_flash_size", 0, 800, 0)
            muzzle:NumSlider(phrase("control.brightness"), "betterlights_hunter_muzzle_flash_brightness", 0, 10, 2)
            muzzle:NumSlider(phrase("control.duration"), "betterlights_hunter_muzzle_flash_time", 0, 1, 2)
            addColorMixerControl(muzzle, "control.flash_color", "betterlights_hunter_muzzle_flash_color_r", "betterlights_hunter_muzzle_flash_color_g", "betterlights_hunter_muzzle_flash_color_b")

            local blast = addSection(panel, "section.blast_flash", nil, true)
            blast:CheckBox(phrase("control.flash_on_explosion"), "betterlights_hunter_flechette_blast_enable")
            blast:NumSlider(phrase("control.radius"), "betterlights_hunter_flechette_blast_size", 0, 800, 0)
            blast:NumSlider(phrase("control.brightness"), "betterlights_hunter_flechette_blast_brightness", 0, 10, 2)
            blast:NumSlider(phrase("control.duration"), "betterlights_hunter_flechette_blast_time", 0, 1, 2)
            addColorMixerControl(blast, "control.flash_color", "betterlights_hunter_flechette_blast_color_r", "betterlights_hunter_flechette_blast_color_g", "betterlights_hunter_flechette_blast_color_b")

            addResetButton(panel, {
                betterlights_hunter_enable = 1,
                betterlights_hunter_size = 55,
                betterlights_hunter_brightness = 0.45,
                betterlights_hunter_decay = 2000,
                betterlights_hunter_models_elight = 1,
                betterlights_hunter_models_elight_size_mult = 1.0,
                betterlights_hunter_color_r = 30,
                betterlights_hunter_color_g = 230,
                betterlights_hunter_color_b = 255,
                betterlights_hunter_flechette_enable = 1,
                betterlights_hunter_flechette_size = 90,
                betterlights_hunter_flechette_brightness = 1.25,
                betterlights_hunter_flechette_decay = 1800,
                betterlights_hunter_flechette_color_r = 0,
                betterlights_hunter_flechette_color_g = 235,
                betterlights_hunter_flechette_color_b = 255,
                betterlights_hunter_muzzle_flash_enable = 1,
                betterlights_hunter_muzzle_flash_size = 220,
                betterlights_hunter_muzzle_flash_brightness = 2.0,
                betterlights_hunter_muzzle_flash_time = 0.08,
                betterlights_hunter_muzzle_flash_color_r = 70,
                betterlights_hunter_muzzle_flash_color_g = 220,
                betterlights_hunter_muzzle_flash_color_b = 255,
                betterlights_hunter_flechette_blast_enable = 1,
                betterlights_hunter_flechette_blast_size = 260,
                betterlights_hunter_flechette_blast_brightness = 2.4,
                betterlights_hunter_flechette_blast_time = 0.35,
                betterlights_hunter_flechette_blast_color_r = 80,
                betterlights_hunter_flechette_blast_color_g = 230,
                betterlights_hunter_flechette_blast_color_b = 255,
            })
        end)

    registerPage("NPCs", "BL_HunterChopper", "menu.hunter_chopper", function(panel)
            setupPage(panel, "page.hunter_chopper.title", "page.hunter_chopper.desc")

            local muzzle = addSection(panel, "section.muzzle_flash", nil, true)
            muzzle:CheckBox(phrase("control.flash_on_fire"), "betterlights_hunter_chopper_muzzle_flash_enable")
            muzzle:NumSlider(phrase("control.radius"), "betterlights_hunter_chopper_muzzle_flash_size", 0, 1000, 0)
            muzzle:NumSlider(phrase("control.brightness"), "betterlights_hunter_chopper_muzzle_flash_brightness", 0, 10, 2)
            muzzle:NumSlider(phrase("control.duration"), "betterlights_hunter_chopper_muzzle_flash_time", 0, 1, 2)
            addColorMixerControl(muzzle, "control.flash_color", "betterlights_hunter_chopper_muzzle_flash_color_r", "betterlights_hunter_chopper_muzzle_flash_color_g", "betterlights_hunter_chopper_muzzle_flash_color_b")

            local impact = addSection(panel, "section.impact_flash", nil, true)
            impact:CheckBox(phrase("control.flash_on_impact"), "betterlights_hunter_chopper_bullet_impact_enable")
            impact:NumSlider(phrase("control.radius"), "betterlights_hunter_chopper_bullet_impact_size", 0, 400, 0)
            impact:NumSlider(phrase("control.brightness"), "betterlights_hunter_chopper_bullet_impact_brightness", 0, 5, 2)
            impact:NumSlider(phrase("control.duration"), "betterlights_hunter_chopper_bullet_impact_time", 0, 1, 2)
            addColorMixerControl(impact, "control.flash_color", "betterlights_hunter_chopper_bullet_impact_color_r", "betterlights_hunter_chopper_bullet_impact_color_g", "betterlights_hunter_chopper_bullet_impact_color_b")

            local spotlight = addSection(panel, "section.spotlight", "section.spotlight.desc", true)
            spotlight:CheckBox(phrase("control.enable_spotlight"), "betterlights_hunter_chopper_spotlight_enable")
            spotlight:CheckBox(phrase("control.cast_shadows"), "betterlights_hunter_chopper_spotlight_shadows")
            spotlight:NumSlider(phrase("control.fov"), "betterlights_hunter_chopper_spotlight_fov", 1, 175, 0)
            spotlight:NumSlider(phrase("control.distance"), "betterlights_hunter_chopper_spotlight_distance", 0, 3000, 0)
            spotlight:NumSlider(phrase("control.near_z"), "betterlights_hunter_chopper_spotlight_near", 0, 128, 0)
            spotlight:NumSlider(phrase("control.brightness"), "betterlights_hunter_chopper_spotlight_brightness", 0, 2, 2)
            addColorMixerControl(spotlight, "control.spotlight_color", "betterlights_hunter_chopper_spotlight_color_r", "betterlights_hunter_chopper_spotlight_color_g", "betterlights_hunter_chopper_spotlight_color_b")

            addResetButton(panel, {
                betterlights_hunter_chopper_muzzle_flash_enable = 1,
                betterlights_hunter_chopper_muzzle_flash_size = 260,
                betterlights_hunter_chopper_muzzle_flash_brightness = 2.2,
                betterlights_hunter_chopper_muzzle_flash_time = 0.08,
                betterlights_hunter_chopper_muzzle_flash_color_r = 80,
                betterlights_hunter_chopper_muzzle_flash_color_g = 210,
                betterlights_hunter_chopper_muzzle_flash_color_b = 255,
                betterlights_hunter_chopper_bullet_impact_enable = 1,
                betterlights_hunter_chopper_bullet_impact_size = 80,
                betterlights_hunter_chopper_bullet_impact_brightness = 0.4,
                betterlights_hunter_chopper_bullet_impact_time = 0.12,
                betterlights_hunter_chopper_bullet_impact_color_r = 80,
                betterlights_hunter_chopper_bullet_impact_color_g = 210,
                betterlights_hunter_chopper_bullet_impact_color_b = 255,
                betterlights_hunter_chopper_spotlight_enable = 1,
                betterlights_hunter_chopper_spotlight_shadows = 1,
                betterlights_hunter_chopper_spotlight_fov = 34,
                betterlights_hunter_chopper_spotlight_distance = 1400,
                betterlights_hunter_chopper_spotlight_near = 8,
                betterlights_hunter_chopper_spotlight_brightness = 0.85,
                betterlights_hunter_chopper_spotlight_color_r = 210,
                betterlights_hunter_chopper_spotlight_color_g = 235,
                betterlights_hunter_chopper_spotlight_color_b = 255,
            })
        end)

    registerPage("Environment", "BL_Fire", "menu.fire", function(panel)
            setupPage(panel, "page.fire.title", "page.fire.desc")
            panel:CheckBox(phrase("control.enable"), "betterlights_fire_enable")
            panel:NumSlider(phrase("control.radius"), "betterlights_fire_size", 0, 800, 0)
            panel:NumSlider(phrase("control.brightness"), "betterlights_fire_brightness", 0, 10, 2)
            panel:NumSlider(phrase("control.decay"), "betterlights_fire_decay", 0, 5000, 0)
            panel:CheckBox(phrase("control.add_model_elight"), "betterlights_fire_models_elight")
            panel:NumSlider(phrase("control.model_elight_radius"), "betterlights_fire_models_elight_size_mult", 0, 3, 2)
            addColorMixerControl(panel, "control.color", "betterlights_fire_color_r", "betterlights_fire_color_g", "betterlights_fire_color_b")
            panel:CheckBox(phrase("control.flicker"), "betterlights_fire_flicker_enable")
            panel:NumSlider(phrase("control.flicker_amount"), "betterlights_fire_flicker_amount", 0, 1, 2)
            panel:NumSlider(phrase("control.flicker_size_amount"), "betterlights_fire_flicker_size_amount", 0, 1, 2)
            panel:NumSlider(phrase("control.flicker_speed"), "betterlights_fire_flicker_speed", 0, 30, 1)
            addResetButton(panel, {
                betterlights_fire_enable = 1,
                betterlights_fire_size = 160,
                betterlights_fire_brightness = 5.2,
                betterlights_fire_decay = 2000,
                betterlights_fire_models_elight = 1,
                betterlights_fire_models_elight_size_mult = 1.0,
                betterlights_fire_color_r = 255,
                betterlights_fire_color_g = 170,
                betterlights_fire_color_b = 60,
                betterlights_fire_flicker_enable = 1,
                betterlights_fire_flicker_amount = 0.35,
                betterlights_fire_flicker_size_amount = 0.12,
                betterlights_fire_flicker_speed = 11.5,
            })
        end)

    registerPage("Projectiles", "BL_Explosions", "menu.explosion_flash", function(panel)
        setupPage(panel, "page.explosion_flash.title", "page.explosion_flash.desc")
        panel:CheckBox(phrase("control.enable"), "betterlights_explosion_flash_enable")
        panel:NumSlider(phrase("control.radius"), "betterlights_explosion_flash_size", 0, 800, 0)
        panel:NumSlider(phrase("control.brightness"), "betterlights_explosion_flash_brightness", 0, 10, 2)
        panel:NumSlider(phrase("control.duration_seconds"), "betterlights_explosion_flash_time", 0, 1, 2)
        addColorMixerControl(panel, "control.color", "betterlights_explosion_flash_color_r", "betterlights_explosion_flash_color_g", "betterlights_explosion_flash_color_b")
        addResetButton(panel, {
            betterlights_explosion_flash_enable = 1,
            betterlights_explosion_flash_size = 460,
            betterlights_explosion_flash_brightness = 4.6,
            betterlights_explosion_flash_time = 0.18,
            betterlights_explosion_flash_color_r = 255,
            betterlights_explosion_flash_color_g = 210,
            betterlights_explosion_flash_color_b = 120,
        })
    end)

    registerPage("Projectiles", "BL_Grenade", "menu.frag_grenade", function(panel)
            setupPage(panel, "page.frag_grenade.title", "page.frag_grenade.desc")
            panel:CheckBox(phrase("control.enable"), "betterlights_grenade_enable")
            panel:NumSlider(phrase("control.radius"), "betterlights_grenade_size", 0, 400, 0)
            panel:NumSlider(phrase("control.brightness"), "betterlights_grenade_brightness", 0, 5, 2)
            panel:NumSlider(phrase("control.decay"), "betterlights_grenade_decay", 0, 5000, 0)
            panel:CheckBox(phrase("control.add_model_elight"), "betterlights_grenade_models_elight")
            panel:NumSlider(phrase("control.model_elight_radius"), "betterlights_grenade_models_elight_size_mult", 0, 3, 2)
            addColorMixerControl(panel, "control.color", "betterlights_grenade_color_r", "betterlights_grenade_color_g", "betterlights_grenade_color_b")
            addResetButton(panel, {
                betterlights_grenade_enable = 1,
                betterlights_grenade_size = 80,
                betterlights_grenade_brightness = 0.9,
                betterlights_grenade_decay = 1800,
                betterlights_grenade_models_elight = 1,
                betterlights_grenade_models_elight_size_mult = 1.0,
                betterlights_grenade_color_r = 255,
                betterlights_grenade_color_g = 40,
                betterlights_grenade_color_b = 40,
            })
        end)

    registerPage("NPCs", "BL_CombineMine", "menu.combine_mine", function(panel)
            setupPage(panel, "page.combine_mine.title", "page.combine_mine.desc")
            local alert = addSection(panel, "section.alert_glow", "section.alert_glow.desc", true)
            alert:CheckBox(phrase("control.enable"), "betterlights_combine_mine_enable")
            alert:NumSlider(phrase("control.detection_range"), "betterlights_combine_mine_range", 0, 1024, 0)
            alert:NumSlider(phrase("control.radius"), "betterlights_combine_mine_size", 0, 400, 0)
            alert:NumSlider(phrase("control.brightness"), "betterlights_combine_mine_brightness", 0, 5, 2)
            alert:NumSlider(phrase("control.decay"), "betterlights_combine_mine_decay", 0, 5000, 0)
            addColorMixerControl(alert, "control.alert_color", "betterlights_combine_mine_alert_color_r", "betterlights_combine_mine_alert_color_g", "betterlights_combine_mine_alert_color_b")

            local idle = addSection(panel, "section.idle_glow", "section.idle_glow.desc", false)
            idle:CheckBox(phrase("control.idle_glow"), "betterlights_combine_mine_idle_enable")
            idle:NumSlider(phrase("control.radius"), "betterlights_combine_mine_idle_size", 0, 400, 0)
            idle:NumSlider(phrase("control.brightness"), "betterlights_combine_mine_idle_brightness", 0, 2, 2)
            addColorMixerControl(idle, "control.idle_color", "betterlights_combine_mine_idle_color_r", "betterlights_combine_mine_idle_color_g", "betterlights_combine_mine_idle_color_b")

            local behavior = addSection(panel, "section.pulse_model_light", nil, false)
            behavior:CheckBox(phrase("control.pulse_on_alert"), "betterlights_combine_mine_pulse_enable")
            behavior:NumSlider(phrase("control.pulse_amount"), "betterlights_combine_mine_pulse_amount", 0, 1, 2)
            behavior:NumSlider(phrase("control.pulse_speed"), "betterlights_combine_mine_pulse_speed", 0, 30, 1)
            addModelElightControls(behavior, "betterlights_combine_mine", "control.add_model_elight")
            addResetButton(panel, {
                betterlights_combine_mine_enable = 1,
                betterlights_combine_mine_range = 260,
                betterlights_combine_mine_size = 140,
                betterlights_combine_mine_brightness = 1.2,
                betterlights_combine_mine_decay = 2000,
                betterlights_combine_mine_idle_enable = 1,
                betterlights_combine_mine_idle_size = 80,
                betterlights_combine_mine_idle_brightness = 0.25,
                betterlights_combine_mine_idle_color_r = 90,
                betterlights_combine_mine_idle_color_g = 180,
                betterlights_combine_mine_idle_color_b = 255,
                betterlights_combine_mine_alert_color_r = 255,
                betterlights_combine_mine_alert_color_g = 60,
                betterlights_combine_mine_alert_color_b = 60,
                betterlights_combine_mine_pulse_enable = 1,
                betterlights_combine_mine_pulse_amount = 0.15,
                betterlights_combine_mine_pulse_speed = 6.0,
                betterlights_combine_mine_models_elight = 1,
                betterlights_combine_mine_models_elight_size_mult = 1.0,
            })
        end)

    registerPage("NPCs", "BL_CombineMineResistance", "menu.resistance_mine", function(panel)
            setupPage(panel, "page.resistance_mine.title", "page.resistance_mine.desc")
            panel:CheckBox(phrase("control.enable"), "betterlights_combine_mine_resistance_enable")
            panel:NumSlider(phrase("control.alert_radius"), "betterlights_combine_mine_resistance_size", 0, 400, 0)
            panel:NumSlider(phrase("control.alert_brightness"), "betterlights_combine_mine_resistance_brightness", 0, 5, 2)
            panel:NumSlider(phrase("control.decay"), "betterlights_combine_mine_resistance_decay", 0, 5000, 0)
            addColorMixerControl(panel, "control.alert_color", "betterlights_combine_mine_resistance_color_r", "betterlights_combine_mine_resistance_color_g", "betterlights_combine_mine_resistance_color_b")
            addResetButton(panel, {
                betterlights_combine_mine_resistance_enable = 1,
                betterlights_combine_mine_resistance_size = 140,
                betterlights_combine_mine_resistance_brightness = 1.0,
                betterlights_combine_mine_resistance_decay = 2000,
                betterlights_combine_mine_resistance_color_r = 60,
                betterlights_combine_mine_resistance_color_g = 255,
                betterlights_combine_mine_resistance_color_b = 100,
            })
        end)

    registerPage("Flashlight", "BL_FlashlightGeneral", "menu.general", function(panel)
            setupPage(panel, "page.player_flashlight.title", "page.player_flashlight.desc")
            local behavior = addSection(panel, "section.behavior", nil, true)
            addFlashlightCheckbox(behavior, phrase("control.replace_flashlight"), "betterlights_flashlight_player_enable")
            addFlashlightCheckbox(behavior, phrase("control.use_flashlight_sounds"), "betterlights_flashlight_custom_sounds")
            addHelpText(behavior, phrase("help.default_flashlight_sounds"))

            addFlashlightResetButton(panel, {
                betterlights_flashlight_player_enable = 0,
                betterlights_flashlight_custom_sounds = 1,
            })
        end, "page.player_flashlight.desc")

    registerPage("Flashlight", "BL_FlashlightPosition", "menu.position", function(panel)
            setupPage(panel, "page.flashlight_position.title", "page.flashlight_position.desc")
            local firstPerson = addSection(
                panel,
                "section.flashlight_position_first_person",
                "section.flashlight_position_first_person.desc",
                true
            )
            addFlashlightCheckbox(firstPerson, phrase("control.attach_beam_to_weapon"), "betterlights_flashlight_weapon_attachment")
            addHelpText(firstPerson, phrase("help.attach_beam_to_weapon"))
            addFlashlightSlider(firstPerson, phrase("control.forward_offset"), "betterlights_flashlight_forward_offset", -32, 96, 1)
            addHelpText(firstPerson, phrase("help.forward_offset"))
            addFlashlightSlider(firstPerson, phrase("control.attached_side_offset"), "betterlights_flashlight_attachment_offset", -24, 24, 1)
            addHelpText(firstPerson, phrase("help.attached_side_offset"))
            addFlashlightSlider(firstPerson, phrase("control.view_origin_side_offset"), "betterlights_flashlight_fallback_offset", -24, 24, 1)
            addHelpText(firstPerson, phrase("help.view_origin_side_offset"))

            local world = addSection(
                panel,
                "section.flashlight_position_world",
                "section.flashlight_position_world.desc",
                true
            )
            addFlashlightCheckbox(world, phrase("control.attach_beam_to_weapon"), "betterlights_flashlight_world_weapon_attachment")
            addHelpText(world, phrase("help.attach_beam_to_weapon"))
            addFlashlightSlider(world, phrase("control.forward_offset"), "betterlights_flashlight_world_forward_offset", -32, 96, 1)
            addHelpText(world, phrase("help.forward_offset"))
            addFlashlightSlider(world, phrase("control.attached_side_offset"), "betterlights_flashlight_world_attachment_offset", -24, 24, 1)
            addHelpText(world, phrase("help.attached_side_offset"))
            addFlashlightSlider(world, phrase("control.view_origin_side_offset"), "betterlights_flashlight_world_fallback_offset", -24, 24, 1)
            addHelpText(world, phrase("help.view_origin_side_offset"))

            local spill = addSection(
                panel,
                "section.flashlight_world_spill",
                "section.flashlight_world_spill.desc",
                true
            )
            addFlashlightCheckbox(spill, phrase("control.flashlight_world_spill"), "betterlights_flashlight_world_spill")
            local spillForced = isFlashlightSettingForced("betterlights_flashlight_world_spill")
            beginControlGroup(spill, "betterlights_flashlight_world_spill", function()
                return getEffectiveFlashlightBool("betterlights_flashlight_world_spill")
            end, spillForced and {
                disabledHelpKey = "state.feature_disabled_by_server",
                disabledTitleKey = "state.section_disabled_by_server",
                highlighted = true
            } or nil)
            addFlashlightCheckbox(spill, phrase("control.flashlight_world_spill_match"), "betterlights_flashlight_world_spill_match")
            addHelpText(spill, phrase("help.flashlight_world_spill_match"))
            addFlashlightSlider(spill, phrase("control.flashlight_world_spill_size"), "betterlights_flashlight_world_spill_size", 32, 512, 0)
            addFlashlightSlider(spill, phrase("control.flashlight_world_spill_brightness"), "betterlights_flashlight_world_spill_brightness", 0.1, 5, 2)
            addFlashlightColorMixer(
                spill,
                "control.flashlight_world_spill_color",
                "betterlights_flashlight_world_spill_color_r",
                "betterlights_flashlight_world_spill_color_g",
                "betterlights_flashlight_world_spill_color_b",
                255,
                245,
                225
            )

            addFlashlightResetButton(panel, {
                betterlights_flashlight_weapon_attachment = 1,
                betterlights_flashlight_forward_offset = 0,
                betterlights_flashlight_attachment_offset = 2,
                betterlights_flashlight_fallback_offset = 0,
                betterlights_flashlight_world_weapon_attachment = 1,
                betterlights_flashlight_world_forward_offset = 16,
                betterlights_flashlight_world_attachment_offset = 2,
                betterlights_flashlight_world_fallback_offset = 0,
                betterlights_flashlight_world_spill = 0,
                betterlights_flashlight_world_spill_match = 1,
                betterlights_flashlight_world_spill_size = 128,
                betterlights_flashlight_world_spill_brightness = 0.47,
                betterlights_flashlight_world_spill_color_r = 255,
                betterlights_flashlight_world_spill_color_g = 245,
                betterlights_flashlight_world_spill_color_b = 225,
            })

            local blacklist = addSection(
                panel,
                "section.flashlight_attachment_blacklist",
                "section.flashlight_attachment_blacklist.desc",
                false
            )
            BetterLights.Flashlight.BuildWeaponAttachmentBlacklistEditor(blacklist)
        end, "page.flashlight_position.desc")

    registerPage("Flashlight", "BL_FlashlightVisual", "menu.visual", function(panel)
            BetterLights.ClearFlashlightKnownTextureCache()

            populateFlashlightVisualPanel(panel)
        end, "page.flashlight_visuals.desc")

    registerPage("Projectiles", "BL_HeliBomb", "menu.heli_bomb", function(panel)
            setupPage(panel, "page.heli_bomb.title", "page.heli_bomb.desc")
            local glow = addSection(panel, "section.bomb_glow", nil, true)
            addLightControls(glow, "betterlights_heli_bomb", {
                radiusMax = 400,
                modelElight = true,
                modelElightLabel = "control.add_model_elight"
            })
            addColorMixerControl(glow, "control.glow_color", "betterlights_heli_bomb_color_r", "betterlights_heli_bomb_color_g", "betterlights_heli_bomb_color_b")

            local flash = addSection(panel, "section.explosion_flash", nil, true)
            flash:CheckBox(phrase("control.flash_on_explosion"), "betterlights_heli_bomb_flash_enable")
            flash:NumSlider(phrase("control.radius"), "betterlights_heli_bomb_flash_size", 0, 800, 0)
            flash:NumSlider(phrase("control.brightness"), "betterlights_heli_bomb_flash_brightness", 0, 10, 2)
            flash:NumSlider(phrase("control.duration"), "betterlights_heli_bomb_flash_time", 0, 1, 2)
            addColorMixerControl(flash, "control.flash_color", "betterlights_heli_bomb_flash_color_r", "betterlights_heli_bomb_flash_color_g", "betterlights_heli_bomb_flash_color_b")
            addResetButton(panel, {
                betterlights_heli_bomb_enable = 1,
                betterlights_heli_bomb_size = 140,
                betterlights_heli_bomb_brightness = 1.4,
                betterlights_heli_bomb_decay = 2000,
                betterlights_heli_bomb_models_elight = 1,
                betterlights_heli_bomb_models_elight_size_mult = 1.0,
                betterlights_heli_bomb_color_r = 255,
                betterlights_heli_bomb_color_g = 60,
                betterlights_heli_bomb_color_b = 60,
                betterlights_heli_bomb_flash_enable = 1,
                betterlights_heli_bomb_flash_size = 320,
                betterlights_heli_bomb_flash_brightness = 5.0,
                betterlights_heli_bomb_flash_time = 0.18,
                betterlights_heli_bomb_flash_color_r = 255,
                betterlights_heli_bomb_flash_color_g = 210,
                betterlights_heli_bomb_flash_color_b = 120,
            })
        end)

    registerPage("Projectiles", "BL_Magnusson", "menu.magnusson", function(panel)
            setupPage(panel, "page.magnusson.title", "page.magnusson.desc")
            local glow = addSection(panel, "section.device_glow", nil, true)
            addLightControls(glow, "betterlights_magnusson", {
                radiusMax = 400,
                modelElight = true,
                modelElightLabel = "control.add_model_elight"
            })
            addColorMixerControl(glow, "control.glow_color", "betterlights_magnusson_color_r", "betterlights_magnusson_color_g", "betterlights_magnusson_color_b")

            local flash = addSection(panel, "section.explosion_flash", nil, true)
            flash:CheckBox(phrase("control.flash_on_explosion"), "betterlights_magnusson_flash_enable")
            flash:NumSlider(phrase("control.radius"), "betterlights_magnusson_flash_size", 0, 800, 0)
            flash:NumSlider(phrase("control.brightness"), "betterlights_magnusson_flash_brightness", 0, 10, 2)
            flash:NumSlider(phrase("control.duration"), "betterlights_magnusson_flash_time", 0, 1, 2)
            addColorMixerControl(flash, "control.flash_color", "betterlights_magnusson_flash_color_r", "betterlights_magnusson_flash_color_g", "betterlights_magnusson_flash_color_b")
            addResetButton(panel, {
                betterlights_magnusson_enable = 1,
                betterlights_magnusson_size = 130,
                betterlights_magnusson_brightness = 0.48,
                betterlights_magnusson_decay = 2000,
                betterlights_magnusson_models_elight = 1,
                betterlights_magnusson_models_elight_size_mult = 1.0,
                betterlights_magnusson_color_r = 130,
                betterlights_magnusson_color_g = 180,
                betterlights_magnusson_color_b = 255,
                betterlights_magnusson_flash_enable = 1,
                betterlights_magnusson_flash_size = 360,
                betterlights_magnusson_flash_brightness = 2.2,
                betterlights_magnusson_flash_time = 2.0,
                betterlights_magnusson_flash_color_r = 180,
                betterlights_magnusson_flash_color_g = 220,
                betterlights_magnusson_flash_color_b = 255,
            })
        end)

    registerPage("NPCs", "BL_Manhack", "menu.manhack", function(panel)
            setupPage(panel, "page.manhack.title", "page.manhack.desc")
            panel:CheckBox(phrase("control.enable"), "betterlights_manhack_enable")
            panel:NumSlider(phrase("control.radius"), "betterlights_manhack_size", 0, 400, 0)
            panel:NumSlider(phrase("control.brightness"), "betterlights_manhack_brightness", 0, 5, 2)
            panel:NumSlider(phrase("control.decay"), "betterlights_manhack_decay", 0, 5000, 0)
            panel:CheckBox(phrase("control.add_model_elight"), "betterlights_manhack_models_elight")
            panel:NumSlider(phrase("control.model_elight_radius"), "betterlights_manhack_models_elight_size_mult", 0, 3, 2)
            addColorMixerControl(panel, "control.hostile_color", "betterlights_manhack_color_r", "betterlights_manhack_color_g", "betterlights_manhack_color_b")
            addColorMixerControl(panel, "control.hacked_color", "betterlights_manhack_hacked_color_r", "betterlights_manhack_hacked_color_g", "betterlights_manhack_hacked_color_b")
            addResetButton(panel, {
                betterlights_manhack_enable = 1,
                betterlights_manhack_size = 70,
                betterlights_manhack_brightness = 0.6,
                betterlights_manhack_decay = 2000,
                betterlights_manhack_models_elight = 1,
                betterlights_manhack_models_elight_size_mult = 1.0,
                betterlights_manhack_color_r = 255,
                betterlights_manhack_color_g = 60,
                betterlights_manhack_color_b = 60,
                betterlights_manhack_hacked_color_r = 60,
                betterlights_manhack_hacked_color_g = 255,
                betterlights_manhack_hacked_color_b = 60,
            })
        end)

    registerPage("NPCs", "BL_Antlions", "menu.antlions", function(panel)
            addAntlionPanel(panel)
        end)

    registerPage("NPCs", "BL_Rollermines", "menu.rollermines", function(panel)
            addRollerminePanel(panel)
        end)

    registerPage("NPCs", "BL_CScanner", "menu.cscanner", function(panel)
            setupPage(panel, "page.cscanner.title", "page.cscanner.desc")

            local function addScannerGlowSection(titleKey, prefix)
                local glow = addSection(panel, titleKey, nil, true)
                addLightControls(glow, prefix, {
                    radiusMax = 600,
                    modelElight = true,
                    modelElightLabel = "control.add_model_elight"
                })
                addColorMixerControl(glow, "control.glow_color", prefix .. "_color_r", prefix .. "_color_g", prefix .. "_color_b")
            end

            local function addScannerSearchlightSection(titleKey, prefix)
                local searchlight = addSection(panel, titleKey, "section.searchlight.desc", true)
                searchlight:CheckBox(phrase("control.enable_searchlight"), prefix .. "_searchlight_enable")
                searchlight:CheckBox(phrase("control.cast_shadows"), prefix .. "_searchlight_shadows")
                searchlight:NumSlider(phrase("control.fov"), prefix .. "_searchlight_fov", 1, 175, 0)
                searchlight:NumSlider(phrase("control.distance"), prefix .. "_searchlight_distance", 0, 3000, 0)
                searchlight:NumSlider(phrase("control.near_z"), prefix .. "_searchlight_near", 0, 128, 0)
                searchlight:NumSlider(phrase("control.brightness"), prefix .. "_searchlight_brightness", 0, 2, 2)
                searchlight:NumSlider(phrase("control.falloff"), prefix .. "_searchlight_falloff", 0, 100, 0)
                addColorMixerControl(searchlight, "control.searchlight_color", prefix .. "_searchlight_color_r", prefix .. "_searchlight_color_g", prefix .. "_searchlight_color_b")
            end

            addScannerGlowSection("section.city_scanner_glow", "betterlights_cscanner")
            addScannerSearchlightSection("section.city_scanner_searchlight", "betterlights_cscanner")
            addScannerGlowSection("section.shield_scanner_glow", "betterlights_shieldscanner")
            addScannerSearchlightSection("section.shield_scanner_searchlight", "betterlights_shieldscanner")

            addResetButton(panel, {
                betterlights_cscanner_enable = 1,
                betterlights_cscanner_size = 120,
                betterlights_cscanner_brightness = 0.7,
                betterlights_cscanner_decay = 2000,
                betterlights_cscanner_models_elight = 1,
                betterlights_cscanner_models_elight_size_mult = 1.0,
                betterlights_cscanner_color_r = 180,
                betterlights_cscanner_color_g = 230,
                betterlights_cscanner_color_b = 255,
                betterlights_cscanner_searchlight_enable = 1,
                betterlights_cscanner_searchlight_shadows = 1,
                betterlights_cscanner_searchlight_fov = 38,
                betterlights_cscanner_searchlight_distance = 900,
                betterlights_cscanner_searchlight_near = 8,
                betterlights_cscanner_searchlight_brightness = 1.25,
                betterlights_cscanner_searchlight_falloff = 25,
                betterlights_cscanner_searchlight_color_r = 255,
                betterlights_cscanner_searchlight_color_g = 255,
                betterlights_cscanner_searchlight_color_b = 255,
                betterlights_shieldscanner_enable = 1,
                betterlights_shieldscanner_size = 120,
                betterlights_shieldscanner_brightness = 0.7,
                betterlights_shieldscanner_decay = 2000,
                betterlights_shieldscanner_models_elight = 1,
                betterlights_shieldscanner_models_elight_size_mult = 1.0,
                betterlights_shieldscanner_color_r = 180,
                betterlights_shieldscanner_color_g = 230,
                betterlights_shieldscanner_color_b = 255,
                betterlights_shieldscanner_searchlight_enable = 1,
                betterlights_shieldscanner_searchlight_shadows = 1,
                betterlights_shieldscanner_searchlight_fov = 38,
                betterlights_shieldscanner_searchlight_distance = 900,
                betterlights_shieldscanner_searchlight_near = 8,
                betterlights_shieldscanner_searchlight_brightness = 1.25,
                betterlights_shieldscanner_searchlight_falloff = 25,
                betterlights_shieldscanner_searchlight_color_r = 255,
                betterlights_shieldscanner_searchlight_color_g = 255,
                betterlights_shieldscanner_searchlight_color_b = 255,
            })
        end)

        registerPage("Eye Glow", "BL_CombineSoldiers", "menu.combine_soldiers", function(panel)
            addCombineEyeGlowPanel(panel)
        end, "page.combine_eye.desc")

        registerPage("Eye Glow", "BL_DogEyeGlow", "menu.dog_eye_glow", function(panel)
            setupPage(panel, "page.dog_eye_glow.title", "page.dog_eye_glow.desc")

            local dog = addSection(panel, "section.dog_eyes", nil, true)
            addLightControls(dog, "betterlights_dog_eye", {
                radiusMax = 200
            })
            addColorMixerControl(dog, "control.color", "betterlights_dog_eye_color_r", "betterlights_dog_eye_color_g", "betterlights_dog_eye_color_b", 255, 60, 60)

            addResetButton(panel, {
                betterlights_dog_eye_enable = 1,
                betterlights_dog_eye_size = 70,
                betterlights_dog_eye_brightness = 0.4,
                betterlights_dog_eye_decay = 1500,
                betterlights_dog_eye_color_r = 255,
                betterlights_dog_eye_color_g = 60,
                betterlights_dog_eye_color_b = 60,
            })
        end)

    registerPage("Pickups", "BL_Pickup_Battery", "menu.battery", function(panel)
            setupPage(panel, "page.battery.title", "page.battery.desc")
            panel:CheckBox(phrase("control.enable"), "betterlights_item_battery_enable")
            panel:NumSlider(phrase("control.radius"), "betterlights_item_battery_size", 0, 300, 0)
            panel:NumSlider(phrase("control.brightness"), "betterlights_item_battery_brightness", 0, 2, 2)
            panel:NumSlider(phrase("control.decay"), "betterlights_item_battery_decay", 0, 5000, 0)
            panel:CheckBox(phrase("control.add_model_elight"), "betterlights_item_battery_models_elight")
            panel:NumSlider(phrase("control.elight_radius"), "betterlights_item_battery_models_elight_size_mult", 0, 3, 2)
            addColorMixerControl(panel, "control.color", "betterlights_item_battery_color_r", "betterlights_item_battery_color_g", "betterlights_item_battery_color_b")
            addResetButton(panel, {
                betterlights_item_battery_enable = 1,
                betterlights_item_battery_size = 55,
                betterlights_item_battery_brightness = 0.2,
                betterlights_item_battery_decay = 1800,
                betterlights_item_battery_models_elight = 1,
                betterlights_item_battery_models_elight_size_mult = 1.0,
                betterlights_item_battery_color_r = 110,
                betterlights_item_battery_color_g = 190,
                betterlights_item_battery_color_b = 255,
            })
        end)

    registerPage("Pickups", "BL_Pickup_Vial", "menu.health_vial", function(panel)
            setupPage(panel, "page.health_vial.title", "page.health_vial.desc")
            panel:CheckBox(phrase("control.enable"), "betterlights_item_healthvial_enable")
            panel:NumSlider(phrase("control.radius"), "betterlights_item_healthvial_size", 0, 300, 0)
            panel:NumSlider(phrase("control.brightness"), "betterlights_item_healthvial_brightness", 0, 2, 2)
            panel:NumSlider(phrase("control.decay"), "betterlights_item_healthvial_decay", 0, 5000, 0)
            panel:CheckBox(phrase("control.add_model_elight"), "betterlights_item_healthvial_models_elight")
            panel:NumSlider(phrase("control.elight_radius"), "betterlights_item_healthvial_models_elight_size_mult", 0, 3, 2)
            addColorMixerControl(panel, "control.color", "betterlights_item_healthvial_color_r", "betterlights_item_healthvial_color_g", "betterlights_item_healthvial_color_b")
            addResetButton(panel, {
                betterlights_item_healthvial_enable = 1,
                betterlights_item_healthvial_size = 45,
                betterlights_item_healthvial_brightness = 0.18,
                betterlights_item_healthvial_decay = 1800,
                betterlights_item_healthvial_models_elight = 1,
                betterlights_item_healthvial_models_elight_size_mult = 1.0,
                betterlights_item_healthvial_color_r = 150,
                betterlights_item_healthvial_color_g = 255,
                betterlights_item_healthvial_color_b = 150,
            })
        end)

    registerPage("Pickups", "BL_Pickup_HealthKit", "menu.health_kit", function(panel)
            setupPage(panel, "page.health_kit.title", "page.health_kit.desc")
            panel:CheckBox(phrase("control.enable"), "betterlights_item_healthkit_enable")
            panel:NumSlider(phrase("control.radius"), "betterlights_item_healthkit_size", 0, 300, 0)
            panel:NumSlider(phrase("control.brightness"), "betterlights_item_healthkit_brightness", 0, 2, 2)
            panel:NumSlider(phrase("control.decay"), "betterlights_item_healthkit_decay", 0, 5000, 0)
            panel:CheckBox(phrase("control.add_model_elight"), "betterlights_item_healthkit_models_elight")
            panel:NumSlider(phrase("control.elight_radius"), "betterlights_item_healthkit_models_elight_size_mult", 0, 3, 2)
            addColorMixerControl(panel, "control.color", "betterlights_item_healthkit_color_r", "betterlights_item_healthkit_color_g", "betterlights_item_healthkit_color_b")
            addResetButton(panel, {
                betterlights_item_healthkit_enable = 1,
                betterlights_item_healthkit_size = 55,
                betterlights_item_healthkit_brightness = 0.2,
                betterlights_item_healthkit_decay = 1800,
                betterlights_item_healthkit_models_elight = 1,
                betterlights_item_healthkit_models_elight_size_mult = 1.0,
                betterlights_item_healthkit_color_r = 150,
                betterlights_item_healthkit_color_g = 255,
                betterlights_item_healthkit_color_b = 150,
            })
        end)

        registerPage("Environment", "BL_Chargers", "menu.chargers", function(panel)
                setupPage(panel, "page.chargers.title", "page.chargers.desc")
                local suit = addSection(panel, "section.suit_charger", nil, true)
                addLightControls(suit, "betterlights_suitcharger", {
                    enableLabel = "control.enable",
                    radiusMax = 300,
                    brightnessMax = 2,
                    modelElight = true,
                    modelElightLabel = "control.add_model_elight"
                })
                addColorMixerControl(suit, "control.suit_color", "betterlights_suitcharger_color_r", "betterlights_suitcharger_color_g", "betterlights_suitcharger_color_b")

                local health = addSection(panel, "section.health_charger", nil, true)
                addLightControls(health, "betterlights_healthcharger", {
                    enableLabel = "control.enable",
                    radiusMax = 300,
                    brightnessMax = 2,
                    modelElight = true,
                    modelElightLabel = "control.add_model_elight"
                })
                addColorMixerControl(health, "control.health_color", "betterlights_healthcharger_color_r", "betterlights_healthcharger_color_g", "betterlights_healthcharger_color_b")
                addResetButton(panel, {
                    betterlights_suitcharger_enable = 1,
                    betterlights_suitcharger_size = 75,
                    betterlights_suitcharger_brightness = 0.25,
                    betterlights_suitcharger_decay = 1800,
                    betterlights_suitcharger_models_elight = 1,
                    betterlights_suitcharger_models_elight_size_mult = 1.0,
                    betterlights_suitcharger_color_r = 255,
                    betterlights_suitcharger_color_g = 180,
                    betterlights_suitcharger_color_b = 80,
                    betterlights_healthcharger_enable = 1,
                    betterlights_healthcharger_size = 75,
                    betterlights_healthcharger_brightness = 0.25,
                    betterlights_healthcharger_decay = 1800,
                    betterlights_healthcharger_models_elight = 1,
                    betterlights_healthcharger_models_elight_size_mult = 1.0,
                    betterlights_healthcharger_color_r = 110,
                    betterlights_healthcharger_color_g = 190,
                    betterlights_healthcharger_color_b = 255,
                })
            end)

    end

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

        spawnmenu.AddToolMenuOption(
            SPAWNMENU_TAB_ID,
            SPAWNMENU_CATEGORY_ID,
            "BL_About",
            phrase("menu.about"),
            "",
            "",
            buildAboutPanel
        )
    end)
end
