-- BetterLights: Dim red light for frag grenades
-- Client-side only

if CLIENT then
    local cvar_enable = CreateClientConVar("betterlights_grenade_enable", "1", true, false, "Enable dim red light on frag grenades (npc_grenade_frag)")
    local cvar_size = CreateClientConVar("betterlights_grenade_size", "80", true, false, "Dynamic light radius for frag grenades")
    local cvar_brightness = CreateClientConVar("betterlights_grenade_brightness", "0.9", true, false, "Dynamic light brightness for frag grenades")
    local cvar_decay = CreateClientConVar("betterlights_grenade_decay", "1800", true, false, "Dynamic light decay for frag grenades")
    local cvar_models_elight = CreateClientConVar("betterlights_grenade_models_elight", "1", true, false, "Also add an entity light (elight) to light the grenade model directly")
    local cvar_models_elight_size_mult = CreateClientConVar("betterlights_grenade_models_elight_size_mult", "1.0", true, false, "Multiplier for grenade elight radius")

    -- Color configuration
    local cvar_col_r = CreateClientConVar("betterlights_grenade_color_r", "255", true, false, "Frag grenade color - red (0-255)")
    local cvar_col_g = CreateClientConVar("betterlights_grenade_color_g", "40", true, false, "Frag grenade color - green (0-255)")
    local cvar_col_b = CreateClientConVar("betterlights_grenade_color_b", "40", true, false, "Frag grenade color - blue (0-255)")
    local function getColor()
        return math.Clamp(math.floor(cvar_col_r:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_col_g:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_col_b:GetFloat() + 0.5), 0, 255)
    end

    hook.Add("Think", "BetterLights_Grenade_DLight", function()
        if not cvar_enable:GetBool() then return end

        local grenades = ents.FindByClass("npc_grenade_frag")
        if not grenades or #grenades == 0 then return end

        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())

        for _, n in ipairs(grenades) do
            if IsValid(n) then
                -- Position at the grenade's center so it lights itself and nearby surfaces
                local pos
                if n.OBBCenter and n.LocalToWorld then
                    pos = n:LocalToWorld(n:OBBCenter())
                elseif n.WorldSpaceCenter then
                    pos = n:WorldSpaceCenter()
                else
                    pos = n:GetPos()
                end

                local idx = n:EntIndex()

                local d = DynamicLight(idx)
                if d then
                    d.pos = pos
                    local r, g, b = getColor()
                    d.r = r
                    d.g = g
                    d.b = b
                    d.brightness = brightness
                    d.decay = decay
                    d.size = size
                    d.minlight = 0
                    d.noworld = false
                    d.nomodel = false
                    d.dietime = CurTime() + 0.1
                end

                if cvar_models_elight:GetBool() then
                    local el = DynamicLight(idx, true) -- elight for models
                    if el then
                        el.pos = pos
                        local r, g, b = getColor()
                        el.r = r
                        el.g = g
                        el.b = b
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
