if CLIENT then
    local BL = BetterLights
    local IsValid = IsValid

    local cvar_enable = BL.CreateClientConVar("betterlights_antlion_spit_enable", "1", true, false, "Enable dynamic light for Antlion spit projectiles (grenade_spit)")
    local cvar_size = BL.CreateClientConVar("betterlights_antlion_spit_size", "100", true, false, "Dynamic light radius for Antlion spit")
    local cvar_brightness = BL.CreateClientConVar("betterlights_antlion_spit_brightness", "1.0", true, false, "Dynamic light brightness for Antlion spit")
    local cvar_decay = BL.CreateClientConVar("betterlights_antlion_spit_decay", "1800", true, false, "Dynamic light decay for Antlion spit")

    local cvar_flash_enable = BL.CreateClientConVar("betterlights_antlion_spit_flash_enable", "1", true, false, "Add a brief light flash when Antlion spit impacts")
    local cvar_flash_size = BL.CreateClientConVar("betterlights_antlion_spit_flash_size", "160", true, false, "Impact flash radius for Antlion spit")
    local cvar_flash_brightness = BL.CreateClientConVar("betterlights_antlion_spit_flash_brightness", "1.5", true, false, "Impact flash brightness for Antlion spit")
    local cvar_flash_time = BL.CreateClientConVar("betterlights_antlion_spit_flash_time", "1.0", true, false, "Duration of the impact flash (seconds)")

    local cvar_col_r = BL.CreateClientConVar("betterlights_antlion_spit_color_r", "120", true, false, "Antlion spit glow color - red (0-255)")
    local cvar_col_g = BL.CreateClientConVar("betterlights_antlion_spit_color_g", "255", true, false, "Antlion spit glow color - green (0-255)")
    local cvar_col_b = BL.CreateClientConVar("betterlights_antlion_spit_color_b", "140", true, false, "Antlion spit glow color - blue (0-255)")
    local cvar_flash_r = BL.CreateClientConVar("betterlights_antlion_spit_flash_color_r", "180", true, false, "Antlion spit flash color - red (0-255)")
    local cvar_flash_g = BL.CreateClientConVar("betterlights_antlion_spit_flash_color_g", "255", true, false, "Antlion spit flash color - green (0-255)")
    local cvar_flash_b = BL.CreateClientConVar("betterlights_antlion_spit_flash_color_b", "120", true, false, "Antlion spit flash color - blue (0-255)")

    local TARGET_CLASS = "grenade_spit"

    BL.TrackClass(TARGET_CLASS)
    hook.Remove("OnEntityCreated", "BetterLights_AntlionSpit_TrackSpawn")
    hook.Remove("EntityRemoved", "BetterLights_AntlionSpit_OnRemove")

    BL.AddNetworkHandler(BL.NET_ANTLION_SPIT_IMPACT, function()
        local pos = net.ReadVector()
        if not cvar_flash_enable:GetBool() then return end

        local duration = math.max(0, cvar_flash_time:GetFloat())
        if duration <= 0 then return end

        local r, g, b = BL.GetColorFromCvars(cvar_flash_r, cvar_flash_g, cvar_flash_b)
        local size = math.max(0, cvar_flash_size:GetFloat())
        local brightness = math.max(0, cvar_flash_brightness:GetFloat())
        BL.CreateFlash(pos, r, g, b, size, brightness, duration, 59200)
    end)

    BL.AddThink("BetterLights_AntlionSpit", function()
        if not cvar_enable:GetBool() then return end

        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())
        local r, g, b = BL.GetColorFromCvars(cvar_col_r, cvar_col_g, cvar_col_b)

        BL.ForEach(TARGET_CLASS, function(ent)
            if not IsValid(ent) then return end

            local pos = BL.GetEntityCenter(ent)
            if not pos then return end

            BL.CreateDLight(
                ent:EntIndex(),
                pos,
                r,
                g,
                b,
                brightness,
                decay,
                size,
                false,
                BL.LIGHT_OPTIONS_GAMEPLAY
            )
        end)
    end)
end
