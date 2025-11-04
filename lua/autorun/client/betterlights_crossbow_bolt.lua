-- BetterLights: Crossbow bolt dynamic lighting (orange glow)
-- Client-side only

if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
    local cvar_enable = CreateClientConVar("betterlights_bolt_enable", "1", true, false, "Enable dynamic light for crossbow bolts")
    local cvar_size = CreateClientConVar("betterlights_bolt_size", "220", true, false, "Dynamic light radius for crossbow bolts")
    local cvar_brightness = CreateClientConVar("betterlights_bolt_brightness", "0.96", true, false, "Dynamic light brightness for crossbow bolts")
    local cvar_decay = CreateClientConVar("betterlights_bolt_decay", "2000", true, false, "Dynamic light decay for crossbow bolts")

    -- Color configuration
    local cvar_col_r = CreateClientConVar("betterlights_bolt_color_r", "255", true, false, "Crossbow bolt color - red (0-255)")
    local cvar_col_g = CreateClientConVar("betterlights_bolt_color_g", "140", true, false, "Crossbow bolt color - green (0-255)")
    local cvar_col_b = CreateClientConVar("betterlights_bolt_color_b", "40", true, false, "Crossbow bolt color - blue (0-255)")
    local function getColor()
        return math.Clamp(math.floor(cvar_col_r:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_col_g:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_col_b:GetFloat() + 0.5), 0, 255)
    end

    if BL.TrackClass then BL.TrackClass("crossbow_bolt") end

    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_CrossbowBolt_DLight", function()
        if not cvar_enable:GetBool() then return end

        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())

        local function update(ent)
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

        if BL.ForEach then
            BL.ForEach("crossbow_bolt", update)
        else
            for _, ent in ipairs(ents.FindByClass("crossbow_bolt")) do update(ent) end
        end
    end)
end
