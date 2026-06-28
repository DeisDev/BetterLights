TOOL.Category = "Better Lights"
TOOL.Name = "#tool.betterlights_model_lookup.name"
TOOL.Command = nil
TOOL.ConfigName = ""
local CLIENT_CONVAR_DEFAULTS = {
    mode = "summary",
    output = "console",
    trace = "1",
    vectors = "1"
}
TOOL.ClientConVar = CLIENT_CONVAR_DEFAULTS

local RESULT_MESSAGE = "BetterLights_ModelLookup_Result"
local TOOL_CVAR_PREFIX = "betterlights_model_lookup_"

if SERVER then
    util.AddNetworkString(RESULT_MESSAGE)
end

if CLIENT then
    language.Add("tool.betterlights_model_lookup.name", language.GetPhrase("betterlights.tool.model_lookup.name"))
    language.Add("tool.betterlights_model_lookup.desc", language.GetPhrase("betterlights.tool.model_lookup.desc"))
    language.Add("tool.betterlights_model_lookup.left", language.GetPhrase("betterlights.tool.model_lookup.left"))

    TOOL.Information = {
        { name = "left" }
    }
end

local MODE_LABELS = {
    summary = "Summary",
    attachments = "Attachments",
    bones = "Bones",
    skins_bodygroups = "Skins and Bodygroups",
    materials = "Materials",
    full = "Full Report"
}

local function addLine(lines, text)
    lines[#lines + 1] = text
end

local function addBlank(lines)
    lines[#lines + 1] = ""
end

local function formatVector(vec)
    if not vec then return "nil" end
    return string.format("%.2f %.2f %.2f", vec.x or 0, vec.y or 0, vec.z or 0)
end

local function formatAngle(ang)
    if not ang then return "nil" end
    return string.format("%.2f %.2f %.2f", ang.p or 0, ang.y or 0, ang.r or 0)
end

local function addEntitySummary(lines, ent, includeVectors)
    if not IsValid(ent) then
        addLine(lines, "Entity: invalid")
        return
    end

    addLine(lines, string.format("Entity: #%d %s", ent:EntIndex(), ent.GetClass and ent:GetClass() or "unknown"))
    addLine(lines, "Model: " .. tostring(ent.GetModel and ent:GetModel() or "unknown"))

    if ent.GetSkin then
        addLine(lines, "Skin: " .. tostring(ent:GetSkin()))
    end

    if ent.GetModelScale then
        addLine(lines, "Model scale: " .. tostring(ent:GetModelScale()))
    end

    if includeVectors then
        addLine(lines, "Position: " .. formatVector(ent:GetPos()))
        addLine(lines, "Angles: " .. formatAngle(ent:GetAngles()))

        if ent.WorldSpaceCenter then
            addLine(lines, "World center: " .. formatVector(ent:WorldSpaceCenter()))
        end

        if ent.OBBMins and ent.OBBMaxs then
            addLine(lines, "OBB mins: " .. formatVector(ent:OBBMins()))
            addLine(lines, "OBB maxs: " .. formatVector(ent:OBBMaxs()))
        end
    end
end

local function addTraceInfo(lines, trace, includeVectors)
    addLine(lines, "Trace:")
    addLine(lines, "  Hit: " .. tostring(trace.Hit))
    addLine(lines, "  Hit world: " .. tostring(trace.HitWorld))

    if includeVectors then
        addLine(lines, "  Hit position: " .. formatVector(trace.HitPos))
        addLine(lines, "  Hit normal: " .. formatVector(trace.HitNormal))
    end

    addLine(lines, "  Hit group: " .. tostring(trace.HitGroup))
    addLine(lines, "  Physics bone: " .. tostring(trace.PhysicsBone))
end

local function addAttachmentInfo(lines, ent, includeVectors)
    addLine(lines, "Attachments:")

    local found = false
    if IsValid(ent) and ent.GetAttachments and ent.LookupAttachment and ent.GetAttachment then
        local attachments = ent:GetAttachments() or {}
        for _, attachment in ipairs(attachments) do
            found = true
            local id = attachment.id or ent:LookupAttachment(attachment.name or "")
            local line = string.format("  %d: %s", id or 0, tostring(attachment.name))

            if includeVectors and id and id > 0 then
                local data = ent:GetAttachment(id)
                if data then
                    line = line .. " pos=" .. formatVector(data.Pos) .. " ang=" .. formatAngle(data.Ang)
                end
            end

            addLine(lines, line)
        end
    end

    if not found then
        addLine(lines, "  none")
    end
end

local function addBoneInfo(lines, ent, includeVectors)
    addLine(lines, "Bones:")

    local found = false
    if IsValid(ent) and ent.GetBoneCount and ent.GetBoneName then
        local count = ent:GetBoneCount() or 0
        for i = 0, count - 1 do
            found = true
            local line = string.format("  %d: %s", i, tostring(ent:GetBoneName(i)))

            if includeVectors and ent.GetBonePosition then
                local pos, ang = ent:GetBonePosition(i)
                line = line .. " pos=" .. formatVector(pos) .. " ang=" .. formatAngle(ang)
            end

            addLine(lines, line)
        end
    end

    if not found then
        addLine(lines, "  none")
    end
end

local function addSkinBodygroupInfo(lines, ent)
    addLine(lines, "Skins and bodygroups:")

    if not IsValid(ent) then
        addLine(lines, "  none")
        return
    end

    if ent.GetSkin then
        addLine(lines, "  Current skin: " .. tostring(ent:GetSkin()))
    end

    if ent.SkinCount then
        addLine(lines, "  Skin count: " .. tostring(ent:SkinCount()))
    end

    local foundBodygroup = false
    if ent.GetNumBodyGroups and ent.GetBodygroupName and ent.GetBodygroupCount and ent.GetBodygroup then
        local count = ent:GetNumBodyGroups() or 0
        for id = 0, count - 1 do
            foundBodygroup = true
            addLine(lines, string.format("  Bodygroup %d: %s current=%s count=%s", id, tostring(ent:GetBodygroupName(id)), tostring(ent:GetBodygroup(id)), tostring(ent:GetBodygroupCount(id))))
        end
    end

    if not foundBodygroup then
        addLine(lines, "  Bodygroups: none")
    end
end

local function addMaterialInfo(lines, ent)
    addLine(lines, "Materials:")

    local found = false
    if IsValid(ent) and ent.GetMaterials then
        local materials = ent:GetMaterials() or {}
        for i, materialName in ipairs(materials) do
            found = true
            addLine(lines, string.format("  %d: %s", i, tostring(materialName)))
        end
    end

    if IsValid(ent) and ent.GetMaterial and ent:GetMaterial() ~= "" then
        found = true
        addLine(lines, "  Override: " .. tostring(ent:GetMaterial()))
    end

    if not found then
        addLine(lines, "  none")
    end
end

local function buildReport(trace, mode, includeTrace, includeVectors)
    local ent = trace.Entity
    local lines = {}

    addLine(lines, "[BetterLights] Model Lookup Tool")
    addLine(lines, "Mode: " .. tostring(MODE_LABELS[mode] or mode))
    addBlank(lines)

    addEntitySummary(lines, ent, includeVectors)

    if includeTrace then
        addBlank(lines)
        addTraceInfo(lines, trace, includeVectors)
    end

    if mode == "attachments" or mode == "full" then
        addBlank(lines)
        addAttachmentInfo(lines, ent, includeVectors)
    end

    if mode == "bones" or mode == "full" then
        addBlank(lines)
        addBoneInfo(lines, ent, includeVectors)
    end

    if mode == "skins_bodygroups" or mode == "full" then
        addBlank(lines)
        addSkinBodygroupInfo(lines, ent)
    end

    if mode == "materials" or mode == "full" then
        addBlank(lines)
        addMaterialInfo(lines, ent)
    end

    return table.concat(lines, "\n")
end

if CLIENT then
    net.Receive(RESULT_MESSAGE, function()
        local report = net.ReadString()
        local output = net.ReadString()

        if output == "clipboard" or output == "both" then
            if SetClipboardText then
                SetClipboardText(report)
                chat.AddText(Color(80, 150, 230), "[BetterLights] ", color_white, language.GetPhrase("betterlights.tool.model_lookup.copied"))
            else
                chat.AddText(Color(255, 100, 100), "[BetterLights] ", color_white, language.GetPhrase("betterlights.tool.model_lookup.clipboard_unavailable"))
            end
        end

        if output == "console" or output == "both" then
            MsgN(report)
        end
    end)
end

function TOOL:LeftClick(trace)
    if CLIENT then return true end
    if not trace or not IsValid(trace.Entity) then return false end

    local owner = self:GetOwner()
    if not IsValid(owner) then return false end

    local mode = self:GetClientInfo("mode")
    local output = self:GetClientInfo("output")
    local includeTrace = self:GetClientNumber("trace") ~= 0
    local includeVectors = self:GetClientNumber("vectors") ~= 0
    local report = buildReport(trace, mode, includeTrace, includeVectors)

    net.Start(RESULT_MESSAGE)
    net.WriteString(report)
    net.WriteString(output)
    net.Send(owner)

    return true
end

function TOOL:RightClick()
    return false
end

function TOOL:Reload()
    return false
end

if CLIENT then
    local function getToolConVarValue(name, defaultValue)
        local cvar = GetConVar(TOOL_CVAR_PREFIX .. name)
        if not cvar then return defaultValue end

        return cvar:GetString()
    end

    local function addChoice(combo, labelKey, value, currentValue)
        combo:AddChoice(language.GetPhrase(labelKey), value, value == currentValue)
    end

    function TOOL.BuildCPanel(panel)
        panel:ClearControls()
        panel:Help(language.GetPhrase("betterlights.tool.model_lookup.desc"))

        local mode = vgui.Create("DForm")
        mode:SetName(language.GetPhrase("betterlights.tool.model_lookup.section.mode"))
        mode:SetExpanded(true)
        panel:AddItem(mode)

        local modeCombo = mode:ComboBox(language.GetPhrase("betterlights.tool.model_lookup.mode"), "betterlights_model_lookup_mode")
        local currentMode = getToolConVarValue("mode", CLIENT_CONVAR_DEFAULTS.mode)
        addChoice(modeCombo, "betterlights.tool.model_lookup.mode.summary", "summary", currentMode)
        addChoice(modeCombo, "betterlights.tool.model_lookup.mode.attachments", "attachments", currentMode)
        addChoice(modeCombo, "betterlights.tool.model_lookup.mode.bones", "bones", currentMode)
        addChoice(modeCombo, "betterlights.tool.model_lookup.mode.skins_bodygroups", "skins_bodygroups", currentMode)
        addChoice(modeCombo, "betterlights.tool.model_lookup.mode.materials", "materials", currentMode)
        addChoice(modeCombo, "betterlights.tool.model_lookup.mode.full", "full", currentMode)

        local output = vgui.Create("DForm")
        output:SetName(language.GetPhrase("betterlights.tool.model_lookup.section.output"))
        output:SetExpanded(true)
        panel:AddItem(output)

        local outputCombo = output:ComboBox(language.GetPhrase("betterlights.tool.model_lookup.output"), "betterlights_model_lookup_output")
        local currentOutput = getToolConVarValue("output", CLIENT_CONVAR_DEFAULTS.output)
        addChoice(outputCombo, "betterlights.tool.model_lookup.output.console", "console", currentOutput)
        addChoice(outputCombo, "betterlights.tool.model_lookup.output.clipboard", "clipboard", currentOutput)
        addChoice(outputCombo, "betterlights.tool.model_lookup.output.both", "both", currentOutput)

        local options = vgui.Create("DForm")
        options:SetName(language.GetPhrase("betterlights.tool.model_lookup.section.options"))
        options:SetExpanded(true)
        panel:AddItem(options)

        options:CheckBox(language.GetPhrase("betterlights.tool.model_lookup.include_trace"), "betterlights_model_lookup_trace")
        options:CheckBox(language.GetPhrase("betterlights.tool.model_lookup.include_vectors"), "betterlights_model_lookup_vectors")
        options:Help(language.GetPhrase("betterlights.tool.model_lookup.help"))
    end
end
