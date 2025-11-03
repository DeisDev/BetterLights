-- BetterLights: Antlion Worker spit (grenade_spit) glow and impact flash
-- Client-side only

if CLIENT then
    -- ConVars: in-flight glow
    local cvar_enable = CreateClientConVar("betterlights_antlion_spit_enable", "1", true, false, "Enable dynamic light for Antlion spit projectiles (grenade_spit)")
    local cvar_size = CreateClientConVar("betterlights_antlion_spit_size", "100", true, false, "Dynamic light radius for Antlion spit")
    local cvar_brightness = CreateClientConVar("betterlights_antlion_spit_brightness", "1.0", true, false, "Dynamic light brightness for Antlion spit")
    local cvar_decay = CreateClientConVar("betterlights_antlion_spit_decay", "1800", true, false, "Dynamic light decay for Antlion spit")

    -- ConVars: impact flash
    local cvar_flash_enable = CreateClientConVar("betterlights_antlion_spit_flash_enable", "1", true, false, "Add a brief light flash when Antlion spit impacts")
    local cvar_flash_size = CreateClientConVar("betterlights_antlion_spit_flash_size", "160", true, false, "Impact flash radius for Antlion spit")
    local cvar_flash_brightness = CreateClientConVar("betterlights_antlion_spit_flash_brightness", "1.5", true, false, "Impact flash brightness for Antlion spit")
    local cvar_flash_time = CreateClientConVar("betterlights_antlion_spit_flash_time", "1.0", true, false, "Duration of the impact flash (seconds)")

    -- Colors
    local cvar_col_r = CreateClientConVar("betterlights_antlion_spit_color_r", "120", true, false, "Antlion spit glow color - red (0-255)")
    local cvar_col_g = CreateClientConVar("betterlights_antlion_spit_color_g", "255", true, false, "Antlion spit glow color - green (0-255)")
    local cvar_col_b = CreateClientConVar("betterlights_antlion_spit_color_b", "140", true, false, "Antlion spit glow color - blue (0-255)")
    local cvar_flash_r = CreateClientConVar("betterlights_antlion_spit_flash_color_r", "180", true, false, "Antlion spit flash color - red (0-255)")
    local cvar_flash_g = CreateClientConVar("betterlights_antlion_spit_flash_color_g", "255", true, false, "Antlion spit flash color - green (0-255)")
    local cvar_flash_b = CreateClientConVar("betterlights_antlion_spit_flash_color_b", "120", true, false, "Antlion spit flash color - blue (0-255)")
    local function getGlowColor()
        return math.Clamp(math.floor(cvar_col_r:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_col_g:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_col_b:GetFloat() + 0.5), 0, 255)
    end
    local function getFlashColor()
        return math.Clamp(math.floor(cvar_flash_r:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_flash_g:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_flash_b:GetFloat() + 0.5), 0, 255)
    end

    local TARGET_CLASS = "grenade_spit"

    -- Tracking
    local BL_Spit_Tracked = BL_Spit_Tracked or {} -- ent -> { spawn = time }
    local BL_Spit_Flashes = BL_Spit_Flashes or {}

    -- Track newly created spit
    hook.Add("OnEntityCreated", "BetterLights_AntlionSpit_TrackSpawn", function(ent)
        timer.Simple(0, function()
            if not IsValid(ent) then return end
            local cls = (ent.GetClass and ent:GetClass()) or ""
            if cls == TARGET_CLASS then
                BL_Spit_Tracked[ent] = { spawn = CurTime() }
            end
        end)
    end)

    -- Seed existing on load
    timer.Simple(0, function()
        for _, ent in ipairs(ents.FindByClass(TARGET_CLASS)) do
            if IsValid(ent) then
                BL_Spit_Tracked[ent] = { spawn = CurTime() }
            end
        end
    end)

    -- Remove tracking and schedule a flash on removal (impact)
    hook.Add("EntityRemoved", "BetterLights_AntlionSpit_OnRemove", function(ent, fullUpdate)
        if fullUpdate then return end
        -- If we tracked it, spawn a flash at its last known position
        local data = BL_Spit_Tracked[ent]
        if data ~= nil then
            BL_Spit_Tracked[ent] = nil
            if not cvar_flash_enable:GetBool() then return end
            local now = CurTime()
            local lived = now - (data.spawn or now)
            if lived < 0.05 then return end -- avoid spawn artifacts

            local pos
            if ent and ent.LocalToWorld and ent.OBBCenter then
                pos = ent:LocalToWorld(ent:OBBCenter())
            elseif ent and ent.WorldSpaceCenter then
                pos = ent:WorldSpaceCenter()
            else
                pos = ent and ent.GetPos and ent:GetPos() or nil
            end
            if not pos then return end

            local dur = math.max(0, cvar_flash_time:GetFloat())
            if dur <= 0 then return end
            table.insert(BL_Spit_Flashes, { pos = pos, start = now, die = now + dur, id = 59200 + (now * 1000 % 3000) })
        end
    end)

    -- Continuous glow while in flight
    hook.Add("Think", "BetterLights_AntlionSpit_GlowThink", function()
        if not cvar_enable:GetBool() then return end

        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())

        for ent, info in pairs(BL_Spit_Tracked) do
            if not IsValid(ent) then
                BL_Spit_Tracked[ent] = nil
            else
                local pos
                if ent.LocalToWorld and ent.OBBCenter then
                    pos = ent:LocalToWorld(ent:OBBCenter())
                elseif ent.WorldSpaceCenter then
                    pos = ent:WorldSpaceCenter()
                else
                    pos = ent:GetPos()
                end

                local d = DynamicLight(ent:EntIndex())
                if d then
                    local r, g, b = getGlowColor()
                    d.pos = pos
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
            end
        end
    end)

    -- Render impact flashes
    hook.Add("Think", "BetterLights_AntlionSpit_FlashThink", function()
        if not cvar_flash_enable:GetBool() then return end
        if not BL_Spit_Flashes or #BL_Spit_Flashes == 0 then return end

        local now = CurTime()
        local baseSize = math.max(0, cvar_flash_size:GetFloat())
        local baseBright = math.max(0, cvar_flash_brightness:GetFloat())

        for i = #BL_Spit_Flashes, 1, -1 do
            local f = BL_Spit_Flashes[i]
            if not f or now >= f.die then
                table.remove(BL_Spit_Flashes, i)
            else
                local dur = math.max(0.001, f.die - f.start)
                local t = (f.die - now) / dur -- 1 -> 0
                local b_eff = baseBright * t
                local s_eff = baseSize * (0.5 + 0.5 * t)

                local d = DynamicLight(f.id or (59400 + i))
                if d then
                    local r, g, b = getFlashColor()
                    d.pos = f.pos
                    d.r = r
                    d.g = g
                    d.b = b
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
