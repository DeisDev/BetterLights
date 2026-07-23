if SERVER then
    hook.Add("CreateEntityRagdoll", "BetterLights_NPCRagdollLights_Class", function(owner, ragdoll)
        if not (IsValid(owner) and IsValid(ragdoll)) then return end
        if not (owner.IsNPC and owner:IsNPC()) then return end
        if not owner.GetClass then return end

        ragdoll:SetNW2String("BetterLights_NPCRagdollClass", owner:GetClass())
    end)
end
