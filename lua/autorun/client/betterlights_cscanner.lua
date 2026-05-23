if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights

    local CurTime = CurTime
    local IsValid = IsValid
    local cvar_enable = CreateClientConVar("betterlights_cscanner_enable", "1", true, false, "Enable dynamic light for Combine Scanners (npc_cscanner)")
    local cvar_size = CreateClientConVar("betterlights_cscanner_size", "120", true, false, "Dynamic light radius for Combine Scanners")
    local cvar_brightness = CreateClientConVar("betterlights_cscanner_brightness", "0.7", true, false, "Dynamic light brightness for Combine Scanners")
    local cvar_decay = CreateClientConVar("betterlights_cscanner_decay", "2000", true, false, "Dynamic light decay for Combine Scanners")
    local cvar_models_elight = CreateClientConVar("betterlights_cscanner_models_elight", "1", true, false, "Also add an entity light (elight) to light the scanner model directly")
    local cvar_models_elight_size_mult = CreateClientConVar("betterlights_cscanner_models_elight_size_mult", "1.0", true, false, "Multiplier for scanner elight radius")

    local cvar_col_r = CreateClientConVar("betterlights_cscanner_color_r", "180", true, false, "Scanner glow color - red (0-255)")
    local cvar_col_g = CreateClientConVar("betterlights_cscanner_color_g", "230", true, false, "Scanner glow color - green (0-255)")
    local cvar_col_b = CreateClientConVar("betterlights_cscanner_color_b", "255", true, false, "Scanner glow color - blue (0-255)")

    local cvar_sl_enable = CreateClientConVar("betterlights_cscanner_searchlight_enable", "1", true, false, "Add a directional, shadow-casting searchlight to scanners")
    local cvar_sl_fov = CreateClientConVar("betterlights_cscanner_searchlight_fov", "38", true, false, "Searchlight FOV (degrees)")
    local cvar_sl_far = CreateClientConVar("betterlights_cscanner_searchlight_distance", "900", true, false, "Searchlight distance (FarZ)")
    local cvar_sl_near = CreateClientConVar("betterlights_cscanner_searchlight_near", "8", true, false, "Searchlight near plane (NearZ)")
    local cvar_sl_brightness = CreateClientConVar("betterlights_cscanner_searchlight_brightness", "0.7", true, false, "Searchlight brightness (0-1+)")
    local cvar_sl_shadows = CreateClientConVar("betterlights_cscanner_searchlight_shadows", "1", true, false, "Enable shadow casting for the searchlight (expensive; engine limit ~8)")
    local cvar_sl_include_claw = CreateClientConVar("betterlights_scanner_searchlight_include_clawscanner", "1", true, false, "Also attach searchlights to npc_clawscanner if present")

    local cvar_sl_r = CreateClientConVar("betterlights_cscanner_searchlight_color_r", "255", true, false, "Scanner searchlight color - red (0-255)")
    local cvar_sl_g = CreateClientConVar("betterlights_cscanner_searchlight_color_g", "255", true, false, "Scanner searchlight color - green (0-255)")
    local cvar_sl_b = CreateClientConVar("betterlights_cscanner_searchlight_color_b", "255", true, false, "Scanner searchlight color - blue (0-255)")

    local scannerProjectors = {}

    if BL.TrackClass then
        BL.TrackClass("npc_cscanner")
        if GetConVar and GetConVar("betterlights_scanner_searchlight_include_clawscanner") then
            BL.TrackClass("npc_clawscanner")
        end
    end

    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_CScanner_DLight", function()
        local now = CurTime()

        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())
        local el_mult = math.max(0, cvar_models_elight_size_mult:GetFloat())
        local r, g, b = BL.GetColorFromCvars(cvar_col_r, cvar_col_g, cvar_col_b)
        local dietime = now + 0.1
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
                local lamp = scannerProjectors[ent]
                if not lamp or not lamp:IsValid() then
                    lamp = ProjectedTexture()
                    if lamp then
                        lamp:SetTexture("effects/flashlight001")
                        scannerProjectors[ent] = lamp
                    end
                end
                if lamp and lamp:IsValid() then
                    local origin = pos
                    if ent.GetUp then
                        origin = origin - ent:GetUp() * 8
                    else
                        origin = origin + Vector(0, 0, -8)
                    end
                    local forward = ent.GetForward and ent:GetForward() or Vector(1, 0, 0)
                    local target = origin + forward * 100 + Vector(0, 0, -80)
                    local ang = (target - origin):Angle()

                    lamp:SetPos(origin)
                    lamp:SetAngles(ang)
                    lamp:SetNearZ(sl_near)
                    lamp:SetFarZ(sl_far)
                    lamp:SetFOV(sl_fov)
                    lamp:SetBrightness(sl_bright)
                    lamp:SetColor(Color(sl_r, sl_g, sl_b))
                    lamp:SetEnableShadows(sl_shadows)
                    lamp:Update()
                end
            end
        end
        
        if BL.ForEach then
            BL.ForEach("npc_cscanner", processScanner)
            if includeClaw then
                BL.ForEach("npc_clawscanner", processScanner)
            end
        else
            for _, ent in ipairs(ents.FindByClass("npc_cscanner") or {}) do
                processScanner(ent)
            end
            if includeClaw then
                for _, ent in ipairs(ents.FindByClass("npc_clawscanner") or {}) do
                    processScanner(ent)
                end
            end
        end

        for ent, lamp in pairs(scannerProjectors) do
            local removeIt = (not sl_enable) or (not IsValid(ent)) or (not seen[ent])
            if removeIt then
                if lamp and lamp.IsValid and lamp:IsValid() then lamp:Remove() end
                scannerProjectors[ent] = nil
            end
        end
    end)
end
