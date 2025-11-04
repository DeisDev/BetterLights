-- BetterLights: RPG (Held) subtle red light at the laser dot (aim hit point)
-- Client-side only

if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
    local cvar_enable = CreateClientConVar("betterlights_rpg_hold_enable", "1", true, false, "Enable subtle red lights on the RPG while held")
    local cvar_size = CreateClientConVar("betterlights_rpg_hold_size", "24", true, false, "Dynamic light radius for held RPG lights")
    local cvar_brightness = CreateClientConVar("betterlights_rpg_hold_brightness", "0.22", true, false, "Dynamic light brightness for held RPG lights")
    local cvar_decay = CreateClientConVar("betterlights_rpg_hold_decay", "2000", true, false, "Dynamic light decay for held RPG lights")
    local cvar_update_hz = CreateClientConVar("betterlights_rpg_hold_update_hz", "30", true, false, "Update rate in Hz (15-120)")
    -- Elight removed per request; weapon/hand glow now uses a hand-attached world dlight

    -- Color configuration (subtle red)
    local cvar_col_r = CreateClientConVar("betterlights_rpg_hold_color_r", "255", true, false, "RPG (Held) color - red (0-255)")
    local cvar_col_g = CreateClientConVar("betterlights_rpg_hold_color_g", "60", true, false, "RPG (Held) color - green (0-255)")
    local cvar_col_b = CreateClientConVar("betterlights_rpg_hold_color_b", "60", true, false, "RPG (Held) color - blue (0-255)")
    local function getColor()
        return math.Clamp(math.floor(cvar_col_r:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_col_g:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_col_b:GetFloat() + 0.5), 0, 255)
    end

    local function getRPGModelLightPos(ply, wep)
        -- Prefer viewmodel attachments for first person, then worldmodel
        if IsValid(ply) and ply == LocalPlayer() then
            local vm = ply:GetViewModel()
            if IsValid(vm) then
                local names = { "muzzle", "laser", "muzzle_flash" }
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
            local names = { "muzzle", "laser", "muzzle_flash" }
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

    local function getLeftHandPos(ply, wep)
        -- Try viewmodel first (first-person hands)
        if IsValid(ply) and ply == LocalPlayer() then
            local vm = ply:GetViewModel()
            if IsValid(vm) then
                local bone = vm:LookupBone("ValveBiped.Bip01_L_Hand")
                if bone and bone >= 0 then
                    local m = vm:GetBoneMatrix(bone)
                    if m then
                        local pos = m:GetTranslation()
                        if pos and pos ~= vector_origin then return pos end
                    end
                    local pos = vm:GetBonePosition(bone)
                    if pos and pos ~= vector_origin then return pos end
                end
            end
        end

        -- Fallback to player worldmodel bone
        if IsValid(ply) then
            local bone = ply:LookupBone("ValveBiped.Bip01_L_Hand")
            if bone and bone >= 0 then
                local m = ply:GetBoneMatrix(bone)
                if m then
                    local pos = m:GetTranslation()
                    if pos and pos ~= vector_origin then return pos end
                end
                local pos = ply:GetBonePosition(bone)
                if pos and pos ~= vector_origin then return pos end
            end
        end

        -- Last resort: near weapon/model position
        return getRPGModelLightPos(ply, wep)
    end

    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_RPG_Held_DLight", function()
        if not cvar_enable:GetBool() then return end
    -- Refresh cap
    local hz = math.Clamp(cvar_update_hz:GetFloat(), 15, 120)
    BetterLights._nextTick = BetterLights._nextTick or {}
    local now = CurTime()
    local key = "RPG_Held_DLight"
    local nxt = BetterLights._nextTick[key] or 0
    if now < nxt then return end
    BetterLights._nextTick[key] = now + (1 / hz)

        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "weapon_rpg" then return end

        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())

        -- World light: place at the laser dot (aim hit point) using a long trace
        local startPos = ply.EyePos and ply:EyePos() or (ply.GetShootPos and ply:GetShootPos()) or wep:GetPos()
        local dir = ply.GetAimVector and ply:GetAimVector() or (ply.EyeAngles and ply:EyeAngles():Forward()) or Vector(1,0,0)
        local tr = util.TraceLine({
            start = startPos,
            endpos = startPos + dir * 8192,
            filter = { ply, wep }
        })
        local pos_world
        if tr.Hit then
            pos_world = tr.HitPos + tr.HitNormal * 6
        else
            pos_world = startPos + dir * 1024
        end

        local r, g, b = getColor()

        -- Stable index per player
        local idx = ply:EntIndex() + 1520

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

        -- Attach a second subtle world dlight to the player's left hand so the weapon and hand glow
        local pos_hand = getLeftHandPos(ply, wep)
        if pos_hand then
            local d2 = DynamicLight(idx + 1)
            if d2 then
                d2.pos = pos_hand
                d2.r = r
                d2.g = g
                d2.b = b
                d2.brightness = brightness
                d2.decay = decay
                d2.size = size
                d2.minlight = 0
                d2.noworld = false
                d2.nomodel = false
                d2.dietime = CurTime() + 0.1
            end
        end
    end)
end
