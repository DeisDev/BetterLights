if CLIENT then
    local BL = BetterLights
    local cvar_enable = BL.CreateClientConVar("betterlights_rpg_hold_enable", "1", true, false, "Enable subtle red lights on the RPG while held")
    local cvar_size = BL.CreateClientConVar("betterlights_rpg_hold_size", "24", true, false, "Dynamic light radius for held RPG lights")
    local cvar_brightness = BL.CreateClientConVar("betterlights_rpg_hold_brightness", "0.22", true, false, "Dynamic light brightness for held RPG lights")
    local cvar_decay = BL.CreateClientConVar("betterlights_rpg_hold_decay", "2000", true, false, "Dynamic light decay for held RPG lights")

    local cvar_col_r = BL.CreateClientConVar("betterlights_rpg_hold_color_r", "255", true, false, "RPG (Held) color - red (0-255)")
    local cvar_col_g = BL.CreateClientConVar("betterlights_rpg_hold_color_g", "60", true, false, "RPG (Held) color - green (0-255)")
    local cvar_col_b = BL.CreateClientConVar("betterlights_rpg_hold_color_b", "60", true, false, "RPG (Held) color - blue (0-255)")

    local ATTACH_NAMES = { "muzzle", "laser", "muzzle_flash" }

    local function getLeftHandPos(ply, wep)
        if not IsValid(ply) then return nil end

        if ply == LocalPlayer() then
            local vm = ply:GetViewModel()
            local pos = BL.GetBonePosition(vm, "ValveBiped.Bip01_L_Hand")
            if pos then return pos end
        end

        local pos = BL.GetBonePosition(ply, "ValveBiped.Bip01_L_Hand")
        if pos then return pos end

        return BL.GetHeldWeaponModelLightPos(ply, wep, ATTACH_NAMES, 16)
    end
    BL.AddThink("BetterLights_RPG_Held_DLight", function()
        if not cvar_enable:GetBool() then return end

        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        if not BL.IsPlayerHoldingWeapon("weapon_rpg") then return end

        local wep = ply:GetActiveWeapon()
        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())

        local r, g, b = BL.GetColorFromCvars(cvar_col_r, cvar_col_g, cvar_col_b)

        local pos_world = BL.GetHeldWeaponTraceLightPos(ply, wep, "rpg_hold", 8192, 1024)
        local idx = ply:EntIndex() + 1520

        BL.CreateDLight(idx, pos_world, r, g, b, brightness, decay, size, false)

        local pos_hand = getLeftHandPos(ply, wep)
        if pos_hand then
            BL.CreateDLight(idx + 1, pos_hand, r, g, b, brightness, decay, size, false)
        end
    end)
end
