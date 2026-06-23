if CLIENT then
    local SERVER_BOOL_MESSAGE = "BetterLights_SetServerBool"
    local COLOR_BG = Color(245, 247, 250)
    local COLOR_BORDER = Color(175, 185, 196)
    local COLOR_TEXT = Color(32, 36, 40)
    local COLOR_MUTED = Color(84, 92, 102)
    local COLOR_ACCENT = Color(80, 150, 230)

    local function addResetButton(panel, defaults, label)
        local btn = vgui.Create("DButton")
        btn:SetTall(30)
        btn:SetText(label or "Reset to Defaults")
        btn:SetTooltip("Restore the settings on this page to their default values.")
        btn.Paint = function(self, w, h)
            local hovered = self:IsHovered()
            surface.SetDrawColor(hovered and Color(235, 241, 248) or Color(248, 249, 251))
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(COLOR_BORDER)
            surface.DrawOutlinedRect(0, 0, w, h)
        end
        btn.DoClick = function()
            for cvar, def in pairs(defaults) do
                RunConsoleCommand(cvar, tostring(def))
            end
        end

        panel:AddItem(btn)
    end

    local function addBrightnessResetButton(panel)
        local resetBrightness = panel:Button("Reset Brightness")
        resetBrightness.DoClick = function()
            RunConsoleCommand("betterlights_flashlight_brightness", "1.35")
        end
    end

    local function addFovResetButton(panel)
        local resetFov = panel:Button("Reset FOV")
        resetFov.DoClick = function()
            RunConsoleCommand("betterlights_flashlight_fov", "45")
        end
    end

    local function addBeamLengthResetButton(panel)
        local resetBeamLength = panel:Button("Reset Beam Length")
        resetBeamLength.DoClick = function()
            RunConsoleCommand("betterlights_flashlight_distance", "1200")
        end
    end

    local function setupPage(panel, title, subtitle)
        panel:ClearControls()

        local header = vgui.Create("DPanel")
        header:SetTall(subtitle and subtitle ~= "" and 62 or 42)
        header.Paint = function(_, w, h)
            surface.SetDrawColor(COLOR_BG)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(COLOR_ACCENT)
            surface.DrawRect(0, 0, 4, h)
            surface.SetDrawColor(COLOR_BORDER)
            surface.DrawOutlinedRect(0, 0, w, h)
        end

        local titleLabel = vgui.Create("DLabel", header)
        titleLabel:Dock(TOP)
        titleLabel:DockMargin(12, 8, 12, 0)
        titleLabel:SetTall(20)
        titleLabel:SetText(title)
        titleLabel:SetFont("DermaDefaultBold")
        titleLabel:SetTextColor(COLOR_TEXT)

        if subtitle and subtitle ~= "" then
            local body = vgui.Create("DLabel", header)
            body:Dock(FILL)
            body:DockMargin(12, 0, 12, 8)
            body:SetWrap(true)
            body:SetText(subtitle)
            body:SetTextColor(COLOR_MUTED)
        end

        panel:AddItem(header)
    end

    local function addSection(panel, title, subtitle, expanded)
        local form = vgui.Create("DForm")
        form:SetName(title)
        form:SetExpanded(expanded ~= false)

        if subtitle and subtitle ~= "" then
            form:Help(subtitle)
        end

        panel:AddItem(form)
        return form
    end

    local function addModelElightControls(panel, prefix, label)
        panel:CheckBox(label or "Add model elight", prefix .. "_models_elight")
        panel:NumSlider("Model elight radius x", prefix .. "_models_elight_size_mult", 0, 3, 2)
    end

    local function addLightControls(panel, prefix, options)
        options = options or {}

        if options.enableLabel ~= false then
            panel:CheckBox(options.enableLabel or "Enable", prefix .. "_enable")
        end

        if options.radiusCvar or options.radiusLabel ~= false then
            panel:NumSlider(options.radiusLabel or "Radius", options.radiusCvar or prefix .. "_size", options.radiusMin or 0, options.radiusMax or 400, options.radiusDecimals or 0)
        end

        if options.brightnessCvar or options.brightnessLabel ~= false then
            panel:NumSlider(options.brightnessLabel or "Brightness", options.brightnessCvar or prefix .. "_brightness", options.brightnessMin or 0, options.brightnessMax or 5, options.brightnessDecimals or 2)
        end

        if options.decayLabel ~= false then
            panel:NumSlider(options.decayLabel or "Decay", prefix .. "_decay", options.decayMin or 0, options.decayMax or 5000, options.decayDecimals or 0)
        end

        if options.modelElight then
            addModelElightControls(panel, prefix, options.modelElightLabel)
        end
    end

    local function addColorMixerControl(panel, label, rCvar, gCvar, bCvar, defaultR, defaultG, defaultB)
        local container = vgui.Create("DPanel")
        container:SetTall(254)
        container.Paint = function(_, w, h)
            surface.SetDrawColor(250, 251, 253)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(COLOR_BORDER)
            surface.DrawOutlinedRect(0, 0, w, h)
        end

        if label and label ~= "" then
            local text = vgui.Create("DLabel", container)
            text:Dock(TOP)
            text:DockMargin(8, 5, 8, 0)
            text:SetTall(18)
            text:SetText(label)
            text:SetFont("DermaDefaultBold")
            text:SetTextColor(COLOR_TEXT)
        end

        local mixer = vgui.Create("DColorMixer", container)
        mixer:Dock(FILL)
        mixer:DockMargin(8, label and label ~= "" and 3 or 8, 8, 8)
        mixer:SetTall(190)
        mixer:SetPalette(true)
        mixer:SetAlphaBar(false)
        mixer:SetWangs(true)

        local currentR = GetConVar(rCvar)
        local currentG = GetConVar(gCvar)
        local currentB = GetConVar(bCvar)
        mixer:SetColor(Color(
            currentR and currentR:GetInt() or defaultR or 255,
            currentG and currentG:GetInt() or defaultG or 255,
            currentB and currentB:GetInt() or defaultB or 255
        ))

        mixer.ValueChanged = function(_, color)
            if mixer.BetterLightsUpdating then return end

            RunConsoleCommand(rCvar, tostring(color.r))
            RunConsoleCommand(gCvar, tostring(color.g))
            RunConsoleCommand(bCvar, tostring(color.b))
        end

        mixer.Think = function()
            local cr = GetConVar(rCvar)
            local cg = GetConVar(gCvar)
            local cb = GetConVar(bCvar)
            if not (cr and cg and cb) then return end

            local r = cr:GetInt()
            local g = cg:GetInt()
            local b = cb:GetInt()
            local last = mixer.BetterLightsLastColor
            if last and last.r == r and last.g == g and last.b == b then return end

            mixer.BetterLightsUpdating = true
            mixer:SetColor(Color(r, g, b))
            mixer.BetterLightsUpdating = false
            mixer.BetterLightsLastColor = { r = r, g = g, b = b }
        end

        local reset = vgui.Create("DButton", container)
        reset:Dock(BOTTOM)
        reset:DockMargin(8, 0, 8, 8)
        reset:SetTall(26)
        reset:SetText("Reset Color")
        reset:SetTooltip("Restore only this color to its default value.")
        reset.DoClick = function()
            RunConsoleCommand(rCvar, tostring(defaultR or 255))
            RunConsoleCommand(gCvar, tostring(defaultG or 255))
            RunConsoleCommand(bCvar, tostring(defaultB or 255))
        end

        panel:AddItem(container)
        return mixer
    end

    local function copyText(text)
        if not SetClipboardText then return end

        SetClipboardText(text)
        notification.AddLegacy("Copied texture path.", NOTIFY_GENERIC, 3)
        surface.PlaySound("buttons/button14.wav")
    end

    local function addCurrentTexturePreview(panel, path)
        local preview = vgui.Create("DPanel")
        preview:SetTall(118)
        preview.Paint = function(_, w, h)
            surface.SetDrawColor(238, 238, 238, 255)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(170, 170, 170, 255)
            surface.DrawOutlinedRect(0, 0, w, h)
        end

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
        title:SetText("Current texture")
        title:SetTextColor(Color(35, 35, 35))

        local value = vgui.Create("DLabel", details)
        value:Dock(FILL)
        value:SetWrap(true)
        value:SetText(path)
        value:SetTextColor(Color(35, 35, 35))

        local copy = vgui.Create("DButton", details)
        copy:Dock(BOTTOM)
        copy:SetTall(24)
        copy:SetText("Copy Path")
        copy.DoClick = function()
            copyText(path)
        end

        panel:AddItem(preview)
    end

    local function addTextureTile(layout, path, refresh)
        local tile = vgui.Create("DPanel")
        tile:SetSize(132, 164)
        tile.Paint = function(_, w, h)
            surface.SetDrawColor(238, 238, 238, 255)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(170, 170, 170, 255)
            surface.DrawOutlinedRect(0, 0, w, h)
        end

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
            if BetterLights.SetFlashlightTexturePath and BetterLights.SetFlashlightTexturePath(path) then
                notification.AddLegacy("Flashlight texture changed.", NOTIFY_GENERIC, 3)
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
        label:SetTextColor(Color(35, 35, 35))

        local buttons = vgui.Create("DPanel", tile)
        buttons:Dock(BOTTOM)
        buttons:SetTall(28)
        buttons.Paint = nil

        local use = vgui.Create("DButton", buttons)
        use:Dock(LEFT)
        use:SetWide(64)
        use:SetText("Use")
        use.DoClick = preview.DoClick

        local copy = vgui.Create("DButton", buttons)
        copy:Dock(RIGHT)
        copy:SetWide(64)
        copy:SetText("Copy")
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
        net.Start(SERVER_BOOL_MESSAGE)
            net.WriteString(cvarName)
            net.WriteBool(value)
        net.SendToServer()
    end

    local function canChangeServerSettings()
        return game.SinglePlayer() or (IsValid(LocalPlayer()) and LocalPlayer():IsAdmin())
    end

    concommand.Add("betterlights_toggle", function()
        if not canChangeServerSettings() then
            notification.AddLegacy("Only admins can toggle Better Lights globally.", NOTIFY_ERROR, 4)
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
        row:SetTextColor(Color(0, 0, 0))
        if row.Label then
            row.Label:SetTextColor(Color(0, 0, 0))
        end
        row:SetValue((not cvar or cvar:GetBool()) and 1 or 0)
        row:SizeToContents()

        row.OnChange = function(_, value)
            if canChangeServerSettings() then
                requestServerBool(cvarName, value)
                return
            end

            notification.AddLegacy("Only admins can change BetterLights server settings.", NOTIFY_ERROR, 4)
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
        local btn = panel:Button("Reset Server Settings")
        btn.DoClick = function()
            if not canChangeServerSettings() then
                notification.AddLegacy("Only admins can reset BetterLights server settings.", NOTIFY_ERROR, 4)
                surface.PlaySound("buttons/button10.wav")
                return
            end

            for cvarName, value in pairs(defaults) do
                requestServerBool(cvarName, value ~= 0 and value ~= false)
            end
        end
    end

    local function normalizeVersion(version)
        if not version then return "" end

        local normalized = string.match(version, "v%d+%.%d+%.%d+")
        if normalized then return normalized end

        normalized = string.match(version, "%d+%.%d+%.%d+")
        if normalized then return "v" .. normalized end

        return string.Trim(tostring(version))
    end

    local function readChangelogJson()
        if not file or not file.Read then return nil end

        return file.Read("data_static/betterlights_changelog.json", "GAME")
    end

    local function createChangelogEntry(version)
        return {
            title = "Better Lights " .. version,
            version = version,
            items = {},
            placeholder = true
        }
    end

    local function parseChangelogJsonEntries(source)
        if not source or source == "" or not util or not util.JSONToTable then return {} end

        local decoded = util.JSONToTable(source)
        if not istable(decoded) then return {} end

        local entries = {}
        for _, entry in ipairs(decoded) do
            if istable(entry) then
                local version = normalizeVersion(entry.version or entry.title)
                local title = tostring(entry.title or ("Better Lights " .. version))
                local items = {}

                if istable(entry.items) then
                    for _, item in ipairs(entry.items) do
                        table.insert(items, tostring(item))
                    end
                end

                table.insert(entries, {
                    title = title,
                    version = version,
                    items = items
                })
            end
        end

        return entries
    end

    local function getChangelogEntries()
        local currentVersion = normalizeVersion(BetterLights and BetterLights.VERSION)
        local entries = parseChangelogJsonEntries(readChangelogJson())

        local currentIndex

        for index, entry in ipairs(entries) do
            if entry.version == currentVersion then
                currentIndex = index
                break
            end
        end

        if currentVersion ~= "" and not currentIndex then
            table.insert(entries, 1, createChangelogEntry(currentVersion))
        elseif currentIndex and currentIndex > 1 then
            local currentEntry = table.remove(entries, currentIndex)
            table.insert(entries, 1, currentEntry)
        end

        return entries, currentVersion
    end

    local function styleScrollBar(scrollPanel)
        local bar = scrollPanel:GetVBar()
        if not IsValid(bar) then return end

        bar:SetWide(10)
        bar.Paint = function(_, w, h)
            surface.SetDrawColor(235, 239, 244)
            surface.DrawRect(0, 0, w, h)
        end
        bar.btnGrip.Paint = function(_, w, h)
            surface.SetDrawColor(150, 164, 178)
            surface.DrawRect(2, 0, w - 4, h)
        end
        bar.btnUp.Paint = function(_, w, h)
            surface.SetDrawColor(235, 239, 244)
            surface.DrawRect(0, 0, w, h)
        end
        bar.btnDown.Paint = bar.btnUp.Paint
    end

    local function addChangelogText(parent, text, font, color, marginBottom)
        local label = vgui.Create("DLabel", parent)
        label:Dock(TOP)
        label:DockMargin(0, 0, 8, marginBottom or 8)
        label:SetText(text)
        label:SetFont(font or "DermaDefault")
        label:SetTextColor(color or COLOR_TEXT)
        label:SetWrap(true)
        label:SetAutoStretchVertical(true)
        return label
    end

    local function addChangelogItem(parent, text)
        local row = vgui.Create("DPanel", parent)
        row:Dock(TOP)
        row:DockMargin(0, 0, 8, 10)
        row:SetTall(math.max(48, 36 + (math.ceil(string.len(text) / 72) - 1) * 18))
        row.Paint = function(_, w, h)
            surface.SetDrawColor(248, 250, 252)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(215, 223, 232)
            surface.DrawOutlinedRect(0, 0, w, h)
            surface.SetDrawColor(COLOR_ACCENT)
            surface.DrawRect(0, 0, 4, h)
        end

        local label = vgui.Create("DLabel", row)
        label:Dock(FILL)
        label:DockMargin(18, 9, 12, 9)
        label:SetText(text)
        label:SetTextColor(COLOR_TEXT)
        label:SetWrap(true)
        label:SetAutoStretchVertical(true)

        return row
    end

    local function populateChangelogDetail(panel, entry)
        panel:Clear()
        if not entry then return end

        local canvas = panel:GetCanvas()
        if IsValid(canvas) then
            canvas:DockPadding(12, 12, 12, 12)
        end

        local header = vgui.Create("DPanel", panel)
        header:Dock(TOP)
        header:DockMargin(0, 0, 8, 12)
        header:SetTall(98)
        header.Paint = function(_, w, h)
            surface.SetDrawColor(COLOR_BG)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(COLOR_ACCENT)
            surface.DrawRect(0, 0, 5, h)
            surface.SetDrawColor(COLOR_BORDER)
            surface.DrawOutlinedRect(0, 0, w, h)
        end

        local title = vgui.Create("DLabel", header)
        title:Dock(TOP)
        title:DockMargin(16, 12, 16, 0)
        title:SetTall(34)
        title:SetText(entry.title)
        title:SetFont("DermaLarge")
        title:SetTextColor(COLOR_TEXT)

        local subtitle = vgui.Create("DLabel", header)
        subtitle:Dock(TOP)
        subtitle:DockMargin(16, 4, 16, 0)
        subtitle:SetTall(24)
        subtitle:SetText(entry.version ~= "" and ("Release notes for " .. entry.version) or "Release notes")
        subtitle:SetTextColor(COLOR_MUTED)

        if entry.placeholder then
            addChangelogText(panel, "No changelog written yet", "DermaDefaultBold", COLOR_MUTED)
            return
        end

        if #entry.items == 0 then
            addChangelogText(panel, "No changelog entries found.", "DermaDefaultBold", COLOR_MUTED)
            return
        end

        for _, item in ipairs(entry.items) do
            addChangelogItem(panel, item)
        end
    end

    local function openChangelogWindow()
        local entries, currentVersion = getChangelogEntries()

        local frame = vgui.Create("DFrame")
        frame:SetTitle("Better Lights Changelog")
        frame:SetSize(math.min(ScrW() - 80, 780), math.min(ScrH() - 80, 560))
        frame:Center()
        frame:MakePopup()

        local body = vgui.Create("DPanel", frame)
        body:Dock(FILL)
        body:DockMargin(10, 10, 10, 10)
        body.Paint = function(_, w, h)
            surface.SetDrawColor(242, 245, 248)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(COLOR_BORDER)
            surface.DrawOutlinedRect(0, 0, w, h)
        end

        local footer = vgui.Create("DPanel", frame)
        footer:Dock(BOTTOM)
        footer:DockMargin(10, 0, 10, 10)
        footer:SetTall(32)
        footer.Paint = nil

        local workshopChangelog = vgui.Create("DButton", footer)
        workshopChangelog:Dock(RIGHT)
        workshopChangelog:SetWide(190)
        workshopChangelog:SetText("Workshop Changelog")
        workshopChangelog:SetTooltip("Open the Steam Workshop changelog page.")
        workshopChangelog.DoClick = function()
            gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/changelog/3597784225")
        end

        local versions = vgui.Create("DScrollPanel", body)
        versions:Dock(LEFT)
        versions:DockMargin(10, 10, 0, 10)
        versions:SetWide(196)
        versions.Paint = function(_, w, h)
            surface.SetDrawColor(250, 251, 253)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(COLOR_BORDER)
            surface.DrawOutlinedRect(0, 0, w, h)
        end
        versions:GetCanvas():DockPadding(8, 8, 8, 8)
        styleScrollBar(versions)

        local versionTitle = vgui.Create("DLabel", versions)
        versionTitle:Dock(TOP)
        versionTitle:DockMargin(0, 0, 0, 8)
        versionTitle:SetTall(20)
        versionTitle:SetText("Versions")
        versionTitle:SetFont("DermaDefaultBold")
        versionTitle:SetTextColor(COLOR_TEXT)

        local detail = vgui.Create("DScrollPanel", body)
        detail:Dock(FILL)
        detail:DockMargin(10, 10, 10, 10)
        detail.Paint = function(_, w, h)
            surface.SetDrawColor(255, 255, 255)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(COLOR_BORDER)
            surface.DrawOutlinedRect(0, 0, w, h)
        end
        detail:GetCanvas():DockPadding(12, 12, 12, 12)
        styleScrollBar(detail)

        if #entries == 0 then
            populateChangelogDetail(detail, {
                title = "Better Lights",
                items = { "No changelog entries found." }
            })
            return
        end

        local selectedButton
        local function selectEntry(entry, button)
            if IsValid(selectedButton) then
                selectedButton.BetterLightsSelected = false
            end

            selectedButton = button
            if IsValid(selectedButton) then
                selectedButton.BetterLightsSelected = true
            end

            populateChangelogDetail(detail, entry)
        end

        local firstButton
        local currentButton
        local currentEntry

        for _, entry in ipairs(entries) do
            local button = vgui.Create("DButton", versions)
            button:Dock(TOP)
            button:DockMargin(0, 0, 0, 6)
            button:SetTall(42)
            button:SetText("")
            button:SetTooltip(entry.title)
            button.Paint = function(self, w, h)
                local selected = self.BetterLightsSelected
                local hovered = self:IsHovered()
                surface.SetDrawColor(selected and Color(225, 237, 250) or hovered and Color(243, 247, 252) or Color(248, 249, 251))
                surface.DrawRect(0, 0, w, h)
                surface.SetDrawColor(selected and COLOR_ACCENT or COLOR_BORDER)
                surface.DrawOutlinedRect(0, 0, w, h)
                if selected then
                    surface.SetDrawColor(COLOR_ACCENT)
                    surface.DrawRect(0, 0, 4, h)
                end

                draw.SimpleText(entry.version ~= "" and entry.version or entry.title, "DermaDefaultBold", 12, 9, COLOR_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                if entry.version == currentVersion then
                    draw.SimpleText("Current", "DermaDefault", 12, 24, COLOR_MUTED, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                end
            end
            button.DoClick = function()
                selectEntry(entry, button)
            end

            firstButton = firstButton or button
            if entry.version == currentVersion then
                currentButton = button
                currentEntry = entry
            end
        end

        selectEntry(currentEntry or entries[1], currentButton or firstButton)
    end

    local function getClientDefaultSettings()
        local defaults = {}
        local files = file.Find("lua/autorun/client/betterlights_*.lua", "GAME")

        for _, fileName in ipairs(files or {}) do
            local source = file.Read("lua/autorun/client/" .. fileName, "GAME")
            if source then
                for cvarName, defaultValue in string.gmatch(source, [[CreateClientConVar%(%s*"([^"]+)"%s*,%s*"([^"]*)"]]) do
                    defaults[cvarName] = defaultValue
                end
            end
        end

        return defaults
    end

    local function resetAllSettings()
        if not canChangeServerSettings() then
            notification.AddLegacy("Only admins can reset all BetterLights settings.", NOTIFY_ERROR, 4)
            surface.PlaySound("buttons/button10.wav")
            return
        end

        Derma_Query(
            "Reset all Better Lights settings to their default values?",
            "Reset Better Lights Settings",
            "Reset All",
            function()
                for cvarName, defaultValue in pairs(getClientDefaultSettings()) do
                    RunConsoleCommand(cvarName, defaultValue)
                end

                if BetterLights then
                    if BetterLights.ClearFlashlightRecentTextures then
                        BetterLights.ClearFlashlightRecentTextures()
                    end

                    if BetterLights.ClearFlashlightKnownTextureCache then
                        BetterLights.ClearFlashlightKnownTextureCache()
                    end
                end

                requestServerBool("betterlights_enable", true)
                notification.AddLegacy("BetterLights settings reset to defaults.", NOTIFY_GENERIC, 4)
                surface.PlaySound("buttons/button14.wav")
            end,
            "Cancel"
        )
    end

    populateFlashlightVisualPanel = function(panel, filterText)
        setupPage(panel, "Flashlight Visuals", "Beam appearance, projected texture, and texture library tools.")
        activeFlashlightVisualPanel = panel
        activeFlashlightVisualFilter = filterText

        if not BetterLights or not BetterLights.SetFlashlightTexturePath then
            panel:Help("Flashlight visual controls are unavailable because projected textures are not available.")
            return
        end

        local beam = addSection(panel, "Beam", "Core projected texture settings.", true)
        beam:CheckBox("Cast shadows", "betterlights_flashlight_shadows")
        beam:CheckBox("Flicker", "betterlights_flashlight_flicker")
        beam:CheckBox("Flashlight sway", "betterlights_flashlight_sway")
        beam:NumSlider("Brightness", "betterlights_flashlight_brightness", 0.1, 5, 2)
        addBrightnessResetButton(beam)
        beam:NumSlider("FOV", "betterlights_flashlight_fov", 10, 120, 0)
        addFovResetButton(beam)
        beam:NumSlider("Beam length", "betterlights_flashlight_distance", 128, 4096, 0)
        addBeamLengthResetButton(beam)

        local texture = addSection(panel, "Texture", "Use a material path such as effects/flashlight001. You can also paste paths with materials/ or .vmt/.vtf.", true)

        local currentCvar = GetConVar("betterlights_flashlight_texture")
        local typedPath = currentCvar and currentCvar:GetString() or "effects/flashlight001"
        local currentPath = BetterLights.GetFlashlightTexturePath and BetterLights.GetFlashlightTexturePath() or typedPath

        texture:Help("Current: " .. currentPath)
        addCurrentTexturePreview(texture, currentPath)

        local manualEntry = vgui.Create("DTextEntry")
        manualEntry:SetText(typedPath)
        manualEntry:SetUpdateOnType(false)
        texture:AddItem(manualEntry)

        local manualButtons = vgui.Create("DPanel")
        manualButtons:SetTall(28)
        manualButtons.Paint = nil

        local useManual = vgui.Create("DButton", manualButtons)
        useManual:Dock(LEFT)
        useManual:SetWide(76)
        useManual:SetText("Use")
        useManual.DoClick = function()
            local path = BetterLights.NormalizeFlashlightTexturePath(manualEntry:GetText())
            if BetterLights.SetFlashlightTexturePath(path) then
                notification.AddLegacy("Flashlight texture changed.", NOTIFY_GENERIC, 3)
                surface.PlaySound("buttons/button15.wav")
                return
            end

            notification.AddLegacy("That texture path was not found.", NOTIFY_ERROR, 4)
            surface.PlaySound("buttons/button10.wav")
        end

        local copyCurrent = vgui.Create("DButton", manualButtons)
        copyCurrent:Dock(LEFT)
        copyCurrent:DockMargin(6, 0, 0, 0)
        copyCurrent:SetWide(76)
        copyCurrent:SetText("Copy")
        copyCurrent.DoClick = function()
            copyText(currentPath)
        end

        local useDefault = vgui.Create("DButton", manualButtons)
        useDefault:Dock(LEFT)
        useDefault:DockMargin(6, 0, 0, 0)
        useDefault:SetWide(76)
        useDefault:SetText("Default")
        useDefault.DoClick = function()
            if BetterLights.SetFlashlightTexturePath then
                BetterLights.SetFlashlightTexturePath("effects/flashlight001")
            end
        end

        texture:AddItem(manualButtons)

        local recent = BetterLights.GetFlashlightRecentTextures and BetterLights.GetFlashlightRecentTextures() or {}
        if #recent > 0 then
            local recentSection = addSection(panel, "Recent Textures", nil, false)
            addTextureGrid(recentSection, recent, function()
                populateFlashlightVisualPanel(panel, filterText)
            end)

            local clearRecent = recentSection:Button("Clear Recent Textures")
            clearRecent.DoClick = function()
                if BetterLights.ClearFlashlightRecentTextures then
                    BetterLights.ClearFlashlightRecentTextures()
                end

                populateFlashlightVisualPanel(panel, filterText)
            end
        end

        local knownSection = addSection(panel, "Known Textures", "Search material paths discovered by Better Lights.", false)

        local refreshTextures = knownSection:Button("Refresh Textures")
        refreshTextures.DoClick = function()
            if BetterLights.ClearFlashlightKnownTextureCache then
                BetterLights.ClearFlashlightKnownTextureCache()
            end

            populateFlashlightVisualPanel(panel, filterText)
        end

        local filterRow = vgui.Create("DPanel")
        filterRow:SetTall(28)
        filterRow.Paint = nil

        local filter = vgui.Create("DTextEntry", filterRow)
        filter:Dock(FILL)
        filter:SetPlaceholderText("Search texture paths")
        filter:SetText(filterText or "")

        local applyFilter = vgui.Create("DButton", filterRow)
        applyFilter:Dock(RIGHT)
        applyFilter:SetWide(72)
        applyFilter:SetText("Search")
        applyFilter.DoClick = function()
            populateFlashlightVisualPanel(panel, filter:GetText())
        end

        filter.OnEnter = applyFilter.DoClick
        knownSection:AddItem(filterRow)

        local known = BetterLights.GetFlashlightKnownTextures and BetterLights.GetFlashlightKnownTextures() or {}
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
            panel:Help("No matching textures found.")
        end

        addResetButton(panel, {
            betterlights_flashlight_brightness = 1.35,
            betterlights_flashlight_fov = 45,
            betterlights_flashlight_distance = 1200,
            betterlights_flashlight_shadows = 1,
            betterlights_flashlight_flicker = 0,
            betterlights_flashlight_sway = 1,
            betterlights_flashlight_texture = "effects/flashlight001",
        }, "Reset Visual Settings")
    end

    cvars.AddChangeCallback("betterlights_flashlight_texture", function()
        timer.Simple(0, function()
            if not IsValid(activeFlashlightVisualPanel) then return end
            populateFlashlightVisualPanel(activeFlashlightVisualPanel, activeFlashlightVisualFilter)
        end)
    end, "BetterLights_FlashlightVisualRefresh")

    local WORLD_WEAPON_DEFAULTS = {
        { slug = "crossbow", name = "Crossbow", size = 34, brightness = 0.12, decay = 0, elight = 1, elightMult = 1.0, r = 255, g = 110, b = 25 },
        { slug = "toolgun", name = "Tool Gun", size = 42, brightness = 0.22, decay = 0, elight = 1, elightMult = 1.0, r = 255, g = 255, b = 255 },
        { slug = "gravitygun", name = "Gravity Gun", size = 48, brightness = 0.25, decay = 0, elight = 1, elightMult = 1.0, r = 255, g = 140, b = 40 },
        { slug = "physgun", name = "Physics Gun", size = 48, brightness = 0.25, decay = 0, elight = 1, elightMult = 1.0, r = 70, g = 130, b = 255 },
        { slug = "medkit", name = "Medkit", size = 42, brightness = 0.22, decay = 0, elight = 1, elightMult = 1.0, r = 150, g = 255, b = 150 },
        { slug = "bugbait", name = "Bugbait", size = 34, brightness = 0.12, decay = 0, elight = 1, elightMult = 1.0, r = 90, g = 170, b = 255 },
        { slug = "ar2", name = "Pulse Rifle", size = 38, brightness = 0.14, decay = 0, elight = 1, elightMult = 1.0, r = 255, g = 70, b = 55 },
        { slug = "frag", name = "Frag Grenade", size = 36, brightness = 0.2, decay = 0, elight = 1, elightMult = 1.0, r = 255, g = 40, b = 40 },
    }

    local function addWorldWeaponPanel(panel)
        setupPage(panel, "World Weapon Pickups", "Subtle lights for spawned or dropped weapon entities. Each weapon keeps its own radius, brightness, elight, and color.")
        local resetDefaults = {}

        local defs = BetterLights and BetterLights.GetWorldWeaponLightDefinitions and BetterLights.GetWorldWeaponLightDefinitions() or WORLD_WEAPON_DEFAULTS

        for _, info in ipairs(defs) do
            local prefix = "betterlights_world_weapon_" .. info.slug
            local form = addSection(panel, info.name, nil, false)
            addLightControls(form, prefix, {
                radiusMax = 300,
                brightnessMax = 2,
                modelElight = true,
                modelElightLabel = "Add model elight"
            })

            addColorMixerControl(form, "Color", prefix .. "_color_r", prefix .. "_color_g", prefix .. "_color_b", info.r, info.g, info.b)

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

    local AMMO_PICKUP_DEFAULTS = {
        { slug = "ar2", name = "AR2 Ammo", enable = 1, size = 40, brightness = 0.14, decay = 0, elight = 1, elightMult = 1.0, r = 90, g = 170, b = 255 },
        { slug = "ar2_large", name = "AR2 Ammo Large", enable = 1, size = 48, brightness = 0.16, decay = 0, elight = 1, elightMult = 1.0, r = 90, g = 170, b = 255 },
        { slug = "ar2_alt", name = "AR2 Alt Ammo", enable = 1, size = 60, brightness = 0.25, decay = 0, elight = 1, elightMult = 1.0, r = 255, g = 220, b = 60 },
        { slug = "smg1", name = "SMG Ammo", enable = 0, size = 32, brightness = 0.08, decay = 0, elight = 1, elightMult = 1.0, r = 235, g = 235, b = 235 },
        { slug = "smg1_large", name = "SMG Ammo Large", enable = 0, size = 32, brightness = 0.08, decay = 0, elight = 1, elightMult = 1.0, r = 235, g = 235, b = 235 },
        { slug = "smg1_grenade", name = "SMG Grenade", enable = 0, size = 32, brightness = 0.08, decay = 0, elight = 1, elightMult = 1.0, r = 235, g = 235, b = 235 },
        { slug = "357", name = ".357 Ammo", enable = 0, size = 32, brightness = 0.08, decay = 0, elight = 1, elightMult = 1.0, r = 235, g = 235, b = 235 },
        { slug = "357_large", name = ".357 Ammo Large", enable = 0, size = 32, brightness = 0.08, decay = 0, elight = 1, elightMult = 1.0, r = 235, g = 235, b = 235 },
        { slug = "crossbow", name = "Crossbow Bolts", enable = 0, size = 32, brightness = 0.08, decay = 0, elight = 1, elightMult = 1.0, r = 235, g = 235, b = 235 },
        { slug = "pistol", name = "Pistol Ammo", enable = 0, size = 32, brightness = 0.08, decay = 0, elight = 1, elightMult = 1.0, r = 235, g = 235, b = 235 },
        { slug = "pistol_large", name = "Pistol Ammo Large", enable = 0, size = 32, brightness = 0.08, decay = 0, elight = 1, elightMult = 1.0, r = 235, g = 235, b = 235 },
        { slug = "rpg_round", name = "RPG Round", enable = 0, size = 32, brightness = 0.08, decay = 0, elight = 1, elightMult = 1.0, r = 235, g = 235, b = 235 },
        { slug = "buckshot", name = "Buckshot", enable = 0, size = 32, brightness = 0.08, decay = 0, elight = 1, elightMult = 1.0, r = 235, g = 235, b = 235 },
    }

    local function addAmmoPickupPanel(panel)
        setupPage(panel, "Ammo Pickups", "AR2 ammo glows by default. Other ammo pickups are off by default and can be enabled here.")

        local resetDefaults = {}
        local defs = BetterLights and BetterLights.GetAmmoPickupLightDefinitions and BetterLights.GetAmmoPickupLightDefinitions() or AMMO_PICKUP_DEFAULTS

        for _, info in ipairs(defs) do
            local prefix = "betterlights_ammo_" .. info.slug
            local form = addSection(panel, info.name, info.enable == 0 and "Off by default." or "Enabled by default.", false)
            addLightControls(form, prefix, {
                radiusMax = 300,
                brightnessMax = 2,
                modelElight = true,
                modelElightLabel = "Add model elight"
            })
            addColorMixerControl(form, "Color", prefix .. "_color_r", prefix .. "_color_g", prefix .. "_color_b", info.r, info.g, info.b)

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
            title = "Combine Elite",
            subtitle = "combine_super_soldier",
            prefix = "bl_combine_soldier_elite",
            size = 40,
            brightness = 0.5,
            decay = 1500,
            r = 255,
            g = 72,
            b = 72
        },
        {
            title = "Prison Guard - Yellow",
            subtitle = "combine_soldier_prisonguard skin 0",
            prefix = "bl_combine_soldier_prisonguard_yellow",
            size = 40,
            brightness = 0.5,
            decay = 1500,
            r = 255,
            g = 220,
            b = 70
        },
        {
            title = "Prison Guard - Red",
            subtitle = "combine_soldier_prisonguard skin 1",
            prefix = "bl_combine_soldier_prisonguard_red",
            size = 40,
            brightness = 0.5,
            decay = 1500,
            r = 255,
            g = 72,
            b = 72
        },
        {
            title = "Standard Soldier - Blue",
            subtitle = "combine_soldier skin 0",
            prefix = "bl_combine_soldier_standard_blue",
            size = 40,
            brightness = 0.5,
            decay = 1500,
            r = 95,
            g = 150,
            b = 255
        },
        {
            title = "Standard Soldier - Orange",
            subtitle = "combine_soldier skin 1",
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
        setupPage(panel, "Combine Soldier Eye Glow", "Eye glow colors for Combine Soldier variants and detected skins.")

        local resetDefaults = {}

        for _, info in ipairs(COMBINE_EYE_GLOW_DEFAULTS) do
            local prefix = info.prefix
            local form = addSection(panel, info.title, info.subtitle, false)
            addLightControls(form, prefix, {
                radiusMax = 200
            })
            addColorMixerControl(form, "Color", prefix .. "_color_r", prefix .. "_color_g", prefix .. "_color_b", info.r, info.g, info.b)

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
            title = "Rollermines",
            subtitle = "Shared settings for npc_rollermine lights. Colors are chosen from the rollermine skin.",
            prefix = "betterlights_rollermine",
            size = 110,
            brightness = 0.6,
            decay = 2000,
            elight = 1,
            elightMult = 1.0,
            colors = {
                { label = "Default Rollermine - Blue", suffix = "color", r = 110, g = 190, b = 255 },
                { label = "Hacked Rollermine - Yellow", suffix = "skin1_color", r = 255, g = 220, b = 60 },
                { label = "Hostile Rollermine - Red", suffix = "skin2_color", r = 255, g = 80, b = 80 }
            }
        }
    }

    local function addRollerminePanel(panel)
        setupPage(panel, "Rollermines", "Glow for rollermines and their color variants. The chosen color gets brighter when it attacks.")

        local resetDefaults = {}

        for _, info in ipairs(ROLLERMINE_DEFAULTS) do
            local prefix = info.prefix
            local form = addSection(panel, info.title, info.subtitle, true)
            addLightControls(form, prefix, {
                radiusMax = 400,
                modelElight = true,
                modelElightLabel = "Add model elight"
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
                    addColorMixerControl(form, colorInfo.label, colorPrefix .. "_r", colorPrefix .. "_g", colorPrefix .. "_b", colorInfo.r, colorInfo.g, colorInfo.b)
                    resetDefaults[colorPrefix .. "_r"] = colorInfo.r
                    resetDefaults[colorPrefix .. "_g"] = colorInfo.g
                    resetDefaults[colorPrefix .. "_b"] = colorInfo.b
                end
            end
        end

        addResetButton(panel, resetDefaults)
    end

    local function addClientPanels()
        spawnmenu.AddToolMenuOption("Better Lights", "General", "BL_Admin", "Admin", "", "", function(panel)
            setupPage(panel, "Better Lights", "Global controls and maintenance tools. Server settings require admin access.")

            local server = addSection(panel, "Server", "Controls the addon globally for this server.", true)
            addServerBoolCheckbox(server, "Enable Better Lights", "betterlights_enable")
            addServerBoolResetButton(server, {
                betterlights_enable = 1,
            })

            local maintenance = addSection(panel, "Maintenance", "Reset local client options, cached flashlight textures, and global enable state.", true)
            local resetAllBtn = maintenance:Button("Reset All Better Lights Settings")
            resetAllBtn.DoClick = resetAllSettings
            maintenance:Help("Optional bind command: betterlights_toggle")
        end)

        spawnmenu.AddToolMenuOption("Better Lights", "Projectiles", "BL_CombineBall", "Combine AR2 Orb", "", "", function(panel)
            setupPage(panel, "Combine AR2 Orb", "Blue/cyan light for prop_combine_ball.")
            panel:CheckBox("Enable", "betterlights_combineball_enable")
            panel:NumSlider("Radius", "betterlights_combineball_size", 0, 800, 0)
            panel:NumSlider("Brightness", "betterlights_combineball_brightness", 0, 10, 2)
            panel:NumSlider("Decay", "betterlights_combineball_decay", 0, 5000, 0)
            addColorMixerControl(panel, "Color", "betterlights_combineball_color_r", "betterlights_combineball_color_g", "betterlights_combineball_color_b")
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

    spawnmenu.AddToolMenuOption("Better Lights", "Gunfire", "BL_BulletImpacts", "Bullet Impacts", "", "", function(panel)
            setupPage(panel, "Bullet Impacts", "Subtle flashes when bullets hit surfaces. AR2 impacts can use their own blue tint.")
            local generic = addSection(panel, "Generic Impacts", "Used for most bullet impact flashes.", true)
            addLightControls(generic, "betterlights_bullet_impact", {
                radiusMax = 300,
                brightnessMax = 2,
                decayLabel = false
            })
            addColorMixerControl(generic, "Color", "betterlights_bullet_impact_color_r", "betterlights_bullet_impact_color_g", "betterlights_bullet_impact_color_b")

            local ar2 = addSection(panel, "AR2 Impacts", "Optional Combine Rifle tint override.", true)
            addLightControls(ar2, "betterlights_bullet_impact_ar2", {
                enableLabel = "Enable AR2 tint",
                radiusLabel = "Radius",
                radiusMax = 300,
                brightnessLabel = "Brightness",
                brightnessMax = 2,
                decayLabel = false
            })
            addColorMixerControl(ar2, "Color", "betterlights_bullet_impact_ar2_color_r", "betterlights_bullet_impact_ar2_color_g", "betterlights_bullet_impact_ar2_color_b")
            addResetButton(panel, {
                betterlights_bullet_impact_enable = 1,
                betterlights_bullet_impact_size = 60,
                betterlights_bullet_impact_brightness = 0.25,
                betterlights_bullet_impact_ar2_enable = 1,
                betterlights_bullet_impact_ar2_size = 70,
                betterlights_bullet_impact_ar2_brightness = 0.3,
                betterlights_bullet_impact_color_r = 255,
                betterlights_bullet_impact_color_g = 160,
                betterlights_bullet_impact_color_b = 60,
                betterlights_bullet_impact_ar2_color_r = 110,
                betterlights_bullet_impact_ar2_color_g = 190,
                betterlights_bullet_impact_ar2_color_b = 255,
            })
        end)

    spawnmenu.AddToolMenuOption("Better Lights", "Gunfire", "BL_MuzzleFlash", "Muzzle Flash", "", "", function(panel)
            setupPage(panel, "Muzzle Flash", "Brief light at the muzzle when a weapon fires. AR2 muzzle flashes can use their own tint.")
            local generic = addSection(panel, "Generic Muzzle Flash", nil, true)
            addLightControls(generic, "betterlights_muzzle", {
                radiusMax = 300,
                brightnessMax = 2,
                decayLabel = false
            })
            addColorMixerControl(generic, "Color", "betterlights_muzzle_color_r", "betterlights_muzzle_color_g", "betterlights_muzzle_color_b")

            local ar2 = addSection(panel, "AR2 Muzzle Flash", "Optional Combine Rifle tint override.", true)
            addLightControls(ar2, "betterlights_muzzle_ar2", {
                enableLabel = "Enable AR2 tint",
                radiusMax = 300,
                brightnessMax = 2,
                decayLabel = false
            })
            addColorMixerControl(ar2, "Color", "betterlights_muzzle_ar2_color_r", "betterlights_muzzle_ar2_color_g", "betterlights_muzzle_ar2_color_b")
            addResetButton(panel, {
                betterlights_muzzle_enable = 1,
                betterlights_muzzle_size = 250,
                betterlights_muzzle_brightness = 2.0,
                betterlights_muzzle_ar2_enable = 1,
                betterlights_muzzle_ar2_size = 250,
                betterlights_muzzle_ar2_brightness = 2.0,
                betterlights_muzzle_color_r = 255,
                betterlights_muzzle_color_g = 170,
                betterlights_muzzle_color_b = 90,
                betterlights_muzzle_ar2_color_r = 110,
                betterlights_muzzle_ar2_color_g = 190,
                betterlights_muzzle_ar2_color_b = 255,
            })
        end)

    spawnmenu.AddToolMenuOption("Better Lights", "Projectiles", "BL_Bolt", "Crossbow Bolt", "", "", function(panel)
            setupPage(panel, "Crossbow Bolt", "Warm orange light for crossbow bolts.")
            panel:CheckBox("Enable", "betterlights_bolt_enable")
            panel:NumSlider("Radius", "betterlights_bolt_size", 0, 800, 0)
            panel:NumSlider("Brightness", "betterlights_bolt_brightness", 0, 10, 2)
            panel:NumSlider("Decay", "betterlights_bolt_decay", 0, 5000, 0)
            addColorMixerControl(panel, "Color", "betterlights_bolt_color_r", "betterlights_bolt_color_g", "betterlights_bolt_color_b")
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

    spawnmenu.AddToolMenuOption("Better Lights", "Weapons", "BL_CrossbowHeld", "Crossbow (Held)", "", "", function(panel)
            setupPage(panel, "Crossbow (Held)", "Subtle orange light while holding the Crossbow.")
            panel:CheckBox("Enable", "betterlights_crossbow_hold_enable")
            panel:NumSlider("Radius", "betterlights_crossbow_hold_size", 0, 300, 0)
            panel:NumSlider("Brightness", "betterlights_crossbow_hold_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_crossbow_hold_decay", 0, 5000, 0)
            addColorMixerControl(panel, "Color", "betterlights_crossbow_hold_color_r", "betterlights_crossbow_hold_color_g", "betterlights_crossbow_hold_color_b")
            addResetButton(panel, {
                betterlights_crossbow_hold_enable = 1,
                betterlights_crossbow_hold_size = 30,
                betterlights_crossbow_hold_brightness = 0.32,
                betterlights_crossbow_hold_decay = 2000,
                betterlights_crossbow_hold_color_r = 255,
                betterlights_crossbow_hold_color_g = 140,
                betterlights_crossbow_hold_color_b = 40,
            })
        end)

    spawnmenu.AddToolMenuOption("Better Lights", "Pickups", "BL_WorldWeapons", "World Weapons", "", "", function(panel)
            addWorldWeaponPanel(panel)
        end)

    spawnmenu.AddToolMenuOption("Better Lights", "Pickups", "BL_AmmoPickups", "Ammo Pickups", "", "", function(panel)
            addAmmoPickupPanel(panel)
        end)

    spawnmenu.AddToolMenuOption("Better Lights", "Projectiles", "BL_RPG", "RPG Rocket", "", "", function(panel)
            setupPage(panel, "RPG Rocket", "Warm flame light for RPG rockets in flight.")
            panel:CheckBox("Enable", "betterlights_rpg_enable")
            panel:NumSlider("Radius", "betterlights_rpg_size", 0, 800, 0)
            panel:NumSlider("Brightness", "betterlights_rpg_brightness", 0, 10, 2)
            panel:NumSlider("Decay", "betterlights_rpg_decay", 0, 5000, 0)
            addColorMixerControl(panel, "Color", "betterlights_rpg_color_r", "betterlights_rpg_color_g", "betterlights_rpg_color_b")
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

        spawnmenu.AddToolMenuOption("Better Lights", "Projectiles", "BL_AntlionSpit", "Antlion Spit", "", "", function(panel)
            setupPage(panel, "Antlion Spit", "Acid-green glow on Antlion Worker spit with a small impact flash.")
            local glow = addSection(panel, "In-Flight Glow", "grenade_spit while it is moving.", true)
            glow:CheckBox("Enable glow", "betterlights_antlion_spit_enable")
            glow:NumSlider("Radius", "betterlights_antlion_spit_size", 0, 400, 0)
            glow:NumSlider("Brightness", "betterlights_antlion_spit_brightness", 0, 5, 2)
            glow:NumSlider("Decay", "betterlights_antlion_spit_decay", 0, 5000, 0)
            addColorMixerControl(glow, "Glow Color", "betterlights_antlion_spit_color_r", "betterlights_antlion_spit_color_g", "betterlights_antlion_spit_color_b")

            local flash = addSection(panel, "Impact Flash", nil, true)
            flash:CheckBox("Flash on impact", "betterlights_antlion_spit_flash_enable")
            flash:NumSlider("Radius", "betterlights_antlion_spit_flash_size", 0, 800, 0)
            flash:NumSlider("Brightness", "betterlights_antlion_spit_flash_brightness", 0, 10, 2)
            flash:NumSlider("Duration", "betterlights_antlion_spit_flash_time", 0, 1, 2)
            addColorMixerControl(flash, "Flash Color", "betterlights_antlion_spit_flash_color_r", "betterlights_antlion_spit_flash_color_g", "betterlights_antlion_spit_flash_color_b")
            addResetButton(panel, {
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
        end)

    spawnmenu.AddToolMenuOption("Better Lights", "Environment", "BL_Fire", "Burning Entities", "", "", function(panel)
            setupPage(panel, "Burning Entities", "Light for entities on fire, with optional flicker and model-only elight.")
            panel:CheckBox("Enable", "betterlights_fire_enable")
            panel:NumSlider("Radius", "betterlights_fire_size", 0, 800, 0)
            panel:NumSlider("Brightness", "betterlights_fire_brightness", 0, 10, 2)
            panel:NumSlider("Decay", "betterlights_fire_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_fire_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_fire_models_elight_size_mult", 0, 3, 2)
            addColorMixerControl(panel, "Color", "betterlights_fire_color_r", "betterlights_fire_color_g", "betterlights_fire_color_b")
            panel:CheckBox("Flicker", "betterlights_fire_flicker_enable")
            panel:NumSlider("Flicker amount", "betterlights_fire_flicker_amount", 0, 1, 2)
            panel:NumSlider("Flicker size amt", "betterlights_fire_flicker_size_amount", 0, 1, 2)
            panel:NumSlider("Flicker speed", "betterlights_fire_flicker_speed", 0, 30, 1)
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

        spawnmenu.AddToolMenuOption("Better Lights", "Environment", "BL_Explosions", "Explosion Flash (Generic)", "", "", function(panel)
                setupPage(panel, "Explosion Flash", "Brief flash when generic explosions occur, such as env_explosion or explosive barrels.")
                panel:CheckBox("Enable", "betterlights_explosion_flash_enable")
                panel:NumSlider("Radius", "betterlights_explosion_flash_size", 0, 800, 0)
                panel:NumSlider("Brightness", "betterlights_explosion_flash_brightness", 0, 10, 2)
                panel:NumSlider("Duration (s)", "betterlights_explosion_flash_time", 0, 1, 2)
                panel:Help("Detection")
                panel:CheckBox("Detect env_* explosion entities", "betterlights_explosion_detect_env")
                panel:CheckBox("Detect explosive barrels", "betterlights_explosion_detect_barrels")
                addColorMixerControl(panel, "Color", "betterlights_explosion_flash_color_r", "betterlights_explosion_flash_color_g", "betterlights_explosion_flash_color_b")
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
    spawnmenu.AddToolMenuOption("Better Lights", "Projectiles", "BL_Grenade", "Frag Grenade", "", "", function(panel)
            setupPage(panel, "Frag Grenade", "Dim red light for thrown frag grenades.")
            panel:CheckBox("Enable", "betterlights_grenade_enable")
            panel:NumSlider("Radius", "betterlights_grenade_size", 0, 400, 0)
            panel:NumSlider("Brightness", "betterlights_grenade_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_grenade_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_grenade_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_grenade_models_elight_size_mult", 0, 3, 2)
            addColorMixerControl(panel, "Color", "betterlights_grenade_color_r", "betterlights_grenade_color_g", "betterlights_grenade_color_b")
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

    spawnmenu.AddToolMenuOption("Better Lights", "NPCs", "BL_CombineMine", "Combine Mine", "", "", function(panel)
            setupPage(panel, "Combine Mine", "Idle blue glow with a red alert glow when you are within range.")
            local alert = addSection(panel, "Alert Glow", "Visible when the mine is armed or a player is nearby.", true)
            alert:CheckBox("Enable", "betterlights_combine_mine_enable")
            alert:NumSlider("Detection range", "betterlights_combine_mine_range", 0, 1024, 0)
            alert:NumSlider("Radius", "betterlights_combine_mine_size", 0, 400, 0)
            alert:NumSlider("Brightness", "betterlights_combine_mine_brightness", 0, 5, 2)
            alert:NumSlider("Decay", "betterlights_combine_mine_decay", 0, 5000, 0)
            addColorMixerControl(alert, "Alert Color", "betterlights_combine_mine_alert_color_r", "betterlights_combine_mine_alert_color_g", "betterlights_combine_mine_alert_color_b")

            local idle = addSection(panel, "Idle Glow", "Low blue light while the mine is idle.", false)
            idle:CheckBox("Idle glow", "betterlights_combine_mine_idle_enable")
            idle:NumSlider("Radius", "betterlights_combine_mine_idle_size", 0, 400, 0)
            idle:NumSlider("Brightness", "betterlights_combine_mine_idle_brightness", 0, 2, 2)
            addColorMixerControl(idle, "Idle Color", "betterlights_combine_mine_idle_color_r", "betterlights_combine_mine_idle_color_g", "betterlights_combine_mine_idle_color_b")

            local behavior = addSection(panel, "Pulse and Model Light", nil, false)
            behavior:CheckBox("Pulse on alert", "betterlights_combine_mine_pulse_enable")
            behavior:NumSlider("Pulse amount", "betterlights_combine_mine_pulse_amount", 0, 1, 2)
            behavior:NumSlider("Pulse speed", "betterlights_combine_mine_pulse_speed", 0, 30, 1)
            addModelElightControls(behavior, "betterlights_combine_mine", "Add model elight")
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

    spawnmenu.AddToolMenuOption("Better Lights", "NPCs", "BL_CombineMineResistance", "Resistance Mine", "", "", function(panel)
            setupPage(panel, "Resistance Mine", "Friendly mine alert glow. Uses the hostile Combine Mine range and idle settings.")
            panel:CheckBox("Enable", "betterlights_combine_mine_resistance_enable")
            panel:NumSlider("Alert radius size", "betterlights_combine_mine_resistance_size", 0, 400, 0)
            panel:NumSlider("Alert brightness", "betterlights_combine_mine_resistance_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_combine_mine_resistance_decay", 0, 5000, 0)
            addColorMixerControl(panel, "Alert Color", "betterlights_combine_mine_resistance_color_r", "betterlights_combine_mine_resistance_color_g", "betterlights_combine_mine_resistance_color_b")
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

    spawnmenu.AddToolMenuOption("Better Lights", "Weapons", "BL_Physgun", "Physics Gun", "", "", function(panel)
            setupPage(panel, "Physics Gun", "Light that matches your Weapon Color, with optional override color.")
            panel:CheckBox("Enable", "betterlights_physgun_enable")
            panel:NumSlider("Radius", "betterlights_physgun_size", 0, 300, 0)
            panel:NumSlider("Brightness", "betterlights_physgun_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_physgun_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_physgun_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_physgun_models_elight_size_mult", 0, 3, 2)
            panel:CheckBox("Override Weapon Color", "betterlights_physgun_color_override")
            addColorMixerControl(panel, "Override Color", "betterlights_physgun_color_r", "betterlights_physgun_color_g", "betterlights_physgun_color_b")
            addResetButton(panel, {
                betterlights_physgun_enable = 1,
                betterlights_physgun_size = 33,
                betterlights_physgun_brightness = 0.3,
                betterlights_physgun_decay = 2000,
                betterlights_physgun_models_elight = 1,
                betterlights_physgun_models_elight_size_mult = 1.0,
                betterlights_physgun_color_override = 0,
                betterlights_physgun_color_r = 70,
                betterlights_physgun_color_g = 130,
                betterlights_physgun_color_b = 255,
            })
        end)

    spawnmenu.AddToolMenuOption("Better Lights", "Weapons", "BL_GravityGun", "Gravity Gun", "", "", function(panel)
            setupPage(panel, "Gravity Gun", "Warm orange physcannon light with a separate supercharged color.")
            panel:CheckBox("Enable", "betterlights_gravitygun_enable")
            panel:NumSlider("Radius", "betterlights_gravitygun_size", 0, 300, 0)
            panel:NumSlider("Brightness", "betterlights_gravitygun_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_gravitygun_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_gravitygun_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_gravitygun_models_elight_size_mult", 0, 3, 2)
            addColorMixerControl(panel, "Color", "betterlights_gravitygun_color_r", "betterlights_gravitygun_color_g", "betterlights_gravitygun_color_b")
            addColorMixerControl(panel, "Supercharged Color", "betterlights_gravitygun_super_color_r", "betterlights_gravitygun_super_color_g", "betterlights_gravitygun_super_color_b")
            addResetButton(panel, {
                betterlights_gravitygun_enable = 1,
                betterlights_gravitygun_size = 36,
                betterlights_gravitygun_brightness = 0.35,
                betterlights_gravitygun_decay = 2000,
                betterlights_gravitygun_models_elight = 1,
                betterlights_gravitygun_models_elight_size_mult = 1.0,
                betterlights_gravitygun_color_r = 255,
                betterlights_gravitygun_color_g = 140,
                betterlights_gravitygun_color_b = 40,
                betterlights_gravitygun_super_color_r = 40,
                betterlights_gravitygun_super_color_g = 140,
                betterlights_gravitygun_super_color_b = 255,
            })
        end)

    spawnmenu.AddToolMenuOption("Better Lights", "Weapons", "BL_RPG_Held", "RPG (Held)", "", "", function(panel)
            setupPage(panel, "RPG (Held)", "Subtle red light at the laser dot and on your left hand.")
            panel:CheckBox("Enable", "betterlights_rpg_hold_enable")
            panel:NumSlider("Radius", "betterlights_rpg_hold_size", 0, 300, 0)
            panel:NumSlider("Brightness", "betterlights_rpg_hold_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_rpg_hold_decay", 0, 5000, 0)
            addColorMixerControl(panel, "Color", "betterlights_rpg_hold_color_r", "betterlights_rpg_hold_color_g", "betterlights_rpg_hold_color_b")
            addResetButton(panel, {
                betterlights_rpg_hold_enable = 1,
                betterlights_rpg_hold_size = 24,
                betterlights_rpg_hold_brightness = 0.22,
                betterlights_rpg_hold_decay = 2000,
                betterlights_rpg_hold_color_r = 255,
                betterlights_rpg_hold_color_g = 60,
                betterlights_rpg_hold_color_b = 60,
            })
        end)

    spawnmenu.AddToolMenuOption("Better Lights", "Weapons", "BL_ToolGun", "Tool Gun", "", "", function(panel)
            setupPage(panel, "Tool Gun", "Small white light at the muzzle with wall-safe placement.")
            panel:CheckBox("Enable", "betterlights_toolgun_enable")
            panel:NumSlider("Radius", "betterlights_toolgun_size", 0, 300, 0)
            panel:NumSlider("Brightness", "betterlights_toolgun_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_toolgun_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_toolgun_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_toolgun_models_elight_size_mult", 0, 3, 2)
            addColorMixerControl(panel, "Color", "betterlights_toolgun_color_r", "betterlights_toolgun_color_g", "betterlights_toolgun_color_b")
            addResetButton(panel, {
                betterlights_toolgun_enable = 1,
                betterlights_toolgun_size = 28,
                betterlights_toolgun_brightness = 0.225,
                betterlights_toolgun_decay = 2000,
                betterlights_toolgun_models_elight = 1,
                betterlights_toolgun_models_elight_size_mult = 1.0,
                betterlights_toolgun_color_r = 255,
                betterlights_toolgun_color_g = 255,
                betterlights_toolgun_color_b = 255,
            })
        end)

    spawnmenu.AddToolMenuOption("Better Lights", "Flashlight", "BL_FlashlightGeneral", "General", "", "", function(panel)
            setupPage(panel, "Player Flashlight", "Replacement flashlight controls. Server and gamemode flashlight rules are still respected.")
            local behavior = addSection(panel, "Behavior", nil, true)
            behavior:CheckBox("Replace my flashlight with Better Lights", "betterlights_flashlight_player_enable")
            behavior:CheckBox("Use Better Lights flashlight sounds", "betterlights_flashlight_custom_sounds")
            behavior:Help("Disable custom sounds to use vanilla flashlight sound events, including Workshop sound replacements.")
            addResetButton(panel, {
                betterlights_flashlight_player_enable = 0,
                betterlights_flashlight_custom_sounds = 1,
            })
        end)

    spawnmenu.AddToolMenuOption("Better Lights", "Flashlight", "BL_FlashlightPosition", "Position", "", "", function(panel)
            setupPage(panel, "Flashlight Position", "Fine tune where the player flashlight starts from.")
            local origin = addSection(panel, "Origin", nil, true)
            origin:CheckBox("Attach beam to weapon", "betterlights_flashlight_weapon_attachment")
            origin:Help("When disabled, the flashlight uses your eye position instead.")
            origin:NumSlider("Forward offset", "betterlights_flashlight_forward_offset", -32, 96, 1)
            origin:Help("This value is added on top of the default beam position.")
            origin:NumSlider("Attached side offset", "betterlights_flashlight_attachment_offset", -24, 24, 1)
            origin:NumSlider("Fallback side offset", "betterlights_flashlight_fallback_offset", -24, 24, 1)
            addResetButton(panel, {
                betterlights_flashlight_weapon_attachment = 1,
                betterlights_flashlight_forward_offset = 0,
                betterlights_flashlight_attachment_offset = 2,
                betterlights_flashlight_fallback_offset = 8,
            })
        end)

    spawnmenu.AddToolMenuOption("Better Lights", "Flashlight", "BL_FlashlightVisual", "Visual", "", "", function(panel)
            if BetterLights and BetterLights.ClearFlashlightKnownTextureCache then
                BetterLights.ClearFlashlightKnownTextureCache()
            end

            populateFlashlightVisualPanel(panel)
        end)

    spawnmenu.AddToolMenuOption("Better Lights", "Projectiles", "BL_HeliBomb", "Helicopter Bomb", "", "", function(panel)
            setupPage(panel, "Helicopter Bomb", "Red glow on helicopter bombs with a brief explosion flash.")
            local glow = addSection(panel, "Bomb Glow", nil, true)
            addLightControls(glow, "betterlights_heli_bomb", {
                radiusMax = 400,
                modelElight = true,
                modelElightLabel = "Add model elight"
            })
            addColorMixerControl(glow, "Glow Color", "betterlights_heli_bomb_color_r", "betterlights_heli_bomb_color_g", "betterlights_heli_bomb_color_b")

            local flash = addSection(panel, "Explosion Flash", nil, true)
            flash:CheckBox("Flash on explosion", "betterlights_heli_bomb_flash_enable")
            flash:NumSlider("Radius", "betterlights_heli_bomb_flash_size", 0, 800, 0)
            flash:NumSlider("Brightness", "betterlights_heli_bomb_flash_brightness", 0, 10, 2)
            flash:NumSlider("Duration", "betterlights_heli_bomb_flash_time", 0, 1, 2)
            addColorMixerControl(flash, "Flash Color", "betterlights_heli_bomb_flash_color_r", "betterlights_heli_bomb_flash_color_g", "betterlights_heli_bomb_flash_color_b")
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

    spawnmenu.AddToolMenuOption("Better Lights", "Projectiles", "BL_Magnusson", "Magnusson Device", "", "", function(panel)
            setupPage(panel, "Magnusson Device", "Light blue glow on Magnusson devices with a brief explosion flash.")
            local glow = addSection(panel, "Device Glow", nil, true)
            addLightControls(glow, "betterlights_magnusson", {
                radiusMax = 400,
                modelElight = true,
                modelElightLabel = "Add model elight"
            })
            addColorMixerControl(glow, "Glow Color", "betterlights_magnusson_color_r", "betterlights_magnusson_color_g", "betterlights_magnusson_color_b")

            local flash = addSection(panel, "Explosion Flash", nil, true)
            flash:CheckBox("Flash on explosion", "betterlights_magnusson_flash_enable")
            flash:NumSlider("Radius", "betterlights_magnusson_flash_size", 0, 800, 0)
            flash:NumSlider("Brightness", "betterlights_magnusson_flash_brightness", 0, 10, 2)
            flash:NumSlider("Duration", "betterlights_magnusson_flash_time", 0, 1, 2)
            addColorMixerControl(flash, "Flash Color", "betterlights_magnusson_flash_color_r", "betterlights_magnusson_flash_color_g", "betterlights_magnusson_flash_color_b")
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

    spawnmenu.AddToolMenuOption("Better Lights", "NPCs", "BL_Manhack", "Manhack", "", "", function(panel)
            setupPage(panel, "Manhack", "Red glow for Combine Manhacks.")
            panel:CheckBox("Enable", "betterlights_manhack_enable")
            panel:NumSlider("Radius", "betterlights_manhack_size", 0, 400, 0)
            panel:NumSlider("Brightness", "betterlights_manhack_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_manhack_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_manhack_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_manhack_models_elight_size_mult", 0, 3, 2)
            addColorMixerControl(panel, "Color", "betterlights_manhack_color_r", "betterlights_manhack_color_g", "betterlights_manhack_color_b")
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

    spawnmenu.AddToolMenuOption("Better Lights", "NPCs", "BL_AntlionGrub", "Antlion Grub", "", "", function(panel)
            setupPage(panel, "Antlion Grub", "Subtle green glow on antlion grubs.")
            panel:CheckBox("Enable", "betterlights_antlion_grub_enable")
            panel:NumSlider("Radius", "betterlights_antlion_grub_size", 0, 400, 0)
            panel:NumSlider("Brightness", "betterlights_antlion_grub_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_antlion_grub_decay", 0, 5000, 0)
            addColorMixerControl(panel, "Color", "betterlights_antlion_grub_color_r", "betterlights_antlion_grub_color_g", "betterlights_antlion_grub_color_b")
            addResetButton(panel, {
                betterlights_antlion_grub_enable = 1,
                betterlights_antlion_grub_size = 70,
                betterlights_antlion_grub_brightness = 0.35,
                betterlights_antlion_grub_decay = 2000,
                betterlights_antlion_grub_color_r = 120,
                betterlights_antlion_grub_color_g = 255,
                betterlights_antlion_grub_color_b = 120,
            })
        end)

    spawnmenu.AddToolMenuOption("Better Lights", "NPCs", "BL_AntlionGuardian", "Antlion Guardian", "", "", function(panel)
            setupPage(panel, "Antlion Guardian", "Green glow for Antlion Guardian detection.")
            panel:CheckBox("Enable", "betterlights_antlion_guardian_enable")
            panel:NumSlider("Radius", "betterlights_antlion_guardian_size", 0, 800, 0)
            panel:NumSlider("Brightness", "betterlights_antlion_guardian_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_antlion_guardian_decay", 0, 5000, 0)
            addColorMixerControl(panel, "Color", "betterlights_antlion_guardian_color_r", "betterlights_antlion_guardian_color_g", "betterlights_antlion_guardian_color_b")
            addResetButton(panel, {
                betterlights_antlion_guardian_enable = 1,
                betterlights_antlion_guardian_size = 180,
                betterlights_antlion_guardian_brightness = 0.6,
                betterlights_antlion_guardian_decay = 2000,
                betterlights_antlion_guardian_color_r = 120,
                betterlights_antlion_guardian_color_g = 255,
                betterlights_antlion_guardian_color_b = 140,
            })
        end)

        spawnmenu.AddToolMenuOption("Better Lights", "NPCs", "BL_AntlionWorker", "Antlion Worker", "", "", function(panel)
            setupPage(panel, "Antlion Worker", "Subtle glow for Antlion Workers.")
            panel:CheckBox("Enable", "betterlights_antlion_worker_enable")
            panel:NumSlider("Radius", "betterlights_antlion_worker_size", 0, 800, 0)
            panel:NumSlider("Brightness", "betterlights_antlion_worker_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_antlion_worker_decay", 0, 5000, 0)
            addColorMixerControl(panel, "Color", "betterlights_antlion_worker_color_r", "betterlights_antlion_worker_color_g", "betterlights_antlion_worker_color_b")
            addResetButton(panel, {
                betterlights_antlion_worker_enable = 1,
                betterlights_antlion_worker_size = 120,
                betterlights_antlion_worker_brightness = 0.55,
                betterlights_antlion_worker_decay = 2000,
                betterlights_antlion_worker_color_r = 180,
                betterlights_antlion_worker_color_g = 240,
                betterlights_antlion_worker_color_b = 120,
            })
        end)

    spawnmenu.AddToolMenuOption("Better Lights", "NPCs", "BL_Rollermines", "Rollermines", "", "", function(panel)
            addRollerminePanel(panel)
        end)

    spawnmenu.AddToolMenuOption("Better Lights", "NPCs", "BL_CScanner", "Combine Scanner", "", "", function(panel)
            setupPage(panel, "Combine Scanner", "Cool white/blue glow for Combine Scanners with optional searchlight.")
            local glow = addSection(panel, "Body Glow", nil, true)
            addLightControls(glow, "betterlights_cscanner", {
                radiusMax = 600,
                modelElight = true,
                modelElightLabel = "Add model elight"
            })
            addColorMixerControl(glow, "Glow Color", "betterlights_cscanner_color_r", "betterlights_cscanner_color_g", "betterlights_cscanner_color_b")

            local searchlight = addSection(panel, "Searchlight", "Projected scanner light. Shadows can be expensive.", true)
            searchlight:CheckBox("Enable searchlight", "betterlights_cscanner_searchlight_enable")
            searchlight:CheckBox("Include npc_clawscanner", "betterlights_scanner_searchlight_include_clawscanner")
            searchlight:CheckBox("Cast shadows", "betterlights_cscanner_searchlight_shadows")
            searchlight:NumSlider("FOV", "betterlights_cscanner_searchlight_fov", 1, 175, 0)
            searchlight:NumSlider("Distance", "betterlights_cscanner_searchlight_distance", 0, 3000, 0)
            searchlight:NumSlider("Near Z", "betterlights_cscanner_searchlight_near", 0, 128, 0)
            searchlight:NumSlider("Brightness", "betterlights_cscanner_searchlight_brightness", 0, 2, 2)
            addColorMixerControl(searchlight, "Searchlight Color", "betterlights_cscanner_searchlight_color_r", "betterlights_cscanner_searchlight_color_g", "betterlights_cscanner_searchlight_color_b")
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

        spawnmenu.AddToolMenuOption("Better Lights", "Eye Glow", "BL_CombineSoldiers", "Combine Soldiers", "", "", function(panel)
            addCombineEyeGlowPanel(panel)
        end)

    spawnmenu.AddToolMenuOption("Better Lights", "Pickups", "BL_Pickup_Battery", "Battery", "", "", function(panel)
            setupPage(panel, "Battery", "Subtle glow for item_battery.")
            panel:CheckBox("Enable", "betterlights_item_battery_enable")
            panel:NumSlider("Radius", "betterlights_item_battery_size", 0, 300, 0)
            panel:NumSlider("Brightness", "betterlights_item_battery_brightness", 0, 2, 2)
            panel:NumSlider("Decay", "betterlights_item_battery_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_item_battery_models_elight")
            panel:NumSlider("Elight radius x", "betterlights_item_battery_models_elight_size_mult", 0, 3, 2)
            addColorMixerControl(panel, "Color", "betterlights_item_battery_color_r", "betterlights_item_battery_color_g", "betterlights_item_battery_color_b")
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

    spawnmenu.AddToolMenuOption("Better Lights", "Pickups", "BL_Pickup_Vial", "Health Vial", "", "", function(panel)
            setupPage(panel, "Health Vial", "Subtle glow for item_healthvial.")
            panel:CheckBox("Enable", "betterlights_item_healthvial_enable")
            panel:NumSlider("Radius", "betterlights_item_healthvial_size", 0, 300, 0)
            panel:NumSlider("Brightness", "betterlights_item_healthvial_brightness", 0, 2, 2)
            panel:NumSlider("Decay", "betterlights_item_healthvial_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_item_healthvial_models_elight")
            panel:NumSlider("Elight radius x", "betterlights_item_healthvial_models_elight_size_mult", 0, 3, 2)
            addColorMixerControl(panel, "Color", "betterlights_item_healthvial_color_r", "betterlights_item_healthvial_color_g", "betterlights_item_healthvial_color_b")
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

    spawnmenu.AddToolMenuOption("Better Lights", "Pickups", "BL_Pickup_HealthKit", "Health Kit", "", "", function(panel)
            setupPage(panel, "Health Kit", "Subtle glow for item_healthkit.")
            panel:CheckBox("Enable", "betterlights_item_healthkit_enable")
            panel:NumSlider("Radius", "betterlights_item_healthkit_size", 0, 300, 0)
            panel:NumSlider("Brightness", "betterlights_item_healthkit_brightness", 0, 2, 2)
            panel:NumSlider("Decay", "betterlights_item_healthkit_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_item_healthkit_models_elight")
            panel:NumSlider("Elight radius x", "betterlights_item_healthkit_models_elight_size_mult", 0, 3, 2)
            addColorMixerControl(panel, "Color", "betterlights_item_healthkit_color_r", "betterlights_item_healthkit_color_g", "betterlights_item_healthkit_color_b")
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

        spawnmenu.AddToolMenuOption("Better Lights", "Environment", "BL_Chargers", "Chargers", "", "", function(panel)
                setupPage(panel, "Chargers", "Subtle glows for suit and health wall chargers.")
                local suit = addSection(panel, "Suit Charger", nil, true)
                addLightControls(suit, "betterlights_suitcharger", {
                    enableLabel = "Enable",
                    radiusMax = 300,
                    brightnessMax = 2,
                    modelElight = true,
                    modelElightLabel = "Add model elight"
                })
                addColorMixerControl(suit, "Suit Color", "betterlights_suitcharger_color_r", "betterlights_suitcharger_color_g", "betterlights_suitcharger_color_b")

                local health = addSection(panel, "Health Charger", nil, true)
                addLightControls(health, "betterlights_healthcharger", {
                    enableLabel = "Enable",
                    radiusMax = 300,
                    brightnessMax = 2,
                    modelElight = true,
                    modelElightLabel = "Add model elight"
                })
                addColorMixerControl(health, "Health Color", "betterlights_healthcharger_color_r", "betterlights_healthcharger_color_g", "betterlights_healthcharger_color_b")
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

    local function addAboutPanel()
        spawnmenu.AddToolMenuOption("Better Lights", "About", "BL_About", "About", "", "", function(panel)
            setupPage(panel, "About Better Lights", "Version, support links, source code, and changelog.")
            local version = BetterLights.VERSION

            local author = vgui.Create("DPanel")
            author:SetTall(96)
            author.Paint = function(_, w, h)
                surface.SetDrawColor(250, 251, 253)
                surface.DrawRect(0, 0, w, h)
                surface.SetDrawColor(COLOR_BORDER)
                surface.DrawOutlinedRect(0, 0, w, h)
                surface.SetDrawColor(COLOR_ACCENT)
                surface.DrawRect(0, 0, 4, h)
            end

            local avatar = vgui.Create("AvatarImage", author)
            avatar:Dock(LEFT)
            avatar:DockMargin(14, 14, 14, 14)
            avatar:SetWide(64)
            avatar:SetSteamID("76561199216202475", 64)

            local authorInfo = vgui.Create("DPanel", author)
            authorInfo:Dock(FILL)
            authorInfo:DockMargin(0, 12, 12, 12)
            authorInfo.Paint = nil

            local title = vgui.Create("DLabel", authorInfo)
            title:Dock(TOP)
            title:SetTall(22)
            title:SetText("Better Lights " .. version)
            title:SetFont("DermaDefaultBold")
            title:SetTextColor(COLOR_TEXT)

            local byline = vgui.Create("DLabel", authorInfo)
            byline:Dock(TOP)
            byline:SetTall(20)
            byline:SetText("Created by Catsniffer")
            byline:SetTextColor(COLOR_MUTED)

            local profileBtn = vgui.Create("DButton", authorInfo)
            profileBtn:Dock(BOTTOM)
            profileBtn:SetTall(26)
            profileBtn:SetText("Open Steam Profile")
            profileBtn.DoClick = function()
                gui.OpenURL("https://steamcommunity.com/id/catsniffermeow/")
            end

            panel:AddItem(author)
            panel:Help("Please report bugs and feature requests on GitHub.")
            panel:Help("Please do not use Steam comments or the author's Steam profile for support.")
            panel:Help("License: GPL-3.0-or-later. You may share and modify this addon under the GPL terms; it is provided without warranty.")

            local links = addSection(panel, "Links", nil, true)
            local issueBtn = links:Button("Report Issue / Request Feature")
            issueBtn.DoClick = function()
                gui.OpenURL("https://github.com/DeisDev/BetterLights/issues/new/choose")
            end

            local sourceBtn = links:Button("View Source Code on GitHub")
            sourceBtn.DoClick = function()
                gui.OpenURL("https://github.com/DeisDev/BetterLights")
            end

            local licenseBtn = links:Button("View License")
            licenseBtn.DoClick = function()
                gui.OpenURL("https://github.com/DeisDev/BetterLights/blob/main/LICENSE.md")
            end

            local workshopBtn = links:Button("Steam Workshop Page")
            workshopBtn.DoClick = function()
                gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/?id=3597784225")
            end

            local changelogBtn = links:Button("Changelog")
            changelogBtn.DoClick = function()
                openChangelogWindow()
            end

            local otherAddonsBtn = links:Button("Other Addons")
            otherAddonsBtn.DoClick = function()
                gui.OpenURL("https://steamcommunity.com/workshop/filedetails/?id=3551812511")
            end
        end)
    end


    hook.Add("AddToolMenuTabs", "BetterLights_AddTab", function()
        spawnmenu.AddToolTab("Better Lights", "Better Lights", "icon16/lightbulb.png")
    end)

    hook.Add("PopulateToolMenu", "BetterLights_Populate", function()
        spawnmenu.AddToolCategory("Better Lights", "General", "General")
        spawnmenu.AddToolCategory("Better Lights", "Flashlight", "Flashlight")
        spawnmenu.AddToolCategory("Better Lights", "Weapons", "Held Weapon Lights")
        spawnmenu.AddToolCategory("Better Lights", "Projectiles", "Projectiles & Explosions")
        spawnmenu.AddToolCategory("Better Lights", "NPCs", "NPCs & Traps")
        spawnmenu.AddToolCategory("Better Lights", "Eye Glow", "NPC Eye Glow")
        spawnmenu.AddToolCategory("Better Lights", "Gunfire", "Gunfire Effects")
        spawnmenu.AddToolCategory("Better Lights", "Environment", "World & Environment")
        spawnmenu.AddToolCategory("Better Lights", "Pickups", "Pickups & Ammo")
        spawnmenu.AddToolCategory("Better Lights", "About", "About")
        addClientPanels()
        addAboutPanel()
    end)
end
