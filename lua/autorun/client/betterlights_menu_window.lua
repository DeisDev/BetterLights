if CLIENT then
    local MENU = BetterLights.Menu
    local MENU_COMMAND = "betterlights_menu"
    local DEFAULT_PAGE_ID = "BL_Client"
    local FRAME_ICON = "icon16/lightbulb.png"
    local PAGE_ICON = "icon16/page_white_wrench.png"
    local CATEGORY_ICON = "icon16/folder.png"
    local WIDGET_ICON = "betterlights/icon64/lightbulb.png"
    local WINDOW_MARGIN = 32
    local DEFAULT_FRAME_WIDTH = 1100
    local DEFAULT_FRAME_HEIGHT = 860
    local MIN_FRAME_WIDTH = 720
    local MIN_FRAME_HEIGHT = 540
    local DEFAULT_NAVIGATION_WIDTH = 230
    local MIN_NAVIGATION_WIDTH = 170
    local MIN_CONTENT_WIDTH = 420
    local COOKIE_WINDOW_X = "betterlights_menu_window_x"
    local COOKIE_WINDOW_Y = "betterlights_menu_window_y"
    local COOKIE_WINDOW_WIDTH = "betterlights_menu_window_width"
    local COOKIE_WINDOW_HEIGHT = "betterlights_menu_window_height"
    local COOKIE_NAVIGATION_WIDTH = "betterlights_menu_navigation_width"
    local COOKIE_LAST_PAGE = "betterlights_menu_last_page"
    local bindListenerKey = KEY_NONE
    local bindListenerArmed = false
    local suppressBindToggleUntilRelease = false
    local searchShortcutDown = false
    local escapeShortcutDown = false

    local function phrase(key)
        return MENU.Phrase(key)
    end

    MENU._lastPageId = MENU._lastPageId or cookie.GetString(COOKIE_LAST_PAGE, DEFAULT_PAGE_ID)

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
        searchShortcutDown = input.IsControlDown() and input.IsKeyDown(KEY_F)
        escapeShortcutDown = input.IsKeyDown(KEY_ESCAPE)
    end

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
            MENU.OpenSettings()
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

    local SETTINGS_PANEL = {}

    function SETTINGS_PANEL:Init()
        self.PageDefinitions = {}
        self.CategoryDefinitions = {}
        self.PageNodes = {}
        self.CategoryNodes = {}
        self.CategoryExpansion = {}
        self.PageScrollPositions = {}
        self.CurrentFilter = ""

        self.Divider = vgui.Create("DHorizontalDivider", self)
        self.Divider:Dock(FILL)
        self.Divider:SetDividerWidth(6)
        self.Divider:SetLeftWidth(DEFAULT_NAVIGATION_WIDTH)
        self.Divider:SetLeftMin(MIN_NAVIGATION_WIDTH)
        self.Divider:SetRightMin(MIN_CONTENT_WIDTH)

        self.Navigation = vgui.Create("DPanel", self.Divider)
        self.Navigation:DockPadding(8, 8, 8, 8)

        self.SearchBar = vgui.Create("DPanel", self.Navigation)
        self.SearchBar:Dock(TOP)
        self.SearchBar:SetTall(28)
        self.SearchBar:SetPaintBackground(false)

        self.ClearSearch = vgui.Create("DImageButton", self.SearchBar)
        self.ClearSearch:Dock(RIGHT)
        self.ClearSearch:DockMargin(6, 0, 0, 0)
        self.ClearSearch:SetWide(24)
        self.ClearSearch:SetImage("icon16/cross.png")
        self.ClearSearch:SetTooltip(phrase("tooltip.clear_settings_search"))
        self.ClearSearch:SetVisible(false)

        self.Search = vgui.Create("DTextEntry", self.SearchBar)
        self.Search:Dock(FILL)
        self.Search:SetPlaceholderText(phrase("placeholder.search_settings"))
        self.Search:SetTooltip(phrase("tooltip.search_settings"))
        self.Search:SetUpdateOnType(true)

        self.MatchStatus = vgui.Create("DLabel", self.Navigation)
        self.MatchStatus:Dock(BOTTOM)
        self.MatchStatus:DockMargin(2, 6, 2, 0)
        self.MatchStatus:SetTall(18)
        self.MatchStatus:SetDark(true)
        self.MatchStatus:SetContentAlignment(4)

        self.EmptyState = vgui.Create("DLabel", self.Navigation)
        self.EmptyState:Dock(FILL)
        self.EmptyState:DockMargin(10, 10, 10, 10)
        self.EmptyState:SetText(phrase("help.no_matching_settings_pages"))
        self.EmptyState:SetDark(true)
        self.EmptyState:SetWrap(true)
        self.EmptyState:SetContentAlignment(5)
        self.EmptyState:SetVisible(false)

        self.Content = vgui.Create("DScrollPanel", self.Divider)
        self.Content:GetCanvas():DockPadding(4, 0, 4, 8)

        self.Divider:SetLeft(self.Navigation)
        self.Divider:SetRight(self.Content)

        local owner = self
        self.Search.OnValueChange = function(search)
            owner:RebuildTree(search:GetValue())
        end
        self.Search.OnEnter = function()
            owner:OpenFirstSearchResult()
        end
        self.ClearSearch.DoClick = function()
            owner:ClearSearchFilter(true)
        end

        self:CreateTree()
    end

    function SETTINGS_PANEL:UpdateDividerBounds(width, requestedWidth)
        width = tonumber(width) or self:GetWide()
        if width <= 0 then return end

        local dividerWidth = self.Divider:GetDividerWidth()
        local navigationMin = math.max(80, math.min(MIN_NAVIGATION_WIDTH, math.floor(width * 0.28)))
        local contentMin = math.max(160, math.min(MIN_CONTENT_WIDTH, width - navigationMin - dividerWidth))
        local navigationMax = math.max(navigationMin, width - contentMin - dividerWidth)
        local navigationWidth = math.Clamp(
            tonumber(requestedWidth) or self.Divider:GetLeftWidth(),
            navigationMin,
            navigationMax
        )

        self.Divider:SetLeftMin(navigationMin)
        self.Divider:SetRightMin(contentMin)
        self.Divider:SetLeftWidth(navigationWidth)
    end

    function SETTINGS_PANEL:OnSizeChanged(width)
        self:UpdateDividerBounds(width)
    end

    function SETTINGS_PANEL:FocusSearch()
        if not IsValid(self.Search) then return end

        self.Search:RequestFocus()
        self.Search:SelectAll()
    end

    function SETTINGS_PANEL:ClearSearchFilter(focusSearch)
        if not IsValid(self.Search) then return end

        self.Search:SetText("")
        self:RebuildTree("", self.CurrentPageId)

        if focusSearch then
            self.Search:RequestFocus()
        end
    end

    function SETTINGS_PANEL:OpenFirstSearchResult()
        local page = self.FirstVisiblePage
        if not page then return false end

        self:OpenPage(page)

        local node = self.PageNodes[page.id]
        if IsValid(node) then
            self.SelectingNode = true
            self.Tree:SetSelectedItem(node)
            self.SelectingNode = false
        end

        return true
    end

    function SETTINGS_PANEL:CreateTree()
        if IsValid(self.Tree) then
            self.Tree:Remove()
        end

        local tree = vgui.Create("DTree", self.Navigation)
        tree:Dock(FILL)
        tree:DockMargin(0, 6, 0, 0)
        tree:SetLineHeight(22)
        tree:SetShowIcons(true)

        local owner = self
        tree.OnNodeSelected = function(_, node)
            if owner.SelectingNode then return end
            if not node.BetterLightsPage then return end
            owner:OpenPage(node.BetterLightsPage)
        end

        self.Tree = tree
        self.PageNodes = {}
        self.CategoryNodes = {}
        return tree
    end

    function SETTINGS_PANEL:CaptureCategoryExpansion()
        for categoryId, node in pairs(self.CategoryNodes) do
            if IsValid(node) then
                self.CategoryExpansion[categoryId] = node:GetExpanded()
            end
        end
    end

    function SETTINGS_PANEL:GetPage(id)
        for i = 1, #self.PageDefinitions do
            local page = self.PageDefinitions[i]
            if page.id == id then return page end
        end

        return nil
    end

    function SETTINGS_PANEL:AddCategoryNode(categoryId, category, title, pages, query, selectedPageId)
        if #pages == 0 then return end

        local categoryNode = self.Tree:AddNode(title, category.icon or CATEGORY_ICON)
        local selectedCategory = false
        self.CategoryNodes[categoryId] = categoryNode

        for i = 1, #pages do
            local page = pages[i]
            local pageNode = categoryNode:AddNode(phrase(page.titleKey), PAGE_ICON)
            pageNode.BetterLightsPage = page
            self.PageNodes[page.id] = pageNode

            if page.id == selectedPageId then
                selectedCategory = true
            end
        end

        categoryNode:SetExpanded(
            query ~= "" or selectedCategory or self.CategoryExpansion[categoryId] == true,
            true
        )
    end

    function SETTINGS_PANEL:RebuildTree(filter, selectedPageId)
        filter = string.lower(string.Trim(tostring(filter or "")))
        selectedPageId = selectedPageId or self.CurrentPageId or MENU._lastPageId or DEFAULT_PAGE_ID

        if self.CurrentFilter == "" then
            self:CaptureCategoryExpansion()
        end
        self.CurrentFilter = filter

        local tree = self:CreateTree()
        local categorizedPages = {}
        local knownCategories = {}
        local matchCount = 0
        self.FirstVisiblePage = nil

        for i = 1, #self.CategoryDefinitions do
            local category = self.CategoryDefinitions[i]
            knownCategories[category[1]] = category
            categorizedPages[category[1]] = {}
        end

        for i = 1, #self.PageDefinitions do
            local page = self.PageDefinitions[i]
            local category = knownCategories[page.category]
            local developerOnly = category and category.developer
            if not developerOnly or MENU.IsDeveloperMode() then
                local categoryTitle = category and phrase(category[2]) or page.category
                local pageTitle = phrase(page.titleKey)
                local matches = filter == ""
                    or string.find(string.lower(categoryTitle), filter, 1, true)
                    or string.find(string.lower(pageTitle), filter, 1, true)

                if matches then
                    categorizedPages[page.category] = categorizedPages[page.category] or {}
                    categorizedPages[page.category][#categorizedPages[page.category] + 1] = page
                    matchCount = matchCount + 1
                    self.FirstVisiblePage = self.FirstVisiblePage or page
                end
            end
        end

        for i = 1, #self.CategoryDefinitions do
            local category = self.CategoryDefinitions[i]
            if not category.developer or MENU.IsDeveloperMode() then
                self:AddCategoryNode(
                    category[1],
                    category,
                    phrase(category[2]),
                    categorizedPages[category[1]],
                    filter,
                    selectedPageId
                )
            end
        end

        local extraCategories = {}
        for categoryId, pages in pairs(categorizedPages) do
            if not knownCategories[categoryId] and #pages > 0 then
                extraCategories[#extraCategories + 1] = categoryId
            end
        end
        table.sort(extraCategories)

        for i = 1, #extraCategories do
            local categoryId = extraCategories[i]
            self:AddCategoryNode(
                categoryId,
                {},
                categoryId,
                categorizedPages[categoryId],
                filter,
                selectedPageId
            )
        end

        local selectedNode = self.PageNodes[selectedPageId]
        if IsValid(selectedNode) then
            self.SelectingNode = true
            tree:SetSelectedItem(selectedNode)
            self.SelectingNode = false
        end

        tree:SetVisible(matchCount > 0)
        self.EmptyState:SetVisible(matchCount == 0)
        self.ClearSearch:SetVisible(filter ~= "")
        self.MatchStatus:SetText(MENU.PhraseFormat(
            matchCount == 1 and "status.settings_page_count_one" or "status.settings_page_count_many",
            matchCount
        ))
    end

    function SETTINGS_PANEL:OpenPage(page, forceRefresh)
        if isstring(page) then
            page = self:GetPage(page)
        end
        if not page then return false end
        if not forceRefresh and page.id == self.CurrentPageId and IsValid(self.PageForm) then return true end

        if self.CurrentPageId then
            self.PageScrollPositions[self.CurrentPageId] = self.Content:GetVBar():GetScroll()
        end

        if IsValid(self.PageForm) then
            self.PageForm:Remove()
        end

        local form = vgui.Create("DForm", self.Content)
        form:Dock(TOP)
        form:DockMargin(8, 0, 8, 12)
        form:SetHeaderHeight(0)
        form:SetExpanded(true)
        form:SetPaintBackground(false)
        form:SetName("")
        self.PageForm = form

        self.CurrentPageId = page.id
        MENU._lastPageId = page.id
        cookie.Set(COOKIE_LAST_PAGE, page.id)
        page.buildPanel(form)

        local frame = self:GetParent()
        if IsValid(frame) and frame.SetTitle then
            frame:SetTitle(MENU.PhraseFormat("window.settings.page_title", phrase(page.titleKey)))
        end

        form:InvalidateLayout(true)
        self.Content:GetCanvas():InvalidateLayout(true)
        local targetScroll = self.PageScrollPositions[page.id] or 0
        local owner = self
        timer.Simple(0, function()
            if not IsValid(owner) or owner.CurrentPageId ~= page.id then return end
            owner.Content:GetVBar():SetScroll(targetScroll)
        end)
        return true
    end

    function SETTINGS_PANEL:Refresh(pageId)
        self.PageDefinitions = MENU.GetRegisteredPages()
        self.CategoryDefinitions = MENU.GetCategoryDefinitions()

        local targetPageId = pageId or self.CurrentPageId or MENU._lastPageId or DEFAULT_PAGE_ID
        self:RebuildTree(self.Search:GetValue(), targetPageId)

        local page = self:GetPage(targetPageId) or self:GetPage(DEFAULT_PAGE_ID) or self.PageDefinitions[1]
        if page then
            self:OpenPage(page, true)

            local node = self.PageNodes[page.id]
            if IsValid(node) then
                self.SelectingNode = true
                self.Tree:SetSelectedItem(node)
                self.SelectingNode = false
            end
        end
    end

    vgui.Register("BetterLightsSettingsPanel", SETTINGS_PANEL, "DPanel")

    local function readCookieNumber(name, fallback)
        local value = cookie.GetNumber(name, fallback)
        if not isnumber(value) or value ~= value or value == math.huge or value == -math.huge then
            return fallback
        end

        return math.floor(value)
    end

    local function getFrameLimits()
        local maxWidth = math.max(320, ScrW() - WINDOW_MARGIN)
        local maxHeight = math.max(300, ScrH() - WINDOW_MARGIN)
        return math.min(MIN_FRAME_WIDTH, maxWidth), math.min(MIN_FRAME_HEIGHT, maxHeight), maxWidth, maxHeight
    end

    local function getDefaultFrameSize()
        local minWidth, minHeight, maxWidth, maxHeight = getFrameLimits()
        local width = math.min(DEFAULT_FRAME_WIDTH, math.max(minWidth, math.floor(ScrW() * 0.78)))
        local height = math.min(DEFAULT_FRAME_HEIGHT, math.max(minHeight, math.floor(ScrH() * 0.82)))
        return math.min(width, maxWidth), math.min(height, maxHeight)
    end

    local function getSavedFrameBounds()
        local minWidth, minHeight, maxWidth, maxHeight = getFrameLimits()
        local defaultWidth, defaultHeight = getDefaultFrameSize()
        local width = math.Clamp(readCookieNumber(COOKIE_WINDOW_WIDTH, defaultWidth), minWidth, maxWidth)
        local height = math.Clamp(readCookieNumber(COOKIE_WINDOW_HEIGHT, defaultHeight), minHeight, maxHeight)
        local defaultX = math.floor((ScrW() - width) * 0.5)
        local defaultY = math.floor((ScrH() - height) * 0.5)
        local x = math.Clamp(readCookieNumber(COOKIE_WINDOW_X, defaultX), 0, math.max(0, ScrW() - width))
        local y = math.Clamp(readCookieNumber(COOKIE_WINDOW_Y, defaultY), 0, math.max(0, ScrH() - height))
        return x, y, width, height, minWidth, minHeight
    end

    local function clampFrameToScreen(frame)
        if not IsValid(frame) then return end

        local minWidth, minHeight, maxWidth, maxHeight = getFrameLimits()
        local width = math.Clamp(frame:GetWide(), minWidth, maxWidth)
        local height = math.Clamp(frame:GetTall(), minHeight, maxHeight)
        local x, y = frame:GetPos()

        frame:SetMinWidth(minWidth)
        frame:SetMinHeight(minHeight)
        frame:SetSize(width, height)
        frame:SetPos(
            math.Clamp(x, 0, math.max(0, ScrW() - width)),
            math.Clamp(y, 0, math.max(0, ScrH() - height))
        )

        if IsValid(frame.SettingsPanel) then
            frame.SettingsPanel:UpdateDividerBounds()
        end
    end

    local function saveFrameLayout(frame)
        if not IsValid(frame) then return end

        local x, y = frame:GetPos()
        cookie.Set(COOKIE_WINDOW_X, tostring(math.floor(x)))
        cookie.Set(COOKIE_WINDOW_Y, tostring(math.floor(y)))
        cookie.Set(COOKIE_WINDOW_WIDTH, tostring(math.floor(frame:GetWide())))
        cookie.Set(COOKIE_WINDOW_HEIGHT, tostring(math.floor(frame:GetTall())))

        if IsValid(frame.SettingsPanel) and IsValid(frame.SettingsPanel.Divider) then
            cookie.Set(
                COOKIE_NAVIGATION_WIDTH,
                tostring(math.floor(frame.SettingsPanel.Divider:GetLeftWidth()))
            )
        end
    end

    if IsValid(MENU._settingsFrame) then
        saveFrameLayout(MENU._settingsFrame)
        MENU._settingsFrame:Remove()
        MENU._settingsFrame = nil
    end

    function MENU.OpenSettings(pageId)
        local frame = MENU._settingsFrame
        if IsValid(frame) and not IsValid(frame.SettingsPanel) then
            frame:Remove()
            frame = nil
            MENU._settingsFrame = nil
        end

        if IsValid(frame) then
            clampFrameToScreen(frame)
            frame:SetVisible(true)
            frame:MakePopup()
            frame:MoveToFront()
            frame.SettingsPanel:Refresh(pageId)
            resetBindListener()
            return frame
        end

        local x, y, width, height, minWidth, minHeight = getSavedFrameBounds()
        frame = vgui.Create("DFrame")
        frame:SetSize(width, height)
        frame:SetPos(x, y)
        frame:SetMinWidth(minWidth)
        frame:SetMinHeight(minHeight)
        frame:SetTitle(phrase("window.settings.title"))
        frame:SetIcon(FRAME_ICON)
        frame:SetSizable(true)
        frame:SetScreenLock(true)
        frame:SetDeleteOnClose(false)

        frame.SettingsPanel = vgui.Create("BetterLightsSettingsPanel", frame)
        frame.SettingsPanel:Dock(FILL)
        frame.SettingsPanel:UpdateDividerBounds(
            width,
            readCookieNumber(COOKIE_NAVIGATION_WIDTH, DEFAULT_NAVIGATION_WIDTH)
        )
        frame.SettingsPanel:Refresh(pageId)

        frame.OnClose = function(self)
            saveFrameLayout(self)
        end

        MENU._settingsFrame = frame
        frame:MakePopup()
        resetBindListener()
        return frame
    end

    function MENU.ToggleSettings(pageId)
        local frame = MENU._settingsFrame
        if IsValid(frame) and frame:IsVisible() then
            frame:Close()
            resetBindListener()
            return nil
        end

        return MENU.OpenSettings(pageId)
    end

    function MENU.RefreshSettingsWindow()
        if not IsValid(MENU._settingsFrame) then return end
        if not IsValid(MENU._settingsFrame.SettingsPanel) then return end
        MENU._settingsFrame.SettingsPanel:Refresh()
    end

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
        if not (IsValid(frame) and frame:IsVisible()) then
            if suppressBindToggleUntilRelease
                and bindListenerKey ~= KEY_NONE
                and input.IsKeyDown(bindListenerKey) then
                return
            end

            resetBindListener()
            return
        end

        local settingsPanel = frame.SettingsPanel
        local isActive = frame:IsActive()
        local isKeyTrapping = input.IsKeyTrapping()
        local searchDown = input.IsControlDown() and input.IsKeyDown(KEY_F)
        if searchDown and not searchShortcutDown and isActive and not isKeyTrapping
            and IsValid(settingsPanel) then
            settingsPanel:FocusSearch()
        end
        searchShortcutDown = searchDown

        local escapeDown = input.IsKeyDown(KEY_ESCAPE)
        if escapeDown and not escapeShortcutDown and isActive and not isKeyTrapping then
            if IsValid(settingsPanel) and settingsPanel.Search:IsEditing()
                and settingsPanel.Search:GetValue() ~= "" then
                settingsPanel:ClearSearchFilter(true)
            else
                frame:Close()
            end
        end
        escapeShortcutDown = escapeDown

        if not frame:IsVisible() then return end

        local keyCode = getMenuBindingKey()
        if keyCode == KEY_NONE then
            resetBindListener()
            return
        end

        local keyDown = input.IsKeyDown(keyCode)
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

    hook.Add("OnScreenSizeChanged", "BetterLights_ClampSettingsWindow", function()
        local frame = MENU._settingsFrame
        if not IsValid(frame) then return end

        timer.Simple(0, function()
            if not IsValid(frame) then return end
            clampFrameToScreen(frame)
        end)
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

            MENU.OpenSettings()
        end
    })
end
