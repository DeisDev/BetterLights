-- BetterLights: Antlion Worker subtle back glow
-- Attaches a dynamic light to npc_antlion_worker at the bone "Antlion.Back_Bone".

if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
    local cvar_enable = CreateClientConVar("betterlights_antlion_worker_enable", "1", true, false, "Enable subtle glow on Antlion Workers")
    local cvar_size = CreateClientConVar("betterlights_antlion_worker_size", "120", true, false, "Antlion Worker light radius")
    local cvar_brightness = CreateClientConVar("betterlights_antlion_worker_brightness", "0.55", true, false, "Antlion Worker light brightness")
    local cvar_decay = CreateClientConVar("betterlights_antlion_worker_decay", "2000", true, false, "Antlion Worker light decay")

    -- Color configuration (yellow-green default)
    local cvar_col_r = CreateClientConVar("betterlights_antlion_worker_color_r", "180", true, false, "Antlion Worker color - red (0-255)")
    local cvar_col_g = CreateClientConVar("betterlights_antlion_worker_color_g", "240", true, false, "Antlion Worker color - green (0-255)")
    local cvar_col_b = CreateClientConVar("betterlights_antlion_worker_color_b", "120", true, false, "Antlion Worker color - blue (0-255)")
    local function getColor()
        return math.Clamp(math.floor(cvar_col_r:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_col_g:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_col_b:GetFloat() + 0.5), 0, 255)
    end

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
        local names = { "glow", "light", "abdomen", "body", "spine" }
        for _, name in ipairs(names) do
            local idx = ent:LookupAttachment(name)
            if idx and idx > 0 then
                local att = ent:GetAttachment(idx)
                if att and att.Pos then return att.Pos end
            end
        end
        return ent:LocalToWorld(ent:OBBCenter())
    end

    if BL.TrackClass then BL.TrackClass("npc_antlion_worker") end

    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_AntlionWorker", function()
        if not cvar_enable:GetBool() then return end

        local function update(ent)
            if not IsValid(ent) then goto cont end
            if ent.GetNoDraw and ent:GetNoDraw() then goto cont end

            local pos = getBackBonePos(ent)
            if not pos then goto cont end

            local dl = DynamicLight(ent:EntIndex() + 23200)
            if dl then
                dl.pos = pos
                local r, g, b = getColor()
                dl.r = r
                dl.g = g
                dl.b = b
                dl.brightness = math.max(0, cvar_brightness:GetFloat())
                dl.decay = math.max(0, cvar_decay:GetFloat())
                dl.size = math.max(0, cvar_size:GetFloat())
                dl.dietime = CurTime() + 0.05
            end

            ::cont::
        end

        if BL.ForEach then
            BL.ForEach("npc_antlion_worker", update)
        else
            for _, ent in ipairs(ents.FindByClass("npc_antlion_worker")) do update(ent) end
        end
    end)
end
