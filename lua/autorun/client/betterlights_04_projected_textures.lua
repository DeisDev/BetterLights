if CLIENT then

    local BL = BetterLights

    BL._projectedTextureUpdates = BL._projectedTextureUpdates or {}
    BL._projectedTextureRecords = BL._projectedTextureRecords or {}
    BL._projectedTextureCandidateList = BL._projectedTextureCandidateList or {}
    BL._projectedBudgetPrevious = BL._projectedBudgetPrevious or {}
    BL._projectedBudgetNext = BL._projectedBudgetNext or {}
    BL._projectedTextureStores = BL._projectedTextureStores or {}
    setmetatable(BL._projectedTextureStores, { __mode = "k" })

    for lamp in pairs(BL._projectedTextureUpdates) do
        BL._projectedTextureUpdates[lamp] = nil
    end

    function BL.RegisterProjectedTextureStore(store, dataStore)
        if type(store) ~= "table" then return false end

        local registration = BL._projectedTextureStores[store]
        if not registration then
            registration = {}
            BL._projectedTextureStores[store] = registration
        end

        if dataStore then
            registration.dataStore = dataStore
        end

        return true
    end

    function BL.UnregisterProjectedTextureStore(store, shouldClear)
        if type(store) ~= "table" then return end

        local registration = BL._projectedTextureStores[store]
        if shouldClear then
            BL.ClearProjectedTextures(store, registration and registration.dataStore)
        end

        BL._projectedTextureStores[store] = nil
    end

    function BL.GetOrCreateProjectedTexture(store, key, texture)
        if not ProjectedTexture then return nil end
        if not BL.IsEnabled() then return nil end

        BL.RegisterProjectedTextureStore(store)

        local lamp = store[key]
        if lamp and lamp.IsValid and lamp:IsValid() then return lamp end

        if lamp then
            BL._projectedTextureUpdates[lamp] = nil
            BL._projectedTextureRecords[lamp] = nil
            BL._projectedBudgetPrevious[lamp] = nil
            BL._projectedBudgetNext[lamp] = nil
        end

        lamp = ProjectedTexture()
        if not lamp then return nil end

        if texture then
            lamp:SetTexture(texture)
        end

        store[key] = lamp
        return lamp
    end

    function BL.UpdateProjectedTexture(lamp, options)
        if not (lamp and lamp.IsValid and lamp:IsValid()) then return false end
        if not (options and options.pos) then return false end

        local record = BL._projectedTextureRecords[lamp]
        if not record then
            record = {
                key = lamp,
                lamp = lamp
            }
            BL._projectedTextureRecords[lamp] = record
        end

        local color = options.color or color_white
        record.options = options
        record.pos = options.pos
        record.r = color.r or 255
        record.g = color.g or 255
        record.b = color.b or 255
        record.brightness = math.max(0, tonumber(options.brightness) or 0)
        record.size = math.max(1, tonumber(options.farZ) or 1)
        record.priority = tonumber(options.priority) or BL.LIGHT_PRIORITY_AMBIENT
        BL._projectedTextureUpdates[lamp] = record
        return true
    end

    function BL.RemoveProjectedTexture(store, key, dataStore)
        BL.RegisterProjectedTextureStore(store, dataStore)

        local lamp = store[key]

        if lamp then
            BL._projectedTextureUpdates[lamp] = nil
            BL._projectedTextureRecords[lamp] = nil
            BL._projectedBudgetPrevious[lamp] = nil
            BL._projectedBudgetNext[lamp] = nil
        end

        if lamp and lamp.IsValid and lamp:IsValid() then
            lamp:Remove()
        end

        store[key] = nil
        if dataStore then
            dataStore[key] = nil
        end
    end

    function BL.RemoveStaleProjectedTextures(store, seen, shouldRemove, dataStore)
        BL.RegisterProjectedTextureStore(store, dataStore)

        for key in pairs(store) do
            if (not seen[key]) or (shouldRemove and shouldRemove(key)) then
                BL.RemoveProjectedTexture(store, key, dataStore)
            end
        end
    end

    function BL.ClearProjectedTextures(store, dataStore)
        BL.RegisterProjectedTextureStore(store, dataStore)

        for key in pairs(store) do
            BL.RemoveProjectedTexture(store, key, dataStore)
        end
    end

    function BL.ClearAllProjectedTextures()
        for store, registration in pairs(BL._projectedTextureStores) do
            BL.ClearProjectedTextures(store, registration.dataStore)
        end

        for lamp in pairs(BL._projectedTextureUpdates) do
            BL._projectedTextureUpdates[lamp] = nil
        end

        for lamp in pairs(BL._projectedTextureRecords) do
            BL._projectedTextureRecords[lamp] = nil
            BL._projectedBudgetPrevious[lamp] = nil
            BL._projectedBudgetNext[lamp] = nil
        end
    end

    hook.Add("BetterLights_EffectiveEnabledChanged", "BetterLights_ProjectorEffectiveEnable", function(enabled)
        if not enabled then
            BL.ClearAllProjectedTextures()
        end
    end)

    hook.Add("ShutDown", "BetterLights_ProjectorStoreCleanup", function()
        BL.ClearAllProjectedTextures()
    end)

    if not BL.IsEnabled() then
        BL.ClearAllProjectedTextures()
    end

    local function applyProjectedTextureOptions(lamp, options, brightnessScale)
        if options.texture then lamp:SetTexture(options.texture) end
        lamp:SetPos(options.pos)
        lamp:SetAngles(options.ang)
        lamp:SetNearZ(options.nearZ)
        lamp:SetFarZ(options.farZ)
        lamp:SetFOV(options.fov)
        lamp:SetBrightness((tonumber(options.brightness) or 0) * brightnessScale)
        lamp:SetColor(options.color or color_white)
        lamp:SetEnableShadows(options.shadows)
        if options.shadowDepthBias then lamp:SetShadowDepthBias(options.shadowDepthBias) end
        if options.shadowSlopeScaleDepthBias then lamp:SetShadowSlopeScaleDepthBias(options.shadowSlopeScaleDepthBias) end
        if options.shadowFilter then lamp:SetShadowFilter(options.shadowFilter) end
        if options.noCull ~= nil then lamp:SetNoCull(options.noCull) end
        if options.linearAttenuation then lamp:SetLinearAttenuation(options.linearAttenuation) end
        if options.constantAttenuation then lamp:SetConstantAttenuation(options.constantAttenuation) end
        if options.quadraticAttenuation then lamp:SetQuadraticAttenuation(options.quadraticAttenuation) end
        lamp:Update()
    end

    hook.Add("PreDrawOpaqueRenderables", "BetterLights_ProjectorUpdate", function(isDrawingDepth)
        if not BL.IsMainViewRender(isDrawingDepth) then return end

        local candidates = BL._projectedTextureCandidateList
        for i = #candidates, 1, -1 do
            candidates[i] = nil
        end

        for lamp, record in pairs(BL._projectedTextureUpdates) do
            BL._projectedTextureUpdates[lamp] = nil

            if lamp and lamp.IsValid and lamp:IsValid() and record.options then
                candidates[#candidates + 1] = record
            end
        end

        local selected, selectedCount, stats = BL.SelectLightBudgetCandidates(
            "projected",
            candidates,
            BL._projectedBudgetPrevious,
            BL._projectedBudgetNext,
            BL._lightBudgetScratch.projected
        )

        for i = 1, selectedCount do
            local record = selected[i]
            local lamp = record.lamp
            if lamp and lamp.IsValid and lamp:IsValid() then
                applyProjectedTextureOptions(lamp, record.options, record._budgetFade or 1)
                stats.emitted = stats.emitted + 1
            end
        end

        for i = 1, #candidates do
            local record = candidates[i]
            local lamp = record.lamp
            if not BL._projectedBudgetNext[record.key]
                and lamp
                and lamp.IsValid
                and lamp:IsValid()
            then
                lamp:SetBrightness(0)
                lamp:SetEnableShadows(false)
                lamp:Update()
            end
        end

        BL._projectedBudgetPrevious, BL._projectedBudgetNext =
            BL._projectedBudgetNext, BL._projectedBudgetPrevious
    end)
end
