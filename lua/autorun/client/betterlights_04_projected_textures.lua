if CLIENT then

    local BL = BetterLights

    BL._projectedTextureUpdates = BL._projectedTextureUpdates or {}

    function BL.GetOrCreateProjectedTexture(store, key, texture)
        if not ProjectedTexture then return nil end

        local lamp = store[key]
        if lamp and lamp.IsValid and lamp:IsValid() then return lamp end

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

        if options.texture then lamp:SetTexture(options.texture) end
        lamp:SetPos(options.pos)
        lamp:SetAngles(options.ang)
        lamp:SetNearZ(options.nearZ)
        lamp:SetFarZ(options.farZ)
        lamp:SetFOV(options.fov)
        lamp:SetBrightness(options.brightness)
        lamp:SetColor(options.color)
        lamp:SetEnableShadows(options.shadows)
        if options.noCull ~= nil then lamp:SetNoCull(options.noCull) end
        if options.linearAttenuation then lamp:SetLinearAttenuation(options.linearAttenuation) end
        if options.constantAttenuation then lamp:SetConstantAttenuation(options.constantAttenuation) end
        if options.quadraticAttenuation then lamp:SetQuadraticAttenuation(options.quadraticAttenuation) end
        BL._projectedTextureUpdates[lamp] = true
        return true
    end

    function BL.RemoveProjectedTexture(store, key, dataStore)
        local lamp = store[key]

        if lamp then
            BL._projectedTextureUpdates[lamp] = nil
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
        for key in pairs(store) do
            if (not seen[key]) or (shouldRemove and shouldRemove(key)) then
                BL.RemoveProjectedTexture(store, key, dataStore)
            end
        end
    end

    function BL.ClearProjectedTextures(store, dataStore)
        for key in pairs(store) do
            BL.RemoveProjectedTexture(store, key, dataStore)
        end
    end

    hook.Add("PreDrawOpaqueRenderables", "BetterLights_ProjectorUpdate", function()
        for lamp in pairs(BL._projectedTextureUpdates) do
            BL._projectedTextureUpdates[lamp] = nil

            if lamp and lamp.IsValid and lamp:IsValid() then
                lamp:Update()
            end
        end
    end)
end
