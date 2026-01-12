-- BetterLights: Muzzle Flash (client)
-- Spawns a brief DynamicLight at the muzzle when a weapon fires.

if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
    
    local cvar_enable = CreateClientConVar("betterlights_muzzle_enable", "1", true, false, "Enable muzzle flash light on firing")
    local cvar_size = CreateClientConVar("betterlights_muzzle_size", "250", true, false, "Muzzle flash radius")
    local cvar_brightness = CreateClientConVar("betterlights_muzzle_brightness", "2.00", true, false, "Muzzle flash brightness")

    local cvar_ar2_enable = CreateClientConVar("betterlights_muzzle_ar2_enable", "1", true, false, "Use blue tint for AR2 muzzle flashes")
    local cvar_ar2_size = CreateClientConVar("betterlights_muzzle_ar2_size", "250", true, false, "AR2 muzzle flash radius")
    local cvar_ar2_brightness = CreateClientConVar("betterlights_muzzle_ar2_brightness", "2.0", true, false, "AR2 muzzle flash brightness")

    -- Color configuration
    local cvar_col_r = CreateClientConVar("betterlights_muzzle_color_r", "255", true, false, "Generic muzzle flash color - red (0-255)")
    local cvar_col_g = CreateClientConVar("betterlights_muzzle_color_g", "170", true, false, "Generic muzzle flash color - green (0-255)")
    local cvar_col_b = CreateClientConVar("betterlights_muzzle_color_b", "90", true, false, "Generic muzzle flash color - blue (0-255)")
    local cvar_ar2_col_r = CreateClientConVar("betterlights_muzzle_ar2_color_r", "110", true, false, "AR2 muzzle flash color - red (0-255)")
    local cvar_ar2_col_g = CreateClientConVar("betterlights_muzzle_ar2_color_g", "190", true, false, "AR2 muzzle flash color - green (0-255)")
    local cvar_ar2_col_b = CreateClientConVar("betterlights_muzzle_ar2_color_b", "255", true, false, "AR2 muzzle flash color - blue (0-255)")

    -- Register network handler for muzzle flashes
    BL.AddNetworkHandler(BL.NET_MUZZLE_FLASH, function()
        if not cvar_enable:GetBool() then return end
        local pos = net.ReadVector()
        local isAR2 = net.ReadBool()

        local duration = 0.08
        if isAR2 and cvar_ar2_enable:GetBool() then
            local r, g, b = BL.GetColorFromCvars(cvar_ar2_col_r, cvar_ar2_col_g, cvar_ar2_col_b)
            local size = cvar_ar2_size:GetFloat()
            local brightness = cvar_ar2_brightness:GetFloat()
            BL.CreateFlash(pos, r, g, b, size, brightness, duration, 61000)
        else
            local r, g, b = BL.GetColorFromCvars(cvar_col_r, cvar_col_g, cvar_col_b)
            local size = cvar_size:GetFloat()
            local brightness = cvar_brightness:GetFloat()
            BL.CreateFlash(pos, r, g, b, size, brightness, duration, 61000)
        end
    end)
end
