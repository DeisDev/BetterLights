-- BetterLights: Antlion Guardian green glow
-- Applies a green glow to Antlion Guardian variant of npc_antlionguard using client-available heuristics.

if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
    -- Localize hot globals
    local CurTime = CurTime
    local IsValid = IsValid
    local DynamicLight = DynamicLight
    local cvar_enable = CreateClientConVar("betterlights_antlion_guardian_enable", "1", true, false, "Enable green glow on Antlion Guardian")
    local cvar_size = CreateClientConVar("betterlights_antlion_guardian_size", "180", true, false, "Guardian light radius")
    local cvar_brightness = CreateClientConVar("betterlights_antlion_guardian_brightness", "0.6", true, false, "Guardian light brightness")
    local cvar_decay = CreateClientConVar("betterlights_antlion_guardian_decay", "2000", true, false, "Guardian light decay")

    local cvar_debug = CreateClientConVar("betterlights_antlion_guardian_debug", "0", false, false, "Debug guardian detection prints")

    -- Color configuration
    local cvar_col_r = CreateClientConVar("betterlights_antlion_guardian_color_r", "120", true, false, "Antlion Guardian color - red (0-255)")
    local cvar_col_g = CreateClientConVar("betterlights_antlion_guardian_color_g", "255", true, false, "Antlion Guardian color - green (0-255)")
    local cvar_col_b = CreateClientConVar("betterlights_antlion_guardian_color_b", "140", true, false, "Antlion Guardian color - blue (0-255)")

    -- Detect guardian variant of npc_antlionguard using unified detection helper
    local function looksLikeGuardian(ent)
        return BL.DetectEntityVariant(ent, {
            debugName = "guardian",
            debugCvar = cvar_debug,
            nwBools = { "guardian", "isguardian", "antlionguardian", "is_guardian", "antlion_guardian", "IsGuardian" },
            saveTableKeys = { "m_bGuardian", "guardian", "isguardian", "m_bIsGuardian", "IsGuardian" },
            saveTableKeyword = "guardian",
            skin = function(s) return s > 0 end,  -- Guardian typically uses non-default skin
            targetname = "guardian"
        })
    end

    local function getCorePos(ent)
        -- Try a central body attachment if present
        local pos = BL.GetAttachmentPos(ent, { "chest", "body", "abdomen", "glow" })
        if pos then return pos end
        return BL.GetEntityCenter(ent)
    end

    if BL.TrackClass then BL.TrackClass("npc_antlionguard") end

    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_AntlionGuardian", function()
        if not cvar_enable:GetBool() then return end

        -- Cache ConVar values once per frame
        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())
        local r, g, b = BL.GetColorFromCvars(cvar_col_r, cvar_col_g, cvar_col_b)

        local function update(ent)
            if not IsValid(ent) then return end
            if ent.GetNoDraw and ent:GetNoDraw() then return end
            if not looksLikeGuardian(ent) then return end

            local pos = getCorePos(ent)
            BL.CreateDLight(ent:EntIndex() + 23100, pos, r, g, b, brightness, decay, size, false)
        end

        if BL.ForEach then
            BL.ForEach("npc_antlionguard", update)
        else
            for _, ent in ipairs(ents.FindByClass("npc_antlionguard")) do update(ent) end
        end
    end)
end
