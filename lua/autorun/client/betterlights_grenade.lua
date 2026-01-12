-- BetterLights: Dim red light for frag grenades
-- Client-side only

if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
    -- Localize hot globals
    local IsValid = IsValid
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

    if BL.TrackClass then BL.TrackClass("npc_grenade_frag") end

    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_Grenade_DLight", function()
        if not cvar_enable:GetBool() then return end

        -- Cache ConVar values once per frame
        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())
        local r, g, b = BL.GetColorFromCvars(cvar_col_r, cvar_col_g, cvar_col_b)
        local doElight = cvar_models_elight:GetBool()
        local elMult = math.max(0, cvar_models_elight_size_mult:GetFloat())

        local function update(n)
            if not IsValid(n) then return end

            local pos = BL.GetEntityCenter(n)
            if not pos then return end

            local idx = n:EntIndex()

            -- Create world light
            BL.CreateDLight(idx, pos, r, g, b, brightness, decay, size, false)

            -- Create entity light if enabled
            if doElight then
                BL.CreateDLight(idx, pos, r, g, b, brightness, decay, size * elMult, true)
            end
        end

        if BL.ForEach then
            BL.ForEach("npc_grenade_frag", update)
        else
            for _, n in ipairs(ents.FindByClass("npc_grenade_frag")) do update(n) end
        end
    end)
end
