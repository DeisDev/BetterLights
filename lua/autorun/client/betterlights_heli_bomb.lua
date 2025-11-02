-- BetterLights: Helicopter bombs (grenade_helicopter) red glow with pulse
-- Client-side only

if CLIENT then
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

    local RED = { r = 255, g = 60, b = 60 }
    local FLASH = { r = 255, g = 210, b = 120 }

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

    hook.Add("Think", "BetterLights_HeliBomb_DLight", function()
        if not cvar_enable:GetBool() then return end

        local bombs = ents.FindByClass("grenade_helicopter")
        if not bombs or #bombs == 0 then return end

        local size = math.max(0, cvar_size:GetFloat())
        local brightness_base = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())

        for _, ent in ipairs(bombs) do
            if IsValid(ent) then
                local idx = ent:EntIndex()
                -- steady red (no pulse; no armed state tracking)
                local pos
                if ent.OBBCenter and ent.LocalToWorld then
                    pos = ent:LocalToWorld(ent:OBBCenter())
                elseif ent.WorldSpaceCenter then
                    pos = ent:WorldSpaceCenter()
                else
                    pos = ent:GetPos()
                end

                -- Steady brightness (no pulsing)
                local b_eff = brightness_base

                local d = DynamicLight(ent:EntIndex())
                if d then
                    d.pos = pos
                    d.r = RED.r
                    d.g = RED.g
                    d.b = RED.b
                    d.brightness = b_eff
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
                        el.r = RED.r
                        el.g = RED.g
                        el.b = RED.b
                        el.brightness = b_eff
                        el.decay = decay
                        el.size = size * math.max(0, cvar_models_elight_size_mult:GetFloat())
                        el.minlight = 0
                        el.dietime = CurTime() + 0.1
                    end
                end
            end
        end
    end)

    -- Render short-lived explosion flashes regardless of steady glow setting
    hook.Add("Think", "BetterLights_HeliBomb_FlashThink", function()
        if not cvar_flash_enable:GetBool() then return end
        if not BL_HeliBomb_Flashes or #BL_HeliBomb_Flashes == 0 then return end

        local now = CurTime()
        local baseSize = math.max(0, cvar_flash_size:GetFloat())
        local baseBright = math.max(0, cvar_flash_brightness:GetFloat())

        for i = #BL_HeliBomb_Flashes, 1, -1 do
            local f = BL_HeliBomb_Flashes[i]
            if not f or now >= f.die then
                table.remove(BL_HeliBomb_Flashes, i)
            else
                local dur = math.max(0.001, f.die - f.start)
                local t = (f.die - now) / dur -- 1->0 over lifetime
                -- Ease-out curve for brightness/size
                local b_eff = baseBright * t
                local s_eff = baseSize * (0.4 + 0.6 * t)

                local d = DynamicLight(f.id or (57000 + i))
                if d then
                    d.pos = f.pos
                    d.r = FLASH.r
                    d.g = FLASH.g
                    d.b = FLASH.b
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
    end)
end
