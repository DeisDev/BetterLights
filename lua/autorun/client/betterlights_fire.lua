-- BetterLights: Dynamic light for burning entities
-- Client-side only

if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
    -- Localize frequently used globals
    local CurTime = CurTime
    local IsValid = IsValid
    local DynamicLight = DynamicLight
    local cvar_enable = CreateClientConVar("betterlights_fire_enable", "1", true, false, "Enable dynamic light for entities that are on fire")
    local cvar_size = CreateClientConVar("betterlights_fire_size", "160", true, false, "Dynamic light radius for burning entities")
    local cvar_brightness = CreateClientConVar("betterlights_fire_brightness", "5.2", true, false, "Dynamic light brightness for burning entities")
    local cvar_decay = CreateClientConVar("betterlights_fire_decay", "2000", true, false, "Dynamic light decay for burning entities")
    local cvar_models_elight = CreateClientConVar("betterlights_fire_models_elight", "1", true, false, "Also add an entity light (elight) to light models directly")
    local cvar_models_elight_size_mult = CreateClientConVar("betterlights_fire_models_elight_size_mult", "1.0", true, false, "Multiplier for elight radius on burning entities")
    local cvar_flicker_enable = CreateClientConVar("betterlights_fire_flicker_enable", "1", true, false, "Enable flicker effect for burning entity lights")
    local cvar_flicker_amount = CreateClientConVar("betterlights_fire_flicker_amount", "0.35", true, false, "Flicker intensity (as a fraction of brightness)")
    local cvar_flicker_size_amount = CreateClientConVar("betterlights_fire_flicker_size_amount", "0.12", true, false, "Flicker intensity applied to light radius")
    local cvar_flicker_speed = CreateClientConVar("betterlights_fire_flicker_speed", "11.5", true, false, "Flicker speed (higher = faster flicker)")
    -- removed update_hz throttling entirely (always update every frame)

    -- Color configuration
    local cvar_col_r = CreateClientConVar("betterlights_fire_color_r", "255", true, false, "Burning entities color - red (0-255)")
    local cvar_col_g = CreateClientConVar("betterlights_fire_color_g", "170", true, false, "Burning entities color - green (0-255)")
    local cvar_col_b = CreateClientConVar("betterlights_fire_color_b", "60", true, false, "Burning entities color - blue (0-255)")

    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end

    if BL.TrackClass then BL.TrackClass("entityflame") end
    AddThink("BetterLights_Fire_DLight", function()
        if not cvar_enable:GetBool() then return end

        -- No throttling (always update every frame)

        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())
        local doElight = cvar_models_elight:GetBool()
        local elMult = math.max(0, cvar_models_elight_size_mult:GetFloat())
        local doFlicker = cvar_flicker_enable:GetBool()
        local flickerSpeed = cvar_flicker_speed:GetFloat()
        local flickerAmt = math.max(0, cvar_flicker_amount:GetFloat())
        local flickerSizeAmt = math.max(0, cvar_flicker_size_amount:GetFloat())

        -- Track which target entities we've already lit this frame to avoid duplicate lights
        local seenTargets = {}

        -- Cache color once per frame
        local cr, cg, cb = BL.GetColorFromCvars(cvar_col_r, cvar_col_g, cvar_col_b)

        local function handleFlame(flame)
            if IsValid(flame) then
                local target = flame:GetParent()
                if not IsValid(target) then
                    target = flame:GetOwner()
                end

                local pos
                local lightIndex
                if IsValid(target) then
                    -- Use the entity's OBB center for better "self-lighting" and the target's EntIndex for stability
                    local obbCenter = target.OBBCenter and target:OBBCenter() or Vector(0, 0, 0)
                    pos = target.LocalToWorld and target:LocalToWorld(obbCenter) or (target.WorldSpaceCenter and target:WorldSpaceCenter()) or target:GetPos()
                    lightIndex = target:EntIndex()
                    -- Skip if we've already placed a light for this target this frame
                    if seenTargets[lightIndex] then goto continue_flame end
                    seenTargets[lightIndex] = true
                else
                    pos = flame:GetPos()
                    lightIndex = flame:EntIndex()
                end

                -- Compute flicker-adjusted brightness/size once and use for both dlight and elight
                local b_eff, s_eff = brightness, size
                if doFlicker then
                    local t = CurTime()
                    local phase = (flame:EntIndex() % 17) * 0.37
                    b_eff = BL.CreateFlickerEffect(brightness, t, flickerSpeed, flickerAmt, phase)
                    s_eff = BL.CreateFlickerEffect(size, t, flickerSpeed, flickerSizeAmt, phase)
                end

                -- DLight (world/model)
                local dlight = DynamicLight(lightIndex)
                if dlight then
                    dlight.pos = pos
                    dlight.r = cr
                    dlight.g = cg
                    dlight.b = cb
                    dlight.brightness = b_eff
                    dlight.decay = decay
                    dlight.size = s_eff
                    dlight.minlight = 0
                    dlight.noworld = false
                    dlight.nomodel = false
                    dlight.dietime = CurTime() + 0.16
                end

                -- ELight (model-only)
                if doElight then
                    local el = DynamicLight(lightIndex, true) -- elight: lights models, not world
                    if el then
                        el.pos = pos
                        el.r = cr
                        el.g = cg
                        el.b = cb
                        el.brightness = b_eff
                        el.decay = decay
                        el.size = s_eff * elMult
                        el.minlight = 0
                        -- noworld/nomodel flags are ignored for elights; elights never light world
                        el.dietime = CurTime() + 0.16
                    end
                end

                ::continue_flame::
            end
        end

        if BL.ForEach then
            BL.ForEach("entityflame", handleFlame)
        else
            local flames = ents.FindByClass("entityflame")
            if not flames or #flames == 0 then return end
            for _, flame in ipairs(flames) do handleFlame(flame) end
        end
    end)
end
