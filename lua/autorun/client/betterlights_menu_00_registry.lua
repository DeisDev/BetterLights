if CLIENT then
    BetterLights.Menu = BetterLights.Menu or {}
    local MENU = BetterLights.Menu
    local DEFAULT_CATEGORY_ICON = "icon16/folder.png"
    local DEFAULT_PAGE_ICON = "icon16/page_white_wrench.png"

    local function isDeveloperMode()
        local developer = GetConVar("developer")
        return developer and developer:GetInt() >= 1
    end

    local function phrase(key)
        return language.GetPhrase("betterlights." .. key)
    end

    local function phraseFormat(key, ...)
        return string.format(phrase(key), ...)
    end

    MENU.Phrase = phrase
    MENU.PhraseFormat = phraseFormat
    MENU.IsDeveloperMode = isDeveloperMode

    local registry = MENU._registry
    if not (istable(registry) and registry.schema == 1) then
        registry = {
            schema = 1,
            revision = 0,
            categoriesById = {},
            categoryOwnerById = {},
            categoryIdsByOwner = {},
            pagesById = {},
            pageOwnerById = {},
            pageIdsByOwner = {}
        }
        MENU._registry = registry
    end

    -- Owner-scoped sets replace their previous contents, including definitions removed during auto refresh.
    -- Registering an empty owner set removes that owner's definitions.
    -- Lower order values appear first. Omitted page order falls back to localized title sorting.
    -- Categories accept id, titleKey, icon, order, and isVisible.
    -- Pages add category, buildPanel, descriptionKey, fullTitleKey, icon, order, isVisible, default, and localized searchKeys.

    local function normalizeId(value)
        if not isstring(value) then return nil end

        value = string.Trim(value)
        if value == "" then return nil end
        return value
    end

    local function copyDefinition(definition)
        local copy = {}
        for key, value in pairs(definition) do
            copy[key] = value
        end
        return copy
    end

    local function normalizeOrder(value)
        if value == nil then return nil end

        value = tonumber(value)
        if not value or value ~= value or value == math.huge or value == -math.huge then return nil end
        return value
    end

    local function reportRegistryError(kind, reason)
        local message = "Could not register menu " .. kind .. ": " .. reason
        ErrorNoHalt("[BetterLights] " .. message .. "\n")
        return nil, message
    end

    local function inferPageDescriptionKey(titleKey)
        local pageKey = string.match(titleKey, "^(page%..+)%.title$")
        if pageKey then return pageKey .. ".desc" end

        local menuKey = string.match(titleKey, "^menu%.(.+)$")
        if menuKey then return "page." .. menuKey .. ".desc" end
    end

    local function inferPageFullTitleKey(descriptionKey)
        if not descriptionKey then return nil end
        return string.gsub(descriptionKey, "%.desc$", ".title")
    end

    local function normalizeCategoryDefinition(definition)
        if not istable(definition) then return nil, "the definition must be a table" end

        local category = copyDefinition(definition)
        category.id = normalizeId(category.id)
        category.titleKey = normalizeId(category.titleKey)
        if not category.id then return nil, "id must be a non-empty string" end
        if not category.titleKey then return nil, "titleKey must be a non-empty string" end
        if category.icon ~= nil then
            category.icon = normalizeId(category.icon)
            if not category.icon then return nil, "icon must be a non-empty string when provided" end
        end
        if category.order ~= nil then
            category.order = normalizeOrder(category.order)
            if category.order == nil then return nil, "order must be a finite number when provided" end
        end
        if category.isVisible ~= nil and not isfunction(category.isVisible) then
            return nil, "isVisible must be a function when provided"
        end

        return category
    end

    local function normalizePageDefinition(definition, id, titleKey, buildPanel, descriptionKey)
        if not istable(definition) then
            definition = {
                category = definition,
                id = id,
                titleKey = titleKey,
                buildPanel = buildPanel,
                descriptionKey = descriptionKey
            }
        end

        local page = copyDefinition(definition)
        page.category = normalizeId(page.category)
        page.id = normalizeId(page.id)
        page.titleKey = normalizeId(page.titleKey)
        if not page.category then return nil, "category must be a non-empty string" end
        if not page.id then return nil, "id must be a non-empty string" end
        if not page.titleKey then return nil, "titleKey must be a non-empty string" end
        if not isfunction(page.buildPanel) then return nil, "buildPanel must be a function" end
        if page.descriptionKey ~= nil then
            page.descriptionKey = normalizeId(page.descriptionKey)
            if not page.descriptionKey then return nil, "descriptionKey must be a non-empty string when provided" end
        end
        if page.fullTitleKey ~= nil then
            page.fullTitleKey = normalizeId(page.fullTitleKey)
            if not page.fullTitleKey then return nil, "fullTitleKey must be a non-empty string when provided" end
        end
        if page.icon ~= nil then
            page.icon = normalizeId(page.icon)
            if not page.icon then return nil, "icon must be a non-empty string when provided" end
        end
        if page.order ~= nil then
            page.order = normalizeOrder(page.order)
            if page.order == nil then return nil, "order must be a finite number when provided" end
        end
        if page.isVisible ~= nil and not isfunction(page.isVisible) then
            return nil, "isVisible must be a function when provided"
        end
        if page.default ~= nil and type(page.default) ~= "boolean" then
            return nil, "default must be a boolean when provided"
        end
        if page.searchKeys ~= nil then
            if not istable(page.searchKeys) then return nil, "searchKeys must be a table when provided" end
            local searchKeys = {}
            for i = 1, #page.searchKeys do
                local searchKey = normalizeId(page.searchKeys[i])
                if not searchKey then return nil, "searchKeys entries must be non-empty strings" end
                searchKeys[#searchKeys + 1] = searchKey
            end
            page.searchKeys = searchKeys
        end

        page.descriptionKey = page.descriptionKey or inferPageDescriptionKey(page.titleKey)
        page.fullTitleKey = page.fullTitleKey or inferPageFullTitleKey(page.descriptionKey)
        return page
    end

    local function detachDefinitionOwner(id, ownerById, idsByOwner)
        local owner = ownerById[id]
        if not owner then return end

        local ownedIds = idsByOwner[owner]
        if ownedIds then
            ownedIds[id] = nil
        end
        ownerById[id] = nil
    end

    local function setOwnedDefinition(definition, owner, byId, ownerById, idsByOwner)
        detachDefinitionOwner(definition.id, ownerById, idsByOwner)
        byId[definition.id] = definition

        if owner then
            ownerById[definition.id] = owner
            idsByOwner[owner] = idsByOwner[owner] or {}
            idsByOwner[owner][definition.id] = true
        end
    end

    local function notifyRegistryChanged()
        registry.revision = registry.revision + 1
        hook.Run("BetterLights_MenuRegistryChanged", registry.revision)

        if MENU.RefreshSettingsPanel then
            MENU.RefreshSettingsPanel()
        end
    end

    local function replaceOwnedDefinitions(
        kind,
        owner,
        definitions,
        normalizer,
        byId,
        ownerById,
        idsByOwner
    )
        owner = normalizeId(owner)
        if not owner then return reportRegistryError(kind .. " set", "owner must be a non-empty string") end
        if not istable(definitions) then return reportRegistryError(kind .. " set", "definitions must be a table") end

        local normalized = {}
        local nextIds = {}
        for i = 1, #definitions do
            local definition, reason = normalizer(definitions[i])
            if not definition then return reportRegistryError(kind, reason) end
            if nextIds[definition.id] then
                return reportRegistryError(kind .. " set", "duplicate id '" .. definition.id .. "'")
            end

            normalized[#normalized + 1] = definition
            nextIds[definition.id] = true
        end

        local previousIds = idsByOwner[owner] or {}
        for id in pairs(previousIds) do
            if not nextIds[id] and ownerById[id] == owner then
                byId[id] = nil
                ownerById[id] = nil
            end
        end

        idsByOwner[owner] = {}
        for i = 1, #normalized do
            setOwnedDefinition(normalized[i], owner, byId, ownerById, idsByOwner)
        end

        notifyRegistryChanged()
        return normalized
    end

    function MENU.RegisterCategory(definition)
        local category, reason = normalizeCategoryDefinition(definition)
        if not category then return reportRegistryError("category", reason) end

        setOwnedDefinition(
            category,
            nil,
            registry.categoriesById,
            registry.categoryOwnerById,
            registry.categoryIdsByOwner
        )
        notifyRegistryChanged()
        return category
    end

    function MENU.RegisterCategories(owner, definitions)
        return replaceOwnedDefinitions(
            "category",
            owner,
            definitions,
            normalizeCategoryDefinition,
            registry.categoriesById,
            registry.categoryOwnerById,
            registry.categoryIdsByOwner
        )
    end

    -- Without removePages, pages remain available under an implicit category using the category ID as its title.
    function MENU.UnregisterCategory(id, removePages)
        id = normalizeId(id)
        if not id then return false end

        local removed = false
        if registry.categoriesById[id] then
            detachDefinitionOwner(id, registry.categoryOwnerById, registry.categoryIdsByOwner)
            registry.categoriesById[id] = nil
            removed = true
        end

        if removePages then
            local pageIds = {}
            for pageId, page in pairs(registry.pagesById) do
                if page.category == id then
                    pageIds[#pageIds + 1] = pageId
                end
            end
            for i = 1, #pageIds do
                local pageId = pageIds[i]
                detachDefinitionOwner(pageId, registry.pageOwnerById, registry.pageIdsByOwner)
                registry.pagesById[pageId] = nil
                removed = true
            end
        end

        if removed then notifyRegistryChanged() end
        return removed
    end

    function MENU.RegisterPage(definition, id, titleKey, buildPanel, descriptionKey)
        local page, reason = normalizePageDefinition(definition, id, titleKey, buildPanel, descriptionKey)
        if not page then return reportRegistryError("page", reason) end

        setOwnedDefinition(
            page,
            nil,
            registry.pagesById,
            registry.pageOwnerById,
            registry.pageIdsByOwner
        )
        notifyRegistryChanged()
        return page
    end

    function MENU.RegisterPages(owner, definitions)
        return replaceOwnedDefinitions(
            "page",
            owner,
            definitions,
            normalizePageDefinition,
            registry.pagesById,
            registry.pageOwnerById,
            registry.pageIdsByOwner
        )
    end

    function MENU.UnregisterPage(id)
        id = normalizeId(id)
        if not id or not registry.pagesById[id] then return false end

        detachDefinitionOwner(id, registry.pageOwnerById, registry.pageIdsByOwner)
        registry.pagesById[id] = nil
        notifyRegistryChanged()
        return true
    end

    local function getSortedDefinitions(byId)
        local definitions = {}
        for _, definition in pairs(byId) do
            definitions[#definitions + 1] = definition
        end
        table.sort(definitions, function(a, b)
            return a.id < b.id
        end)
        return definitions
    end

    function MENU.GetCategoryDefinitions()
        return getSortedDefinitions(registry.categoriesById)
    end

    function MENU.GetRegisteredPages()
        return getSortedDefinitions(registry.pagesById)
    end

    function MENU.GetRegisteredPage(id)
        return registry.pagesById[id]
    end

    function MENU.BuildPage(id, panel)
        local page = MENU.GetRegisteredPage(id)
        if not page then return false end

        page.buildPanel(panel, page)
        return true
    end

    local function getOptionalPhrase(key)
        if not key then return "" end

        local phraseKey = "betterlights." .. key
        local value = language.GetPhrase(phraseKey)
        if value == phraseKey then return "" end
        return value
    end

    local function isDefinitionVisible(definition)
        if not definition.isVisible then return true end

        local succeeded, visible = pcall(definition.isVisible, definition)
        if not succeeded then
            if definition._visibilityError ~= visible then
                definition._visibilityError = visible
                ErrorNoHalt(
                    "[BetterLights] Menu visibility check for '"
                    .. definition.id
                    .. "' failed: "
                    .. tostring(visible)
                    .. "\n"
                )
            end
            return false
        end

        definition._visibilityError = nil
        return visible == true
    end

    local function compareNavigationItems(a, b)
        local aOrder = a.order
        local bOrder = b.order
        if aOrder ~= nil or bOrder ~= nil then
            aOrder = aOrder or math.huge
            bOrder = bOrder or math.huge
            if aOrder ~= bOrder then return aOrder < bOrder end
        end

        local aTitle = string.lower(a.title)
        local bTitle = string.lower(b.title)
        if aTitle ~= bTitle then return aTitle < bTitle end
        return a.id < b.id
    end

    local function pageMatchesFilter(page, filter)
        if filter == "" then return true end
        if string.find(string.lower(page.categoryTitle), filter, 1, true) then return true end
        if string.find(string.lower(page.title), filter, 1, true) then return true end
        if string.find(string.lower(page.fullTitle), filter, 1, true) then return true end
        if string.find(string.lower(page.description), filter, 1, true) then return true end

        for i = 1, #page.searchTerms do
            if string.find(string.lower(page.searchTerms[i]), filter, 1, true) then return true end
        end

        return false
    end

    function MENU.BuildNavigationModel(filter)
        filter = string.lower(string.Trim(tostring(filter or "")))

        local categoryViewsById = {}
        local hiddenCategories = {}
        for id, category in pairs(registry.categoriesById) do
            if isDefinitionVisible(category) then
                categoryViewsById[id] = {
                    id = id,
                    title = phrase(category.titleKey),
                    titleKey = category.titleKey,
                    icon = category.icon or DEFAULT_CATEGORY_ICON,
                    order = category.order,
                    allPages = {},
                    pages = {}
                }
            else
                hiddenCategories[id] = true
            end
        end

        local pagesById = {}
        for id, page in pairs(registry.pagesById) do
            if not hiddenCategories[page.category] and isDefinitionVisible(page) then
                local category = categoryViewsById[page.category]
                if not category then
                    category = {
                        id = page.category,
                        title = page.category,
                        icon = DEFAULT_CATEGORY_ICON,
                        allPages = {},
                        pages = {}
                    }
                    categoryViewsById[page.category] = category
                end

                local title = phrase(page.titleKey)
                local fullTitle = getOptionalPhrase(page.fullTitleKey)
                local searchTerms = {}
                for i = 1, #(page.searchKeys or {}) do
                    searchTerms[#searchTerms + 1] = phrase(page.searchKeys[i])
                end

                local pageView = {
                    id = id,
                    category = page.category,
                    categoryTitle = category.title,
                    title = title,
                    titleKey = page.titleKey,
                    description = getOptionalPhrase(page.descriptionKey),
                    descriptionKey = page.descriptionKey,
                    fullTitle = fullTitle ~= "" and fullTitle or title,
                    fullTitleKey = page.fullTitleKey,
                    icon = page.icon or DEFAULT_PAGE_ICON,
                    order = page.order,
                    default = page.default == true,
                    searchTerms = searchTerms
                }
                category.allPages[#category.allPages + 1] = pageView
                pagesById[id] = pageView
            end
        end

        local allCategories = {}
        for _, category in pairs(categoryViewsById) do
            if #category.allPages > 0 then
                table.sort(category.allPages, compareNavigationItems)
                allCategories[#allCategories + 1] = category
            end
        end
        table.sort(allCategories, compareNavigationItems)

        local categories = {}
        local pages = {}
        local defaultPage
        local matchCount = 0
        for i = 1, #allCategories do
            local category = allCategories[i]
            for j = 1, #category.allPages do
                local page = category.allPages[j]
                pages[#pages + 1] = page
                if page.default and not defaultPage then
                    defaultPage = page
                end
                if pageMatchesFilter(page, filter) then
                    category.pages[#category.pages + 1] = page
                    matchCount = matchCount + 1
                end
            end
            if #category.pages > 0 then
                categories[#categories + 1] = category
            end
        end

        for i = 1, #allCategories do
            local category = allCategories[i]
            category.allPages = nil
            category.order = nil
        end
        for i = 1, #pages do
            local page = pages[i]
            page.categoryTitle = nil
            page.searchTerms = nil
            page.order = nil
            page.default = nil
        end

        return {
            categories = categories,
            pages = pages,
            pagesById = pagesById,
            defaultPage = defaultPage or pages[1],
            filter = filter,
            matchCount = matchCount,
            revision = registry.revision
        }
    end

    local refreshSettingsPanelQueued = false
    function MENU.RefreshSettingsPanel()
        if refreshSettingsPanelQueued then return end
        refreshSettingsPanelQueued = true

        timer.Simple(0, function()
            refreshSettingsPanelQueued = false
            if MENU.RefreshSettingsWindow then
                MENU.RefreshSettingsWindow()
            end
        end)
    end

    MENU.RegisterCategories("BetterLights_Menu_Categories", {
        { id = "General", titleKey = "category.general", icon = "icon16/cog.png", order = 100 },
        { id = "Appearance", titleKey = "category.appearance", icon = "icon16/application_view_tile.png", order = 200 },
        { id = "Profiles", titleKey = "category.profiles", icon = "icon16/disk.png", order = 300 },
        { id = "Flashlight", titleKey = "category.flashlight", icon = "icon16/lightbulb.png", order = 400 },
        { id = "Weapons", titleKey = "category.weapons", icon = "icon16/gun.png", order = 500 },
        { id = "Gunfire", titleKey = "category.gunfire", icon = "icon16/bomb.png", order = 600 },
        { id = "Projectiles", titleKey = "category.projectiles", icon = "icon16/bullet_go.png", order = 700 },
        { id = "NPCs", titleKey = "category.npcs", icon = "icon16/group.png", order = 800 },
        { id = "Eye Glow", titleKey = "category.eye_glow", icon = "icon16/eye.png", order = 900 },
        { id = "Environment", titleKey = "category.environment", icon = "icon16/world.png", order = 1000 },
        { id = "Pickups", titleKey = "category.pickups", icon = "icon16/box.png", order = 1100 },
        { id = "Integrations", titleKey = "category.integrations", icon = "icon16/plugin.png", order = 1200 },
        { id = "Admin", titleKey = "category.admin", icon = "icon16/shield.png", order = 1300 },
        {
            id = "Developer",
            titleKey = "category.developer",
            icon = "icon16/wrench.png",
            order = 1400,
            isVisible = isDeveloperMode
        },
        { id = "About", titleKey = "category.about", icon = "icon16/information.png", order = 1500 }
    })

    cvars.RemoveChangeCallback("developer", "BetterLights_MenuDeveloperVisibility")
    cvars.AddChangeCallback("developer", function()
        MENU.RefreshSettingsPanel()
    end, "BetterLights_MenuDeveloperVisibility")

    -- Remove the old broad effect-page owner before category-scoped page modules register.
    MENU.RegisterPages("BetterLights_Menu_ClientEffects", {})
    MENU.RegisterPages("BetterLights_Menu_NPCLights", {})

    MENU.EnsurePagesRegistered = nil
    MENU.RegisterGeneralPanel = nil
    MENU.RegisterAppearancePanel = nil
    MENU.RegisterGunfirePanels = nil
    MENU.RegisterWeaponPanels = nil
    MENU.RegisterNPCLightPanels = nil
    MENU.RegisterIntegrationPanels = nil
    MENU.RegisterDeveloperPanel = nil
    MENU.RegisterAboutPanel = nil
    MENU.RegisterServerPanels = nil
end
