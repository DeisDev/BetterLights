if CLIENT then

    local MENU = BetterLights.Menu

    local function phrase(key)
        return MENU.Phrase and MENU.Phrase(key) or language.GetPhrase("betterlights." .. key)
    end

    local function phraseFormat(key, ...)
        return string.format(phrase(key), ...)
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
            title = phraseFormat("changelog.entry_title", version),
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
                local title = tostring(entry.title or phraseFormat("changelog.entry_title", version))
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
        local currentVersion = normalizeVersion(BetterLights.VERSION)
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

    local function addChangelogText(parent, text, font, marginBottom)
        local label = vgui.Create("DLabel", parent)
        label:Dock(TOP)
        label:DockMargin(0, 0, 8, marginBottom or 8)
        label:SetText(text)
        label:SetFont(font or "DermaDefault")
        label:SetDark(true)
        label:SetWrap(true)
        label:SetAutoStretchVertical(true)
        return label
    end

    local function addChangelogItem(parent, text)
        return addChangelogText(parent, text, "DermaDefault", 10)
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
        header:SetTall(68)
        header.Paint = nil

        local title = vgui.Create("DLabel", header)
        title:Dock(TOP)
        title:DockMargin(0, 0, 16, 0)
        title:SetTall(34)
        title:SetText(entry.title)
        title:SetFont("DermaLarge")
        title:SetDark(true)

        local subtitle = vgui.Create("DLabel", header)
        subtitle:Dock(TOP)
        subtitle:DockMargin(0, 4, 16, 0)
        subtitle:SetTall(24)
        subtitle:SetText(entry.version ~= "" and phraseFormat("changelog.release_notes_for", entry.version) or phrase("changelog.release_notes"))
        subtitle:SetDark(true)

        if entry.placeholder then
            addChangelogText(panel, phrase("changelog.none_written"), "DermaDefaultBold")
            return
        end

        if #entry.items == 0 then
            addChangelogText(panel, phrase("changelog.none_found"), "DermaDefaultBold")
            return
        end

        for _, item in ipairs(entry.items) do
            addChangelogItem(panel, item)
        end
    end

    function MENU.OpenChangelogWindow()
        local entries, currentVersion = getChangelogEntries()

        local frame = vgui.Create("DFrame")
        frame:SetTitle(phrase("window.changelog_title"))
        frame:SetSize(math.min(ScrW() - 80, 780), math.min(ScrH() - 80, 560))
        frame:Center()
        frame:MakePopup()

        local body = vgui.Create("DPanel", frame)
        body:Dock(FILL)
        body:DockMargin(10, 10, 10, 10)
        body.Paint = nil

        local footer = vgui.Create("DPanel", frame)
        footer:Dock(BOTTOM)
        footer:DockMargin(10, 0, 10, 10)
        footer:SetTall(32)
        footer.Paint = nil

        local styleButton = MENU.StyleButton
        local workshopChangelog = styleButton(vgui.Create("DButton", footer))
        workshopChangelog:Dock(RIGHT)
        workshopChangelog:SetWide(190)
        workshopChangelog:SetText(phrase("button.workshop_changelog"))
        workshopChangelog:SetTooltip(phrase("tooltip.workshop_changelog"))
        workshopChangelog.DoClick = function()
            gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/changelog/3597784225")
        end

        local versions = vgui.Create("DScrollPanel", body)
        versions:Dock(LEFT)
        versions:DockMargin(10, 10, 0, 10)
        versions:SetWide(196)
        versions.Paint = nil
        versions:GetCanvas():DockPadding(8, 8, 8, 8)

        local versionTitle = vgui.Create("DLabel", versions)
        versionTitle:Dock(TOP)
        versionTitle:DockMargin(0, 0, 0, 8)
        versionTitle:SetTall(20)
        versionTitle:SetText(phrase("label.versions"))
        versionTitle:SetFont("DermaDefaultBold")
        versionTitle:SetDark(true)

        local detail = vgui.Create("DScrollPanel", body)
        detail:Dock(FILL)
        detail:DockMargin(10, 10, 10, 10)
        detail.Paint = nil
        detail:GetCanvas():DockPadding(12, 12, 12, 12)

        if #entries == 0 then
            populateChangelogDetail(detail, {
                title = phrase("addon.name"),
                items = { phrase("changelog.none_found") }
            })
            return
        end

        local selectedButton
        local function versionButtonText(entry, selected)
            local text = entry.version ~= "" and entry.version or entry.title
            if entry.version == currentVersion then
                text = text .. " - " .. phrase("label.current")
            end

            return selected and "> " .. text or text
        end

        local function selectEntry(entry, button)
            if IsValid(selectedButton) then
                selectedButton.BetterLightsSelected = false
                if selectedButton.BetterLightsEntry then
                    selectedButton:SetText(versionButtonText(selectedButton.BetterLightsEntry, false))
                end
            end

            selectedButton = button
            if IsValid(selectedButton) then
                selectedButton.BetterLightsSelected = true
                if selectedButton.BetterLightsEntry then
                    selectedButton:SetText(versionButtonText(selectedButton.BetterLightsEntry, true))
                end
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
            button.BetterLightsEntry = entry
            button:SetText(versionButtonText(entry, false))
            button:SetTooltip(entry.title)
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
end
