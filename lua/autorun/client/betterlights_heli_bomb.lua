if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
    local CurTime = CurTime
    local IsValid = IsValid
    -- Note: DynamicLight is NOT localized to ensure compatibility with wrappers like GShader Library
    local cvar_enable = BL.CreateClientConVar("betterlights_heli_bomb_enable", "1", true, false, "Enable dynamic light for helicopter bombs (grenade_helicopter)")
    local cvar_size = BL.CreateClientConVar("betterlights_heli_bomb_size", "140", true, false, "Dynamic light radius for helicopter bombs")
    local cvar_brightness = BL.CreateClientConVar("betterlights_heli_bomb_brightness", "1.4", true, false, "Dynamic light brightness for helicopter bombs")
    local cvar_decay = BL.CreateClientConVar("betterlights_heli_bomb_decay", "2000", true, false, "Dynamic light decay for helicopter bombs")
    local cvar_models_elight = BL.CreateClientConVar("betterlights_heli_bomb_models_elight", "1", true, false, "Also add an entity light (elight) to light the bomb model directly")
    local cvar_models_elight_size_mult = BL.CreateClientConVar("betterlights_heli_bomb_models_elight_size_mult", "1.0", true, false, "Multiplier for helicopter bomb elight radius")
    local cvar_flash_enable = BL.CreateClientConVar("betterlights_heli_bomb_flash_enable", "1", true, false, "Add a brief light flash when a helicopter bomb explodes")
    local cvar_flash_size = BL.CreateClientConVar("betterlights_heli_bomb_flash_size", "320", true, false, "Explosion flash radius for helicopter bombs")
    local cvar_flash_brightness = BL.CreateClientConVar("betterlights_heli_bomb_flash_brightness", "5.0", true, false, "Explosion flash brightness for helicopter bombs")
    local cvar_flash_time = BL.CreateClientConVar("betterlights_heli_bomb_flash_time", "0.18", true, false, "Duration of the explosion flash")

    local cvar_col_r = BL.CreateClientConVar("betterlights_heli_bomb_color_r", "255", true, false, "Heli bomb glow color - red (0-255)")
    local cvar_col_g = BL.CreateClientConVar("betterlights_heli_bomb_color_g", "60", true, false, "Heli bomb glow color - green (0-255)")
    local cvar_col_b = BL.CreateClientConVar("betterlights_heli_bomb_color_b", "60", true, false, "Heli bomb glow color - blue (0-255)")
    local cvar_flash_r = BL.CreateClientConVar("betterlights_heli_bomb_flash_color_r", "255", true, false, "Heli bomb flash color - red (0-255)")
    local cvar_flash_g = BL.CreateClientConVar("betterlights_heli_bomb_flash_color_g", "210", true, false, "Heli bomb flash color - green (0-255)")
    local cvar_flash_b = BL.CreateClientConVar("betterlights_heli_bomb_flash_color_b", "120", true, false, "Heli bomb flash color - blue (0-255)")

    hook.Add("EntityRemoved", "BetterLights_HeliBomb_FlashOnRemoval", function(ent, fullUpdate)
        if fullUpdate then return end
        if not BL.IsEntityClass(ent, "grenade_helicopter") then return end
        if not cvar_flash_enable:GetBool() then return end

        local pos = BL.GetEntityCenter(ent)
        if not pos then return end

        local dur = math.max(0, cvar_flash_time:GetFloat())
        if dur <= 0 then return end
        
        local fr, fg, fb = BL.GetColorFromCvars(cvar_flash_r, cvar_flash_g, cvar_flash_b)
        local flashSize = math.max(0, cvar_flash_size:GetFloat())
        local flashBrightness = math.max(0, cvar_flash_brightness:GetFloat())
        BL.CreateFlash(pos, fr, fg, fb, flashSize, flashBrightness, dur, 56000)
    end)

    if BL.TrackClass then BL.TrackClass("grenade_helicopter") end

    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_HeliBomb", function()
        if not cvar_enable:GetBool() then return end

        local gr, gg, gb = BL.GetColorFromCvars(cvar_col_r, cvar_col_g, cvar_col_b)

        local size = math.max(0, cvar_size:GetFloat())
        local brightness_base = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())
        local elMult = math.max(0, cvar_models_elight_size_mult:GetFloat())
        local doElight = cvar_models_elight:GetBool()

        local function update(ent)
            if not IsValid(ent) then return end
            local idx = ent:EntIndex()
            local pos = BL.GetEntityCenter(ent)
            if not pos then return end

            BL.CreateDLight(idx, pos, gr, gg, gb, brightness_base, decay, size, false)

            if doElight then
                BL.CreateDLight(idx, pos, gr, gg, gb, brightness_base, decay, size * elMult, true)
            end
        end

        if BL.ForEach then
            BL.ForEach("grenade_helicopter", update)
        else
            for _, ent in ipairs(ents.FindByClass("grenade_helicopter")) do update(ent) end
        end
    end)
end
