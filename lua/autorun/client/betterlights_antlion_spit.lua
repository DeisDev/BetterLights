-- BetterLights: Antlion Worker spit (grenade_spit) glow and impact flash
-- Client-side only

if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
    -- Localize frequently used globals to reduce global table lookups per frame
    local CurTime = CurTime
    local IsValid = IsValid
    local DynamicLight = DynamicLight
    local ipairs = ipairs
    local pairs = pairs
    local insert = table.insert
    local remove = table.remove
    local timer_Simple = timer.Simple
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
    if BL.TrackClass then BL.TrackClass(TARGET_CLASS) end
    hook.Add("OnEntityCreated", "BetterLights_AntlionSpit_TrackSpawn", function(ent)
        -- Keep this for older GMod without our core loaded very early
        if BetterLights and BetterLights._classes and BetterLights._classes[TARGET_CLASS] then return end
    timer_Simple(0, function()
            if not IsValid(ent) then return end
            local cls = (ent.GetClass and ent:GetClass()) or ""
            if cls == TARGET_CLASS then
                BL_Spit_Tracked[ent] = { spawn = CurTime() }
            end
        end)
    end)

    -- Seed existing on load
    timer_Simple(0, function()
        if BL.ForEach then
            BL.ForEach(TARGET_CLASS, function(ent) BL_Spit_Tracked[ent] = { spawn = CurTime() } end)
        else
            for _, ent in ipairs(ents.FindByClass(TARGET_CLASS)) do
                if IsValid(ent) then BL_Spit_Tracked[ent] = { spawn = CurTime() } end
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

    -- Consolidated Think: handle both in-flight glow and queued impact flashes
    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_AntlionSpit", function()
        local doGlow = cvar_enable:GetBool()
        local doFlash = cvar_flash_enable:GetBool()

        -- Precompute colors once per frame
        local gr, gg, gb = getGlowColor()
        local fr, fg, fb = getFlashColor()

        if doGlow then
            local size = math.max(0, cvar_size:GetFloat())
            local brightness = math.max(0, cvar_brightness:GetFloat())
            local decay = math.max(0, cvar_decay:GetFloat())

            -- Iterate currently tracked grenade_spit via core; ensure BL_Spit_Tracked has spawn times
            if BL.ForEach then
                BL.ForEach(TARGET_CLASS, function(ent)
                    if not IsValid(ent) then return end
                    if BL_Spit_Tracked[ent] == nil then BL_Spit_Tracked[ent] = { spawn = CurTime() } end

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
                        d.pos = pos
                        d.r = gr
                        d.g = gg
                        d.b = gb
                        d.brightness = brightness
                        d.decay = decay
                        d.size = size
                        d.minlight = 0
                        d.noworld = false
                        d.nomodel = false
                        d.dietime = CurTime() + 0.1
                    end
                end)
            else
                for _, ent in ipairs(ents.FindByClass(TARGET_CLASS)) do
                    if IsValid(ent) then
                        if BL_Spit_Tracked[ent] == nil then BL_Spit_Tracked[ent] = { spawn = CurTime() } end
                        local d = DynamicLight(ent:EntIndex())
                        if d then
                            local pos = ent.WorldSpaceCenter and ent:WorldSpaceCenter() or ent:GetPos()
                            d.pos = pos
                            d.r = gr
                            d.g = gg
                            d.b = gb
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
            end
            -- Cleanup invalids in our spawn-time map
            for ent, _ in pairs(BL_Spit_Tracked) do if not IsValid(ent) then BL_Spit_Tracked[ent] = nil end end
        end

        -- Impact flashes
        if doFlash and BL_Spit_Flashes and #BL_Spit_Flashes > 0 then
            local now = CurTime()
            local baseSize = math.max(0, cvar_flash_size:GetFloat())
            local baseBright = math.max(0, cvar_flash_brightness:GetFloat())

            for i = #BL_Spit_Flashes, 1, -1 do
                local f = BL_Spit_Flashes[i]
                if not f or now >= f.die then
                    remove(BL_Spit_Flashes, i)
                else
                    local dur = math.max(0.001, f.die - f.start)
                    local t = (f.die - now) / dur -- 1 -> 0
                    local b_eff = baseBright * t
                    local s_eff = baseSize * (0.5 + 0.5 * t)

                    local d = DynamicLight(f.id or (59400 + i))
                    if d then
                        d.pos = f.pos
                        d.r = fr
                        d.g = fg
                        d.b = fb
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
        end
    end)
end
