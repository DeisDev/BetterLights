-- BetterLights: Gravity Gun (physcannon) warm orange light
-- Client-side only

if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
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
    local function getColor()
        return math.Clamp(math.floor(cvar_col_r:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_col_g:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_col_b:GetFloat() + 0.5), 0, 255)
    end

    local function getGravgunLightPos(ply, wep)
        -- Prefer viewmodel attachments in first person, then worldmodel attachments
        if IsValid(ply) and ply == LocalPlayer() then
            local vm = ply:GetViewModel()
            if IsValid(vm) then
                local names = { "muzzle", "core", "fork", "claw", "muzzle_flash" }
                for _, name in ipairs(names) do
                    local id = vm:LookupAttachment(name)
                    if id and id > 0 then
                        local att = vm:GetAttachment(id)
                        if att and att.Pos then return att.Pos end
                    end
                end
            end
        end

        if IsValid(wep) then
            local names = { "muzzle", "core", "fork", "claw", "muzzle_flash" }
            for _, name in ipairs(names) do
                local id = wep.LookupAttachment and wep:LookupAttachment(name)
                if id and id > 0 then
                    local att = wep.GetAttachment and wep:GetAttachment(id)
                    if att and att.Pos then return att.Pos end
                end
            end
            if wep.WorldSpaceCenter then return wep:WorldSpaceCenter() end
        end

        if IsValid(ply) and ply.EyePos then
            return ply:EyePos() + (ply.EyeAngles and ply:EyeAngles():Forward() * 16 or Vector(16, 0, 0))
        end

        return IsValid(wep) and wep:GetPos() or Vector(0, 0, 0)
    end

    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_GravityGun_DLight", function()
        if not cvar_enable:GetBool() then return end

        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "weapon_physcannon" then return end

        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())

        -- Model light position (for elight): use viewmodel/worldmodel attachments when possible
        local pos_model = getGravgunLightPos(ply, wep)

        -- World light position (for dlight): place just in front of nearby walls to avoid clipping into geometry
        local eye = ply:EyePos()
        local fwd = ply:EyeAngles():Forward()
        local tr = util.TraceLine({
            start = eye,
            endpos = eye + fwd * 48,
            filter = { ply, wep }
        })
        local pos_world = tr.Hit and (tr.HitPos + tr.HitNormal * 6) or (eye + fwd * 24)

        -- Fallback if model pos failed
        if not pos_model then pos_model = pos_world end

        -- Use a stable index separate from other features (offset from player index)
        local idx = ply:EntIndex() + 1460

        local d = DynamicLight(idx)
        if d then
            d.pos = pos_world
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
            local el = DynamicLight(idx, true)
            if el then
                el.pos = pos_model
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
    end)
end
