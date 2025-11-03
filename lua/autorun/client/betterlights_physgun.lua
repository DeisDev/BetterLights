-- BetterLights: Physgun light matching player's weapon (physgun) color
-- Client-side only

if CLIENT then
    local cvar_enable = CreateClientConVar("betterlights_physgun_enable", "1", true, false, "Enable dynamic light for the physgun matching your weapon color")
    local cvar_size = CreateClientConVar("betterlights_physgun_size", "33", true, false, "Dynamic light radius for the physgun")
    local cvar_brightness = CreateClientConVar("betterlights_physgun_brightness", "0.3", true, false, "Dynamic light brightness for the physgun")
    local cvar_decay = CreateClientConVar("betterlights_physgun_decay", "2000", true, false, "Dynamic light decay for the physgun")
    local cvar_models_elight = CreateClientConVar("betterlights_physgun_models_elight", "1", true, false, "Also add an entity light (elight) to light the physgun model directly")
    local cvar_models_elight_size_mult = CreateClientConVar("betterlights_physgun_models_elight_size_mult", "1.0", true, false, "Multiplier for physgun elight radius")

    -- Optional color override (defaults to weapon color)
    local cvar_col_override = CreateClientConVar("betterlights_physgun_color_override", "0", true, false, "Override physgun color instead of using Weapon Color")
    local cvar_col_r = CreateClientConVar("betterlights_physgun_color_r", "70", true, false, "Physgun override color - red (0-255)")
    local cvar_col_g = CreateClientConVar("betterlights_physgun_color_g", "130", true, false, "Physgun override color - green (0-255)")
    local cvar_col_b = CreateClientConVar("betterlights_physgun_color_b", "255", true, false, "Physgun override color - blue (0-255)")

    local function getPhysgunColorRGB()
        if cvar_col_override:GetBool() then
            local r = math.Clamp(math.floor(cvar_col_r:GetFloat() + 0.5), 0, 255)
            local g = math.Clamp(math.floor(cvar_col_g:GetFloat() + 0.5), 0, 255)
            local b = math.Clamp(math.floor(cvar_col_b:GetFloat() + 0.5), 0, 255)
            return r, g, b
        end
        local ply = LocalPlayer()
        if not IsValid(ply) then return 70, 130, 255 end -- fallback cyan-ish
        local v = ply.GetWeaponColor and ply:GetWeaponColor()
        if not v then return 70, 130, 255 end
        -- Clamp to [0,1] and convert to 0-255
        local r = math.Clamp(v.x or v.X or 0, 0, 1) * 255
        local g = math.Clamp(v.y or v.Y or 0, 0, 1) * 255
        local b = math.Clamp(v.z or v.Z or 0, 0, 1) * 255
        -- Ensure minimum visibility
        return math.floor(r), math.floor(g), math.floor(b)
    end

    local function getPhysgunLightPos(ply, wep)
        -- Try viewmodel muzzle in first person, then worldmodel attachments, then fallbacks
        if IsValid(ply) and ply == LocalPlayer() then
            local vm = ply:GetViewModel()
            if IsValid(vm) then
                local names = { "muzzle", "fork", "muzzle_flash", "laser" }
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
            local names = { "muzzle", "fork", "muzzle_flash", "laser" }
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

    hook.Add("Think", "BetterLights_Physgun_DLight", function()
        if not cvar_enable:GetBool() then return end

        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "weapon_physgun" then return end

        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())

        -- Model light position (for elight): use viewmodel/worldmodel attachments when possible
        local pos_model = getPhysgunLightPos(ply, wep)
        
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
        local r, g, b = getPhysgunColorRGB()

        -- Use a stable index separate from other features (offset from player index)
        local idx = ply:EntIndex() + 1440

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
            d.dietime = CurTime() + 0.1
        end

        if cvar_models_elight:GetBool() then
            local el = DynamicLight(idx, true)
            if el then
                el.pos = pos_model
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
