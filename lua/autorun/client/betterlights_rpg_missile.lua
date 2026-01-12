-- BetterLights: RPG rocket dynamic lighting
-- Client-side only

if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
    -- Localize hot globals
    local CurTime = CurTime
    local IsValid = IsValid
    local cvar_enable = CreateClientConVar("betterlights_rpg_enable", "1", true, false, "Enable dynamic light for fired RPG rockets")
    local cvar_size = CreateClientConVar("betterlights_rpg_size", "280", true, false, "Dynamic light radius for RPG rockets")
    local cvar_brightness = CreateClientConVar("betterlights_rpg_brightness", "2.2", true, false, "Dynamic light brightness for RPG rockets")
    local cvar_decay = CreateClientConVar("betterlights_rpg_decay", "2000", true, false, "Dynamic light decay for RPG rockets")

    -- Color configuration
    local cvar_col_r = CreateClientConVar("betterlights_rpg_color_r", "255", true, false, "RPG rocket color - red (0-255)")
    local cvar_col_g = CreateClientConVar("betterlights_rpg_color_g", "170", true, false, "RPG rocket color - green (0-255)")
    local cvar_col_b = CreateClientConVar("betterlights_rpg_color_b", "60", true, false, "RPG rocket color - blue (0-255)")

    -- Impact flash configuration
    local cvar_flash_enable = CreateClientConVar("betterlights_rpg_flash_enable", "1", true, false, "Add a brief light flash when an RPG rocket explodes")
    local cvar_flash_size = CreateClientConVar("betterlights_rpg_flash_size", "340", true, false, "Explosion flash radius for RPG rockets")
    local cvar_flash_brightness = CreateClientConVar("betterlights_rpg_flash_brightness", "4.8", true, false, "Explosion flash brightness for RPG rockets")
    local cvar_flash_time = CreateClientConVar("betterlights_rpg_flash_time", "0.18", true, false, "Duration of the RPG explosion flash (seconds)")
    local cvar_flash_r = CreateClientConVar("betterlights_rpg_flash_color_r", "255", true, false, "RPG flash color - red (0-255)")
    local cvar_flash_g = CreateClientConVar("betterlights_rpg_flash_color_g", "210", true, false, "RPG flash color - green (0-255)")
    local cvar_flash_b = CreateClientConVar("betterlights_rpg_flash_color_b", "120", true, false, "RPG flash color - blue (0-255)")

    hook.Add("EntityRemoved", "BetterLights_RPG_FlashOnRemoval", function(ent, fullUpdate)
        if fullUpdate then return end
        if not BL.IsEntityClass(ent, "rpg_missile") then return end
        if not cvar_flash_enable:GetBool() then return end

        local pos = ent.WorldSpaceCenter and ent:WorldSpaceCenter() or ent:GetPos()
        if BL.ShouldSuppressFlash("rpg", pos) then return end
        
        local dur = math.max(0, cvar_flash_time:GetFloat())
        if dur <= 0 then return end
        
        local fr, fg, fb = BL.GetColorFromCvars(cvar_flash_r, cvar_flash_g, cvar_flash_b)
        local flashSize = math.max(0, cvar_flash_size:GetFloat())
        local flashBrightness = math.max(0, cvar_flash_brightness:GetFloat())
        BL.CreateFlash(pos, fr, fg, fb, flashSize, flashBrightness, dur, 58000)
        BL.RecordFlashPosition("rpg", pos)
    end)

    -- Track rockets once
    if BL.TrackClass then BL.TrackClass("rpg_missile") end

    -- Centralized Think for rocket glow only (flashes handled by core)
    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_RPGMissile_DLight", function()
        if not cvar_enable:GetBool() then return end

        -- Cache colors and settings once per frame
        local r, g, b = BL.GetColorFromCvars(cvar_col_r, cvar_col_g, cvar_col_b)
        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())

        local function update(ent)
            if not IsValid(ent) then return end
            local pos = ent:WorldSpaceCenter()
            BL.CreateDLight(ent:EntIndex(), pos, r, g, b, brightness, decay, size, false)
        end

        if BL.ForEach then
            BL.ForEach("rpg_missile", update)
        else
            for _, ent in ipairs(ents.FindByClass("rpg_missile")) do update(ent) end
        end
    end)
end
