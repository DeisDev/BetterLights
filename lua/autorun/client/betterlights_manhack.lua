-- BetterLights: Manhack (npc_manhack) glow
-- Client-side only

if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
    -- Localize hot globals
    local CurTime = CurTime
    local IsValid = IsValid
    local DynamicLight = DynamicLight
    local cvar_enable = CreateClientConVar("betterlights_manhack_enable", "1", true, false, "Enable dynamic light for Manhacks (npc_manhack)")
    local cvar_size = CreateClientConVar("betterlights_manhack_size", "70", true, false, "Dynamic light radius for Manhacks")
    local cvar_brightness = CreateClientConVar("betterlights_manhack_brightness", "0.6", true, false, "Dynamic light brightness for Manhacks")
    local cvar_decay = CreateClientConVar("betterlights_manhack_decay", "2000", true, false, "Dynamic light decay for Manhacks")
    local cvar_models_elight = CreateClientConVar("betterlights_manhack_models_elight", "1", true, false, "Also add an entity light (elight) to light the Manhack model directly")
    local cvar_models_elight_size_mult = CreateClientConVar("betterlights_manhack_models_elight_size_mult", "1.0", true, false, "Multiplier for Manhack elight radius")

    -- Color configuration
    local cvar_col_r = CreateClientConVar("betterlights_manhack_color_r", "255", true, false, "Manhack color - red (0-255)")
    local cvar_col_g = CreateClientConVar("betterlights_manhack_color_g", "60", true, false, "Manhack color - green (0-255)")
    local cvar_col_b = CreateClientConVar("betterlights_manhack_color_b", "60", true, false, "Manhack color - blue (0-255)")
    local function getColor()
        return math.Clamp(math.floor(cvar_col_r:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_col_g:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_col_b:GetFloat() + 0.5), 0, 255)
    end

    if BL.TrackClass then BL.TrackClass("npc_manhack") end

    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_Manhack_DLight", function()
        if not cvar_enable:GetBool() then return end

        local r, g, b = getColor()
        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())

        local function update(ent)
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

                if cvar_models_elight:GetBool() then
                    local el = DynamicLight(idx, true)
                    if el then
                        el.pos = pos
                        el.r = r
                        el.g = g
                        el.b = b
                        el.brightness = brightness
                        el.decay = decay
                        el.size = size * math.max(0, cvar_models_elight_size_mult:GetFloat())
                        el.minlight = 0
                        el.dietime = CurTime() + 0.1
                    end
                end
            end
        end

        if BL.ForEach then
            BL.ForEach("npc_manhack", update)
        else
            for _, ent in ipairs(ents.FindByClass("npc_manhack")) do update(ent) end
        end
    end)
end
