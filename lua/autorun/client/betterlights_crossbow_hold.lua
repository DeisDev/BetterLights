if CLIENT then
    local BL = BetterLights
    local cvar_enable = BL.CreateClientConVar("betterlights_crossbow_hold_enable", "1", true, false, "Enable passive dynamic light while holding the Crossbow")
    local cvar_size = BL.CreateClientConVar("betterlights_crossbow_hold_size", "30", true, false, "Dynamic light radius for held Crossbow")
    local cvar_brightness = BL.CreateClientConVar("betterlights_crossbow_hold_brightness", "0.32", true, false, "Dynamic light brightness for held Crossbow")
    local cvar_decay = BL.CreateClientConVar("betterlights_crossbow_hold_decay", "2000", true, false, "Dynamic light decay for held Crossbow")
    local cvar_require_loaded = BL.CreateClientConVar("betterlights_crossbow_hold_require_loaded", "1", true, false, "Only emit light when a bolt is loaded (clip > 0)")

    local cvar_col_r = BL.CreateClientConVar("betterlights_crossbow_hold_color_r", "255", true, false, "Crossbow (held) color - red (0-255)")
    local cvar_col_g = BL.CreateClientConVar("betterlights_crossbow_hold_color_g", "140", true, false, "Crossbow (held) color - green (0-255)")
    local cvar_col_b = BL.CreateClientConVar("betterlights_crossbow_hold_color_b", "40", true, false, "Crossbow (held) color - blue (0-255)")

    local SURFACE_LIGHT = { key = "xbow_hold", distance = 48, missDistance = 24, hitOffset = 6 }
    local CLIP_INTERNAL_VARIABLE = "m_iClip1"

    local function isCrossbowLoaded(weapon)
        if not (IsValid(weapon) and weapon.GetInternalVariable) then return false end

        local clip = weapon:GetInternalVariable(CLIP_INTERNAL_VARIABLE)
        return isnumber(clip) and clip > 0
    end

    BL.AddThink("BetterLights_CrossbowHold_DLight", function()
        if not cvar_enable:GetBool() then return end

        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:Alive() then return end
        if not BL.IsPlayerHoldingWeapon("weapon_crossbow") then return end

        local wep = ply:GetActiveWeapon()
        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())

        local r, g, b = BL.GetColorFromCvars(cvar_col_r, cvar_col_g, cvar_col_b)

        if cvar_require_loaded:GetBool() and not isCrossbowLoaded(wep) then return end

        BL.CreateHeldWeaponSurfaceLight(ply, wep, SURFACE_LIGHT, ply:EntIndex() + 1337, r, g, b, brightness, decay, size, false)
    end)
end
