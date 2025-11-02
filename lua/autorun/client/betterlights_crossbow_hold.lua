-- BetterLights: Passive light when holding the Crossbow
-- Client-side only

if CLIENT then
    local cvar_enable = CreateClientConVar("betterlights_crossbow_hold_enable", "1", true, false, "Enable passive dynamic light while holding the Crossbow")
    local cvar_size = CreateClientConVar("betterlights_crossbow_hold_size", "30", true, false, "Dynamic light radius for held Crossbow")
    local cvar_brightness = CreateClientConVar("betterlights_crossbow_hold_brightness", "0.32", true, false, "Dynamic light brightness for held Crossbow")
    local cvar_decay = CreateClientConVar("betterlights_crossbow_hold_decay", "2000", true, false, "Dynamic light decay for held Crossbow")
    local cvar_require_loaded = CreateClientConVar("betterlights_crossbow_hold_require_loaded", "1", true, false, "Only emit light when a bolt is loaded (clip > 0)")

    local ORANGE = { r = 255, g = 140, b = 40 }

    local function getHeldCrossbowPos(ply, wep)
        -- Prefer viewmodel attachment when in first-person
        local vm = IsValid(ply) and ply:GetViewModel() or nil
        if IsValid(vm) then
            local idx = vm:LookupAttachment("muzzle") or 0
            if idx <= 0 then idx = 1 end
            local att = vm:GetAttachment(idx)
            if att and att.Pos then return att.Pos end
        end

        -- Fallback to world model attachment
        if IsValid(wep) then
            local idx = wep:LookupAttachment("muzzle") or 0
            if idx > 0 then
                local att = wep:GetAttachment(idx)
                if att and att.Pos then return att.Pos end
            end
            -- Fallback to weapon position
            if wep.WorldSpaceCenter then return wep:WorldSpaceCenter() end
            return wep:GetPos()
        end

        -- Final fallback: player view position slightly forward
        return LocalPlayer():EyePos() + LocalPlayer():EyeAngles():Forward() * 20
    end

    hook.Add("Think", "BetterLights_CrossbowHold_DLight", function()
        if not cvar_enable:GetBool() then return end

        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:Alive() then return end

        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "weapon_crossbow" then return end

        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())

        if cvar_require_loaded:GetBool() then
            -- Determine if the crossbow currently has a bolt loaded
            local loaded = false

            if wep.Clip1 then
                local clip = wep:Clip1()
                if isnumber(clip) then
                    loaded = clip > 0
                end
            end

            -- Fallback heuristic: if not reloading and weapon reports HasAmmo, assume loaded
            if not loaded then
                local inReload = false
                if wep.GetActivity then
                    local ok, act = pcall(wep.GetActivity, wep)
                    if ok and act ~= nil and _G.ACT_VM_RELOAD ~= nil then
                        inReload = (act == _G.ACT_VM_RELOAD)
                    end
                end
                if not inReload and wep.HasAmmo and wep:HasAmmo() then
                    loaded = true
                end
            end

            if not loaded then return end
        end

        -- Model light position (for elight-style model illumination in the future): attachments if possible
        local pos_model = getHeldCrossbowPos(ply, wep)

        -- World light (dlight) position: trace from EyePos so it doesn't clip into nearby walls
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

        local dlight = DynamicLight(ply:EntIndex() + 1337) -- offset to avoid collisions
        if dlight then
            dlight.pos = pos_world
            dlight.r = ORANGE.r
            dlight.g = ORANGE.g
            dlight.b = ORANGE.b
            dlight.brightness = brightness
            dlight.decay = decay
            dlight.size = size
            dlight.minlight = 0
            dlight.noworld = false
            dlight.nomodel = false
            dlight.dietime = CurTime() + 0.1
        end
    end)
end
