-- BetterLights: Suit/Health Chargers ambient glows
-- Client-side only

if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
    -- Suit charger (orange)
    local sc_enable = CreateClientConVar("betterlights_suitcharger_enable", "1", true, false, "Enable glow for item_suitcharger")
    local sc_size = CreateClientConVar("betterlights_suitcharger_size", "75", true, false, "Glow radius for item_suitcharger")
    local sc_bright = CreateClientConVar("betterlights_suitcharger_brightness", "0.25", true, false, "Glow brightness for item_suitcharger")
    local sc_decay = CreateClientConVar("betterlights_suitcharger_decay", "1800", true, false, "Glow decay for item_suitcharger")
    local sc_elight = CreateClientConVar("betterlights_suitcharger_models_elight", "1", true, false, "Add elight to light the charger model")
    local sc_elmult = CreateClientConVar("betterlights_suitcharger_models_elight_size_mult", "1.0", true, false, "Elight radius multiplier for item_suitcharger")
    local sc_r = CreateClientConVar("betterlights_suitcharger_color_r", "255", true, false, "Suit charger color - red (0-255)")
    local sc_g = CreateClientConVar("betterlights_suitcharger_color_g", "180", true, false, "Suit charger color - green (0-255)")
    local sc_b = CreateClientConVar("betterlights_suitcharger_color_b", "80", true, false, "Suit charger color - blue (0-255)")

    -- Health charger (blue)
    local hc_enable = CreateClientConVar("betterlights_healthcharger_enable", "1", true, false, "Enable glow for item_healthcharger")
    local hc_size = CreateClientConVar("betterlights_healthcharger_size", "75", true, false, "Glow radius for item_healthcharger")
    local hc_bright = CreateClientConVar("betterlights_healthcharger_brightness", "0.25", true, false, "Glow brightness for item_healthcharger")
    local hc_decay = CreateClientConVar("betterlights_healthcharger_decay", "1800", true, false, "Glow decay for item_healthcharger")
    local hc_elight = CreateClientConVar("betterlights_healthcharger_models_elight", "1", true, false, "Add elight to light the charger model")
    local hc_elmult = CreateClientConVar("betterlights_healthcharger_models_elight_size_mult", "1.0", true, false, "Elight radius multiplier for item_healthcharger")
    local hc_r = CreateClientConVar("betterlights_healthcharger_color_r", "110", true, false, "Health charger color - red (0-255)")
    local hc_g = CreateClientConVar("betterlights_healthcharger_color_g", "190", true, false, "Health charger color - green (0-255)")
    local hc_b = CreateClientConVar("betterlights_healthcharger_color_b", "255", true, false, "Health charger color - blue (0-255)")

    local function readRGB(r, g, b)
        local cr = math.Clamp(math.floor(r:GetFloat() + 0.5), 0, 255)
        local cg = math.Clamp(math.floor(g:GetFloat() + 0.5), 0, 255)
        local cb = math.Clamp(math.floor(b:GetFloat() + 0.5), 0, 255)
        return cr, cg, cb
    end

    local function process(class, en, sz, br, de, el, elmult, rcv, gcv, bcv)
        if not en:GetBool() then return end
        local list
        if BL.ForEach then
            list = {}
            BL.TrackClass(class)
            BL.ForEach(class, function(e) table.insert(list, e) end)
            if #list == 0 then return end
        else
            list = ents.FindByClass(class)
            if not list or #list == 0 then return end
        end
        local size = math.max(0, sz:GetFloat())
        local brightness = math.max(0, br:GetFloat())
        local decay = math.max(0, de:GetFloat())
        local el_mult = math.max(0, elmult:GetFloat())
        local cr, cg, cb = readRGB(rcv, gcv, bcv)
        for _, ent in ipairs(list) do
            if IsValid(ent) then
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
                    d.r = cr
                    d.g = cg
                    d.b = cb
                    d.brightness = brightness
                    d.decay = decay
                    d.size = size
                    d.minlight = 0
                    d.noworld = false
                    d.nomodel = false
                    d.dietime = CurTime() + 0.1
                end

                if el:GetBool() then
                    local elx = DynamicLight(idx, true)
                    if elx then
                        elx.pos = pos
                        elx.r = cr
                        elx.g = cg
                        elx.b = cb
                        elx.brightness = brightness
                        elx.decay = decay
                        elx.size = size * el_mult
                        elx.minlight = 0
                        elx.dietime = CurTime() + 0.1
                    end
                end
            end
        end
    end

    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_Chargers_DLight", function()
        process("item_suitcharger", sc_enable, sc_size, sc_bright, sc_decay, sc_elight, sc_elmult, sc_r, sc_g, sc_b)
        process("item_healthcharger", hc_enable, hc_size, hc_bright, hc_decay, hc_elight, hc_elmult, hc_r, hc_g, hc_b)
    end)
end
