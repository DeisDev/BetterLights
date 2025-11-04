-- BetterLights: Combine AR2 orb dynamic lighting
-- Client-side only

if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
    -- ConVars for tweaking
    local cvar_enable = CreateClientConVar("betterlights_combineball_enable", "1", true, false, "Enable dynamic light for Combine AR2 orb")
    local cvar_size = CreateClientConVar("betterlights_combineball_size", "320", true, false, "Dynamic light radius for Combine AR2 orb")
    local cvar_brightness = CreateClientConVar("betterlights_combineball_brightness", "2.5", true, false, "Dynamic light brightness for Combine AR2 orb")
    local cvar_decay = CreateClientConVar("betterlights_combineball_decay", "2000", true, false, "Dynamic light decay for Combine AR2 orb (higher = faster fade)")

    -- Performance and behavior controls
    local cvar_world_enable = CreateClientConVar("betterlights_combineball_world_light_enable", "1", true, false, "Enable world lighting (turn off to avoid lighting static world surfaces)")
    local cvar_models_enable = CreateClientConVar("betterlights_combineball_model_light_enable", "1", true, false, "Enable model lighting")
    local cvar_models_elight = CreateClientConVar("betterlights_combineball_models_elight", "0", true, false, "Also add an entity light (elight) for models (useful when world light is disabled)")
    local cvar_models_elight_size_mult = CreateClientConVar("betterlights_combineball_models_elight_size_mult", "1.0", true, false, "Multiplier for model elight radius")
    local cvar_update_hz = CreateClientConVar("betterlights_combineball_update_hz", "30", true, false, "Update rate in Hz (0 = every frame)")

    -- Color configuration
    local cvar_col_r = CreateClientConVar("betterlights_combineball_color_r", "80", true, false, "Combine ball color - red (0-255)")
    local cvar_col_g = CreateClientConVar("betterlights_combineball_color_g", "180", true, false, "Combine ball color - green (0-255)")
    local cvar_col_b = CreateClientConVar("betterlights_combineball_color_b", "255", true, false, "Combine ball color - blue (0-255)")
    local function getCombineBallColor()
        local r = math.Clamp(math.floor(cvar_col_r:GetFloat() + 0.5), 0, 255)
        local g = math.Clamp(math.floor(cvar_col_g:GetFloat() + 0.5), 0, 255)
        local b = math.Clamp(math.floor(cvar_col_b:GetFloat() + 0.5), 0, 255)
        return r, g, b
    end

    if BL.TrackClass then BL.TrackClass("prop_combine_ball") end

    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_CombineBall_DLight", function()
        if not cvar_enable:GetBool() then return end

        -- Optional throttling
        local hz = math.max(0, cvar_update_hz:GetFloat())
        if hz > 0 then
            local now = CurTime()
            BetterLights._cb_next = BetterLights._cb_next or 0
            if now < BetterLights._cb_next then return end
            BetterLights._cb_next = now + (1 / hz)
        end

        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())
        local wantWorld = cvar_world_enable:GetBool()
        local wantModels = cvar_models_enable:GetBool()
        local wantElight = cvar_models_elight:GetBool()
        local elMult = math.max(0, cvar_models_elight_size_mult:GetFloat())

        local function update(ent)
            if IsValid(ent) then
                local pos = ent:WorldSpaceCenter()
                local r, g, b = getCombineBallColor()

                -- World dynamic light: optionally also hits models (if wantModels)
                if wantWorld then
                    local dl = DynamicLight(ent:EntIndex())
                    if dl then
                        dl.pos = pos
                        dl.r = r
                        dl.g = g
                        dl.b = b
                        dl.brightness = brightness
                        dl.decay = decay
                        dl.size = size
                        dl.minlight = 0
                        dl.noworld = false
                        dl.nomodel = not wantModels -- world-only when models disabled
                        dl.dietime = CurTime() + 0.1
                    end
                end

                -- Model-only lighting when world is disabled, or if explicitly requested via elight
                if wantModels and (not wantWorld) then
                    if wantElight then
                        local el = DynamicLight(ent:EntIndex(), true)
                        if el then
                            el.pos = pos
                            el.r = r
                            el.g = g
                            el.b = b
                            el.brightness = brightness
                            el.decay = decay
                            el.size = size * elMult
                            el.minlight = 0
                            el.dietime = CurTime() + 0.1
                        end
                    else
                        -- If elight is disabled, use a dlight restricted to models-only
                        local dlm = DynamicLight(ent:EntIndex())
                        if dlm then
                            dlm.pos = pos
                            dlm.r = r
                            dlm.g = g
                            dlm.b = b
                            dlm.brightness = brightness
                            dlm.decay = decay
                            dlm.size = size
                            dlm.minlight = 0
                            dlm.noworld = true
                            dlm.nomodel = false
                            dlm.dietime = CurTime() + 0.1
                        end
                    end
                end
            
            end
        end

        if BL.ForEach then
            BL.ForEach("prop_combine_ball", update)
        else
            for _, ent in ipairs(ents.FindByClass("prop_combine_ball")) do update(ent) end
        end
    end)
end
