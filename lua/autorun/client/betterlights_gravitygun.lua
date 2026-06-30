if CLIENT then
    local BL = BetterLights
    local IsValid = IsValid
    local GetConVar = GetConVar
    -- Note: DynamicLight is NOT localized to ensure compatibility with wrappers like GShader Library
    local cvar_enable = BL.CreateClientConVar("betterlights_gravitygun_enable", "1", true, false, "Enable dynamic light for the gravity gun (physcannon)")
    local cvar_size = BL.CreateClientConVar("betterlights_gravitygun_size", "36", true, false, "Dynamic light radius for the gravity gun")
    local cvar_brightness = BL.CreateClientConVar("betterlights_gravitygun_brightness", "0.35", true, false, "Dynamic light brightness for the gravity gun")
    local cvar_decay = BL.CreateClientConVar("betterlights_gravitygun_decay", "2000", true, false, "Dynamic light decay for the gravity gun")
    local cvar_models_elight = BL.CreateClientConVar("betterlights_gravitygun_models_elight", "1", true, false, "Also add an entity light (elight) to light the gravity gun model directly")
    local cvar_models_elight_size_mult = BL.CreateClientConVar("betterlights_gravitygun_models_elight_size_mult", "1.0", true, false, "Multiplier for gravity gun elight radius")

    local cvar_col_r = BL.CreateClientConVar("betterlights_gravitygun_color_r", "255", true, false, "Gravity gun color - red (0-255)")
    local cvar_col_g = BL.CreateClientConVar("betterlights_gravitygun_color_g", "140", true, false, "Gravity gun color - green (0-255)")
    local cvar_col_b = BL.CreateClientConVar("betterlights_gravitygun_color_b", "40", true, false, "Gravity gun color - blue (0-255)")
    local cvar_super_col_r = BL.CreateClientConVar("betterlights_gravitygun_super_color_r", "40", true, false, "Supercharged gravity gun color - red (0-255)")
    local cvar_super_col_g = BL.CreateClientConVar("betterlights_gravitygun_super_color_g", "140", true, false, "Supercharged gravity gun color - green (0-255)")
    local cvar_super_col_b = BL.CreateClientConVar("betterlights_gravitygun_super_color_b", "255", true, false, "Supercharged gravity gun color - blue (0-255)")

    local PLACEMENT = {
        view = { "muzzle" },
        world = { "muzzle" }
    }
    local SURFACE_LIGHT = { key = "gravgun", distance = 48, missDistance = 24, hitOffset = 6, dietime = 0.16 }

    local function isSuperCharged(ply, wep)
        if not IsValid(wep) then return false end
        local megaConvar = GetConVar and (GetConVar("physcannon_mega_enabled") or GetConVar("physcannon_mega"))
        if megaConvar and megaConvar:GetBool() then return true end
        if wep.IsSuperCharged and wep:IsSuperCharged() then return true end
        if wep.GetInternalVariable then
            local val = wep:GetInternalVariable("m_bIsSuperCharged")
            if val ~= nil and val ~= 0 then return true end
            val = wep:GetInternalVariable("m_bSuperCharged")
            if val ~= nil and val ~= 0 then return true end
        end
        if wep.GetNWBool and (wep:GetNWBool("IsSuperCharged") or wep:GetNWBool("SuperCharged") or wep:GetNWBool("supercharged")) then return true end
        if wep.GetNWInt and wep:GetNWInt("SuperCharged", 0) ~= 0 then return true end
        if wep.GetNW2Bool and (wep:GetNW2Bool("IsSuperCharged") or wep:GetNW2Bool("SuperCharged") or wep:GetNW2Bool("supercharged")) then return true end
        if IsValid(ply) and ply.GetNWBool and (ply:GetNWBool("IsSuperGravityGun") or ply:GetNWBool("SuperGravityGun") or ply:GetNWBool("HasSuperGravityGun") or ply:GetNWBool("super_gravity_gun")) then
            return true
        end
        if IsValid(ply) and ply.GetNW2Bool and (ply:GetNW2Bool("IsSuperGravityGun") or ply:GetNW2Bool("SuperGravityGun") or ply:GetNW2Bool("HasSuperGravityGun") or ply:GetNW2Bool("super_gravity_gun")) then
            return true
        end
        if wep.GetSkin and wep:GetSkin() == 1 then return true end
        if IsValid(ply) then
            local vm = ply:GetViewModel()
            if IsValid(vm) and vm.GetSkin and vm:GetSkin() == 1 then return true end
        end
        return false
    end
    BL.AddThink("BetterLights_GravityGun_DLight", function()
        if not cvar_enable:GetBool() then return end

        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        if not BL.IsPlayerHoldingWeapon("weapon_physcannon") then return end

        local wep = ply:GetActiveWeapon()

        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())
        local doElight = cvar_models_elight:GetBool()
        local elMult = math.max(0, cvar_models_elight_size_mult:GetFloat())

        local r, g, b
        if isSuperCharged(ply, wep) then
            r, g, b = BL.GetColorFromCvars(cvar_super_col_r, cvar_super_col_g, cvar_super_col_b)
        else
            r, g, b = BL.GetColorFromCvars(cvar_col_r, cvar_col_g, cvar_col_b)
        end

        local idx = ply:EntIndex() + 1460

        local created = BL.CreateHeldWeaponSurfaceLight(ply, wep, SURFACE_LIGHT, idx, r, g, b, brightness, decay, size, false)
        if not created then return end

        if doElight then
            BL.CreateHeldWeaponAttachmentLight(ply, wep, PLACEMENT, idx, r, g, b, brightness, decay, size * elMult, true, { dietime = 0.16 })
        end
    end)
end
