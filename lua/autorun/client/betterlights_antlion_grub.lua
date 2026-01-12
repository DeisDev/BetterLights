-- BetterLights: Antlion Grub green abdomen glow
-- Subtle dynamic light placed near the grub's abdomen.

if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
    -- Localize hot globals
    local IsValid = IsValid
    local cvar_enable = CreateClientConVar("betterlights_antlion_grub_enable", "1", true, false, "Enable green glow on Antlion Grubs")
    local cvar_size = CreateClientConVar("betterlights_antlion_grub_size", "70", true, false, "Grub light radius")
    local cvar_brightness = CreateClientConVar("betterlights_antlion_grub_brightness", "0.35", true, false, "Grub light brightness")
    local cvar_decay = CreateClientConVar("betterlights_antlion_grub_decay", "2000", true, false, "Grub light decay")

    -- Color configuration
    local cvar_col_r = CreateClientConVar("betterlights_antlion_grub_color_r", "120", true, false, "Antlion grub color - red (0-255)")
    local cvar_col_g = CreateClientConVar("betterlights_antlion_grub_color_g", "255", true, false, "Antlion grub color - green (0-255)")
    local cvar_col_b = CreateClientConVar("betterlights_antlion_grub_color_b", "120", true, false, "Antlion grub color - blue (0-255)")

    local ATTACH_NAMES = { "glow", "glow1", "abdomen", "light", "lum" }

    if BL.TrackClass then BL.TrackClass("npc_antlion_grub") end

    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_AntlionGrub", function()
        if not cvar_enable:GetBool() then return end

        -- Cache ConVar values once per frame
        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())
        local r, g, b = BL.GetColorFromCvars(cvar_col_r, cvar_col_g, cvar_col_b)

        local function update(ent)
            if not IsValid(ent) then return end
            if ent.GetNoDraw and ent:GetNoDraw() then return end

            -- Try attachment-based light first
            if not BL.CreateLightFromAttachment(ent, ATTACH_NAMES, r, g, b, brightness, decay, size, false) then
                -- Fallback to OBB center with slight forward offset
                local center = BL.GetEntityCenter(ent)
                if center then
                    local fwd = ent.GetForward and ent:GetForward() or Vector(1, 0, 0)
                    local pos = center + fwd * 2
                    BL.CreateDLight(ent:EntIndex() + 23000, pos, r, g, b, brightness, decay, size, false)
                end
            end
        end

        if BL.ForEach then
            BL.ForEach("npc_antlion_grub", update)
        else
            for _, ent in ipairs(ents.FindByClass("npc_antlion_grub")) do update(ent) end
        end
    end)
end
