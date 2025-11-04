-- BetterLights: Dynamic light for burning entities
-- Client-side only

if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
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
    local cvar_update_hz = CreateClientConVar("betterlights_fire_update_hz", "30", true, false, "Update rate in Hz (15-120)")

    -- Color configuration
    local cvar_col_r = CreateClientConVar("betterlights_fire_color_r", "255", true, false, "Burning entities color - red (0-255)")
    local cvar_col_g = CreateClientConVar("betterlights_fire_color_g", "170", true, false, "Burning entities color - green (0-255)")
    local cvar_col_b = CreateClientConVar("betterlights_fire_color_b", "60", true, false, "Burning entities color - blue (0-255)")
    local function getColor()
        return math.Clamp(math.floor(cvar_col_r:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_col_g:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_col_b:GetFloat() + 0.5), 0, 255)
    end

    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_Fire_DLight", function()
        if not cvar_enable:GetBool() then return end

        -- Refresh cap
        local hz = math.Clamp(cvar_update_hz:GetFloat(), 15, 120)
        BetterLights._nextTick = BetterLights._nextTick or {}
        local now = CurTime()
        local key = "Fire_DLight"
        local nxt = BetterLights._nextTick[key] or 0
        if now < nxt then return end
        BetterLights._nextTick[key] = now + (1 / hz)

        local flames = ents.FindByClass("entityflame")
        if not flames or #flames == 0 then return end

        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())

        -- Track which target entities we've already lit this frame to avoid duplicate lights
        local seenTargets = {}

        for _, flame in ipairs(flames) do
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
                if cvar_flicker_enable:GetBool() then
                    local t = CurTime()
                    local spd = cvar_flicker_speed:GetFloat()
                    local amt = math.max(0, cvar_flicker_amount:GetFloat())
                    local samt = math.max(0, cvar_flicker_size_amount:GetFloat())
                    local phase = (flame:EntIndex() % 17) * 0.37
                    local osc = 0.65 * math.sin(t * spd + phase) + 0.35 * math.sin(t * (spd * 1.7) + phase * 1.13)
                    local mult = 1 + amt * osc
                    local smult = 1 + samt * osc
                    b_eff = math.max(0.1, brightness * mult)
                    s_eff = math.max(0, size * smult)
                end

                local dlight = DynamicLight(lightIndex)
                if dlight then
                    dlight.pos = pos
                    local r, g, b = getColor()
                    dlight.r = r
                    dlight.g = g
                    dlight.b = b
                    dlight.brightness = b_eff
                    dlight.decay = decay
                    dlight.size = s_eff
                    dlight.minlight = 0
                    dlight.noworld = false
                    dlight.nomodel = false
                    dlight.dietime = CurTime() + 0.1
                end

                -- Add an elight to ensure models (like the burning entity itself) are lit
                if cvar_models_elight:GetBool() then
                    local el = DynamicLight(lightIndex, true) -- elight: lights models, not world
                    if el then
                        el.pos = pos
                        local r, g, b = getColor()
                        el.r = r
                        el.g = g
                        el.b = b
                        el.brightness = b_eff
                        el.decay = decay
                        el.size = s_eff * math.max(0, cvar_models_elight_size_mult:GetFloat())
                        el.minlight = 0
                        -- noworld/nomodel flags are ignored for elights; elights never light world
                        el.dietime = CurTime() + 0.1
                    end
                end

                ::continue_flame::
            end
        end
    end)
end
