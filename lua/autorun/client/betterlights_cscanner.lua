-- BetterLights: Combine Scanner (npc_cscanner) glow
-- Client-side only

if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
    local cvar_enable = CreateClientConVar("betterlights_cscanner_enable", "1", true, false, "Enable dynamic light for Combine Scanners (npc_cscanner)")
    local cvar_size = CreateClientConVar("betterlights_cscanner_size", "120", true, false, "Dynamic light radius for Combine Scanners")
    local cvar_brightness = CreateClientConVar("betterlights_cscanner_brightness", "0.7", true, false, "Dynamic light brightness for Combine Scanners")
    local cvar_decay = CreateClientConVar("betterlights_cscanner_decay", "2000", true, false, "Dynamic light decay for Combine Scanners")
    local cvar_models_elight = CreateClientConVar("betterlights_cscanner_models_elight", "1", true, false, "Also add an entity light (elight) to light the scanner model directly")
    local cvar_models_elight_size_mult = CreateClientConVar("betterlights_cscanner_models_elight_size_mult", "1.0", true, false, "Multiplier for scanner elight radius")
    local cvar_update_hz = CreateClientConVar("betterlights_cscanner_update_hz", "30", true, false, "Update rate in Hz (15-120)")

    -- Glow color configuration
    local cvar_col_r = CreateClientConVar("betterlights_cscanner_color_r", "180", true, false, "Scanner glow color - red (0-255)")
    local cvar_col_g = CreateClientConVar("betterlights_cscanner_color_g", "230", true, false, "Scanner glow color - green (0-255)")
    local cvar_col_b = CreateClientConVar("betterlights_cscanner_color_b", "255", true, false, "Scanner glow color - blue (0-255)")
    local function getGlowColor()
        return math.Clamp(math.floor(cvar_col_r:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_col_g:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_col_b:GetFloat() + 0.5), 0, 255)
    end

    -- Directional searchlight (projected texture) settings
    local cvar_sl_enable = CreateClientConVar("betterlights_cscanner_searchlight_enable", "1", true, false, "Add a directional, shadow-casting searchlight to scanners")
    local cvar_sl_fov = CreateClientConVar("betterlights_cscanner_searchlight_fov", "38", true, false, "Searchlight FOV (degrees)")
    local cvar_sl_far = CreateClientConVar("betterlights_cscanner_searchlight_distance", "900", true, false, "Searchlight distance (FarZ)")
    local cvar_sl_near = CreateClientConVar("betterlights_cscanner_searchlight_near", "8", true, false, "Searchlight near plane (NearZ)")
    local cvar_sl_brightness = CreateClientConVar("betterlights_cscanner_searchlight_brightness", "0.7", true, false, "Searchlight brightness (0-1+)")
    local cvar_sl_shadows = CreateClientConVar("betterlights_cscanner_searchlight_shadows", "1", true, false, "Enable shadow casting for the searchlight (expensive; engine limit ~8)")
    local cvar_sl_include_claw = CreateClientConVar("betterlights_scanner_searchlight_include_clawscanner", "1", true, false, "Also attach searchlights to npc_clawscanner if present")

    -- Searchlight color configuration
    local cvar_sl_r = CreateClientConVar("betterlights_cscanner_searchlight_color_r", "255", true, false, "Scanner searchlight color - red (0-255)")
    local cvar_sl_g = CreateClientConVar("betterlights_cscanner_searchlight_color_g", "255", true, false, "Scanner searchlight color - green (0-255)")
    local cvar_sl_b = CreateClientConVar("betterlights_cscanner_searchlight_color_b", "255", true, false, "Scanner searchlight color - blue (0-255)")
    local function getSearchlightColor()
        return math.Clamp(math.floor(cvar_sl_r:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_sl_g:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_sl_b:GetFloat() + 0.5), 0, 255)
    end

    -- Keep projected textures per-entity (keyed by the entity for robust cleanup)
    local scannerProjectors = {}

    if BL.TrackClass then
        BL.TrackClass("npc_cscanner")
        if GetConVar and GetConVar("betterlights_scanner_searchlight_include_clawscanner") then
            BL.TrackClass("npc_clawscanner")
        end
    end

    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_CScanner_DLight", function()
        -- Gather scanners (both types if requested)
        -- Refresh cap
        local hz = math.Clamp(cvar_update_hz:GetFloat(), 15, 120)
        BetterLights._nextTick = BetterLights._nextTick or {}
        local now = CurTime()
        local key = "CScanner_DLight"
        local nxt = BetterLights._nextTick[key] or 0
        if now < nxt then return end
        BetterLights._nextTick[key] = now + (1 / hz)
        local entsList = {}
        if BL.ForEach then
            BL.ForEach("npc_cscanner", function(e) table.insert(entsList, e) end)
            if cvar_sl_include_claw:GetBool() then
                BL.ForEach("npc_clawscanner", function(e) table.insert(entsList, e) end)
            end
        else
            entsList = ents.FindByClass("npc_cscanner") or {}
            if cvar_sl_include_claw:GetBool() then
                local claws = ents.FindByClass("npc_clawscanner")
                if claws and #claws > 0 then
                    for _, e in ipairs(claws) do table.insert(entsList, e) end
                end
            end
        end

        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())

        for _, ent in ipairs(entsList) do
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

                if cvar_enable:GetBool() then
                    local d = DynamicLight(idx)
                    if d then
                        local r, g, b = getGlowColor()
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
                            local r, g, b = getGlowColor()
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

                -- Searchlight (ProjectedTexture)
                if cvar_sl_enable:GetBool() then
                    local lamp = scannerProjectors[ent]
                    if not lamp or not lamp:IsValid() then
                        lamp = ProjectedTexture()
                        if lamp then
                            lamp:SetTexture("effects/flashlight001")
                            scannerProjectors[ent] = lamp
                        end
                    end
                    if lamp and lamp:IsValid() then
                        -- Place slightly below the body and point forward-down
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
                        lamp:SetNearZ(math.max(0.1, cvar_sl_near:GetFloat()))
                        lamp:SetFarZ(math.max(1, cvar_sl_far:GetFloat()))
                        lamp:SetFOV(math.Clamp(cvar_sl_fov:GetFloat(), 1, 175))
                        lamp:SetBrightness(cvar_sl_brightness:GetFloat())
                        local rr, gg, bb = getSearchlightColor()
                        lamp:SetColor(Color(rr, gg, bb))
                        lamp:SetEnableShadows(cvar_sl_shadows:GetBool())
                        lamp:Update()
                    end
                end
            end
        end

        -- Cleanup projectors for invalid/removed entities or when disabled
        for ent, lamp in pairs(scannerProjectors) do
            local removeIt = (not cvar_sl_enable:GetBool()) or (not IsValid(ent))
            if not removeIt then
                -- If the entity isn't in the current scanner list (e.g., killed), remove
                local found = false
                for _, e in ipairs(entsList) do if e == ent then found = true break end end
                if not found then removeIt = true end
            end
            if removeIt then
                if lamp and lamp.IsValid and lamp:IsValid() then lamp:Remove() end
                scannerProjectors[ent] = nil
            end
        end
    end)
end
