-- BetterLights: Magnusson Device (Strider Buster) glow and explosion flash
-- Client-side only

if CLIENT then
    -- ConVars
    local cvar_enable = CreateClientConVar("betterlights_magnusson_enable", "1", true, false, "Enable dynamic light for Magnusson devices (Strider Busters)")
    local cvar_size = CreateClientConVar("betterlights_magnusson_size", "130", true, false, "Dynamic light radius for Magnusson devices")
    local cvar_brightness = CreateClientConVar("betterlights_magnusson_brightness", "0.48", true, false, "Dynamic light brightness for Magnusson devices")
    local cvar_decay = CreateClientConVar("betterlights_magnusson_decay", "2000", true, false, "Dynamic light decay for Magnusson devices")
    local cvar_models_elight = CreateClientConVar("betterlights_magnusson_models_elight", "1", true, false, "Also add an entity light (elight) to light the device model directly")
    local cvar_models_elight_size_mult = CreateClientConVar("betterlights_magnusson_models_elight_size_mult", "1.0", true, false, "Multiplier for Magnusson device elight radius")

    -- Explosion flash controls
    local cvar_flash_enable = CreateClientConVar("betterlights_magnusson_flash_enable", "1", true, false, "Add a brief light flash when a Magnusson device explodes")
    local cvar_flash_size = CreateClientConVar("betterlights_magnusson_flash_size", "360", true, false, "Explosion flash radius for Magnusson devices")
    local cvar_flash_brightness = CreateClientConVar("betterlights_magnusson_flash_brightness", "2.2", true, false, "Explosion flash brightness for Magnusson devices")
    local cvar_flash_time = CreateClientConVar("betterlights_magnusson_flash_time", "0.14", true, false, "Duration of the explosion flash (seconds)")

    -- Light blue for glow and flash
    local ORANGE = { r = 130, g = 180, b = 255 }
    local FLASH = { r = 180, g = 220, b = 255 }

    -- Exact classname for Strider Buster in GMod
    local TARGET_CLASS = "weapon_striderbuster"

    -- Track ephemeral flashes and active devices
    local BL_Magnusson_Flashes = BL_Magnusson_Flashes or {}
    local BL_Magnusson_Tracked = BL_Magnusson_Tracked or {} -- maps ent -> spawnTime

    -- Track magnusson devices as they spawn
    hook.Add("OnEntityCreated", "BetterLights_Magnusson_TrackSpawn", function(ent)
        -- Delay one tick to ensure class/model available
        timer.Simple(0, function()
            if not IsValid(ent) then return end
            local cls = (ent.GetClass and ent:GetClass()) or ""
            if cls == TARGET_CLASS then
                BL_Magnusson_Tracked[ent] = CurTime()
            end
        end)
    end)

    -- Initial population (after load)
    timer.Simple(0, function()
        for _, ent in ipairs(ents.GetAll()) do
            local cls = (ent.GetClass and ent:GetClass()) or ""
            if cls == TARGET_CLASS then
                BL_Magnusson_Tracked[ent] = CurTime()
            end
        end
    end)

    -- Flash on removal (explosion)
    hook.Add("EntityRemoved", "BetterLights_Magnusson_FlashOnRemoval", function(ent, fullUpdate)
        if fullUpdate then return end
        if not IsValid(ent) then return end
        -- Untrack when removed
        if BL_Magnusson_Tracked[ent] ~= nil then
            BL_Magnusson_Tracked[ent] = nil
        end
    local class = (ent.GetClass and ent:GetClass()) or ""
    if class ~= TARGET_CLASS then return end
        if not cvar_flash_enable:GetBool() then return end

    -- Avoid spawn flashes: only flash if it existed for some time
    local now = CurTime()
    local spawnTime = BL_Magnusson_Tracked[ent] or (ent.GetCreationTime and ent:GetCreationTime()) or now
    if (now - spawnTime) < 0.2 then return end

        local pos
        if ent.OBBCenter and ent.LocalToWorld then
            pos = ent:LocalToWorld(ent:OBBCenter())
        elseif ent.WorldSpaceCenter then
            pos = ent:WorldSpaceCenter()
        else
            pos = ent:GetPos()
        end

        local dur = math.max(0, cvar_flash_time:GetFloat())
        if dur <= 0 then return end
        table.insert(BL_Magnusson_Flashes, { pos = pos, start = now, die = now + dur, id = 59000 + (now * 1000 % 3000) })
    end)

    -- Steady glow while active
    hook.Add("Think", "BetterLights_Magnusson_DLight", function()
        if not cvar_enable:GetBool() then return end

        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())

        -- Iterate tracked devices
        for ent, spawnTime in pairs(BL_Magnusson_Tracked) do
            if not IsValid(ent) then
                BL_Magnusson_Tracked[ent] = nil
            else
                local cls = (ent.GetClass and ent:GetClass()) or ""
                if cls ~= TARGET_CLASS then
                    BL_Magnusson_Tracked[ent] = nil
                else
                local idx = ent:EntIndex()
                local pos
                if ent.OBBCenter and ent.LocalToWorld then
                    pos = ent:LocalToWorld(ent:OBBCenter())
                elseif ent.WorldSpaceCenter then
                    pos = ent:WorldSpaceCenter()
                else
                    pos = ent:GetPos()
                end

                local d = DynamicLight(idx)
                if d then
                    d.pos = pos
                    d.r = ORANGE.r
                    d.g = ORANGE.g
                    d.b = ORANGE.b
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
                        el.pos = pos
                        el.r = ORANGE.r
                        el.g = ORANGE.g
                        el.b = ORANGE.b
                        el.brightness = brightness
                        el.decay = decay
                        el.size = size * math.max(0, cvar_models_elight_size_mult:GetFloat())
                        el.minlight = 0
                        el.dietime = CurTime() + 0.1
                    end
                end
                end
            end
        end
    end)

    -- Render short-lived explosion flashes
    hook.Add("Think", "BetterLights_Magnusson_FlashThink", function()
        if not cvar_flash_enable:GetBool() then return end
        if not BL_Magnusson_Flashes or #BL_Magnusson_Flashes == 0 then return end

        local now = CurTime()
        local baseSize = math.max(0, cvar_flash_size:GetFloat())
        local baseBright = math.max(0, cvar_flash_brightness:GetFloat())

        for i = #BL_Magnusson_Flashes, 1, -1 do
            local f = BL_Magnusson_Flashes[i]
            if not f or now >= f.die then
                table.remove(BL_Magnusson_Flashes, i)
            else
                local dur = math.max(0.001, f.die - f.start)
                local t = (f.die - now) / dur -- 1->0
                local b_eff = baseBright * t
                local s_eff = baseSize * (0.4 + 0.6 * t)

                local d = DynamicLight(f.id or (60000 + i))
                if d then
                    d.pos = f.pos
                    d.r = FLASH.r
                    d.g = FLASH.g
                    d.b = FLASH.b
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
