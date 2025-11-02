-- BetterLights: Tool Gun (gmod_tool) small white light
-- Client-side only

if CLIENT then
    local cvar_enable = CreateClientConVar("betterlights_toolgun_enable", "1", true, false, "Enable small white dynamic light for the Tool Gun (gmod_tool)")
    local cvar_size = CreateClientConVar("betterlights_toolgun_size", "28", true, false, "Dynamic light radius for the Tool Gun")
    local cvar_brightness = CreateClientConVar("betterlights_toolgun_brightness", "0.225", true, false, "Dynamic light brightness for the Tool Gun")
    local cvar_decay = CreateClientConVar("betterlights_toolgun_decay", "2000", true, false, "Dynamic light decay for the Tool Gun")
    local cvar_models_elight = CreateClientConVar("betterlights_toolgun_models_elight", "1", true, false, "Also add an entity light (elight) to light the Tool Gun model directly")
    local cvar_models_elight_size_mult = CreateClientConVar("betterlights_toolgun_models_elight_size_mult", "1.0", true, false, "Multiplier for Tool Gun elight radius")

    local function getToolgunLightPos(ply, wep)
        -- Prefer viewmodel attachments for first person, then worldmodel attachments
        if IsValid(ply) and ply == LocalPlayer() then
            local vm = ply:GetViewModel()
            if IsValid(vm) then
                local names = { "muzzle", "spark", "laser", "muzzle_flash", "tip" }
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
            local names = { "muzzle", "spark", "laser", "muzzle_flash", "tip" }
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

    hook.Add("Think", "BetterLights_ToolGun_DLight", function()
        if not cvar_enable:GetBool() then return end

        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "gmod_tool" then return end

        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())

        -- Model light position (for elight): use attachments if possible
        local pos_model = getToolgunLightPos(ply, wep)

        -- World light (dlight): trace toward the look direction so it stays just off nearby walls
        local eye = ply:EyePos()
        local fwd = ply:EyeAngles():Forward()
        local tr = util.TraceLine({
            start = eye,
            endpos = eye + fwd * 48,
            filter = { ply, wep }
        })
        local pos_world = tr.Hit and (tr.HitPos + tr.HitNormal * 6) or (eye + fwd * 24)

        if not pos_model then pos_model = pos_world end

        -- Use a stable index separate from other features (offset from player index)
        local idx = ply:EntIndex() + 1480

        -- White light
        local r, g, b = 255, 255, 255

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
