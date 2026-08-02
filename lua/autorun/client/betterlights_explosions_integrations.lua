if CLIENT then
    local BL = BetterLights
    local EXP = BL.Explosions

    local cvar_enable = GetConVar("betterlights_explosion_flash_enable")
    local cvar_size = GetConVar("betterlights_explosion_flash_size")
    local cvar_brightness = GetConVar("betterlights_explosion_flash_brightness")
    local cvar_time = GetConVar("betterlights_explosion_flash_time")
    local cvar_r = GetConVar("betterlights_explosion_flash_color_r")
    local cvar_g = GetConVar("betterlights_explosion_flash_color_g")
    local cvar_b = GetConVar("betterlights_explosion_flash_color_b")
    local HEXA_SHIELD_CLASS = "ent_coral_shield"
    local HEXA_CORE_OFFSET_Z = 4
    local HEXA_CORE_DISTANCE_SQR = 4 * 4

    -- Hexa Core reuses AR2Explosion as a persistent 20 Hz energy-core effect while active.
    local function shouldExcludeHexaCoreEffect(_, _, pos)
        local excluded = false

        BL.ForEach(HEXA_SHIELD_CLASS, function(ent)
            if excluded then return end
            if not (isfunction(ent.GetShieldState) and ent:GetShieldState() == ent.STATE_ACTIVE) then return end

            local entPos = ent:GetPos()
            local dx = pos.x - entPos.x
            local dy = pos.y - entPos.y
            local dz = pos.z - entPos.z - HEXA_CORE_OFFSET_Z
            excluded = dx * dx + dy * dy + dz * dz <= HEXA_CORE_DISTANCE_SQR
        end)

        return excluded
    end

    BL.TrackClass(HEXA_SHIELD_CLASS)

    EXP.RegisterEffectExclusion("hexa_core_shield", {
        effects = { "AR2Explosion" },
        shouldExclude = shouldExcludeHexaCoreEffect,
        source = "integration"
    })

    EXP.RegisterClientProfile("weapon_base_explosion", {
        enableCvar = cvar_enable,
        sizeCvar = cvar_size,
        brightnessCvar = cvar_brightness,
        durationCvar = cvar_time,
        rCvar = cvar_r,
        gCvar = cvar_g,
        bCvar = cvar_b,
        baseId = 61200,
        suppressionKey = "explosion"
    })

    EXP.RegisterClientProfile("cw2_flashbang", {
        enableCvar = cvar_enable,
        sizeCvar = cvar_size,
        brightnessCvar = cvar_brightness,
        durationCvar = cvar_time,
        r = 255,
        g = 255,
        b = 255,
        baseId = 61300,
        suppressionKey = "explosion"
    })
end
