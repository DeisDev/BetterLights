-- BetterLights: Pickup items subtle glow
-- Covers: item_ammo_ar2_altfire, item_battery, item_healthvial, item_healthkit
-- Client-side only

if CLIENT then
    -- AR2 alt-fire ammo (Combine ball ammo) — yellow per feedback; RGB override supported
    local ar2_cvar_enable = CreateClientConVar("betterlights_item_ar2alt_enable", "1", true, false, "Enable dynamic light for item_ammo_ar2_altfire")
    local ar2_cvar_size = CreateClientConVar("betterlights_item_ar2alt_size", "60", true, false, "Dynamic light radius for item_ammo_ar2_altfire")
    local ar2_cvar_brightness = CreateClientConVar("betterlights_item_ar2alt_brightness", "0.25", true, false, "Dynamic light brightness for item_ammo_ar2_altfire")
    local ar2_cvar_decay = CreateClientConVar("betterlights_item_ar2alt_decay", "1800", true, false, "Dynamic light decay for item_ammo_ar2_altfire")
    local ar2_cvar_elight = CreateClientConVar("betterlights_item_ar2alt_models_elight", "1", true, false, "Also add an entity light (elight) for item_ammo_ar2_altfire")
    local ar2_cvar_elight_mult = CreateClientConVar("betterlights_item_ar2alt_models_elight_size_mult", "1.0", true, false, "Multiplier for item_ammo_ar2_altfire elight radius")
    local ar2_update_hz = CreateClientConVar("betterlights_item_ar2alt_update_hz", "20", true, false, "Update rate in Hz (15-120)")
    local ar2_r = CreateClientConVar("betterlights_item_ar2alt_color_r", "255", true, false, "AR2 alt ammo color - red (0-255)")
    local ar2_g = CreateClientConVar("betterlights_item_ar2alt_color_g", "220", true, false, "AR2 alt ammo color - green (0-255)")
    local ar2_b = CreateClientConVar("betterlights_item_ar2alt_color_b", "60", true, false, "AR2 alt ammo color - blue (0-255)")
    local function AR2C()
        return {
            r = math.Clamp(math.floor(ar2_r:GetFloat() + 0.5), 0, 255),
            g = math.Clamp(math.floor(ar2_g:GetFloat() + 0.5), 0, 255),
            b = math.Clamp(math.floor(ar2_b:GetFloat() + 0.5), 0, 255),
        }
    end

    -- Battery — blue per feedback; RGB override supported
    local bat_cvar_enable = CreateClientConVar("betterlights_item_battery_enable", "1", true, false, "Enable dynamic light for item_battery")
    local bat_cvar_size = CreateClientConVar("betterlights_item_battery_size", "55", true, false, "Dynamic light radius for item_battery")
    local bat_cvar_brightness = CreateClientConVar("betterlights_item_battery_brightness", "0.2", true, false, "Dynamic light brightness for item_battery")
    local bat_cvar_decay = CreateClientConVar("betterlights_item_battery_decay", "1800", true, false, "Dynamic light decay for item_battery")
    local bat_cvar_elight = CreateClientConVar("betterlights_item_battery_models_elight", "1", true, false, "Also add an entity light (elight) for item_battery")
    local bat_cvar_elight_mult = CreateClientConVar("betterlights_item_battery_models_elight_size_mult", "1.0", true, false, "Multiplier for item_battery elight radius")
    local bat_update_hz = CreateClientConVar("betterlights_item_battery_update_hz", "20", true, false, "Update rate in Hz (15-120)")
    local bat_r = CreateClientConVar("betterlights_item_battery_color_r", "110", true, false, "Battery color - red (0-255)")
    local bat_g = CreateClientConVar("betterlights_item_battery_color_g", "190", true, false, "Battery color - green (0-255)")
    local bat_b = CreateClientConVar("betterlights_item_battery_color_b", "255", true, false, "Battery color - blue (0-255)")
    local function BATR()
        return {
            r = math.Clamp(math.floor(bat_r:GetFloat() + 0.5), 0, 255),
            g = math.Clamp(math.floor(bat_g:GetFloat() + 0.5), 0, 255),
            b = math.Clamp(math.floor(bat_b:GetFloat() + 0.5), 0, 255),
        }
    end

    -- Health vial — soft green
    local vial_cvar_enable = CreateClientConVar("betterlights_item_healthvial_enable", "1", true, false, "Enable dynamic light for item_healthvial")
    local vial_cvar_size = CreateClientConVar("betterlights_item_healthvial_size", "45", true, false, "Dynamic light radius for item_healthvial")
    local vial_cvar_brightness = CreateClientConVar("betterlights_item_healthvial_brightness", "0.18", true, false, "Dynamic light brightness for item_healthvial")
    local vial_cvar_decay = CreateClientConVar("betterlights_item_healthvial_decay", "1800", true, false, "Dynamic light decay for item_healthvial")
    local vial_cvar_elight = CreateClientConVar("betterlights_item_healthvial_models_elight", "1", true, false, "Also add an entity light (elight) for item_healthvial")
    local vial_cvar_elight_mult = CreateClientConVar("betterlights_item_healthvial_models_elight_size_mult", "1.0", true, false, "Multiplier for item_healthvial elight radius")
    local vial_update_hz = CreateClientConVar("betterlights_item_healthvial_update_hz", "20", true, false, "Update rate in Hz (15-120)")
    local vial_r = CreateClientConVar("betterlights_item_healthvial_color_r", "150", true, false, "Health vial color - red (0-255)")
    local vial_g = CreateClientConVar("betterlights_item_healthvial_color_g", "255", true, false, "Health vial color - green (0-255)")
    local vial_b = CreateClientConVar("betterlights_item_healthvial_color_b", "150", true, false, "Health vial color - blue (0-255)")
    local function VIAL()
        return {
            r = math.Clamp(math.floor(vial_r:GetFloat() + 0.5), 0, 255),
            g = math.Clamp(math.floor(vial_g:GetFloat() + 0.5), 0, 255),
            b = math.Clamp(math.floor(vial_b:GetFloat() + 0.5), 0, 255),
        }
    end

    -- Health kit — soft green per feedback; RGB override supported
    local kit_cvar_enable = CreateClientConVar("betterlights_item_healthkit_enable", "1", true, false, "Enable dynamic light for item_healthkit")
    local kit_cvar_size = CreateClientConVar("betterlights_item_healthkit_size", "55", true, false, "Dynamic light radius for item_healthkit")
    local kit_cvar_brightness = CreateClientConVar("betterlights_item_healthkit_brightness", "0.2", true, false, "Dynamic light brightness for item_healthkit")
    local kit_cvar_decay = CreateClientConVar("betterlights_item_healthkit_decay", "1800", true, false, "Dynamic light decay for item_healthkit")
    local kit_cvar_elight = CreateClientConVar("betterlights_item_healthkit_models_elight", "1", true, false, "Also add an entity light (elight) for item_healthkit")
    local kit_cvar_elight_mult = CreateClientConVar("betterlights_item_healthkit_models_elight_size_mult", "1.0", true, false, "Multiplier for item_healthkit elight radius")
    local kit_update_hz = CreateClientConVar("betterlights_item_healthkit_update_hz", "20", true, false, "Update rate in Hz (15-120)")
    local kit_r = CreateClientConVar("betterlights_item_healthkit_color_r", "150", true, false, "Health kit color - red (0-255)")
    local kit_g = CreateClientConVar("betterlights_item_healthkit_color_g", "255", true, false, "Health kit color - green (0-255)")
    local kit_b = CreateClientConVar("betterlights_item_healthkit_color_b", "150", true, false, "Health kit color - blue (0-255)")
    local function KIT()
        return {
            r = math.Clamp(math.floor(kit_r:GetFloat() + 0.5), 0, 255),
            g = math.Clamp(math.floor(kit_g:GetFloat() + 0.5), 0, 255),
            b = math.Clamp(math.floor(kit_b:GetFloat() + 0.5), 0, 255),
        }
    end

    local function processClass(class, colFn, c_en, c_size, c_bright, c_decay, c_elight, c_el_mult)
        if not c_en:GetBool() then return end
        local list = ents.FindByClass(class)
        if not list or #list == 0 then return end
        local size = math.max(0, c_size:GetFloat())
        local brightness = math.max(0, c_bright:GetFloat())
        local decay = math.max(0, c_decay:GetFloat())
        local el_mult = math.max(0, c_el_mult:GetFloat())
        for _, ent in ipairs(list) do
            if IsValid(ent) then
                local col = colFn()
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
                    d.r = col.r
                    d.g = col.g
                    d.b = col.b
                    d.brightness = brightness
                    d.decay = decay
                    d.size = size
                    d.minlight = 0
                    d.noworld = false
                    d.nomodel = false
                    d.dietime = CurTime() + 0.1
                end

                if c_elight:GetBool() then
                    local el = DynamicLight(idx, true)
                    if el then
                        el.pos = pos
                        el.r = col.r
                        el.g = col.g
                        el.b = col.b
                        el.brightness = brightness
                        el.decay = decay
                        el.size = size * el_mult
                        el.minlight = 0
                        el.dietime = CurTime() + 0.1
                    end
                end
            end
        end
    end

    hook.Add("Think", "BetterLights_Pickups_DLight", function()
        -- Throttle by the lowest of the active pickup rates
        local hz = 120
        if ar2_cvar_enable:GetBool() then hz = math.min(hz, math.Clamp(ar2_update_hz:GetFloat(), 15, 120)) end
        if bat_cvar_enable:GetBool() then hz = math.min(hz, math.Clamp(bat_update_hz:GetFloat(), 15, 120)) end
        if vial_cvar_enable:GetBool() then hz = math.min(hz, math.Clamp(vial_update_hz:GetFloat(), 15, 120)) end
        if kit_cvar_enable:GetBool() then hz = math.min(hz, math.Clamp(kit_update_hz:GetFloat(), 15, 120)) end
        BetterLights = BetterLights or {}
        BetterLights._nextTick = BetterLights._nextTick or {}
        local now = CurTime()
        local key = "Pickups_DLight"
        local nxt = BetterLights._nextTick[key] or 0
        if now < nxt then return end
        BetterLights._nextTick[key] = now + (1 / hz)
        processClass("item_ammo_ar2_altfire", AR2C, ar2_cvar_enable, ar2_cvar_size, ar2_cvar_brightness, ar2_cvar_decay, ar2_cvar_elight, ar2_cvar_elight_mult)
        processClass("item_battery", BATR, bat_cvar_enable, bat_cvar_size, bat_cvar_brightness, bat_cvar_decay, bat_cvar_elight, bat_cvar_elight_mult)
        processClass("item_healthvial", VIAL, vial_cvar_enable, vial_cvar_size, vial_cvar_brightness, vial_cvar_decay, vial_cvar_elight, vial_cvar_elight_mult)
        processClass("item_healthkit", KIT, kit_cvar_enable, kit_cvar_size, kit_cvar_brightness, kit_cvar_decay, kit_cvar_elight, kit_cvar_elight_mult)
    end)
end
