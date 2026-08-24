if CLIENT then
    local MENU = BetterLights.Menu
    local MENU_COMMAND = "betterlights_menu"
    local DEFAULT_PAGE_ID = "BL_Client"
    local FRAME_ICON = "icon16/lightbulb.png"
    local PAGE_ICON = "icon16/page_white_wrench.png"
    local CATEGORY_ICON = "icon16/folder.png"
    local WIDGET_ICON = "betterlights/icon64/lightbulb.png"
    local bindListenerKey = KEY_NONE
    local bindListenerArmed = false
    local suppressBindToggleUntilRelease = false

    local function phrase(key)
        return MENU.Phrase(key)
    end

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
            MENU.OpenSettings(DEFAULT_PAGE_ID)
        end
        return open
    end

    function MENU.AddSettingsAccessControls(panel, options)
        options = options or {}

        local access = MENU.AddSection(panel, "section.settings_access", "section.settings_access.desc", true)
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
        panel:Clear()

        local moved = MENU.AddSection(panel, "section.settings_moved", "section.settings_moved.desc", true)
        addOpenSettingsButton(moved)

        MENU.AddClientPreferenceSection(panel)
        MENU.AddSettingsAccessControls(panel, { showOpenButton = false })
    end

    local SETTINGS_PANEL = {}

    function SETTINGS_PANEL:Init()
        self.PageDefinitions = {}
        self.CategoryDefinitions = {}
        self.PageNodes = {}

        self.Divider = vgui.Create("DHorizontalDivider", self)
        self.Divider:Dock(FILL)
        self.Divider:SetDividerWidth(6)
        self.Divider:SetLeftWidth(230)
        self.Divider:SetLeftMin(170)
        self.Divider:SetRightMin(420)

        self.Navigation = vgui.Create("DPanel", self.Divider)
        self.Navigation:DockPadding(6, 6, 6, 6)

        self.Search = vgui.Create("DTextEntry", self.Navigation)
        self.Search:Dock(TOP)
        self.Search:SetTall(24)
        self.Search:SetPlaceholderText(phrase("placeholder.search_settings"))
        self.Search:SetUpdateOnType(true)

        self.Content = vgui.Create("DScrollPanel", self.Divider)
        self.Content:DockPadding(4, 0, 4, 8)

        self.Divider:SetLeft(self.Navigation)
        self.Divider:SetRight(self.Content)

        local owner = self
        self.Search.OnValueChange = function(search)
            owner:RebuildTree(search:GetValue())
        end

        self:CreateTree()
    end

    function SETTINGS_PANEL:CreateTree()
        if IsValid(self.Tree) then
            self.Tree:Remove()
        end

        local tree = vgui.Create("DTree", self.Navigation)
        tree:Dock(FILL)
        tree:DockMargin(0, 6, 0, 0)
        tree:SetShowIcons(true)

        local owner = self
        tree.OnNodeSelected = function(_, node)
            if owner.SelectingNode then return end
            if not node.BetterLightsPage then return end
            owner:OpenPage(node.BetterLightsPage)
        end

        self.Tree = tree
        self.PageNodes = {}
        return tree
    end

    function SETTINGS_PANEL:GetPage(id)
        for i = 1, #self.PageDefinitions do
            local page = self.PageDefinitions[i]
            if page.id == id then return page end
        end

        return nil
    end

    function SETTINGS_PANEL:AddCategoryNode(categoryId, title, pages, query, selectedPageId)
        if #pages == 0 then return end

        local categoryNode = self.Tree:AddNode(title, CATEGORY_ICON)
        local selectedCategory = false

        for i = 1, #pages do
            local page = pages[i]
            local pageNode = categoryNode:AddNode(phrase(page.titleKey), PAGE_ICON)
            pageNode.BetterLightsPage = page
            self.PageNodes[page.id] = pageNode

            if page.id == selectedPageId then
                selectedCategory = true
            end
        end

        categoryNode:SetExpanded(query ~= "" or selectedCategory, true)
    end

    function SETTINGS_PANEL:RebuildTree(filter, selectedPageId)
        filter = string.lower(string.Trim(tostring(filter or "")))
        selectedPageId = selectedPageId or self.CurrentPageId or MENU._lastPageId or DEFAULT_PAGE_ID
        local tree = self:CreateTree()
        local categorizedPages = {}
        local knownCategories = {}

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
                end
            end
        end

        for i = 1, #self.CategoryDefinitions do
            local category = self.CategoryDefinitions[i]
            if not category.developer or MENU.IsDeveloperMode() then
                self:AddCategoryNode(
                    category[1],
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
    end

    function SETTINGS_PANEL:OpenPage(page)
        if isstring(page) then
            page = self:GetPage(page)
        end
        if not page then return false end

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
        page.buildPanel(form)

        form:InvalidateLayout(true)
        self.Content:GetCanvas():InvalidateLayout(true)
        self.Content:GetVBar():SetScroll(0)
        return true
    end

    function SETTINGS_PANEL:Refresh(pageId)
        self.PageDefinitions = MENU.GetRegisteredPages()
        self.CategoryDefinitions = MENU.GetCategoryDefinitions()

        local targetPageId = pageId or self.CurrentPageId or MENU._lastPageId or DEFAULT_PAGE_ID
        self:RebuildTree(self.Search:GetValue(), targetPageId)

        local page = self:GetPage(targetPageId) or self:GetPage(DEFAULT_PAGE_ID) or self.PageDefinitions[1]
        if page then
            self:OpenPage(page)

            local node = self.PageNodes[page.id]
            if IsValid(node) then
                self.SelectingNode = true
                self.Tree:SetSelectedItem(node)
                self.SelectingNode = false
            end
        end
    end

    vgui.Register("BetterLightsSettingsPanel", SETTINGS_PANEL, "DPanel")

    local function getFrameSize()
        local width = math.min(1100, math.max(720, math.floor(ScrW() * 0.78)))
        local height = math.min(860, math.max(540, math.floor(ScrH() * 0.82)))
        return math.min(width, ScrW() - 32), math.min(height, ScrH() - 32)
    end

    if IsValid(MENU._settingsFrame) then
        MENU._settingsFrame:Remove()
        MENU._settingsFrame = nil
    end

    function MENU.OpenSettings(pageId)
        local frame = MENU._settingsFrame
        if IsValid(frame) then
            frame:SetVisible(true)
            frame:MakePopup()
            frame:MoveToFront()
            frame.SettingsPanel:Refresh(pageId)
            resetBindListener()
            return frame
        end

        local width, height = getFrameSize()
        frame = vgui.Create("DFrame")
        frame:SetSize(width, height)
        frame:SetMinWidth(math.min(720, ScrW() - 32))
        frame:SetMinHeight(math.min(540, ScrH() - 32))
        frame:SetTitle(phrase("window.settings.title"))
        frame:SetIcon(FRAME_ICON)
        frame:SetSizable(true)
        frame:SetScreenLock(true)
        frame:SetDeleteOnClose(false)
        frame:Center()

        frame.SettingsPanel = vgui.Create("BetterLightsSettingsPanel", frame)
        frame.SettingsPanel:Dock(FILL)
        frame.SettingsPanel:Refresh(pageId)

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
