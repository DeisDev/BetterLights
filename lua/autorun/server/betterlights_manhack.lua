if SERVER then
    local BL = BetterLights
    local TARGET_CLASS = "npc_manhack"
    local STATE_KEY = "BetterLights_ManhackHacked"
    local STATE_UPDATE_INTERVAL = 0.1
    local tracked = {}
    local trackingEnabled = false
    local nextStateUpdate = 0

    local function isHacked(ent)
        return ent:GetInternalVariable("m_bHackedByAlyx") == true
    end

    local function track(ent)
        if not IsValid(ent) or ent:GetClass() ~= TARGET_CLASS then return end
        tracked[ent] = true
    end

    hook.Add("OnEntityCreated", "BetterLights_ManhackState_Track", function(ent)
        if not BL.IsServerEnabled() then return end
        timer.Simple(0, function()
            if not BL.IsServerEnabled() then return end
            track(ent)
        end)
    end)

    hook.Add("EntityRemoved", "BetterLights_ManhackState_Remove", function(ent)
        tracked[ent] = nil
    end)

    hook.Add("CreateEntityRagdoll", "BetterLights_ManhackState_Ragdoll", function(owner, ragdoll)
        if not (IsValid(owner) and IsValid(ragdoll)) then return end
        if owner:GetClass() ~= TARGET_CLASS then return end
        -- Preserve corpse state even if lighting is enabled only after the owner is gone.
        ragdoll:SetNW2Bool(STATE_KEY, isHacked(owner))
    end)

    hook.Add("Think", "BetterLights_ManhackState_Update", function()
        if not BL.IsServerEnabled() then
            if trackingEnabled then table.Empty(tracked) end
            trackingEnabled = false
            return
        end
        if not trackingEnabled then
            table.Empty(tracked)
            for _, ent in ipairs(ents.FindByClass(TARGET_CLASS)) do
                track(ent)
            end
            trackingEnabled = true
            nextStateUpdate = 0
        end

        local now = CurTime()
        if now < nextStateUpdate then return end
        nextStateUpdate = now + STATE_UPDATE_INTERVAL

        for ent in pairs(tracked) do
            if not IsValid(ent) then
                tracked[ent] = nil
            else
                local hacked = isHacked(ent)
                if ent:GetNW2Bool(STATE_KEY, false) ~= hacked then
                    ent:SetNW2Bool(STATE_KEY, hacked)
                end
            end
        end
    end)
end
