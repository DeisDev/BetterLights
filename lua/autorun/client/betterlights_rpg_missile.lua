if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
    local CurTime = CurTime
    local IsValid = IsValid
    local cvar_enable = BL.CreateClientConVar("betterlights_rpg_enable", "1", true, false, "Enable dynamic light for fired RPG rockets")
    local cvar_size = BL.CreateClientConVar("betterlights_rpg_size", "280", true, false, "Dynamic light radius for RPG rockets")
    local cvar_brightness = BL.CreateClientConVar("betterlights_rpg_brightness", "2.2", true, false, "Dynamic light brightness for RPG rockets")
    local cvar_decay = BL.CreateClientConVar("betterlights_rpg_decay", "2000", true, false, "Dynamic light decay for RPG rockets")

    local cvar_col_r = BL.CreateClientConVar("betterlights_rpg_color_r", "255", true, false, "RPG rocket color - red (0-255)")
    local cvar_col_g = BL.CreateClientConVar("betterlights_rpg_color_g", "170", true, false, "RPG rocket color - green (0-255)")
    local cvar_col_b = BL.CreateClientConVar("betterlights_rpg_color_b", "60", true, false, "RPG rocket color - blue (0-255)")

    local cvar_flash_enable = BL.CreateClientConVar("betterlights_rpg_flash_enable", "1", true, false, "Add a brief light flash when an RPG rocket explodes")
    local cvar_flash_size = BL.CreateClientConVar("betterlights_rpg_flash_size", "340", true, false, "Explosion flash radius for RPG rockets")
    local cvar_flash_brightness = BL.CreateClientConVar("betterlights_rpg_flash_brightness", "4.8", true, false, "Explosion flash brightness for RPG rockets")
    local cvar_flash_time = BL.CreateClientConVar("betterlights_rpg_flash_time", "0.18", true, false, "Duration of the RPG explosion flash (seconds)")
    local cvar_flash_r = BL.CreateClientConVar("betterlights_rpg_flash_color_r", "255", true, false, "RPG flash color - red (0-255)")
    local cvar_flash_g = BL.CreateClientConVar("betterlights_rpg_flash_color_g", "210", true, false, "RPG flash color - green (0-255)")
    local cvar_flash_b = BL.CreateClientConVar("betterlights_rpg_flash_color_b", "120", true, false, "RPG flash color - blue (0-255)")

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

    if BL.TrackClass then BL.TrackClass("rpg_missile") end

    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_RPGMissile_DLight", function()
        if not cvar_enable:GetBool() then return end

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
