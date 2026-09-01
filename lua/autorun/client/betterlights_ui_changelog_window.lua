if CLIENT then

    local BL = BetterLights
    local MENU = BL.Menu

    local AUTO_OPEN_TIMER = "BetterLights_AutoOpenChangelog"
    local SEEN_VERSION_COOKIE = "betterlights_changelog_seen_version"
    local AUTO_OPEN_CVAR = "betterlights_changelog_auto_open"
    local SIMULATE_UPDATE_COMMAND = "betterlights_changelog_simulate_update"
    local TEST_PREVIOUS_VERSION = "v0.0.0-test"
    local WINDOW_MARGIN = 80
    local MIN_FRAME_WIDTH = 560
    local MIN_FRAME_HEIGHT = 360
    local DEFAULT_FRAME_WIDTH = 840
    local DEFAULT_FRAME_HEIGHT = 520
    local cvar_auto_open = BL.CreateClientConVar(
        AUTO_OPEN_CVAR,
        "1",
        true,
        false,
        "Show the Better Lights changelog once after the addon updates",
        0,
        1,
        { includeInProfiles = false }
    )

    timer.Remove(AUTO_OPEN_TIMER)
    if IsValid(MENU._changelogFrame) then
        MENU._changelogFrame:Remove()
    end
    MENU._changelogFrame = nil

    local function phrase(key)
        return MENU.Phrase and MENU.Phrase(key) or language.GetPhrase("betterlights." .. key)
    end

    local function phraseFormat(key, ...)
        return string.format(phrase(key), ...)
    end

    local function normalizeVersion(version)
        if not version then return "" end

        version = string.Trim(tostring(version))

        local normalized = string.match(version, "v%d+%.%d+%.%d+[%w%-%.]*")
        if normalized then return normalized end

        normalized = string.match(version, "%d+%.%d+%.%d+[%w%-%.]*")
        if normalized then return "v" .. normalized end

        return version
    end

    local function getCurrentVersion()
        return normalizeVersion(BL.VERSION)
    end

    local function isDeveloperEnabled()
        local developer = GetConVar("developer")
        return developer and developer:GetInt() >= 1
    end

    local function getFrameSize()
        local maxWidth = math.max(320, ScrW() - WINDOW_MARGIN)
        local maxHeight = math.max(300, ScrH() - WINDOW_MARGIN)
        local minWidth = math.min(MIN_FRAME_WIDTH, maxWidth)
        local minHeight = math.min(MIN_FRAME_HEIGHT, maxHeight)
        return math.min(DEFAULT_FRAME_WIDTH, maxWidth),
            math.min(DEFAULT_FRAME_HEIGHT, maxHeight),
            minWidth,
            minHeight
    end

    local function markVersionSeen(version)
        version = normalizeVersion(version)
        if version == "" then return false end

        cookie.Set(SEEN_VERSION_COOKIE, version)
        return true
    end

    local function readChangelog()
        if not file or not file.Read then return nil end

        return file.Read("data_static/betterlights_changelog.txt", "GAME")
    end

    local function createChangelogEntry(version)
        return {
            title = phraseFormat("changelog.entry_title", version),
            version = version,
            items = {},
            placeholder = true
        }
    end

    local function parseChangelogEntries(source)
        if not source or source == "" then return {} end

        source = string.gsub(source, "\r\n", "\n")
        source = string.gsub(source, "\r", "\n")

        local entries = {}
        local currentEntry
        local readingItems = false

        for line in string.gmatch(source .. "\n", "(.-)\n") do
            line = string.Trim(line)

            if line ~= "" then
                if not currentEntry then
                    local title = string.match(line, "^%[b%](.-)%[/b%]$")
                    if not title or title == "" then return {} end

                    currentEntry = {
                        title = title,
                        version = normalizeVersion(title),
                        items = {}
                    }
                elseif not readingItems then
                    if line ~= "[list]" then return {} end
                    readingItems = true
                elseif line == "[/list]" then
                    table.insert(entries, currentEntry)
                    currentEntry = nil
                    readingItems = false
                else
                    local item = string.match(line, "^%[%*%](.+)$")
                    if not item then return {} end

                    item = string.Trim(item)
                    if item == "" then return {} end
                    table.insert(currentEntry.items, item)
                end
            end
        end

        if currentEntry or readingItems then return {} end

        return entries
    end

    local function getChangelogEntries()
        local currentVersion = getCurrentVersion()
        local entries = parseChangelogEntries(readChangelog())

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
        return addChangelogText(parent, "•  " .. text, "DermaDefault", 10)
    end

    local function populateChangelogDetail(panel, entry)
        panel:Clear()
        if not entry then return end

        panel:GetVBar():SetScroll(0)

        local canvas = panel:GetCanvas()
        if IsValid(canvas) then
            canvas:DockPadding(12, 12, 12, 12)
        end

        local header = vgui.Create("DPanel", panel)
        header:Dock(TOP)
        header:DockMargin(0, 0, 8, 10)
        header:SetTall(64)
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
        local itemCount = #entry.items
        local summaryKey = itemCount == 1 and "changelog.change_count_one" or "changelog.change_count_many"
        subtitle:SetText(phraseFormat(summaryKey, itemCount))
        subtitle:SetFont("DermaDefaultBold")
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

    function MENU.OpenChangelogWindow(showUpdateNotice)
        if IsValid(MENU._changelogFrame) then
            MENU._changelogFrame:MakePopup()
            return MENU._changelogFrame
        end

        local entries, currentVersion = getChangelogEntries()
        local width, height, minWidth, minHeight = getFrameSize()

        local frame = vgui.Create("DFrame")
        frame:SetTitle(showUpdateNotice
            and phraseFormat("window.changelog_updated_title", currentVersion)
            or phrase("window.changelog_title"))
        frame:SetSize(width, height)
        frame:SetMinWidth(minWidth)
        frame:SetMinHeight(minHeight)
        frame:SetSizable(true)
        frame:SetScreenLock(true)
        frame:SetDeleteOnClose(true)
        frame:Center()
        frame:MakePopup()
        MENU._changelogFrame = frame

        local originalOnRemove = frame.OnRemove
        frame.OnRemove = function(self)
            if originalOnRemove then
                originalOnRemove(self)
            end

            if MENU._changelogFrame == self then
                MENU._changelogFrame = nil
            end
        end

        markVersionSeen(currentVersion)

        local body = vgui.Create("DPanel", frame)
        body:Dock(FILL)
        body:DockMargin(10, 10, 10, 10)

        if showUpdateNotice then
            local updateNotice = vgui.Create("DLabel", body)
            updateNotice:Dock(TOP)
            updateNotice:DockMargin(12, 12, 12, 0)
            updateNotice:SetText(phraseFormat("changelog.updated_notice", currentVersion))
            updateNotice:SetFont("DermaDefaultBold")
            updateNotice:SetDark(true)
            updateNotice:SetWrap(true)
            updateNotice:SetAutoStretchVertical(true)
        end

        local versions = vgui.Create("DListView", body)
        versions:Dock(LEFT)
        versions:DockMargin(12, 12, 0, 12)
        versions:SetWide(196)
        versions:SetMultiSelect(false)
        versions:SetSortable(false)
        versions:SetHeaderHeight(28)
        versions:SetDataHeight(28)
        versions:AddColumn(phrase("label.versions"))

        local release = vgui.Create("DPanel", body)
        release:Dock(FILL)
        release:DockMargin(14, 12, 12, 12)
        release.Paint = nil

        local footer = vgui.Create("DPanel", release)
        footer:Dock(BOTTOM)
        footer:DockMargin(0, 8, 0, 0)
        footer:SetTall(66)
        footer.Paint = nil

        local preference = vgui.Create("DPanel", footer)
        preference:Dock(TOP)
        preference:SetTall(26)
        preference.Paint = nil

        local neverShow = vgui.Create("DCheckBoxLabel", preference)
        neverShow:Dock(LEFT)
        neverShow:DockMargin(0, 7, 0, 0)
        neverShow:SetText(phrase("control.never_show_changelog"))
        neverShow:SetTooltip(phrase("tooltip.never_show_changelog"))
        neverShow:SetValue(cvar_auto_open:GetBool() and 0 or 1)
        neverShow:SetDark(true)
        neverShow:SizeToContents()
        neverShow.OnChange = function(_, value)
            BL.ApplyClientSetting(AUTO_OPEN_CVAR, value and 0 or 1)
        end

        local actions = vgui.Create("DPanel", footer)
        actions:Dock(BOTTOM)
        actions:SetTall(32)
        actions.Paint = nil

        local close = vgui.Create("DButton", actions)
        close:Dock(RIGHT)
        close:SetWide(104)
        close:SetText(phrase(showUpdateNotice and "button.got_it" or "button.close"))
        close:SetFont("DermaDefaultBold")
        close.DoClick = function()
            frame:Close()
        end

        local workshopChangelog = vgui.Create("DButton", actions)
        workshopChangelog:Dock(RIGHT)
        workshopChangelog:DockMargin(0, 0, 8, 0)
        workshopChangelog:SetWide(176)
        workshopChangelog:SetText(phrase("button.workshop_changelog"))
        workshopChangelog:SetTooltip(phrase("tooltip.workshop_changelog"))
        workshopChangelog.DoClick = function()
            gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/changelog/3597784225")
        end

        local detail = vgui.Create("DScrollPanel", release)
        detail:Dock(FILL)
        detail.Paint = nil
        detail:GetCanvas():DockPadding(8, 8, 8, 8)

        if #entries == 0 then
            populateChangelogDetail(detail, {
                title = phrase("addon.name"),
                items = { phrase("changelog.none_found") }
            })
            return frame
        end

        local function versionRowText(entry)
            local text = entry.version ~= "" and entry.version or entry.title
            if entry.version == currentVersion then
                return phraseFormat("changelog.current_version", text)
            end

            return text
        end

        versions.OnRowSelected = function(_, _, row)
            populateChangelogDetail(detail, row.BetterLightsEntry)
        end

        local firstRow
        local currentRow

        for _, entry in ipairs(entries) do
            local row = versions:AddLine(versionRowText(entry))
            row.BetterLightsEntry = entry
            row:SetTooltip(entry.title)

            firstRow = firstRow or row
            if entry.version == currentVersion then
                currentRow = row
            end
        end

        versions:SelectItem(currentRow or firstRow)
        versions:RequestFocus()
        return frame
    end

    local function checkForUpdatedChangelog()
        local currentVersion = getCurrentVersion()
        if currentVersion == "" then return end

        local seenVersion = normalizeVersion(cookie.GetString(SEEN_VERSION_COOKIE, ""))
        if not cvar_auto_open:GetBool() then
            markVersionSeen(currentVersion)
            return
        end

        if seenVersion ~= currentVersion then
            MENU.OpenChangelogWindow(true)
        end
    end

    local function queueUpdatedChangelogCheck()
        timer.Create(AUTO_OPEN_TIMER, 1, 1, checkForUpdatedChangelog)
    end

    function MENU._SimulateUpdatedChangelog()
        if not isDeveloperEnabled() then return false end

        local currentVersion = getCurrentVersion()
        if currentVersion == "" then return false end

        timer.Remove(AUTO_OPEN_TIMER)
        if IsValid(MENU._changelogFrame) then
            MENU._changelogFrame:Remove()
        end

        cookie.Set(SEEN_VERSION_COOKIE, TEST_PREVIOUS_VERSION)
        queueUpdatedChangelogCheck()
        return true
    end

    concommand.Remove(SIMULATE_UPDATE_COMMAND)
    concommand.Add(
        SIMULATE_UPDATE_COMMAND,
        function()
            if MENU._SimulateUpdatedChangelog() then
                print("[Better Lights] Queued the simulated update changelog check.")
                return
            end

            print("[Better Lights] Enable developer mode with 'developer 1' to simulate an update.")
        end,
        nil,
        "Replay the automatic Better Lights update changelog check"
    )

    hook.Add("InitPostEntity", "BetterLights_AutoOpenChangelog", queueUpdatedChangelogCheck)

    if IsValid(LocalPlayer()) then
        queueUpdatedChangelogCheck()
    end
end
