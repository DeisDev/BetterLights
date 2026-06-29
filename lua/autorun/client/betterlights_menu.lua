if CLIENT then
    local TAB_ID = "Better Lights"
    BetterLights.Menu = BetterLights.Menu or {}
    local MENU = BetterLights.Menu

    local function isDeveloperMode()
        local developer = GetConVar("developer")
        return developer and developer:GetInt() >= 1
    end

    local CATEGORY_DEFS = {
        { "General", "category.general" },
        { "Flashlight", "category.flashlight" },
        { "Weapons", "category.weapons" },
        { "Projectiles", "category.projectiles" },
        { "NPCs", "category.npcs" },
        { "Eye Glow", "category.eye_glow" },
        { "Gunfire", "category.gunfire" },
        { "Environment", "category.environment" },
        { "Pickups", "category.pickups" },
        { "Developer", "category.developer", developer = true },
        { "About", "category.about" }
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

    function MENU.RegisterPage(category, id, titleKey, buildPanel)
        spawnmenu.AddToolMenuOption(TAB_ID, category, id, phrase(titleKey), "", "", buildPanel)
    end

    local function registerPage(category, id, titleKey, buildPanel)
        MENU.RegisterPage(category, id, titleKey, buildPanel)
    end

    local function registerCategories()
        for _, category in ipairs(CATEGORY_DEFS) do
            if not category.developer or isDeveloperMode() then
                spawnmenu.AddToolCategory(TAB_ID, category[1], phrase(category[2]))
            end
        end
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

    local function resetClientSetting(cvarName, defaultValue)
        if cvarName == "betterlights_flashlight_texture" then
            BetterLights.SetFlashlightTexturePath(defaultValue)
            return
        end

        RunConsoleCommand(cvarName, tostring(defaultValue))
    end

    local function resetRegisteredClientSettings()
        local defaults = BetterLights.GetRegisteredClientConVarDefaults()
        for cvarName, cvar in pairs(BetterLights.GetRegisteredClientConVars()) do
            if cvarName == "betterlights_flashlight_texture" then
                BetterLights.SetFlashlightTexturePath(defaults[cvarName] or "effects/flashlight001")
            elseif cvar and cvar.Revert then
                cvar:Revert()
            else
                resetClientSetting(cvarName, defaults[cvarName] or "")
            end
        end
    end

    local function resetFlashlightTextureLists()
        BetterLights.ClearFlashlightRecentTextures()
        BetterLights.ClearFlashlightKnownTextureCache()
    end

    local function addResetButton(panel, defaults, label)
        local btn = addStyledButton(panel, label or phrase("button.reset_defaults"), phrase("tooltip.reset_defaults"))
        btn.DoClick = function()
            local resetDefaults = BetterLights.ResolveClientResetDefaults(defaults)
            for cvar, def in pairs(resetDefaults) do
                resetClientSetting(cvar, def)
            end
        end
    end

    MENU.AddResetButton = addResetButton

    local function addBrightnessResetButton(panel)
        local resetBrightness = addStyledButton(panel, phrase("button.reset_brightness"))
        resetBrightness.DoClick = function()
            RunConsoleCommand("betterlights_flashlight_brightness", tostring(getClientDefault("betterlights_flashlight_brightness", "1.35")))
        end
    end

    local function addFovResetButton(panel)
        local resetFov = addStyledButton(panel, phrase("button.reset_fov"))
        resetFov.DoClick = function()
            RunConsoleCommand("betterlights_flashlight_fov", tostring(getClientDefault("betterlights_flashlight_fov", "45")))
        end
    end

    local function addBeamLengthResetButton(panel)
        local resetBeamLength = addStyledButton(panel, phrase("button.reset_beam_length"))
        resetBeamLength.DoClick = function()
            RunConsoleCommand("betterlights_flashlight_distance", tostring(getClientDefault("betterlights_flashlight_distance", "1200")))
        end
    end

    local function addFlickerAmountResetButton(panel)
        local resetFlickerAmount = addStyledButton(panel, phrase("button.reset_flicker_amount"))
        resetFlickerAmount.DoClick = function()
            RunConsoleCommand("betterlights_flashlight_flicker_amount", tostring(getClientDefault("betterlights_flashlight_flicker_amount", "0.05")))
        end
    end

    local function addSwayIntensityResetButton(panel)
        local resetSwayIntensity = addStyledButton(panel, phrase("button.reset_sway_intensity"))
        resetSwayIntensity.DoClick = function()
            RunConsoleCommand("betterlights_flashlight_sway_intensity", tostring(getClientDefault("betterlights_flashlight_sway_intensity", "1")))
        end
    end

    local function setupPage(panel, titleKey, subtitleKey)
        panel:ClearControls()

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
        local form = vgui.Create("DForm")
        form:SetName(phrase(titleKey))
        form:SetExpanded(expanded ~= false)

        if subtitleKey and subtitleKey ~= "" then
            addHelpText(form, phrase(subtitleKey))
        end

        panel:AddItem(form)
        return form
    end

    MENU.AddSection = addSection

    local function addRawSection(panel, title, subtitle, expanded)
        local form = vgui.Create("DForm")
        form:SetName(title)
        form:SetExpanded(expanded ~= false)

        if subtitle and subtitle ~= "" then
            addHelpText(form, subtitle)
        end

        panel:AddItem(form)
        return form
    end

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

    local function addColorMixerControl(panel, labelKey, rCvar, gCvar, bCvar, defaultR, defaultG, defaultB)
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
            RunConsoleCommand(rCvar, tostring(getClientDefault(rCvar, defaultR or 255)))
            RunConsoleCommand(gCvar, tostring(getClientDefault(gCvar, defaultG or 255)))
            RunConsoleCommand(bCvar, tostring(getClientDefault(bCvar, defaultB or 255)))
        end

        panel:AddItem(reset)
        return mixer
    end

    MENU.AddColorMixerControl = addColorMixerControl

    local function copyText(text)
        if not SetClipboardText then return end

        SetClipboardText(text)
        notification.AddLegacy(phrase("notice.copied_texture_path"), NOTIFY_GENERIC, 3)
        surface.PlaySound("buttons/button14.wav")
    end

    local function addCurrentTexturePreview(panel, path)
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
        title:SetText(phrase("label.current_texture"))
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
    end

    local function addTextureTile(layout, path, refresh)
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

        local copy = styleButton(vgui.Create("DButton", buttons))
        copy:Dock(RIGHT)
        copy:SetWide(64)
        copy:SetText(phrase("button.copy"))
        copy.DoClick = function()
            copyText(path)
        end

        layout:Add(tile)
    end

    local function addTextureGrid(parent, paths, refresh)
        local layout = vgui.Create("DIconLayout")
        layout:SetSpaceX(8)
        layout:SetSpaceY(8)
        layout:SetTall(math.max(172, #paths * 172))

        for _, path in ipairs(paths) do
            addTextureTile(layout, path, refresh)
        end

        parent:AddItem(layout)
    end

    local populateFlashlightVisualPanel
    local activeFlashlightVisualPanel
    local activeFlashlightVisualFilter

    local function requestServerBool(cvarName, value)
        net.Start(BetterLights.NET_SET_SERVER_BOOL)
            net.WriteString(cvarName)
            net.WriteBool(value)
        net.SendToServer()
    end

    local function canChangeServerSettings()
        return game.SinglePlayer() or (IsValid(LocalPlayer()) and LocalPlayer():IsAdmin())
    end

    concommand.Add("betterlights_toggle", function()
        if not canChangeServerSettings() then
            notification.AddLegacy(phrase("notice.admin_toggle_only"), NOTIFY_ERROR, 4)
            surface.PlaySound("buttons/button10.wav")
            return
        end

        local cvar = GetConVar("betterlights_enable")
        requestServerBool("betterlights_enable", not (cvar and cvar:GetBool()))
    end)

    local function addServerBoolCheckbox(panel, label, cvarName)
        local row = vgui.Create("DCheckBoxLabel")
        local cvar = GetConVar(cvarName)
        row:SetText(label)
        row:SetValue((not cvar or cvar:GetBool()) and 1 or 0)
        row:SizeToContents()

        row.OnChange = function(_, value)
            if canChangeServerSettings() then
                requestServerBool(cvarName, value)
                return
            end

            notification.AddLegacy(phrase("notice.admin_change_server_only"), NOTIFY_ERROR, 4)
            surface.PlaySound("buttons/button10.wav")
            timer.Simple(0, function()
                if not IsValid(row) then return end
                local current = GetConVar(cvarName)
                row:SetValue((not current or current:GetBool()) and 1 or 0)
            end)
        end

        panel:AddItem(row)
        return row
    end

    local function addServerBoolResetButton(panel, defaults)
        local btn = addStyledButton(panel, phrase("button.reset_server_settings"))
        btn.DoClick = function()
            if not canChangeServerSettings() then
                notification.AddLegacy(phrase("notice.admin_reset_server_only"), NOTIFY_ERROR, 4)
                surface.PlaySound("buttons/button10.wav")
                return
            end

            for cvarName, value in pairs(defaults) do
                requestServerBool(cvarName, value ~= 0 and value ~= false)
            end
        end
    end

    local function resetAllSettings()
        if not canChangeServerSettings() then
            notification.AddLegacy(phrase("notice.admin_reset_all_only"), NOTIFY_ERROR, 4)
            surface.PlaySound("buttons/button10.wav")
            return
        end

        Derma_Query(
            phrase("dialog.reset_all.message"),
            phrase("dialog.reset_all.title"),
            phrase("button.reset_all"),
            function()
                resetRegisteredClientSettings()
                resetFlashlightTextureLists()
                requestServerBool("betterlights_enable", true)
                notification.AddLegacy(phrase("notice.settings_reset"), NOTIFY_GENERIC, 4)
                surface.PlaySound("buttons/button14.wav")
            end,
            phrase("button.cancel")
        )
    end

    MENU.AddServerBoolCheckbox = addServerBoolCheckbox
    MENU.AddServerBoolResetButton = addServerBoolResetButton
    MENU.ResetAllSettings = resetAllSettings

    populateFlashlightVisualPanel = function(panel, filterText)
        setupPage(panel, "page.flashlight_visuals.title", "page.flashlight_visuals.desc")
        activeFlashlightVisualPanel = panel
        activeFlashlightVisualFilter = filterText

        local beam = addSection(panel, "section.beam", "section.beam.desc", true)
        beam:CheckBox(phrase("control.cast_shadows"), "betterlights_flashlight_shadows")
        beam:CheckBox(phrase("control.flicker"), "betterlights_flashlight_flicker")
        beam:NumSlider(phrase("control.flicker_amount"), "betterlights_flashlight_flicker_amount", 0, 0.3, 2)
        addFlickerAmountResetButton(beam)
        beam:CheckBox(phrase("control.flashlight_sway"), "betterlights_flashlight_sway")
        beam:NumSlider(phrase("control.sway_intensity"), "betterlights_flashlight_sway_intensity", 0, 3, 2)
        addSwayIntensityResetButton(beam)
        beam:NumSlider(phrase("control.brightness"), "betterlights_flashlight_brightness", 0.1, 5, 2)
        addBrightnessResetButton(beam)
        beam:NumSlider(phrase("control.fov"), "betterlights_flashlight_fov", 10, 120, 0)
        addFovResetButton(beam)
        beam:NumSlider(phrase("control.beam_length"), "betterlights_flashlight_distance", 128, 4096, 0)
        addBeamLengthResetButton(beam)

        local colorSection = addSection(panel, "section.color", "section.color.desc", true)
        addColorMixerControl(colorSection, "control.flashlight_color", "betterlights_flashlight_color_r", "betterlights_flashlight_color_g", "betterlights_flashlight_color_b", 255, 245, 225)

        local texture = addSection(panel, "section.texture", "section.texture.desc", true)

        local currentCvar = GetConVar("betterlights_flashlight_texture")
        local typedPath = currentCvar and currentCvar:GetString() or "effects/flashlight001"
        local currentPath = BetterLights.GetFlashlightTexturePath()

        addHelpText(texture, phraseFormat("help.current_texture", currentPath))
        addCurrentTexturePreview(texture, currentPath)

        local manualEntry = vgui.Create("DTextEntry")
        manualEntry:SetText(typedPath)
        manualEntry:SetUpdateOnType(false)
        texture:AddItem(manualEntry)

        local manualButtons = vgui.Create("DPanel")
        manualButtons:SetTall(28)
        manualButtons.Paint = nil

        local useManual = styleButton(vgui.Create("DButton", manualButtons))
        useManual:Dock(LEFT)
        useManual:SetWide(76)
        useManual:SetText(phrase("button.use"))
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
        useDefault.DoClick = function()
            BetterLights.SetFlashlightTexturePath("effects/flashlight001")
        end

        texture:AddItem(manualButtons)

        local recent = BetterLights.GetFlashlightRecentTextures()
        if #recent > 0 then
            local recentSection = addSection(panel, "section.recent_textures", nil, false)
            addTextureGrid(recentSection, recent, function()
                populateFlashlightVisualPanel(panel, filterText)
            end)

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
        addTextureGrid(knownSection, filtered, function()
            populateFlashlightVisualPanel(panel, filterText)
        end)
        else
            addHelpText(panel, phrase("help.no_matching_textures"))
        end

        addResetButton(panel, {
            betterlights_flashlight_brightness = 1.35,
            betterlights_flashlight_fov = 45,
            betterlights_flashlight_distance = 1200,
            betterlights_flashlight_shadows = 1,
            betterlights_flashlight_flicker = 0,
            betterlights_flashlight_flicker_amount = 0.05,
            betterlights_flashlight_sway = 1,
            betterlights_flashlight_sway_intensity = 1,
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

    local function addWorldWeaponPanel(panel)
        setupPage(panel, "page.world_weapons.title", "page.world_weapons.desc")
        local resetDefaults = {}

        local defs = BetterLights.GetWorldWeaponLightDefinitions()

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

        for _, info in ipairs(defs) do
            local prefix = "betterlights_ammo_" .. info.slug
            local form = info.nameKey and addSection(panel, info.nameKey, info.enable == 0 and "state.starts_disabled" or "state.starts_enabled", false) or addRawSection(panel, info.name, phrase(info.enable == 0 and "state.starts_disabled" or "state.starts_enabled"), false)
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

    local ROLLERMINE_DEFAULTS = {
        {
            titleKey = "page.rollermines.title",
            subtitleKey = "page.rollermines.section_desc",
            prefix = "betterlights_rollermine",
            size = 110,
            brightness = 0.6,
            decay = 2000,
            elight = 1,
            elightMult = 1.0,
            colors = {
                { labelKey = "rollermine.default", suffix = "color", r = 110, g = 190, b = 255 },
                { labelKey = "rollermine.hacked", suffix = "skin1_color", r = 255, g = 220, b = 60 },
                { labelKey = "rollermine.hostile", suffix = "skin2_color", r = 255, g = 80, b = 80 }
            }
        }
    }

    local function addRollerminePanel(panel)
        setupPage(panel, "page.rollermines.title", "page.rollermines.desc")

        local resetDefaults = {}

        for _, info in ipairs(ROLLERMINE_DEFAULTS) do
            local prefix = info.prefix
            local form = addSection(panel, info.titleKey, info.subtitleKey, true)
            addLightControls(form, prefix, {
                radiusMax = 400,
                modelElight = true,
                modelElightLabel = "control.add_model_elight"
            })

            resetDefaults[prefix .. "_enable"] = 1
            resetDefaults[prefix .. "_size"] = info.size
            resetDefaults[prefix .. "_brightness"] = info.brightness
            resetDefaults[prefix .. "_decay"] = info.decay
            resetDefaults[prefix .. "_models_elight"] = info.elight
            resetDefaults[prefix .. "_models_elight_size_mult"] = info.elightMult

            if info.colors then
                for _, colorInfo in ipairs(info.colors) do
                    local colorPrefix = prefix .. "_" .. colorInfo.suffix
                    addColorMixerControl(form, colorInfo.labelKey, colorPrefix .. "_r", colorPrefix .. "_g", colorPrefix .. "_b", colorInfo.r, colorInfo.g, colorInfo.b)
                    resetDefaults[colorPrefix .. "_r"] = colorInfo.r
                    resetDefaults[colorPrefix .. "_g"] = colorInfo.g
                    resetDefaults[colorPrefix .. "_b"] = colorInfo.b
                end
            end
        end

        addResetButton(panel, resetDefaults)
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

        local spitGlow = addSection(panel, "category.projectiles", nil, true)
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

    local function addClientPanels()
        registerPage("Projectiles", "BL_CombineBall", "menu.combine_ball", function(panel)
            setupPage(panel, "page.combine_ball.title", "page.combine_ball.desc")
            panel:CheckBox(phrase("control.enable"), "betterlights_combineball_enable")
            panel:NumSlider(phrase("control.radius"), "betterlights_combineball_size", 0, 800, 0)
            panel:NumSlider(phrase("control.brightness"), "betterlights_combineball_brightness", 0, 10, 2)
            panel:NumSlider(phrase("control.decay"), "betterlights_combineball_decay", 0, 5000, 0)
            addColorMixerControl(panel, "control.color", "betterlights_combineball_color_r", "betterlights_combineball_color_g", "betterlights_combineball_color_b")
            addResetButton(panel, {
                betterlights_combineball_enable = 1,
                betterlights_combineball_size = 320,
                betterlights_combineball_brightness = 2.5,
                betterlights_combineball_decay = 2000,
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
            addResetButton(panel, {
                betterlights_rpg_enable = 1,
                betterlights_rpg_size = 280,
                betterlights_rpg_brightness = 2.2,
                betterlights_rpg_decay = 2000,
                betterlights_rpg_color_r = 255,
                betterlights_rpg_color_g = 170,
                betterlights_rpg_color_b = 60,
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

    registerPage("Environment", "BL_Explosions", "menu.explosion_flash", function(panel)
        setupPage(panel, "page.explosion_flash.title", "page.explosion_flash.desc")
        panel:CheckBox(phrase("control.enable"), "betterlights_explosion_flash_enable")
        panel:NumSlider(phrase("control.radius"), "betterlights_explosion_flash_size", 0, 800, 0)
        panel:NumSlider(phrase("control.brightness"), "betterlights_explosion_flash_brightness", 0, 10, 2)
        panel:NumSlider(phrase("control.duration_seconds"), "betterlights_explosion_flash_time", 0, 1, 2)
        local detection = addSection(panel, "section.detection", nil, true)
        detection:CheckBox(phrase("control.detect_env_explosions"), "betterlights_explosion_detect_env")
        detection:CheckBox(phrase("control.detect_barrels"), "betterlights_explosion_detect_barrels")
        addColorMixerControl(panel, "control.color", "betterlights_explosion_flash_color_r", "betterlights_explosion_flash_color_g", "betterlights_explosion_flash_color_b")
        addResetButton(panel, {
            betterlights_explosion_flash_enable = 1,
            betterlights_explosion_flash_size = 380,
            betterlights_explosion_flash_brightness = 4.6,
            betterlights_explosion_flash_time = 0.18,
            betterlights_explosion_detect_env = 1,
            betterlights_explosion_detect_barrels = 1,
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
            behavior:CheckBox(phrase("control.replace_flashlight"), "betterlights_flashlight_player_enable")
            behavior:CheckBox(phrase("control.use_flashlight_sounds"), "betterlights_flashlight_custom_sounds")
            addHelpText(behavior, phrase("help.default_flashlight_sounds"))

            addResetButton(panel, {
                betterlights_flashlight_player_enable = 0,
                betterlights_flashlight_custom_sounds = 1,
            })
        end)

    registerPage("Flashlight", "BL_FlashlightPosition", "menu.position", function(panel)
            setupPage(panel, "page.flashlight_position.title", "page.flashlight_position.desc")
            local origin = addSection(panel, "section.origin", nil, true)
            origin:CheckBox(phrase("control.attach_beam_to_weapon"), "betterlights_flashlight_weapon_attachment")
            addHelpText(origin, phrase("help.attach_beam_to_weapon"))
            origin:NumSlider(phrase("control.forward_offset"), "betterlights_flashlight_forward_offset", -32, 96, 1)
            addHelpText(origin, phrase("help.forward_offset"))
            origin:NumSlider(phrase("control.attached_side_offset"), "betterlights_flashlight_attachment_offset", -24, 24, 1)
            addHelpText(origin, phrase("help.attached_side_offset"))
            origin:NumSlider(phrase("control.fallback_side_offset"), "betterlights_flashlight_fallback_offset", -24, 24, 1)
            addHelpText(origin, phrase("help.fallback_side_offset"))
            addResetButton(panel, {
                betterlights_flashlight_weapon_attachment = 1,
                betterlights_flashlight_forward_offset = 0,
                betterlights_flashlight_attachment_offset = 2,
                betterlights_flashlight_fallback_offset = 8,
            })
        end)

    registerPage("Flashlight", "BL_FlashlightVisual", "menu.visual", function(panel)
            BetterLights.ClearFlashlightKnownTextureCache()

            populateFlashlightVisualPanel(panel)
        end)

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
            addColorMixerControl(panel, "control.color", "betterlights_manhack_color_r", "betterlights_manhack_color_g", "betterlights_manhack_color_b")
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
            local glow = addSection(panel, "section.body_glow", nil, true)
            addLightControls(glow, "betterlights_cscanner", {
                radiusMax = 600,
                modelElight = true,
                modelElightLabel = "control.add_model_elight"
            })
            addColorMixerControl(glow, "control.glow_color", "betterlights_cscanner_color_r", "betterlights_cscanner_color_g", "betterlights_cscanner_color_b")

            local searchlight = addSection(panel, "section.searchlight", "section.searchlight.desc", true)
            searchlight:CheckBox(phrase("control.enable_searchlight"), "betterlights_cscanner_searchlight_enable")
            searchlight:CheckBox(phrase("control.include_clawscanner"), "betterlights_scanner_searchlight_include_clawscanner")
            searchlight:CheckBox(phrase("control.cast_shadows"), "betterlights_cscanner_searchlight_shadows")
            searchlight:NumSlider(phrase("control.fov"), "betterlights_cscanner_searchlight_fov", 1, 175, 0)
            searchlight:NumSlider(phrase("control.distance"), "betterlights_cscanner_searchlight_distance", 0, 3000, 0)
            searchlight:NumSlider(phrase("control.near_z"), "betterlights_cscanner_searchlight_near", 0, 128, 0)
            searchlight:NumSlider(phrase("control.brightness"), "betterlights_cscanner_searchlight_brightness", 0, 2, 2)
            addColorMixerControl(searchlight, "control.searchlight_color", "betterlights_cscanner_searchlight_color_r", "betterlights_cscanner_searchlight_color_g", "betterlights_cscanner_searchlight_color_b")
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
                betterlights_scanner_searchlight_include_clawscanner = 1,
                betterlights_cscanner_searchlight_shadows = 1,
                betterlights_cscanner_searchlight_fov = 38,
                betterlights_cscanner_searchlight_distance = 900,
                betterlights_cscanner_searchlight_near = 8,
                betterlights_cscanner_searchlight_brightness = 0.7,
                betterlights_cscanner_searchlight_color_r = 255,
                betterlights_cscanner_searchlight_color_g = 255,
                betterlights_cscanner_searchlight_color_b = 255,
            })
        end)

        registerPage("Eye Glow", "BL_CombineSoldiers", "menu.combine_soldiers", function(panel)
            addCombineEyeGlowPanel(panel)
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

    hook.Add("AddToolMenuTabs", "BetterLights_AddTab", function()
        spawnmenu.AddToolTab(TAB_ID, phrase("addon.name"), "icon16/lightbulb.png")
    end)

    hook.Add("AddToolMenuCategories", "BetterLights_AddCategories", function()
        registerCategories()
    end)

    hook.Add("PopulateToolMenu", "BetterLights_Populate", function()
        BetterLights.Menu.RegisterGeneralPanel()
        BetterLights.Menu.RegisterGunfirePanels()
        BetterLights.Menu.RegisterWeaponPanels()
        addClientPanels()
        BetterLights.Menu.RegisterDeveloperPanel()
        BetterLights.Menu.RegisterAboutPanel()
    end)
end
