-- BetterLights: Crossbow bolt dynamic lighting (orange glow)
-- Client-side only

if CLIENT then
    local cvar_enable = CreateClientConVar("betterlights_bolt_enable", "1", true, false, "Enable dynamic light for crossbow bolts")
    local cvar_size = CreateClientConVar("betterlights_bolt_size", "220", true, false, "Dynamic light radius for crossbow bolts")
    local cvar_brightness = CreateClientConVar("betterlights_bolt_brightness", "0.96", true, false, "Dynamic light brightness for crossbow bolts")
    local cvar_decay = CreateClientConVar("betterlights_bolt_decay", "2000", true, false, "Dynamic light decay for crossbow bolts")

    -- Default warm orange color
    local ORANGE = { r = 255, g = 140, b = 40 }

    hook.Add("Think", "BetterLights_CrossbowBolt_DLight", function()
        if not cvar_enable:GetBool() then return end

        local bolts = ents.FindByClass("crossbow_bolt")
        if not bolts or #bolts == 0 then return end

        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())

        for _, ent in ipairs(bolts) do
            if IsValid(ent) then
                local dlight = DynamicLight(ent:EntIndex())
                if dlight then
                    dlight.pos = ent:WorldSpaceCenter()
                    dlight.r = ORANGE.r
                    dlight.g = ORANGE.g
                    dlight.b = ORANGE.b
                    dlight.brightness = brightness
                    dlight.decay = decay
                    dlight.size = size
                    dlight.minlight = 0
                    dlight.noworld = false
                    dlight.nomodel = false
                    dlight.dietime = CurTime() + 0.1
                end
            end
        end
    end)
end
