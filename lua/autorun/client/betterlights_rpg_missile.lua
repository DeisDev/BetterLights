-- BetterLights: RPG rocket dynamic lighting
-- Client-side only

if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
    -- Localize hot globals
    local CurTime = CurTime
    local IsValid = IsValid
    local DynamicLight = DynamicLight
    local ents = ents
    local ipairs = ipairs
    local table_insert = table.insert
    local cvar_enable = CreateClientConVar("betterlights_rpg_enable", "1", true, false, "Enable dynamic light for fired RPG rockets")
    local cvar_size = CreateClientConVar("betterlights_rpg_size", "280", true, false, "Dynamic light radius for RPG rockets")
    local cvar_brightness = CreateClientConVar("betterlights_rpg_brightness", "2.2", true, false, "Dynamic light brightness for RPG rockets")
    local cvar_decay = CreateClientConVar("betterlights_rpg_decay", "2000", true, false, "Dynamic light decay for RPG rockets")

    -- Color configuration
    local cvar_col_r = CreateClientConVar("betterlights_rpg_color_r", "255", true, false, "RPG rocket color - red (0-255)")
    local cvar_col_g = CreateClientConVar("betterlights_rpg_color_g", "170", true, false, "RPG rocket color - green (0-255)")
    local cvar_col_b = CreateClientConVar("betterlights_rpg_color_b", "60", true, false, "RPG rocket color - blue (0-255)")
    local function getColor()
        return math.Clamp(math.floor(cvar_col_r:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_col_g:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_col_b:GetFloat() + 0.5), 0, 255)
    end

    -- Impact flash configuration
    local cvar_flash_enable = CreateClientConVar("betterlights_rpg_flash_enable", "1", true, false, "Add a brief light flash when an RPG rocket explodes")
    local cvar_flash_size = CreateClientConVar("betterlights_rpg_flash_size", "340", true, false, "Explosion flash radius for RPG rockets")
    local cvar_flash_brightness = CreateClientConVar("betterlights_rpg_flash_brightness", "4.8", true, false, "Explosion flash brightness for RPG rockets")
    local cvar_flash_time = CreateClientConVar("betterlights_rpg_flash_time", "0.18", true, false, "Duration of the RPG explosion flash (seconds)")
    local cvar_flash_r = CreateClientConVar("betterlights_rpg_flash_color_r", "255", true, false, "RPG flash color - red (0-255)")
    local cvar_flash_g = CreateClientConVar("betterlights_rpg_flash_color_g", "210", true, false, "RPG flash color - green (0-255)")
    local cvar_flash_b = CreateClientConVar("betterlights_rpg_flash_color_b", "120", true, false, "RPG flash color - blue (0-255)")
    local function getFlashColor()
        return math.Clamp(math.floor(cvar_flash_r:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_flash_g:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_flash_b:GetFloat() + 0.5), 0, 255)
    end

    -- Track ephemeral RPG explosion flashes and a recent list for suppression
    local BL_RPG_Flashes = BL_RPG_Flashes or {}
    local BL_RPG_Recent = BL_RPG_Recent or {}

    local function rpgShouldSuppress(pos)
        local now = CurTime()
        for i = #BL_RPG_Recent, 1, -1 do
            local e = BL_RPG_Recent[i]
            if not e or now - e.t > 0.15 then
                table.remove(BL_RPG_Recent, i)
            else
                if e.pos:DistToSqr(pos) < (40 * 40) then return true end
            end
        end
        return false
    end

    hook.Add("EntityRemoved", "BetterLights_RPG_FlashOnRemoval", function(ent, fullUpdate)
        if fullUpdate then return end
        if not IsValid(ent) or not ent.GetClass then return end
        if ent:GetClass() ~= "rpg_missile" then return end
        if not cvar_flash_enable:GetBool() then return end

        local pos = ent.WorldSpaceCenter and ent:WorldSpaceCenter() or ent:GetPos()
        if rpgShouldSuppress(pos) then return end
        local now = CurTime()
        local dur = math.max(0, cvar_flash_time:GetFloat())
        if dur <= 0 then return end
        table_insert(BL_RPG_Flashes, { pos = pos, start = now, die = now + dur, id = 58000 + (now * 1000 % 4000) })
        table_insert(BL_RPG_Recent, { pos = pos, t = now })
    end)

    -- Track rockets once
    if BL.TrackClass then BL.TrackClass("rpg_missile") end

    -- Centralized Think
    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_RPGMissile_DLight", function()
        local doGlow = cvar_enable:GetBool()
        local doFlash = cvar_flash_enable:GetBool()

        -- Precompute colors and settings once per frame
        local r, g, b = getColor()
        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())
        local fr, fg, fb = getFlashColor()

        if doGlow then
            local function update(ent)
                if IsValid(ent) then
                    local dlight = DynamicLight(ent:EntIndex())
                    if dlight then
                        dlight.pos = ent:WorldSpaceCenter()
                        dlight.r = r
                        dlight.g = g
                        dlight.b = b
                        dlight.brightness = brightness
                        dlight.decay = decay
                        dlight.size = size
                        dlight.minlight = 0
                        dlight.noworld = false
                        dlight.nomodel = false
                        dlight.dietime = CurTime() + 0.1
                    end
                end
            end

            if BL.ForEach then
                BL.ForEach("rpg_missile", update)
            else
                for _, ent in ipairs(ents.FindByClass("rpg_missile")) do update(ent) end
            end
        end

        if doFlash and BL_RPG_Flashes and #BL_RPG_Flashes > 0 then
            local now = CurTime()
            local baseSize = math.max(0, cvar_flash_size:GetFloat())
            local baseBright = math.max(0, cvar_flash_brightness:GetFloat())
            for i = #BL_RPG_Flashes, 1, -1 do
                local f = BL_RPG_Flashes[i]
                if not f or now >= f.die then
                    table.remove(BL_RPG_Flashes, i)
                else
                    local dur = math.max(0.001, f.die - f.start)
                    local t = (f.die - now) / dur
                    local b_eff = baseBright * t
                    local s_eff = baseSize * (0.4 + 0.6 * t)
                    local d = DynamicLight(f.id or (59000 + i))
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
