-- BetterLights: RPG rocket dynamic lighting
-- Client-side only

if CLIENT then
    local cvar_enable = CreateClientConVar("betterlights_rpg_enable", "1", true, false, "Enable dynamic light for fired RPG rockets")
    local cvar_size = CreateClientConVar("betterlights_rpg_size", "280", true, false, "Dynamic light radius for RPG rockets")
    local cvar_brightness = CreateClientConVar("betterlights_rpg_brightness", "2.2", true, false, "Dynamic light brightness for RPG rockets")
    local cvar_decay = CreateClientConVar("betterlights_rpg_decay", "2000", true, false, "Dynamic light decay for RPG rockets")

    -- Color configuration
    local cvar_col_r = CreateClientConVar("betterlights_rpg_color_r", "255", true, false, "RPG rocket color - red (0-255)")
    local cvar_col_g = CreateClientConVar("betterlights_rpg_color_g", "170", true, false, "RPG rocket color - green (0-255)")
    local cvar_col_b = CreateClientConVar("betterlights_rpg_color_b", "60", true, false, "RPG rocket color - blue (0-255)")
    local function getColor()
        return math.Clamp(math.floor(cvar_col_r:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_col_g:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_col_b:GetFloat() + 0.5), 0, 255)
    end

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
                    local r, g, b = getColor()
                    dlight.r = r
                    dlight.g = g
                    dlight.b = b
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
