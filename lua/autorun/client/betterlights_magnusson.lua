-- BetterLights: Magnusson Device (Strider Buster) glow and explosion flash
-- Client-side only

if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
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
    local cvar_flash_time = CreateClientConVar("betterlights_magnusson_flash_time", "2.0", true, false, "Duration of the explosion flash (seconds)")

    -- Color configuration (light blue by default)
    local cvar_col_r = CreateClientConVar("betterlights_magnusson_color_r", "130", true, false, "Magnusson device glow color - red (0-255)")
    local cvar_col_g = CreateClientConVar("betterlights_magnusson_color_g", "180", true, false, "Magnusson device glow color - green (0-255)")
    local cvar_col_b = CreateClientConVar("betterlights_magnusson_color_b", "255", true, false, "Magnusson device glow color - blue (0-255)")
    local cvar_flash_r = CreateClientConVar("betterlights_magnusson_flash_color_r", "180", true, false, "Magnusson flash color - red (0-255)")
    local cvar_flash_g = CreateClientConVar("betterlights_magnusson_flash_color_g", "220", true, false, "Magnusson flash color - green (0-255)")
    local cvar_flash_b = CreateClientConVar("betterlights_magnusson_flash_color_b", "255", true, false, "Magnusson flash color - blue (0-255)")

    -- Exact classname for Strider Buster in GMod
    local TARGET_CLASS = "weapon_striderbuster"

    -- Track active devices for spawn-time checking
    local BL_Magnusson_Tracked = BL_Magnusson_Tracked or {} -- maps ent -> spawnTime

    -- Use core tracking for class
    if BL.TrackClass then BL.TrackClass(TARGET_CLASS) end
    
    -- Seed from core on load
    timer.Simple(0, function()
        if BL.ForEach then BL.ForEach(TARGET_CLASS, function(ent) if IsValid(ent) then BL_Magnusson_Tracked[ent] = CurTime() end end)
        else
            for _, ent in ipairs(ents.FindByClass(TARGET_CLASS)) do BL_Magnusson_Tracked[ent] = CurTime() end
        end
    end)

    -- Track newly created devices
    hook.Add("OnEntityCreated", "BetterLights_Magnusson_Track", function(ent)
        timer.Simple(0, function()
            if IsValid(ent) and ent:GetClass() == TARGET_CLASS then
                BL_Magnusson_Tracked[ent] = CurTime()
            end
        end)
    end)

    -- Flash on removal (explosion)
    hook.Add("EntityRemoved", "BetterLights_Magnusson_FlashOnRemoval", function(ent, fullUpdate)
        if fullUpdate then return end
        if not IsValid(ent) then return end
        
        -- Check if we were tracking this entity
        local spawnTime = BL_Magnusson_Tracked[ent]
        if spawnTime then
            BL_Magnusson_Tracked[ent] = nil
        end
        
        if not BL.IsEntityClass(ent, TARGET_CLASS) then return end
        if not cvar_flash_enable:GetBool() then return end

        -- Avoid spawn flashes: only flash if it existed for some time
        local now = CurTime()
        if spawnTime and (now - spawnTime) < 0.2 then return end

        local pos = BL.GetEntityCenter(ent)
        if not pos then return end

        local dur = math.max(0, cvar_flash_time:GetFloat())
        if dur <= 0 then return end
        
        local fr, fg, fb = BL.GetColorFromCvars(cvar_flash_r, cvar_flash_g, cvar_flash_b)
        local flashSize = math.max(0, cvar_flash_size:GetFloat())
        local flashBrightness = math.max(0, cvar_flash_brightness:GetFloat())
        BL.CreateFlash(pos, fr, fg, fb, flashSize, flashBrightness, dur, 59000)
    end)

    -- Steady glow while active
    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_Magnusson_DLight", function()
        if not cvar_enable:GetBool() then return end

        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())
        local doElight = cvar_models_elight:GetBool()
        local elMult = math.max(0, cvar_models_elight_size_mult:GetFloat())

        -- Cache colors once per frame
        local gr, gg, gb = BL.GetColorFromCvars(cvar_col_r, cvar_col_g, cvar_col_b)

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
                    local pos = BL.GetEntityCenter(ent)
                    if pos then
                        -- Create world light
                        BL.CreateDLight(idx, pos, gr, gg, gb, brightness, decay, size, false)

                        -- Create entity light if enabled
                        if doElight then
                            BL.CreateDLight(idx, pos, gr, gg, gb, brightness, decay, size * elMult, true)
                        end
                    end
                end
            end
        end
    end)
end
