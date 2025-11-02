-- BetterLights: Manhack (npc_manhack) glow
-- Client-side only

if CLIENT then
    local cvar_enable = CreateClientConVar("betterlights_manhack_enable", "1", true, false, "Enable dynamic light for Manhacks (npc_manhack)")
    local cvar_size = CreateClientConVar("betterlights_manhack_size", "70", true, false, "Dynamic light radius for Manhacks")
    local cvar_brightness = CreateClientConVar("betterlights_manhack_brightness", "0.6", true, false, "Dynamic light brightness for Manhacks")
    local cvar_decay = CreateClientConVar("betterlights_manhack_decay", "2000", true, false, "Dynamic light decay for Manhacks")
    local cvar_models_elight = CreateClientConVar("betterlights_manhack_models_elight", "1", true, false, "Also add an entity light (elight) to light the Manhack model directly")
    local cvar_models_elight_size_mult = CreateClientConVar("betterlights_manhack_models_elight_size_mult", "1.0", true, false, "Multiplier for Manhack elight radius")

    local RED = { r = 255, g = 60, b = 60 }

    hook.Add("Think", "BetterLights_Manhack_DLight", function()
        if not cvar_enable:GetBool() then return end

        local entsList = ents.FindByClass("npc_manhack")
        if not entsList or #entsList == 0 then return end

        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())

        for _, ent in ipairs(entsList) do
            if IsValid(ent) then
                local idx = ent:EntIndex()
                local pos
                if ent.OBBCenter and ent.LocalToWorld then
                    pos = ent:LocalToWorld(ent:OBBCenter())
                elseif ent.WorldSpaceCenter then
                    pos = ent:WorldSpaceCenter()
                else
                    pos = ent:GetPos()
                end

                local d = DynamicLight(idx)
                if d then
                    d.pos = pos
                    d.r = RED.r
                    d.g = RED.g
                    d.b = RED.b
                    d.brightness = brightness
                    d.decay = decay
                    d.size = size
                    d.minlight = 0
                    d.noworld = false
                    d.nomodel = false
                    d.dietime = CurTime() + 0.1
                end

                if cvar_models_elight:GetBool() then
                    local el = DynamicLight(idx, true)
                    if el then
                        el.pos = pos
                        el.r = RED.r
                        el.g = RED.g
                        el.b = RED.b
                        el.brightness = brightness
                        el.decay = decay
                        el.size = size * math.max(0, cvar_models_elight_size_mult:GetFloat())
                        el.minlight = 0
                        el.dietime = CurTime() + 0.1
                    end
                end
            end
        end
    end)
end
