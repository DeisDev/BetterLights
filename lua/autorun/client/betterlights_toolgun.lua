if CLIENT then
    local BL = BetterLights
    local IsValid = IsValid
    -- Note: DynamicLight is NOT localized to ensure compatibility with wrappers like GShader Library
    local cvar_enable = BL.CreateClientConVar("betterlights_toolgun_enable", "1", true, false, "Enable small white dynamic light for the Tool Gun (gmod_tool)")
    local cvar_size = BL.CreateClientConVar("betterlights_toolgun_size", "28", true, false, "Dynamic light radius for the Tool Gun")
    local cvar_brightness = BL.CreateClientConVar("betterlights_toolgun_brightness", "0.225", true, false, "Dynamic light brightness for the Tool Gun")
    local cvar_decay = BL.CreateClientConVar("betterlights_toolgun_decay", "2000", true, false, "Dynamic light decay for the Tool Gun")
    local cvar_models_elight = BL.CreateClientConVar("betterlights_toolgun_models_elight", "1", true, false, "Also add an entity light (elight) to light the Tool Gun model directly")
    local cvar_models_elight_size_mult = BL.CreateClientConVar("betterlights_toolgun_models_elight_size_mult", "1.0", true, false, "Multiplier for Tool Gun elight radius")

    local cvar_col_r = BL.CreateClientConVar("betterlights_toolgun_color_r", "255", true, false, "Tool Gun color - red (0-255)")
    local cvar_col_g = BL.CreateClientConVar("betterlights_toolgun_color_g", "255", true, false, "Tool Gun color - green (0-255)")
    local cvar_col_b = BL.CreateClientConVar("betterlights_toolgun_color_b", "255", true, false, "Tool Gun color - blue (0-255)")

    local PLACEMENT = {
        view = { "muzzle" },
        world = { "muzzle" }
    }
    local SURFACE_LIGHT = { key = "toolgun", distance = 48, missDistance = 24, hitOffset = 6, dietime = 0.16 }

    BL.AddThink("BetterLights_ToolGun_DLight", function()
        if not cvar_enable:GetBool() then return end

        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        if not BL.IsPlayerHoldingWeapon("gmod_tool") then return end

        local wep = ply:GetActiveWeapon()

        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())
        local doElight = cvar_models_elight:GetBool()
        local elMult = math.max(0, cvar_models_elight_size_mult:GetFloat())

        local r, g, b = BL.GetColorFromCvars(cvar_col_r, cvar_col_g, cvar_col_b)

        local idx = ply:EntIndex() + 1480

        local created = BL.CreateHeldWeaponSurfaceLight(ply, wep, SURFACE_LIGHT, idx, r, g, b, brightness, decay, size, false)
        if not created then return end

        if doElight then
            BL.CreateHeldWeaponAttachmentLight(ply, wep, PLACEMENT, idx, r, g, b, brightness, decay, size * elMult, true, { dietime = 0.16 })
        end
    end)
end
