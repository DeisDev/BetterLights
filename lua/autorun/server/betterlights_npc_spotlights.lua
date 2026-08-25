if SERVER then
    local STATE_UPDATE_INTERVAL = 0.1
    local SPOTLIGHT_CONFIGS = {
        npc_cscanner = {
            stateKey = "BetterLights_ScannerSpotlightActive",
            targetKey = "BetterLights_ScannerSpotlightTarget"
        },
        npc_clawscanner = {
            stateKey = "BetterLights_ScannerSpotlightActive",
            targetKey = "BetterLights_ScannerSpotlightTarget"
        },
        npc_helicopter = {
            stateKey = "BetterLights_HunterChopperSpotlightActive",
            targetKey = "BetterLights_HunterChopperSpotlightTarget"
        }
    }

    local trackedOwners = {}
    local trackedSpotlights = {}
    local ownerSpotlights = {}
    local nextStateUpdate = 0

    local function getConfig(ent)
        if not (IsValid(ent) and ent.GetClass) then return nil end
        return SPOTLIGHT_CONFIGS[ent:GetClass()]
    end

    local function trackOwner(ent)
        if not getConfig(ent) then return end
        trackedOwners[ent] = true
    end

    local function trackSpotlight(ent)
        if not (IsValid(ent) and ent.GetClass and ent:GetClass() == "spotlight_end") then return end
        trackedSpotlights[ent] = true

        local owner = ent:GetOwner()
        if not getConfig(owner) then return end

        trackOwner(owner)
        ownerSpotlights[owner] = ent
    end

    hook.Add("OnEntityCreated", "BetterLights_NPCSpotlightState_Track", function(ent)
        timer.Simple(0, function()
            trackOwner(ent)
            trackSpotlight(ent)
        end)
    end)

    hook.Add("EntityRemoved", "BetterLights_NPCSpotlightState_Remove", function(ent)
        local owner = ent.GetOwner and ent:GetOwner()
        if IsValid(owner) and ownerSpotlights[owner] == ent then
            ownerSpotlights[owner] = nil
        end

        ownerSpotlights[ent] = nil
        trackedSpotlights[ent] = nil
        trackedOwners[ent] = nil
    end)

    timer.Simple(0, function()
        for className in pairs(SPOTLIGHT_CONFIGS) do
            for _, ent in ipairs(ents.FindByClass(className)) do
                trackOwner(ent)
            end
        end

        for _, ent in ipairs(ents.FindByClass("spotlight_end")) do
            trackSpotlight(ent)
        end
    end)

    hook.Add("Think", "BetterLights_NPCSpotlightState_Update", function()
        local now = CurTime()
        if now < nextStateUpdate then return end
        nextStateUpdate = now + STATE_UPDATE_INTERVAL

        for ent in pairs(trackedSpotlights) do
            if IsValid(ent) then
                trackSpotlight(ent)
            else
                trackedSpotlights[ent] = nil
            end
        end

        for ent in pairs(trackedOwners) do
            local config = getConfig(ent)
            if not config then
                ownerSpotlights[ent] = nil
                trackedOwners[ent] = nil
            else
                local target = ownerSpotlights[ent]
                local active = IsValid(target) and target:GetOwner() == ent
                if ent:GetNW2Bool(config.stateKey, false) ~= active then
                    ent:SetNW2Bool(config.stateKey, active)
                end

                target = active and target or NULL
                if ent:GetNW2Entity(config.targetKey, NULL) ~= target then
                    ent:SetNW2Entity(config.targetKey, target)
                end
            end
        end
    end)
end
