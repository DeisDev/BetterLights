if CLIENT then
    local BL = BetterLights

    local IsValid = IsValid
    local cvar_enable = BL.CreateClientConVar("betterlights_cscanner_enable", "1", true, false, "Enable dynamic light for Combine Scanners (npc_cscanner)")
    local cvar_size = BL.CreateClientConVar("betterlights_cscanner_size", "120", true, false, "Dynamic light radius for Combine Scanners")
    local cvar_brightness = BL.CreateClientConVar("betterlights_cscanner_brightness", "0.7", true, false, "Dynamic light brightness for Combine Scanners")
    local cvar_decay = BL.CreateClientConVar("betterlights_cscanner_decay", "2000", true, false, "Dynamic light decay for Combine Scanners")
    local cvar_models_elight = BL.CreateClientConVar("betterlights_cscanner_models_elight", "1", true, false, "Also add an entity light (elight) to light the scanner model directly")
    local cvar_models_elight_size_mult = BL.CreateClientConVar("betterlights_cscanner_models_elight_size_mult", "1.0", true, false, "Multiplier for scanner elight radius")

    local cvar_col_r = BL.CreateClientConVar("betterlights_cscanner_color_r", "180", true, false, "Scanner glow color - red (0-255)")
    local cvar_col_g = BL.CreateClientConVar("betterlights_cscanner_color_g", "230", true, false, "Scanner glow color - green (0-255)")
    local cvar_col_b = BL.CreateClientConVar("betterlights_cscanner_color_b", "255", true, false, "Scanner glow color - blue (0-255)")

    local cvar_sl_enable = BL.CreateClientConVar("betterlights_cscanner_searchlight_enable", "1", true, false, "Add a directional, shadow-casting searchlight to scanners")
    local cvar_sl_fov = BL.CreateClientConVar("betterlights_cscanner_searchlight_fov", "38", true, false, "Searchlight FOV (degrees)")
    local cvar_sl_far = BL.CreateClientConVar("betterlights_cscanner_searchlight_distance", "900", true, false, "Searchlight distance (FarZ)")
    local cvar_sl_near = BL.CreateClientConVar("betterlights_cscanner_searchlight_near", "8", true, false, "Searchlight near plane (NearZ)")
    local cvar_sl_brightness = BL.CreateClientConVar("betterlights_cscanner_searchlight_brightness", "0.7", true, false, "Searchlight brightness (0-1+)")
    local cvar_sl_shadows = BL.CreateClientConVar("betterlights_cscanner_searchlight_shadows", "1", true, false, "Enable shadow casting for the searchlight (expensive; engine limit ~8)")
    local cvar_sl_include_claw = BL.CreateClientConVar("betterlights_scanner_searchlight_include_clawscanner", "1", true, false, "Also attach searchlights to npc_clawscanner if present")

    local cvar_sl_r = BL.CreateClientConVar("betterlights_cscanner_searchlight_color_r", "255", true, false, "Scanner searchlight color - red (0-255)")
    local cvar_sl_g = BL.CreateClientConVar("betterlights_cscanner_searchlight_color_g", "255", true, false, "Scanner searchlight color - green (0-255)")
    local cvar_sl_b = BL.CreateClientConVar("betterlights_cscanner_searchlight_color_b", "255", true, false, "Scanner searchlight color - blue (0-255)")

    local scannerProjectors = {}

    BL.TrackClass("npc_cscanner")
    BL.TrackClass("npc_clawscanner")
    BL.AddThink("BetterLights_CScanner_DLight", function()
        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())
        local el_mult = math.max(0, cvar_models_elight_size_mult:GetFloat())
        local r, g, b = BL.GetColorFromCvars(cvar_col_r, cvar_col_g, cvar_col_b)
        local includeClaw = cvar_sl_include_claw:GetBool()
        local doGlow = cvar_enable:GetBool()
        local doModelsElight = cvar_models_elight:GetBool()

        local sl_enable = cvar_sl_enable:GetBool()
        local sl_near = math.max(0.1, cvar_sl_near:GetFloat())
        local sl_far = math.max(1, cvar_sl_far:GetFloat())
        local sl_fov = math.Clamp(cvar_sl_fov:GetFloat(), 1, 175)
        local sl_bright = cvar_sl_brightness:GetFloat()
        local sl_r, sl_g, sl_b = BL.GetColorFromCvars(cvar_sl_r, cvar_sl_g, cvar_sl_b)
        local sl_shadows = cvar_sl_shadows:GetBool()

        local seen = {}

        local function processScanner(ent)
            if not IsValid(ent) then return end
            seen[ent] = true
            local idx = ent:EntIndex()
            local pos = BL.GetEntityCenter(ent)

            if doGlow then
                BL.CreateDLight(idx, pos, r, g, b, brightness, decay, size, false)

                if doModelsElight then
                    BL.CreateDLight(idx, pos, r, g, b, brightness, decay, size * el_mult, true)
                end
            end

            if sl_enable then
                local lamp = BL.GetOrCreateProjectedTexture(scannerProjectors, ent, "effects/flashlight001")
                if not lamp then return end

                local origin = pos
                if ent.GetUp then
                    origin = origin - ent:GetUp() * 8
                else
                    origin = origin + Vector(0, 0, -8)
                end
                local forward = ent.GetForward and ent:GetForward() or Vector(1, 0, 0)
                local target = origin + forward * 100 + Vector(0, 0, -80)

                BL.UpdateProjectedTexture(lamp, {
                    pos = origin,
                    ang = (target - origin):Angle(),
                    nearZ = sl_near,
                    farZ = sl_far,
                    fov = sl_fov,
                    brightness = sl_bright,
                    color = Color(sl_r, sl_g, sl_b),
                    shadows = sl_shadows
                })
            end
        end

        BL.ForEach("npc_cscanner", processScanner)
        if includeClaw then
            BL.ForEach("npc_clawscanner", processScanner)
        end

        BL.RemoveStaleProjectedTextures(scannerProjectors, seen, function(ent)
            return (not sl_enable) or (not IsValid(ent))
        end)
    end)
end
