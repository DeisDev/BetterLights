-- BetterLights: RPG rocket dynamic lighting
-- Client-side only

if CLIENT then
    local cvar_enable = CreateClientConVar("betterlights_rpg_enable", "1", true, false, "Enable dynamic light for fired RPG rockets")
    local cvar_size = CreateClientConVar("betterlights_rpg_size", "280", true, false, "Dynamic light radius for RPG rockets")
    local cvar_brightness = CreateClientConVar("betterlights_rpg_brightness", "2.2", true, false, "Dynamic light brightness for RPG rockets")
    local cvar_decay = CreateClientConVar("betterlights_rpg_decay", "2000", true, false, "Dynamic light decay for RPG rockets")

    -- Warm orange/yellow flame color
    local FLAME = { r = 255, g = 170, b = 60 }

    hook.Add("Think", "BetterLights_RPGMissile_DLight", function()
        if not cvar_enable:GetBool() then return end

        -- HL2 RPG projectile class
        local rockets = ents.FindByClass("rpg_missile")
        if not rockets or #rockets == 0 then return end

        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())

        for _, ent in ipairs(rockets) do
            if IsValid(ent) then
                local dlight = DynamicLight(ent:EntIndex())
                if dlight then
                    dlight.pos = ent:WorldSpaceCenter()
                    dlight.r = FLAME.r
                    dlight.g = FLAME.g
                    dlight.b = FLAME.b
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
