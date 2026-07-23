if CLIENT then
    local BL = BetterLights

    local cvar_eye_enable = BL.CreateClientConVar(
        "betterlights_npc_ragdoll_eye_lights_enable",
        "0",
        true,
        false,
        "Keep supported NPC eye lights on their ragdolls",
        0,
        1
    )
    local cvar_ambient_enable = BL.CreateClientConVar(
        "betterlights_npc_ragdoll_ambient_lights_enable",
        "0",
        true,
        false,
        "Keep supported NPC ambient body lights on their ragdolls",
        0,
        1
    )
    local cvar_max_remains = BL.CreateClientConVar(
        "betterlights_npc_ragdoll_max_lit_remains",
        "8",
        true,
        false,
        "Maximum nearest NPC ragdolls that can retain Better Lights effects",
        0,
        32
    )

    BL._npcRagdollLightProviders = BL._npcRagdollLightProviders or {}
    BL._npcRagdollLightRecords = BL._npcRagdollLightRecords or {}
    BL._npcRagdollLightSelection = BL._npcRagdollLightSelection or {}
    BL._npcRagdollLightCandidates = BL._npcRagdollLightCandidates or {}
    BL.NPC_RAGDOLL_LIGHT_OPTIONS = {
        priority = BL.LIGHT_PRIORITY_CORPSE
    }

    local providers = BL._npcRagdollLightProviders
    local records = BL._npcRagdollLightRecords
    local selected = BL._npcRagdollLightSelection
    local selectionCandidates = BL._npcRagdollLightCandidates
    local nextSelectionUpdate = 0
    setmetatable(records, { __mode = "k" })
    setmetatable(selected, { __mode = "k" })

    local function isCategoryEnabled(category)
        if category == "eye" then
            return cvar_eye_enable:GetBool()
        elseif category == "ambient" then
            return cvar_ambient_enable:GetBool()
        end

        return false
    end

    function BL.RegisterNPCRagdollLightProvider(id, definition)
        if type(id) ~= "string" or id == "" then return false end
        if type(definition) ~= "table" then return false end
        if type(definition.class) ~= "string" or definition.class == "" then return false end
        if definition.category ~= "eye" and definition.category ~= "ambient" then return false end
        if not isfunction(definition.update) then return false end

        local classProviders = providers[definition.class]
        if not classProviders then
            classProviders = {}
            providers[definition.class] = classProviders
        end

        classProviders[id] = definition
        return true
    end

    function BL.GetNPCRagdollLightId(entry, slot)
        slot = tostring(slot or "main")
        entry.lightIds = entry.lightIds or {}

        local id = entry.lightIds[slot]
        if id then return id end

        id = BL.NewLightId(80000)
        entry.lightIds[slot] = id
        return id
    end

    local function trackRagdollForClass(ownerClass, source, ragdoll)
        if type(ownerClass) ~= "string" or ownerClass == "" then return end
        if not (IsValid(source) and IsValid(ragdoll)) then return end

        local classProviders = providers[ownerClass]
        if not classProviders then return end

        local record = records[ragdoll]
        if not record then
            record = {
                class = ownerClass,
                entries = {}
            }
        end

        for id, provider in pairs(classProviders) do
            local data = true
            if provider.capture then
                data = provider.capture(source)
            end

            if data ~= nil and data ~= false then
                local entry = record.entries[id] or {}
                entry.data = data
                record.entries[id] = entry
            end
        end

        if next(record.entries) then
            records[ragdoll] = record
        end
    end

    local function trackRagdoll(owner, ragdoll)
        if not (IsValid(owner) and IsValid(ragdoll)) then return end
        if not (owner.IsNPC and owner:IsNPC()) then return end
        if not owner.GetClass then return end

        trackRagdollForClass(owner:GetClass(), owner, ragdoll)
    end

    local function recordHasEnabledProvider(record)
        local classProviders = providers[record.class]
        if not classProviders then return false end

        for id in pairs(record.entries) do
            local provider = classProviders[id]
            if provider and isCategoryEnabled(provider.category) then
                return true
            end
        end

        return false
    end

    local function clearSelection()
        for ragdoll in pairs(selected) do
            selected[ragdoll] = nil
        end
    end

    local function refreshSelection()
        for i = #selectionCandidates, 1, -1 do
            selectionCandidates[i] = nil
        end

        local maxRemains = math.Clamp(cvar_max_remains:GetInt(), 0, 32)
        if maxRemains <= 0 then
            clearSelection()
            return
        end
        if not cvar_eye_enable:GetBool() and not cvar_ambient_enable:GetBool() then
            clearSelection()
            return
        end

        local viewPos = MainEyePos()
        for ragdoll, record in pairs(records) do
            if not IsValid(ragdoll) then
                records[ragdoll] = nil
            elseif recordHasEnabledProvider(record) then
                record.distanceSqr = ragdoll:GetPos():DistToSqr(viewPos)
                if selected[ragdoll] then
                    record.distanceSqr = record.distanceSqr * 0.8
                end
                selectionCandidates[#selectionCandidates + 1] = ragdoll
            end
        end

        clearSelection()

        if #selectionCandidates > maxRemains then
            table.sort(selectionCandidates, function(a, b)
                return records[a].distanceSqr < records[b].distanceSqr
            end)
        end

        for i = 1, math.min(maxRemains, #selectionCandidates) do
            selected[selectionCandidates[i]] = true
        end
    end

    hook.Add("CreateClientsideRagdoll", "BetterLights_NPCRagdollLights_Client", trackRagdoll)
    hook.Add("CreateEntityRagdoll", "BetterLights_NPCRagdollLights_ServerEntity", trackRagdoll)
    local function tryTrackRagdollFallback(ragdoll)
        if not (IsValid(ragdoll) and ragdoll.GetRagdollOwner) then return end

        local owner = ragdoll:GetRagdollOwner()
        if IsValid(owner) then
            trackRagdoll(owner, ragdoll)
            return
        end

        local ownerClass = ragdoll:GetNW2String("BetterLights_NPCRagdollClass", "")
        if ownerClass ~= "" then
            trackRagdollForClass(ownerClass, ragdoll, ragdoll)
        end
    end

    hook.Add("OnEntityCreated", "BetterLights_NPCRagdollLights_OwnerFallback", function(ragdoll)
        if not (ragdoll.GetClass and ragdoll:GetClass() == "prop_ragdoll") then return end

        for _, delay in ipairs({ 0, 0.1, 0.25, 0.5, 1 }) do
            timer.Simple(delay, function()
                if records[ragdoll] then return end
                tryTrackRagdollFallback(ragdoll)
            end)
        end
    end)

    local function updateRagdoll(ragdoll)
        local record = records[ragdoll]
        if not (IsValid(ragdoll) and record) then
            selected[ragdoll] = nil
            records[ragdoll] = nil
            return
        end
        if ragdoll.GetNoDraw and ragdoll:GetNoDraw() then return end

        local classProviders = providers[record.class]
        if not classProviders then return end

        for id, entry in pairs(record.entries) do
            local provider = classProviders[id]
            if provider and isCategoryEnabled(provider.category) then
                provider.update(ragdoll, entry.data, entry)
            end
        end
    end

    BL.AddThink("BetterLights_NPCRagdollLights", function()
        local now = CurTime()
        if now >= nextSelectionUpdate then
            nextSelectionUpdate = now + 0.2
            refreshSelection()
        end

        for ragdoll in pairs(selected) do
            updateRagdoll(ragdoll)
        end
    end)
end
