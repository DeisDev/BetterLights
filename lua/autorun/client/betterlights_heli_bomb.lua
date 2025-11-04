-- BetterLights: Helicopter bombs (grenade_helicopter) red glow with pulse
-- Client-side only

if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
    -- Localize frequently used globals
    local CurTime = CurTime
    local IsValid = IsValid
    local DynamicLight = DynamicLight
    local ProjectedTexture = ProjectedTexture
    -- Steady red glow only for helicopter bombs
    local cvar_enable = CreateClientConVar("betterlights_heli_bomb_enable", "1", true, false, "Enable dynamic light for helicopter bombs (grenade_helicopter)")
    local cvar_size = CreateClientConVar("betterlights_heli_bomb_size", "140", true, false, "Dynamic light radius for helicopter bombs")
    local cvar_brightness = CreateClientConVar("betterlights_heli_bomb_brightness", "1.4", true, false, "Dynamic light brightness for helicopter bombs")
    local cvar_decay = CreateClientConVar("betterlights_heli_bomb_decay", "2000", true, false, "Dynamic light decay for helicopter bombs")
    local cvar_models_elight = CreateClientConVar("betterlights_heli_bomb_models_elight", "1", true, false, "Also add an entity light (elight) to light the bomb model directly")
    local cvar_models_elight_size_mult = CreateClientConVar("betterlights_heli_bomb_models_elight_size_mult", "1.0", true, false, "Multiplier for helicopter bomb elight radius")
    -- Explosion flash controls
    local cvar_flash_enable = CreateClientConVar("betterlights_heli_bomb_flash_enable", "1", true, false, "Add a brief light flash when a helicopter bomb explodes")
    local cvar_flash_size = CreateClientConVar("betterlights_heli_bomb_flash_size", "320", true, false, "Explosion flash radius for helicopter bombs")
    local cvar_flash_brightness = CreateClientConVar("betterlights_heli_bomb_flash_brightness", "5.0", true, false, "Explosion flash brightness for helicopter bombs")
    local cvar_flash_time = CreateClientConVar("betterlights_heli_bomb_flash_time", "0.18", true, false, "Duration of the explosion flash")

    -- Color configuration
    local cvar_col_r = CreateClientConVar("betterlights_heli_bomb_color_r", "255", true, false, "Heli bomb glow color - red (0-255)")
    local cvar_col_g = CreateClientConVar("betterlights_heli_bomb_color_g", "60", true, false, "Heli bomb glow color - green (0-255)")
    local cvar_col_b = CreateClientConVar("betterlights_heli_bomb_color_b", "60", true, false, "Heli bomb glow color - blue (0-255)")
    local cvar_flash_r = CreateClientConVar("betterlights_heli_bomb_flash_color_r", "255", true, false, "Heli bomb flash color - red (0-255)")
    local cvar_flash_g = CreateClientConVar("betterlights_heli_bomb_flash_color_g", "210", true, false, "Heli bomb flash color - green (0-255)")
    local cvar_flash_b = CreateClientConVar("betterlights_heli_bomb_flash_color_b", "120", true, false, "Heli bomb flash color - blue (0-255)")
    local function getGlowColor()
        return math.Clamp(math.floor(cvar_col_r:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_col_g:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_col_b:GetFloat() + 0.5), 0, 255)
    end
    local function getFlashColor()
        return math.Clamp(math.floor(cvar_flash_r:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_flash_g:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_flash_b:GetFloat() + 0.5), 0, 255)
    end

    -- Track ephemeral explosion flashes
    local BL_HeliBomb_Flashes = BL_HeliBomb_Flashes or {}

    -- Capture bomb removal to trigger a flash at its last known position
    hook.Add("EntityRemoved", "BetterLights_HeliBomb_FlashOnRemoval", function(ent, fullUpdate)
        if fullUpdate then return end
        if not ent or not ent.GetClass then return end
        if ent:GetClass() ~= "grenade_helicopter" then return end
        if not cvar_flash_enable:GetBool() then return end

        local pos
        if ent.OBBCenter and ent.LocalToWorld then
            pos = ent:LocalToWorld(ent:OBBCenter())
        elseif ent.WorldSpaceCenter then
            pos = ent:WorldSpaceCenter()
        else
            pos = ent:GetPos()
        end

        local now = CurTime()
        local dur = math.max(0, cvar_flash_time:GetFloat())
        if dur <= 0 then return end
        table.insert(BL_HeliBomb_Flashes, { pos = pos, start = now, die = now + dur, id = 56000 + (now * 1000 % 4000) })
    end)

    if BL.TrackClass then BL.TrackClass("grenade_helicopter") end

    -- Consolidated Think: steady glow + flash rendering in one callback
    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_HeliBomb", function()
        local doGlow = cvar_enable:GetBool()
        local doFlash = cvar_flash_enable:GetBool()

        -- Precompute colors once
        local gr, gg, gb = getGlowColor()
        local fr, fg, fb = getFlashColor()

        if doGlow then
            local size = math.max(0, cvar_size:GetFloat())
            local brightness_base = math.max(0, cvar_brightness:GetFloat())
            local decay = math.max(0, cvar_decay:GetFloat())
            local elMult = math.max(0, cvar_models_elight_size_mult:GetFloat())

            local function update(ent)
                if not IsValid(ent) then return end
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
                    d.r = gr
                    d.g = gg
                    d.b = gb
                    d.brightness = brightness_base
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
                        el.r = gr
                        el.g = gg
                        el.b = gb
                        el.brightness = brightness_base
                        el.decay = decay
                        el.size = size * elMult
                        el.minlight = 0
                        el.dietime = CurTime() + 0.1
                    end
                end
            end

            if BL.ForEach then
                BL.ForEach("grenade_helicopter", update)
            else
                for _, ent in ipairs(ents.FindByClass("grenade_helicopter")) do update(ent) end
            end
        end

        if doFlash and BL_HeliBomb_Flashes and #BL_HeliBomb_Flashes > 0 then
            local now = CurTime()
            local baseSize = math.max(0, cvar_flash_size:GetFloat())
            local baseBright = math.max(0, cvar_flash_brightness:GetFloat())
            for i = #BL_HeliBomb_Flashes, 1, -1 do
                local f = BL_HeliBomb_Flashes[i]
                if not f or now >= f.die then
                    table.remove(BL_HeliBomb_Flashes, i)
                else
                    local dur = math.max(0.001, f.die - f.start)
                    local t = (f.die - now) / dur
                    local b_eff = baseBright * t
                    local s_eff = baseSize * (0.4 + 0.6 * t)
                    local d = DynamicLight(f.id or (57000 + i))
                    if d then
                        d.pos = f.pos
                        d.r = fr
                        d.g = fg
                        d.b = fb
                        d.brightness = b_eff
                        d.decay = 0
                        d.size = s_eff
                        d.minlight = 0
                        d.noworld = false
                        d.nomodel = false
                        d.dietime = now + 0.05
                    end
                end
            end
        end
    end)
end
