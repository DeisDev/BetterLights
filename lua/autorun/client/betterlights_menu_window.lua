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
    local DEFAULT_WINDOW_OPACITY = 100
    local MIN_WINDOW_OPACITY = 50
    local DEFAULT_NAVIGATION_ICONS = true
    local DEFAULT_COMPACT_NAVIGATION = false
    local DEFAULT_TREE_LINE_HEIGHT = 22
    local COMPACT_TREE_LINE_HEIGHT = 18
    local COOKIE_WINDOW_X = "betterlights_menu_window_x"
    local COOKIE_WINDOW_Y = "betterlights_menu_window_y"
    local COOKIE_WINDOW_WIDTH = "betterlights_menu_window_width"
    local COOKIE_WINDOW_HEIGHT = "betterlights_menu_window_height"
    local COOKIE_NAVIGATION_WIDTH = "betterlights_menu_navigation_width"
    local COOKIE_LAST_PAGE = "betterlights_menu_last_page"
    local COOKIE_WINDOW_OPACITY = "betterlights_menu_window_opacity"
    local COOKIE_NAVIGATION_ICONS = "betterlights_menu_navigation_icons"
    local COOKIE_COMPACT_NAVIGATION = "betterlights_menu_compact_navigation"
    local bindListenerKey = KEY_NONE
    local bindListenerArmed = false
    local suppressBindToggleUntilRelease = false
    local searchShortcutDown = false
    local escapeShortcutDown = false
    local PAGE_NAVIGATION_KEYS = { KEY_PAGEUP, KEY_PAGEDOWN, KEY_HOME, KEY_END }
    local PAGE_NAVIGATION_REPEAT_DELAY = 0.4
    local PAGE_NAVIGATION_REPEAT_INTERVAL = 0.1
    local PAGE_NAVIGATION_BLOCKING_CLASSES = {
        DBinder = true,
        DComboBox = true,
        DListView = true,
        DListView_Line = true,
        DMenu = true,
        DNumberWang = true,
        DNumSlider = true,
        DSlider = true,
        DTextEntry = true,
        DTree = true,
        DTree_Node = true,
        NumberWang = true,
        TextEntry = true
    }
    local pageNavigationStates = {}

    local function phrase(key)
        return MENU.Phrase(key)
    end

    local function getOptionalPhrase(key)
        if not key then return "" end

        local phraseKey = "betterlights." .. key
        local value = language.GetPhrase(phraseKey)
        if value == phraseKey then return "" end
        return value
    end

    local function getPageDescription(page)
        return getOptionalPhrase(page and page.descriptionKey)
    end

    local function sortPagesByTitle(pages)
        table.sort(pages, function(a, b)
            local aTitle = string.lower(phrase(a.titleKey))
            local bTitle = string.lower(phrase(b.titleKey))
            if aTitle ~= bTitle then return aTitle < bTitle end

            return a.id < b.id
        end)
    end

    local function getPageFullTitle(page)
        if page and page.descriptionKey then
            local titleKey = string.gsub(page.descriptionKey, "%.desc$", ".title")
            local fullTitle = getOptionalPhrase(titleKey)
            if fullTitle ~= "" then return fullTitle end
        end

        return page and phrase(page.titleKey) or ""
    end

    local function readCookieNumber(name, fallback)
        local value = cookie.GetNumber(name, fallback)
        if not isnumber(value) or value ~= value or value == math.huge or value == -math.huge then
            return fallback
        end

        return math.floor(value)
    end

    local function readCookieBool(name, fallback)
        local value = readCookieNumber(name, fallback and 1 or 0)
        if value ~= 0 and value ~= 1 then return fallback end
        return value == 1
    end

    local function getWindowOpacity()
        return math.Clamp(
            readCookieNumber(COOKIE_WINDOW_OPACITY, DEFAULT_WINDOW_OPACITY),
            MIN_WINDOW_OPACITY,
            100
        )
    end

    local function getNavigationIconsEnabled()
        return readCookieBool(COOKIE_NAVIGATION_ICONS, DEFAULT_NAVIGATION_ICONS)
    end

    local function getNavigationLineHeight()
        if readCookieBool(COOKIE_COMPACT_NAVIGATION, DEFAULT_COMPACT_NAVIGATION) then
            return COMPACT_TREE_LINE_HEIGHT
        end

        return DEFAULT_TREE_LINE_HEIGHT
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

    local function resetPageNavigation()
        for i = 1, #PAGE_NAVIGATION_KEYS do
            local keyCode = PAGE_NAVIGATION_KEYS[i]
            local isDown = input.IsKeyDown(keyCode)
            local state = pageNavigationStates[keyCode]
            if not state then
                state = {}
                pageNavigationStates[keyCode] = state
            end

            state.down = isDown
            state.blocked = isDown
            state.repeatAt = math.huge
        end
    end

    local function focusedControlConsumesPageNavigation(frame)
        local focus = vgui.GetKeyboardFocus()
        while IsValid(focus) and focus ~= frame do
            if isfunction(focus.IsEditing) and focus:IsEditing() then return true end
            if isfunction(focus.IsMenuOpen) and focus:IsMenuOpen() then return true end
            if isfunction(focus.GetSelectedItem)
                or isfunction(focus.GetSelectedLine)
                or isfunction(focus.GetSelectedNumber)
                or isfunction(focus.GetSlideX)
                or isfunction(focus.ChooseOptionID) then
                return true
            end
            if PAGE_NAVIGATION_BLOCKING_CLASSES[focus:GetName()]
                or PAGE_NAVIGATION_BLOCKING_CLASSES[focus:GetClassName()] then
                return true
            end
            focus = focus:GetParent()
        end

        return false
    end

    local function updatePageNavigation(frame, settingsPanel, canNavigate)
        local now = RealTime()
        local focusChecked = false

        for i = 1, #PAGE_NAVIGATION_KEYS do
            local keyCode = PAGE_NAVIGATION_KEYS[i]
            local state = pageNavigationStates[keyCode]
            if not state then
                state = { down = false, blocked = false, repeatAt = 0 }
                pageNavigationStates[keyCode] = state
            end

            local isDown = input.IsKeyDown(keyCode)
            if isDown and canNavigate and not focusChecked then
                canNavigate = not focusedControlConsumesPageNavigation(frame)
                focusChecked = true
            end

            if not isDown then
                state.down = false
                state.blocked = false
                state.repeatAt = 0
            elseif not state.down then
                state.down = true
                state.blocked = not canNavigate
                state.repeatAt = now + PAGE_NAVIGATION_REPEAT_DELAY
                if canNavigate then
                    settingsPanel:HandlePageNavigationKey(keyCode)
                end
            elseif not canNavigate then
                state.blocked = true
            elseif not state.blocked and now >= state.repeatAt then
                state.repeatAt = now + PAGE_NAVIGATION_REPEAT_INTERVAL
                settingsPanel:HandlePageNavigationKey(keyCode)
            end
        end
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

        self.Identity = vgui.Create("DPanel", self.Navigation)
        self.Identity:Dock(TOP)
        self.Identity:SetTall(22)
        self.Identity:SetPaintBackground(false)

        self.Version = vgui.Create("DLabel", self.Identity)
        self.Version:Dock(RIGHT)
        self.Version:DockMargin(8, 0, 0, 0)
        self.Version:SetText(tostring(BetterLights.VERSION or ""))
        self.Version:SetDark(true)
        self.Version:SetContentAlignment(6)
        self.Version:SizeToContents()
        self.Version:SetTooltip(MENU.PhraseFormat("about.version", BetterLights.VERSION or ""))

        self.AddonName = vgui.Create("DLabel", self.Identity)
        self.AddonName:Dock(FILL)
        self.AddonName:SetText(phrase("addon.name"))
        self.AddonName:SetFont("DermaDefaultBold")
        self.AddonName:SetDark(true)
        self.AddonName:SetContentAlignment(4)

        self.SearchBar = vgui.Create("DPanel", self.Navigation)
        self.SearchBar:Dock(TOP)
        self.SearchBar:DockMargin(0, 4, 0, 0)
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
        self.MatchStatus:SetTooltip(phrase("tooltip.page_keyboard_navigation"))

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

    function SETTINGS_PANEL:HandlePageNavigationKey(keyCode)
        if not IsValid(self.Content) then return false end

        local scrollBar = self.Content:GetVBar()
        if not IsValid(scrollBar) then return false end
        if not scrollBar.Enabled then return false end

        local target
        local current = scrollBar:GetScroll()
        local pageSize = math.max(64, math.floor(self.Content:GetTall() * 0.9))

        if keyCode == KEY_PAGEUP then
            target = current - pageSize
        elseif keyCode == KEY_PAGEDOWN then
            target = current + pageSize
        elseif keyCode == KEY_HOME then
            target = 0
        elseif keyCode == KEY_END then
            target = self.Content:GetCanvas():GetTall()
        else
            return false
        end

        scrollBar:SetScroll(target)
        return true
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
        tree:SetLineHeight(getNavigationLineHeight())
        tree:SetShowIcons(getNavigationIconsEnabled())

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

        self.FirstVisiblePage = self.FirstVisiblePage or pages[1]

        local categoryNode = self.Tree:AddNode(title, category.icon or CATEGORY_ICON)
        local selectedCategory = false
        self.CategoryNodes[categoryId] = categoryNode

        for i = 1, #pages do
            local page = pages[i]
            local pageNode = categoryNode:AddNode(phrase(page.titleKey), PAGE_ICON)
            pageNode.BetterLightsPage = page
            local pageDescription = getPageDescription(page)
            if pageDescription ~= "" then
                pageNode:SetTooltip(pageDescription)
            end
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
                local pageDescription = getPageDescription(page)
                local matches = filter == ""
                    or string.find(string.lower(categoryTitle), filter, 1, true)
                    or string.find(string.lower(pageTitle), filter, 1, true)
                    or string.find(string.lower(pageDescription), filter, 1, true)

                if matches then
                    categorizedPages[page.category] = categorizedPages[page.category] or {}
                    categorizedPages[page.category][#categorizedPages[page.category] + 1] = page
                    matchCount = matchCount + 1
                end
            end
        end

        for i = 1, #self.CategoryDefinitions do
            local category = self.CategoryDefinitions[i]
            if not category.developer or MENU.IsDeveloperMode() then
                sortPagesByTitle(categorizedPages[category[1]])
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
            sortPagesByTitle(categorizedPages[categoryId])
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
            self.PageForm:SetVisible(false)
            self.PageForm:SetParent(self)
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
            frame:SetTitle(MENU.PhraseFormat("window.settings.page_title", getPageFullTitle(page)))
        end

        -- A scrollbar can narrow the canvas after the first pass and change wrapped control heights.
        for _ = 1, 2 do
            self.Content:InvalidateLayout(true)
            form:InvalidateChildren(true)
        end
        self.Content:InvalidateLayout(true)
        local targetScroll = self.PageScrollPositions[page.id] or 0
        self.Content:GetVBar():SetScroll(targetScroll)
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

    local function applyWindowAppearance(frame)
        if not IsValid(frame) then return end

        frame:SetAlpha(math.floor(getWindowOpacity() * 2.55 + 0.5))

        local settingsPanel = frame.SettingsPanel
        if not (IsValid(settingsPanel) and IsValid(settingsPanel.Tree)) then return end

        settingsPanel.Tree:SetShowIcons(getNavigationIconsEnabled())
        settingsPanel.Tree:SetLineHeight(getNavigationLineHeight())
        settingsPanel.Tree:InvalidateLayout(true)
    end

    local function resetWindowLayout(frame)
        cookie.Delete(COOKIE_WINDOW_X)
        cookie.Delete(COOKIE_WINDOW_Y)
        cookie.Delete(COOKIE_WINDOW_WIDTH)
        cookie.Delete(COOKIE_WINDOW_HEIGHT)
        cookie.Delete(COOKIE_NAVIGATION_WIDTH)

        if not IsValid(frame) then return end

        local x, y, width, height, minWidth, minHeight = getSavedFrameBounds()
        frame:SetMinWidth(minWidth)
        frame:SetMinHeight(minHeight)
        frame:SetSize(width, height)
        frame:SetPos(x, y)

        if IsValid(frame.SettingsPanel) then
            frame.SettingsPanel:UpdateDividerBounds(width, DEFAULT_NAVIGATION_WIDTH)
        end
    end

    local function addAppearanceCheckBox(panel, labelKey, cookieName, defaultValue)
        local checkBox = vgui.Create("DCheckBoxLabel")
        checkBox:SetText(phrase(labelKey))
        checkBox:SetDark(true)
        checkBox:SetValue(readCookieBool(cookieName, defaultValue) and 1 or 0)
        checkBox:SizeToContents()
        panel:AddItem(checkBox)

        checkBox.OnChange = function(_, value)
            cookie.Set(cookieName, value and "1" or "0")
            applyWindowAppearance(MENU._settingsFrame)
        end
        return checkBox
    end

    local function buildAppearancePage(panel)
        MENU.SetupPage(panel, "page.settings_window.title", "page.settings_window.desc")

        local window = MENU.AddSection(
            panel,
            "section.window_appearance",
            "section.window_appearance.desc",
            true
        )
        local opacity = vgui.Create("DNumSlider")
        opacity:SetText(phrase("control.window_opacity"))
        opacity:SetDark(true)
        opacity:SetMinMax(MIN_WINDOW_OPACITY, 100)
        opacity:SetDecimals(0)
        opacity:SetDefaultValue(DEFAULT_WINDOW_OPACITY)
        opacity:SetValue(getWindowOpacity())
        window:AddItem(opacity)

        opacity.OnValueChanged = function(_, value)
            local rounded = math.Clamp(math.floor(value + 0.5), MIN_WINDOW_OPACITY, 100)
            cookie.Set(COOKIE_WINDOW_OPACITY, tostring(rounded))
            applyWindowAppearance(MENU._settingsFrame)
        end

        MENU.AddHelpText(window, phrase("help.window_opacity"))

        local navigation = MENU.AddSection(
            panel,
            "section.window_navigation",
            "section.window_navigation.desc",
            true
        )
        addAppearanceCheckBox(
            navigation,
            "control.show_navigation_icons",
            COOKIE_NAVIGATION_ICONS,
            DEFAULT_NAVIGATION_ICONS
        )
        addAppearanceCheckBox(
            navigation,
            "control.compact_navigation",
            COOKIE_COMPACT_NAVIGATION,
            DEFAULT_COMPACT_NAVIGATION
        )
        MENU.AddHelpText(navigation, phrase("help.window_navigation"))

        local layout = MENU.AddSection(panel, "section.window_resets", "section.window_resets.desc", false)
        local resetAppearance = MENU.AddStyledButton(layout, phrase("button.reset_window_appearance"))
        resetAppearance.DoClick = function()
            cookie.Delete(COOKIE_WINDOW_OPACITY)
            cookie.Delete(COOKIE_NAVIGATION_ICONS)
            cookie.Delete(COOKIE_COMPACT_NAVIGATION)
            applyWindowAppearance(MENU._settingsFrame)
            MENU.RefreshSettingsWindow()
        end

        local resetLayout = MENU.AddStyledButton(layout, phrase("button.reset_window_layout"))
        resetLayout.DoClick = function()
            resetWindowLayout(MENU._settingsFrame)
        end
        MENU.AddHelpText(layout, phrase("help.window_layout"))

        MENU.AddSettingsAccessControls(panel, { showOpenButton = false })
    end

    function MENU.RegisterAppearancePanel()
        MENU.RegisterPage("Appearance", "BL_SettingsWindow", "page.settings_window.title", buildAppearancePage)
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
            applyWindowAppearance(frame)
            frame:SetVisible(true)
            frame:MakePopup()
            frame:MoveToFront()
            frame.SettingsPanel:Refresh(pageId)
            resetBindListener()
            resetPageNavigation()
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
        applyWindowAppearance(frame)

        frame.OnClose = function(self)
            saveFrameLayout(self)
        end

        MENU._settingsFrame = frame
        frame:MakePopup()
        resetBindListener()
        resetPageNavigation()
        return frame
    end

    function MENU.ToggleSettings(pageId)
        local frame = MENU._settingsFrame
        if IsValid(frame) and frame:IsVisible() then
            frame:Close()
            resetBindListener()
            resetPageNavigation()
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
            resetPageNavigation()
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

        local canNavigatePage = isActive
            and not isKeyTrapping
            and IsValid(settingsPanel)
        if IsValid(settingsPanel) then
            updatePageNavigation(frame, settingsPanel, canNavigatePage)
        end

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

            MENU.ToggleSettings()
        end
    })
end
