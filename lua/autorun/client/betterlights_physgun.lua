if CLIENT then
    local BL = BetterLights
    local IsValid = IsValid
    -- Note: DynamicLight is NOT localized to ensure compatibility with wrappers like GShader Library
    local cvar_enable = BL.CreateClientConVar("betterlights_physgun_enable", "1", true, false, "Enable dynamic light for the physgun matching your weapon color")
    local cvar_size = BL.CreateClientConVar("betterlights_physgun_size", "33", true, false, "Dynamic light radius for the physgun")
    local cvar_brightness = BL.CreateClientConVar("betterlights_physgun_brightness", "0.3", true, false, "Dynamic light brightness for the physgun")
    local cvar_decay = BL.CreateClientConVar("betterlights_physgun_decay", "2000", true, false, "Dynamic light decay for the physgun")
    local cvar_models_elight = BL.CreateClientConVar("betterlights_physgun_models_elight", "1", true, false, "Also add an entity light (elight) to light the physgun model directly")
    local cvar_models_elight_size_mult = BL.CreateClientConVar("betterlights_physgun_models_elight_size_mult", "1.0", true, false, "Multiplier for physgun elight radius")

    local cvar_col_override = BL.CreateClientConVar("betterlights_physgun_color_override", "0", true, false, "Override physgun color instead of using Weapon Color")
    local cvar_col_r = BL.CreateClientConVar("betterlights_physgun_color_r", "70", true, false, "Physgun override color - red (0-255)")
    local cvar_col_g = BL.CreateClientConVar("betterlights_physgun_color_g", "130", true, false, "Physgun override color - green (0-255)")
    local cvar_col_b = BL.CreateClientConVar("betterlights_physgun_color_b", "255", true, false, "Physgun override color - blue (0-255)")

    local ATTACH_NAMES = { "muzzle", "fork", "muzzle_flash", "laser" }
    BL.AddThink("BetterLights_Physgun_DLight", function()
        if not cvar_enable:GetBool() then return end

        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        if not BL.IsPlayerHoldingWeapon("weapon_physgun") then return end

        local wep = ply:GetActiveWeapon()

        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())
        local doElight = cvar_models_elight:GetBool()
        local elMult = math.max(0, cvar_models_elight_size_mult:GetFloat())

        local r, g, b
        if cvar_col_override:GetBool() then
            r, g, b = BL.GetColorFromCvars(cvar_col_r, cvar_col_g, cvar_col_b)
        else
            local v = ply.GetWeaponColor and ply:GetWeaponColor()
            if v then
                r = math.floor(math.Clamp(v.x or v.X or 0, 0, 1) * 255)
                g = math.floor(math.Clamp(v.y or v.Y or 0, 0, 1) * 255)
                b = math.floor(math.Clamp(v.z or v.Z or 0, 0, 1) * 255)
            else
                r, g, b = 70, 130, 255
            end
        end

        local pos_world, pos_model = BL.GetHeldWeaponLightPositions(ply, wep, ATTACH_NAMES, "physgun", 48, 24, 16)
        local idx = ply:EntIndex() + 1440

        BL.CreateDLight(idx, pos_world, r, g, b, brightness, decay, size, false, { dietime = 0.16 })

        if doElight then
            BL.CreateDLight(idx, pos_model, r, g, b, brightness, decay, size * elMult, true, { dietime = 0.16 })
        end
    end)
end
