if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights

    local WEAPONS = {
        {
            class = "weapon_crossbow",
            slug = "crossbow",
            name = "Crossbow",
            size = 34,
            brightness = 0.12,
            decay = 0,
            elight = 1,
            elightMult = 1.0,
            r = 255,
            g = 110,
            b = 25,
            attachments = { "muzzle", "bolt", "tip", "flash", "spark" }
        },
        {
            class = "gmod_tool",
            slug = "toolgun",
            name = "Tool Gun",
            size = 42,
            brightness = 0.22,
            decay = 0,
            elight = 1,
            elightMult = 1.0,
            r = 255,
            g = 255,
            b = 255,
            attachments = { "muzzle" },
            offset = Vector(-7, 0, 0)
        },
        {
            class = "weapon_physcannon",
            slug = "gravitygun",
            name = "Gravity Gun",
            size = 48,
            brightness = 0.25,
            decay = 0,
            elight = 1,
            elightMult = 1.0,
            r = 255,
            g = 140,
            b = 40,
            attachments = { "muzzle", "core", "fork", "claw", "muzzle_flash" }
        },
        {
            class = "weapon_physgun",
            slug = "physgun",
            name = "Physics Gun",
            size = 48,
            brightness = 0.25,
            decay = 0,
            elight = 1,
            elightMult = 1.0,
            r = 70,
            g = 130,
            b = 255,
            attachments = { "muzzle", "fork", "muzzle_flash", "laser" }
        },
        {
            class = "weapon_medkit",
            slug = "medkit",
            name = "Medkit",
            size = 42,
            brightness = 0.22,
            decay = 0,
            elight = 1,
            elightMult = 1.0,
            r = 150,
            g = 255,
            b = 150,
            attachments = { "muzzle", "tip", "light", "glow" }
        },
        {
            class = "weapon_bugbait",
            slug = "bugbait",
            name = "Bugbait",
            size = 34,
            brightness = 0.12,
            decay = 0,
            elight = 1,
            elightMult = 1.0,
            r = 90,
            g = 170,
            b = 255,
            attachments = { "muzzle", "tip", "light", "glow" }
        },
        {
            class = "weapon_ar2",
            slug = "ar2",
            name = "Pulse Rifle",
            size = 38,
            brightness = 0.14,
            decay = 0,
            elight = 1,
            elightMult = 1.0,
            r = 255,
            g = 70,
            b = 55,
            attachments = { "muzzle", "muzzle_flash", "1", "laser" }
        },
        {
            class = "weapon_frag",
            slug = "frag",
            name = "Frag Grenade",
            size = 36,
            brightness = 0.2,
            decay = 0,
            elight = 1,
            elightMult = 1.0,
            r = 255,
            g = 40,
            b = 40,
            attachments = { "muzzle", "tip", "light", "glow" }
        }
    }

    for _, info in ipairs(WEAPONS) do
        local prefix = "betterlights_world_weapon_" .. info.slug
        info.cvar_enable = CreateClientConVar(prefix .. "_enable", "1", true, false, "Enable world weapon light for " .. info.name)
        info.cvar_size = CreateClientConVar(prefix .. "_size", tostring(info.size), true, false, "Dynamic light radius for world " .. info.name)
        info.cvar_brightness = CreateClientConVar(prefix .. "_brightness", tostring(info.brightness), true, false, "Dynamic light brightness for world " .. info.name)
        info.cvar_decay = CreateClientConVar(prefix .. "_decay", tostring(info.decay), true, false, "Dynamic light decay for world " .. info.name)
        info.cvar_models_elight = CreateClientConVar(prefix .. "_models_elight", tostring(info.elight), true, false, "Also add an entity light (elight) for world " .. info.name)
        info.cvar_models_elight_size_mult = CreateClientConVar(prefix .. "_models_elight_size_mult", tostring(info.elightMult), true, false, "Multiplier for world " .. info.name .. " elight radius")
        info.cvar_r = CreateClientConVar(prefix .. "_color_r", tostring(info.r), true, false, info.name .. " world weapon color - red (0-255)")
        info.cvar_g = CreateClientConVar(prefix .. "_color_g", tostring(info.g), true, false, info.name .. " world weapon color - green (0-255)")
        info.cvar_b = CreateClientConVar(prefix .. "_color_b", tostring(info.b), true, false, info.name .. " world weapon color - blue (0-255)")

        if BL.TrackClass then
            BL.TrackClass(info.class)
        end
    end

    function BL.GetWorldWeaponLightDefinitions()
        return WEAPONS
    end

    local function isWorldWeapon(ent)
        if not IsValid(ent) then return false end

        if ent.GetOwner and IsValid(ent:GetOwner()) then return false end
        if ent.GetParent and IsValid(ent:GetParent()) then return false end

        return true
    end

    local function getLightPosition(ent, info)
        local attachments = info.attachments
        local bones = info.bones
        local pos = BL.GetAttachmentPos and BL.GetAttachmentPos(ent, attachments)
        if pos then
            if info.offset then
                pos = pos + ent:LocalToWorld(info.offset) - ent:GetPos()
            end

            return pos
        end

        if BL.GetBonePosition and bones then
            for _, boneName in ipairs(bones) do
                pos = BL.GetBonePosition(ent, boneName)
                if pos then return pos end
            end
        end

        return BL.GetEntityCenter(ent)
    end

    local function updateWeapon(info)
        if not info.cvar_enable:GetBool() then return end

        local size = math.max(0, info.cvar_size:GetFloat())
        local brightness = math.max(0, info.cvar_brightness:GetFloat())
        local decay = math.max(0, info.cvar_decay:GetFloat())
        local doElight = info.cvar_models_elight:GetBool()
        local elMult = math.max(0, info.cvar_models_elight_size_mult:GetFloat())
        local r, g, b = BL.GetColorFromCvars(info.cvar_r, info.cvar_g, info.cvar_b)

        local function update(ent)
            if not isWorldWeapon(ent) then return end

            local pos = getLightPosition(ent, info)
            if not pos then return end

            local idx = ent:EntIndex() + 28000
            BL.CreateDLight(idx, pos, r, g, b, brightness, decay, size, false)

            if doElight then
                BL.CreateDLight(idx + 10000, pos, r, g, b, brightness, decay, size * elMult, true)
            end
        end

        if BL.ForEach then
            BL.ForEach(info.class, update)
        else
            for _, ent in ipairs(ents.FindByClass(info.class)) do
                update(ent)
            end
        end
    end

    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_WorldWeapons_DLight", function()
        for _, info in ipairs(WEAPONS) do
            updateWeapon(info)
        end
    end)
end
