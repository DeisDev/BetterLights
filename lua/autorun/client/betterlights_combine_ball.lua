-- BetterLights: Combine AR2 orb dynamic lighting
-- Client-side only

if CLIENT then
    -- ConVars for tweaking
    local cvar_enable = CreateClientConVar("betterlights_combineball_enable", "1", true, false, "Enable dynamic light for Combine AR2 orb")
    local cvar_size = CreateClientConVar("betterlights_combineball_size", "320", true, false, "Dynamic light radius for Combine AR2 orb")
    local cvar_brightness = CreateClientConVar("betterlights_combineball_brightness", "2.5", true, false, "Dynamic light brightness for Combine AR2 orb")
    local cvar_decay = CreateClientConVar("betterlights_combineball_decay", "2000", true, false, "Dynamic light decay for Combine AR2 orb (higher = faster fade)")

    -- Color configuration
    local cvar_col_r = CreateClientConVar("betterlights_combineball_color_r", "80", true, false, "Combine ball color - red (0-255)")
    local cvar_col_g = CreateClientConVar("betterlights_combineball_color_g", "180", true, false, "Combine ball color - green (0-255)")
    local cvar_col_b = CreateClientConVar("betterlights_combineball_color_b", "255", true, false, "Combine ball color - blue (0-255)")
    local function getCombineBallColor()
        local r = math.Clamp(math.floor(cvar_col_r:GetFloat() + 0.5), 0, 255)
        local g = math.Clamp(math.floor(cvar_col_g:GetFloat() + 0.5), 0, 255)
        local b = math.Clamp(math.floor(cvar_col_b:GetFloat() + 0.5), 0, 255)
        return r, g, b
    end

    hook.Add("Think", "BetterLights_CombineBall_DLight", function()
        if not cvar_enable:GetBool() then return end

        -- Find all live combine balls; class name from HL2 is prop_combine_ball
        -- Use ipairs per ents.FindByClass guidance
        local balls = ents.FindByClass("prop_combine_ball")
        if balls == nil or #balls == 0 then return end

        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())

        for _, ent in ipairs(balls) do
            if IsValid(ent) then
                local dlight = DynamicLight(ent:EntIndex())
                if dlight then
                    local r, g, b = getCombineBallColor()
                    dlight.pos = ent:WorldSpaceCenter()
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
