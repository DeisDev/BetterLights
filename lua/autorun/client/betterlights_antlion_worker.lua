-- BetterLights: Antlion Worker subtle back glow
-- Attaches a dynamic light to npc_antlion_worker at the bone "Antlion.Back_Bone".

if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
    -- Localize hot globals
    local CurTime = CurTime
    local IsValid = IsValid
    local DynamicLight = DynamicLight
    local cvar_enable = CreateClientConVar("betterlights_antlion_worker_enable", "1", true, false, "Enable subtle glow on Antlion Workers")
    local cvar_size = CreateClientConVar("betterlights_antlion_worker_size", "120", true, false, "Antlion Worker light radius")
    local cvar_brightness = CreateClientConVar("betterlights_antlion_worker_brightness", "0.55", true, false, "Antlion Worker light brightness")
    local cvar_decay = CreateClientConVar("betterlights_antlion_worker_decay", "2000", true, false, "Antlion Worker light decay")

    -- Color configuration (yellow-green default)
    local cvar_col_r = CreateClientConVar("betterlights_antlion_worker_color_r", "180", true, false, "Antlion Worker color - red (0-255)")
    local cvar_col_g = CreateClientConVar("betterlights_antlion_worker_color_g", "240", true, false, "Antlion Worker color - green (0-255)")
    local cvar_col_b = CreateClientConVar("betterlights_antlion_worker_color_b", "120", true, false, "Antlion Worker color - blue (0-255)")

    local BONE_NAME = "Antlion.Back_Bone"

    local function getBackBonePos(ent)
        if not IsValid(ent) then return end
        local bone = ent:LookupBone(BONE_NAME)
        if bone and bone >= 0 then
            local m = ent:GetBoneMatrix(bone)
            if m then
                local pos = m:GetTranslation()
                if pos and pos ~= vector_origin then return pos end
            end
            local pos = ent:GetBonePosition(bone)
            if pos and pos ~= vector_origin then return pos end
        end
        -- Fallbacks: try a few likely attachments, then OBB center
        local pos = BL.GetAttachmentPos(ent, { "glow", "light", "abdomen", "body", "spine" })
        if pos then return pos end
        return BL.GetEntityCenter(ent)
    end

    if BL.TrackClass then BL.TrackClass("npc_antlion_worker") end

    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_AntlionWorker", function()
        if not cvar_enable:GetBool() then return end

        -- Cache ConVar values once per frame
        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())
        local r, g, b = BL.GetColorFromCvars(cvar_col_r, cvar_col_g, cvar_col_b)

        local function update(ent)
            if not IsValid(ent) then return end
            if ent.GetNoDraw and ent:GetNoDraw() then return end

            local pos = getBackBonePos(ent)
            if not pos then return end

            BL.CreateDLight(ent:EntIndex() + 23200, pos, r, g, b, brightness, decay, size, false)
        end

        if BL.ForEach then
            BL.ForEach("npc_antlion_worker", update)
        else
            for _, ent in ipairs(ents.FindByClass("npc_antlion_worker")) do update(ent) end
        end
    end)
end
