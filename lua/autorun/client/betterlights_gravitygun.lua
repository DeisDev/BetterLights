-- BetterLights: Gravity Gun (physcannon) warm orange light
-- Client-side only

if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
    -- Localize frequently used globals
    local CurTime = CurTime
    local IsValid = IsValid
    local GetConVar = GetConVar
    -- Note: DynamicLight is NOT localized to ensure compatibility with wrappers like GShader Library
    local cvar_enable = CreateClientConVar("betterlights_gravitygun_enable", "1", true, false, "Enable dynamic light for the gravity gun (physcannon)")
    local cvar_size = CreateClientConVar("betterlights_gravitygun_size", "36", true, false, "Dynamic light radius for the gravity gun")
    local cvar_brightness = CreateClientConVar("betterlights_gravitygun_brightness", "0.35", true, false, "Dynamic light brightness for the gravity gun")
    local cvar_decay = CreateClientConVar("betterlights_gravitygun_decay", "2000", true, false, "Dynamic light decay for the gravity gun")
    local cvar_models_elight = CreateClientConVar("betterlights_gravitygun_models_elight", "1", true, false, "Also add an entity light (elight) to light the gravity gun model directly")
    local cvar_models_elight_size_mult = CreateClientConVar("betterlights_gravitygun_models_elight_size_mult", "1.0", true, false, "Multiplier for gravity gun elight radius")

    -- Color configuration
    local cvar_col_r = CreateClientConVar("betterlights_gravitygun_color_r", "255", true, false, "Gravity gun color - red (0-255)")
    local cvar_col_g = CreateClientConVar("betterlights_gravitygun_color_g", "140", true, false, "Gravity gun color - green (0-255)")
    local cvar_col_b = CreateClientConVar("betterlights_gravitygun_color_b", "40", true, false, "Gravity gun color - blue (0-255)")
    local cvar_super_col_r = CreateClientConVar("betterlights_gravitygun_super_color_r", "40", true, false, "Supercharged gravity gun color - red (0-255)")
    local cvar_super_col_g = CreateClientConVar("betterlights_gravitygun_super_color_g", "140", true, false, "Supercharged gravity gun color - green (0-255)")
    local cvar_super_col_b = CreateClientConVar("betterlights_gravitygun_super_color_b", "255", true, false, "Supercharged gravity gun color - blue (0-255)")

    local ATTACH_NAMES = { "muzzle", "core", "fork", "claw", "muzzle_flash" }
    local function getGravgunLightPos(ply, wep)
        -- Prefer viewmodel attachments in first person, then worldmodel attachments
        if IsValid(ply) and ply == LocalPlayer() then
            local vm = ply:GetViewModel()
            if IsValid(vm) then
                local pos = BL.GetAttachmentPos and BL.GetAttachmentPos(vm, ATTACH_NAMES)
                if pos then return pos end
            end
        end

        if IsValid(wep) then
            local pos = BL.GetAttachmentPos and BL.GetAttachmentPos(wep, ATTACH_NAMES)
            if pos then return pos end
            if wep.WorldSpaceCenter then return wep:WorldSpaceCenter() end
        end

        if IsValid(ply) and ply.EyePos then
            return ply:EyePos() + (ply.EyeAngles and ply:EyeAngles():Forward() * 16 or Vector(16, 0, 0))
        end

        return IsValid(wep) and wep:GetPos() or Vector(0, 0, 0)
    end

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
        if IsValid(ply) and ply.GetNWBool then
            if ply:GetNWBool("IsSuperGravityGun") or ply:GetNWBool("SuperGravityGun") or ply:GetNWBool("HasSuperGravityGun") or ply:GetNWBool("super_gravity_gun") then return true end
        end
        if IsValid(ply) and ply.GetNW2Bool then
            if ply:GetNW2Bool("IsSuperGravityGun") or ply:GetNW2Bool("SuperGravityGun") or ply:GetNW2Bool("HasSuperGravityGun") or ply:GetNW2Bool("super_gravity_gun") then return true end
        end
        if wep.GetSkin and wep:GetSkin() == 1 then return true end
        if IsValid(ply) then
            local vm = ply:GetViewModel()
            if IsValid(vm) and vm.GetSkin and vm:GetSkin() == 1 then return true end
        end
        return false
    end

    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_GravityGun_DLight", function()
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

        -- Model light position (for elight): use viewmodel/worldmodel attachments when possible
        local pos_model = getGravgunLightPos(ply, wep)

        -- World light position (for dlight): place just in front of nearby walls to avoid clipping into geometry
        local eye = ply:EyePos()
        local fwd = ply:EyeAngles():Forward()
        local tr = (BetterLights.TraceLineReuse and BetterLights.TraceLineReuse("gravgun", {
            start = eye,
            endpos = eye + fwd * 48,
            filter = { ply, wep }
        })) or util.TraceLine({ start = eye, endpos = eye + fwd * 48, filter = { ply, wep } })
        local pos_world = tr.Hit and (tr.HitPos + tr.HitNormal * 6) or (eye + fwd * 24)

        -- Fallback if model pos failed
        if not pos_model then pos_model = pos_world end

        -- Use a stable index separate from other features (offset from player index)
        local idx = ply:EntIndex() + 1460

        -- DLight (world/model)
        local d = DynamicLight(idx)
        if d then
            d.pos = pos_world
            d.r = r
            d.g = g
            d.b = b
            d.brightness = brightness
            d.decay = decay
            d.size = size
            d.minlight = 0
            d.noworld = false
            d.nomodel = false
            d.dietime = CurTime() + 0.16
        end

        -- ELight (model-only)
        if doElight then
            local el = DynamicLight(idx, true)
            if el then
                el.pos = pos_model
                el.r = r
                el.g = g
                el.b = b
                el.brightness = brightness
                el.decay = decay
                el.size = size * elMult
                el.minlight = 0
                el.dietime = CurTime() + 0.16
            end
        end
    end)
end
