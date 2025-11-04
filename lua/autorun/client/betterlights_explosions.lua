-- BetterLights: Generic Explosion Flashes (env_explosion, explosive barrels, etc.)
-- Client-side only

if CLIENT then
    -- Feature toggles and tuning
    local cvar_enable = CreateClientConVar("betterlights_explosion_flash_enable", "1", true, false, "Enable generic explosion flashes (env_explosion, explosive barrels, etc.)")
    local cvar_size = CreateClientConVar("betterlights_explosion_flash_size", "380", true, false, "Generic explosion flash radius")
    local cvar_brightness = CreateClientConVar("betterlights_explosion_flash_brightness", "4.6", true, false, "Generic explosion flash brightness")
    local cvar_time = CreateClientConVar("betterlights_explosion_flash_time", "0.18", true, false, "Generic explosion flash duration (seconds)")
    local cvar_update_hz = CreateClientConVar("betterlights_explosion_flash_update_hz", "60", true, false, "Update rate in Hz (15-120) for flash fade")
    -- Color config (incremental RGB support)
    local cvar_r = CreateClientConVar("betterlights_explosion_flash_color_r", "255", true, false, "Explosion flash color - red component (0-255)")
    local cvar_g = CreateClientConVar("betterlights_explosion_flash_color_g", "210", true, false, "Explosion flash color - green component (0-255)")
    local cvar_b = CreateClientConVar("betterlights_explosion_flash_color_b", "120", true, false, "Explosion flash color - blue component (0-255)")

    -- Detection toggles
    local cvar_detect_env = CreateClientConVar("betterlights_explosion_detect_env", "1", true, false, "Detect env_explosion/env_physexplosion/env_ar2explosion entities")
    local cvar_detect_barrel = CreateClientConVar("betterlights_explosion_detect_barrels", "1", true, false, "Detect explosive barrels by removal (oildrum001_explosive model)")

    local function getFlashColor()
        local r = math.Clamp(math.floor(cvar_r:GetFloat() + 0.5), 0, 255)
        local g = math.Clamp(math.floor(cvar_g:GetFloat() + 0.5), 0, 255)
        local b = math.Clamp(math.floor(cvar_b:GetFloat() + 0.5), 0, 255)
        return r, g, b
    end

    local recent = recent or {}
    local flashes = flashes or {}

    local function shouldSuppress(pos)
        local now = CurTime()
        for i = #recent, 1, -1 do
            local e = recent[i]
            if not e or now - e.t > 0.15 then
                table.remove(recent, i)
            else
                if e.pos:DistToSqr(pos) < (40 * 40) then return true end
            end
        end
        return false
    end

    local function spawnFlashAt(pos)
        if not cvar_enable:GetBool() then return end
        local dur = math.max(0, cvar_time:GetFloat())
        if dur <= 0 then return end
        if shouldSuppress(pos) then return end
        local now = CurTime()
        table.insert(flashes, { pos = pos, start = now, die = now + dur, id = 61000 + (now * 1000 % 3000) })
        table.insert(recent, { pos = pos, t = now })
    end

    -- Detect env_* explosion entities as they spawn
    hook.Add("OnEntityCreated", "BetterLights_Explosion_OnCreated", function(ent)
        if not cvar_detect_env:GetBool() then return end
        timer.Simple(0, function()
            if not IsValid(ent) then return end
            local cls = ent.GetClass and ent:GetClass() or ""
            if cls == "env_explosion" or cls == "env_physexplosion" or cls == "env_ar2explosion" then
                local pos = ent.WorldSpaceCenter and ent:WorldSpaceCenter() or ent:GetPos()
                spawnFlashAt(pos)
            end
        end)
    end)

    -- Detect explosive barrels by removal
    local function isExplosiveBarrel(ent)
        if not IsValid(ent) then return false end
        if not ent.GetModel then return false end
        local m = string.lower(ent:GetModel() or "")
        return string.find(m, "oildrum001_explosive", 1, true) ~= nil
    end

    hook.Add("EntityRemoved", "BetterLights_Explosion_OnBarrelRemoved", function(ent, fullUpdate)
        if fullUpdate then return end
        if not cvar_detect_barrel:GetBool() then return end
        if not IsValid(ent) then return end
        local cls = ent.GetClass and ent:GetClass() or ""
        if cls ~= "prop_physics" and cls ~= "prop_physics_multiplayer" then return end
        if not isExplosiveBarrel(ent) then return end
        local pos = ent.WorldSpaceCenter and ent:WorldSpaceCenter() or ent:GetPos()
        spawnFlashAt(pos)
    end)

    -- Render and decay flashes
    hook.Add("Think", "BetterLights_ExplosionFlash_Think", function()
        if not cvar_enable:GetBool() then return end
        if not flashes or #flashes == 0 then return end
        -- Refresh cap
        local hz = math.Clamp(cvar_update_hz:GetFloat(), 15, 120)
        BetterLights = BetterLights or {}
        BetterLights._nextTick = BetterLights._nextTick or {}
        local now = CurTime()
        local key = "ExplosionFlash_Think"
        local nxt = BetterLights._nextTick[key] or 0
        if now < nxt then return end
        BetterLights._nextTick[key] = now + (1 / hz)
        local baseSize = math.max(0, cvar_size:GetFloat())
        local baseBright = math.max(0, cvar_brightness:GetFloat())
        local cr, cg, cb = getFlashColor()

        for i = #flashes, 1, -1 do
            local f = flashes[i]
            if not f or now >= f.die then
                table.remove(flashes, i)
            else
                local dur = math.max(0.001, f.die - f.start)
                local t = (f.die - now) / dur
                local b_eff = baseBright * t
                local s_eff = baseSize * (0.4 + 0.6 * t)
                local d = DynamicLight(f.id or (62000 + i))
                if d then
                    d.pos = f.pos
                    d.r = cr
                    d.g = cg
                    d.b = cb
                    d.brightness = b_eff
                    d.decay = 0
                    d.size = s_eff
                    d.minlight = 0
                    d.noworld = false
                    d.nomodel = false
                    d.dietime = now + 0.05
                end
            end
        end
    end)
end
