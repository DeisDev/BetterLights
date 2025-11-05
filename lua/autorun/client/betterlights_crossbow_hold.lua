-- BetterLights: Passive light when holding the Crossbow
-- Client-side only

if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
    local cvar_enable = CreateClientConVar("betterlights_crossbow_hold_enable", "1", true, false, "Enable passive dynamic light while holding the Crossbow")
    local cvar_size = CreateClientConVar("betterlights_crossbow_hold_size", "30", true, false, "Dynamic light radius for held Crossbow")
    local cvar_brightness = CreateClientConVar("betterlights_crossbow_hold_brightness", "0.32", true, false, "Dynamic light brightness for held Crossbow")
    local cvar_decay = CreateClientConVar("betterlights_crossbow_hold_decay", "2000", true, false, "Dynamic light decay for held Crossbow")
    local cvar_require_loaded = CreateClientConVar("betterlights_crossbow_hold_require_loaded", "1", true, false, "Only emit light when a bolt is loaded (clip > 0)")

    -- Color configuration
    local cvar_col_r = CreateClientConVar("betterlights_crossbow_hold_color_r", "255", true, false, "Crossbow (held) color - red (0-255)")
    local cvar_col_g = CreateClientConVar("betterlights_crossbow_hold_color_g", "140", true, false, "Crossbow (held) color - green (0-255)")
    local cvar_col_b = CreateClientConVar("betterlights_crossbow_hold_color_b", "40", true, false, "Crossbow (held) color - blue (0-255)")

    local ATTACH_NAMES = { "muzzle", "bolt", "tip", "flash", "spark" }
    local function getHeldCrossbowPos(ply, wep)
        -- Prefer viewmodel attachment when in first-person
        if IsValid(ply) and ply == LocalPlayer() then
            local vm = ply:GetViewModel()
            if IsValid(vm) then
                local pos = BetterLights.GetAttachmentPos and BetterLights:GetAttachmentPos(vm, ATTACH_NAMES)
                if pos then return pos end
            end
        end

        -- Fallback to world model attachment
        if IsValid(wep) then
            local pos = BetterLights.GetAttachmentPos and BetterLights:GetAttachmentPos(wep, ATTACH_NAMES)
            if pos then return pos end
            -- Fallback to weapon position
            if wep.WorldSpaceCenter then return wep:WorldSpaceCenter() end
            return wep:GetPos()
        end

        -- Final fallback: player view position slightly forward
        return ply:EyePos() + (ply.EyeAngles and ply:EyeAngles():Forward() * 20 or Vector(20, 0, 0))
    end

    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_CrossbowHold_DLight", function()
        if not cvar_enable:GetBool() then return end

        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:Alive() then return end
        if not BL.IsPlayerHoldingWeapon("weapon_crossbow") then return end

        local wep = ply:GetActiveWeapon()
        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())

        -- Cache color once per frame
        local r, g, b = BL.GetColorFromCvars(cvar_col_r, cvar_col_g, cvar_col_b)

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
        local tr = (BetterLights.TraceLineReuse and BetterLights.TraceLineReuse("xbow_hold", {
            start = eye,
            endpos = eye + fwd * 48,
            filter = { ply, wep }
        })) or util.TraceLine({ start = eye, endpos = eye + fwd * 48, filter = { ply, wep } })
        local pos_world = tr.Hit and (tr.HitPos + tr.HitNormal * 6) or (eye + fwd * 24)

        -- Fallback if model pos failed
        if not pos_model then pos_model = pos_world end

        local dlight = DynamicLight(ply:EntIndex() + 1337) -- offset to avoid collisions
        if dlight then
            dlight.pos = pos_world
            dlight.r = r
            dlight.g = g
            dlight.b = b
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
