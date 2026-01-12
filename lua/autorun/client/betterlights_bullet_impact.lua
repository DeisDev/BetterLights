-- BetterLights: Bullet impact flashes via server-driven net event
-- Client-only receiver; server gathers hits and broadcasts them.

if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
    
    -- Client config
    local cvar_enable = CreateClientConVar("betterlights_bullet_impact_enable", "1", true, false, "Enable subtle dynamic light on bullet impacts")
    local cvar_size = CreateClientConVar("betterlights_bullet_impact_size", "60", true, false, "Dynamic light radius for generic bullet impacts")
    local cvar_brightness = CreateClientConVar("betterlights_bullet_impact_brightness", "0.25", true, false, "Dynamic light brightness for generic bullet impacts")

    local cvar_ar2_enable = CreateClientConVar("betterlights_bullet_impact_ar2_enable", "1", true, false, "Enable special color for AR2 bullet impacts")
    local cvar_ar2_size = CreateClientConVar("betterlights_bullet_impact_ar2_size", "70", true, false, "Dynamic light radius for AR2 bullet impacts")
    local cvar_ar2_brightness = CreateClientConVar("betterlights_bullet_impact_ar2_brightness", "0.3", true, false, "Dynamic light brightness for AR2 bullet impacts")

    -- Color configuration
    local cvar_col_r = CreateClientConVar("betterlights_bullet_impact_color_r", "255", true, false, "Generic bullet impact color - red (0-255)")
    local cvar_col_g = CreateClientConVar("betterlights_bullet_impact_color_g", "160", true, false, "Generic bullet impact color - green (0-255)")
    local cvar_col_b = CreateClientConVar("betterlights_bullet_impact_color_b", "60", true, false, "Generic bullet impact color - blue (0-255)")
    local cvar_ar2_col_r = CreateClientConVar("betterlights_bullet_impact_ar2_color_r", "110", true, false, "AR2 bullet impact color - red (0-255)")
    local cvar_ar2_col_g = CreateClientConVar("betterlights_bullet_impact_ar2_color_g", "190", true, false, "AR2 bullet impact color - green (0-255)")
    local cvar_ar2_col_b = CreateClientConVar("betterlights_bullet_impact_ar2_color_b", "255", true, false, "AR2 bullet impact color - blue (0-255)")

    -- Register network handler for bullet impacts
    BL.AddNetworkHandler(BL.NET_BULLET_IMPACT, function()
        if not cvar_enable:GetBool() then return end
        local pos = net.ReadVector()
        local isAR2 = net.ReadBool()

        local duration = 0.14
        if isAR2 and cvar_ar2_enable:GetBool() then
            local r, g, b = BL.GetColorFromCvars(cvar_ar2_col_r, cvar_ar2_col_g, cvar_ar2_col_b)
            local size = cvar_ar2_size:GetFloat()
            local brightness = cvar_ar2_brightness:GetFloat()
            BL.CreateFlash(pos, r, g, b, size, brightness, duration, 60000)
        else
            local r, g, b = BL.GetColorFromCvars(cvar_col_r, cvar_col_g, cvar_col_b)
            local size = cvar_size:GetFloat()
            local brightness = cvar_brightness:GetFloat()
            BL.CreateFlash(pos, r, g, b, size, brightness, duration, 60000)
        end
    end)
end
