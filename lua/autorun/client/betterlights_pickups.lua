-- BetterLights: Pickup items subtle glow
-- Covers: item_ammo_ar2_altfire, item_battery, item_healthvial, item_healthkit
-- Client-side only

if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
    
    -- AR2 alt-fire ammo (Combine ball ammo) — yellow per feedback; RGB override supported
    local ar2_cvar_enable = CreateClientConVar("betterlights_item_ar2alt_enable", "1", true, false, "Enable dynamic light for item_ammo_ar2_altfire")
    local ar2_cvar_size = CreateClientConVar("betterlights_item_ar2alt_size", "60", true, false, "Dynamic light radius for item_ammo_ar2_altfire")
    local ar2_cvar_brightness = CreateClientConVar("betterlights_item_ar2alt_brightness", "0.25", true, false, "Dynamic light brightness for item_ammo_ar2_altfire")
    local ar2_cvar_decay = CreateClientConVar("betterlights_item_ar2alt_decay", "1800", true, false, "Dynamic light decay for item_ammo_ar2_altfire")
    local ar2_cvar_elight = CreateClientConVar("betterlights_item_ar2alt_models_elight", "1", true, false, "Also add an entity light (elight) for item_ammo_ar2_altfire")
    local ar2_cvar_elight_mult = CreateClientConVar("betterlights_item_ar2alt_models_elight_size_mult", "1.0", true, false, "Multiplier for item_ammo_ar2_altfire elight radius")
    local ar2_r = CreateClientConVar("betterlights_item_ar2alt_color_r", "255", true, false, "AR2 alt ammo color - red (0-255)")
    local ar2_g = CreateClientConVar("betterlights_item_ar2alt_color_g", "220", true, false, "AR2 alt ammo color - green (0-255)")
    local ar2_b = CreateClientConVar("betterlights_item_ar2alt_color_b", "60", true, false, "AR2 alt ammo color - blue (0-255)")

    -- Battery — blue per feedback; RGB override supported
    local bat_cvar_enable = CreateClientConVar("betterlights_item_battery_enable", "1", true, false, "Enable dynamic light for item_battery")
    local bat_cvar_size = CreateClientConVar("betterlights_item_battery_size", "55", true, false, "Dynamic light radius for item_battery")
    local bat_cvar_brightness = CreateClientConVar("betterlights_item_battery_brightness", "0.2", true, false, "Dynamic light brightness for item_battery")
    local bat_cvar_decay = CreateClientConVar("betterlights_item_battery_decay", "1800", true, false, "Dynamic light decay for item_battery")
    local bat_cvar_elight = CreateClientConVar("betterlights_item_battery_models_elight", "1", true, false, "Also add an entity light (elight) for item_battery")
    local bat_cvar_elight_mult = CreateClientConVar("betterlights_item_battery_models_elight_size_mult", "1.0", true, false, "Multiplier for item_battery elight radius")
    local bat_r = CreateClientConVar("betterlights_item_battery_color_r", "110", true, false, "Battery color - red (0-255)")
    local bat_g = CreateClientConVar("betterlights_item_battery_color_g", "190", true, false, "Battery color - green (0-255)")
    local bat_b = CreateClientConVar("betterlights_item_battery_color_b", "255", true, false, "Battery color - blue (0-255)")

    -- Health vial — soft green
    local vial_cvar_enable = CreateClientConVar("betterlights_item_healthvial_enable", "1", true, false, "Enable dynamic light for item_healthvial")
    local vial_cvar_size = CreateClientConVar("betterlights_item_healthvial_size", "45", true, false, "Dynamic light radius for item_healthvial")
    local vial_cvar_brightness = CreateClientConVar("betterlights_item_healthvial_brightness", "0.18", true, false, "Dynamic light brightness for item_healthvial")
    local vial_cvar_decay = CreateClientConVar("betterlights_item_healthvial_decay", "1800", true, false, "Dynamic light decay for item_healthvial")
    local vial_cvar_elight = CreateClientConVar("betterlights_item_healthvial_models_elight", "1", true, false, "Also add an entity light (elight) for item_healthvial")
    local vial_cvar_elight_mult = CreateClientConVar("betterlights_item_healthvial_models_elight_size_mult", "1.0", true, false, "Multiplier for item_healthvial elight radius")
    local vial_r = CreateClientConVar("betterlights_item_healthvial_color_r", "150", true, false, "Health vial color - red (0-255)")
    local vial_g = CreateClientConVar("betterlights_item_healthvial_color_g", "255", true, false, "Health vial color - green (0-255)")
    local vial_b = CreateClientConVar("betterlights_item_healthvial_color_b", "150", true, false, "Health vial color - blue (0-255)")

    -- Health kit — soft green per feedback; RGB override supported
    local kit_cvar_enable = CreateClientConVar("betterlights_item_healthkit_enable", "1", true, false, "Enable dynamic light for item_healthkit")
    local kit_cvar_size = CreateClientConVar("betterlights_item_healthkit_size", "55", true, false, "Dynamic light radius for item_healthkit")
    local kit_cvar_brightness = CreateClientConVar("betterlights_item_healthkit_brightness", "0.2", true, false, "Dynamic light brightness for item_healthkit")
    local kit_cvar_decay = CreateClientConVar("betterlights_item_healthkit_decay", "1800", true, false, "Dynamic light decay for item_healthkit")
    local kit_cvar_elight = CreateClientConVar("betterlights_item_healthkit_models_elight", "1", true, false, "Also add an entity light (elight) for item_healthkit")
    local kit_cvar_elight_mult = CreateClientConVar("betterlights_item_healthkit_models_elight_size_mult", "1.0", true, false, "Multiplier for item_healthkit elight radius")
    local kit_r = CreateClientConVar("betterlights_item_healthkit_color_r", "150", true, false, "Health kit color - red (0-255)")
    local kit_g = CreateClientConVar("betterlights_item_healthkit_color_g", "255", true, false, "Health kit color - green (0-255)")
    local kit_b = CreateClientConVar("betterlights_item_healthkit_color_b", "150", true, false, "Health kit color - blue (0-255)")

    -- Track entity classes at module load for efficiency
    if BL.TrackClass then
        BL.TrackClass("item_ammo_ar2_altfire")
        BL.TrackClass("item_battery")
        BL.TrackClass("item_healthvial")
        BL.TrackClass("item_healthkit")
    end

    local function processClass(class, r_cvar, g_cvar, b_cvar, c_en, c_size, c_bright, c_decay, c_elight, c_el_mult)
        if not c_en:GetBool() then return end
        
        local size = math.max(0, c_size:GetFloat())
        local brightness = math.max(0, c_bright:GetFloat())
        local decay = math.max(0, c_decay:GetFloat())
        local el_mult = math.max(0, c_el_mult:GetFloat())
        local doElight = c_elight:GetBool()
        
        -- Cache color once per class per frame
        local r, g, b = BL.GetColorFromCvars(r_cvar, g_cvar, b_cvar)
        
        local function update(ent)
            if not IsValid(ent) then return end
            local idx = ent:EntIndex()
            local pos = BL.GetEntityCenter(ent)
            if pos then
                -- Create world light
                BL.CreateDLight(idx, pos, r, g, b, brightness, decay, size, false)
                
                -- Create entity light if enabled
                if doElight then
                    BL.CreateDLight(idx, pos, r, g, b, brightness, decay, size * el_mult, true)
                end
            end
        end
        
        if BL.ForEach then
            BL.ForEach(class, update)
        else
            local list = ents.FindByClass(class)
            if list then
                for _, ent in ipairs(list) do update(ent) end
            end
        end
    end

    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_Pickups_DLight", function()
        processClass("item_ammo_ar2_altfire", ar2_r, ar2_g, ar2_b, ar2_cvar_enable, ar2_cvar_size, ar2_cvar_brightness, ar2_cvar_decay, ar2_cvar_elight, ar2_cvar_elight_mult)
        processClass("item_battery", bat_r, bat_g, bat_b, bat_cvar_enable, bat_cvar_size, bat_cvar_brightness, bat_cvar_decay, bat_cvar_elight, bat_cvar_elight_mult)
        processClass("item_healthvial", vial_r, vial_g, vial_b, vial_cvar_enable, vial_cvar_size, vial_cvar_brightness, vial_cvar_decay, vial_cvar_elight, vial_cvar_elight_mult)
        processClass("item_healthkit", kit_r, kit_g, kit_b, kit_cvar_enable, kit_cvar_size, kit_cvar_brightness, kit_cvar_decay, kit_cvar_elight, kit_cvar_elight_mult)
    end)
end
