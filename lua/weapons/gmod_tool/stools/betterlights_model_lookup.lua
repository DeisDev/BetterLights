local function isDeveloperMode()
    local developer = GetConVar("developer")
    return developer and developer:GetInt() >= 1
end

TOOL.Category = "Better Lights"
TOOL.Name = "#tool.betterlights_model_lookup.name"
TOOL.Command = nil
TOOL.ConfigName = ""
TOOL.AddToMenu = isDeveloperMode()
local CLIENT_CONVAR_DEFAULTS = {
    output = "console",
    labels = "1",
    header = "1",
    entity_index = "1",
    entity_class = "1",
    model = "1",
    skin = "1",
    model_scale = "1",
    position = "1",
    angles = "1",
    bounds = "1",
    trace = "1",
    trace_vectors = "1",
    attachments = "0",
    attachment_vectors = "0",
    bones = "0",
    bone_vectors = "0",
    skins_bodygroups = "0",
    materials = "0"
}
TOOL.ClientConVar = CLIENT_CONVAR_DEFAULTS

local RESULT_MESSAGE = "BetterLights_ModelLookup_Result"
local HELD_WEAPON_MESSAGE = "BetterLights_ModelLookup_HeldWeapon"
local TOOL_CVAR_PREFIX = "betterlights_model_lookup_"

if SERVER then
    util.AddNetworkString(RESULT_MESSAGE)
    util.AddNetworkString(HELD_WEAPON_MESSAGE)
end

if CLIENT then
    language.Add("tool.betterlights_model_lookup.name", language.GetPhrase("betterlights.tool.model_lookup.name"))
    language.Add("tool.betterlights_model_lookup.desc", language.GetPhrase("betterlights.tool.model_lookup.desc"))
    language.Add("tool.betterlights_model_lookup.left", language.GetPhrase("betterlights.tool.model_lookup.left"))

    TOOL.Information = {
        { name = "left" }
    }
end

local VALID_OUTPUTS = {
    console = true,
    clipboard = true,
    both = true
}

local LOOKUP_OPTION_NAMES = {
    "labels",
    "header",
    "entity_index",
    "entity_class",
    "model",
    "skin",
    "model_scale",
    "position",
    "angles",
    "bounds",
    "trace",
    "trace_vectors",
    "attachments",
    "attachment_vectors",
    "bones",
    "bone_vectors",
    "skins_bodygroups",
    "materials"
}

local LOOKUP_PRESETS = {
    model_only = {
        model = true
    },
    summary = {
        labels = true,
        header = true,
        entity_index = true,
        entity_class = true,
        model = true,
        skin = true,
        model_scale = true,
        position = true,
        angles = true,
        bounds = true,
        trace = true,
        trace_vectors = true
    },
    full = {
        labels = true,
        header = true,
        entity_index = true,
        entity_class = true,
        model = true,
        skin = true,
        model_scale = true,
        position = true,
        angles = true,
        bounds = true,
        trace = true,
        trace_vectors = true,
        attachments = true,
        attachment_vectors = true,
        bones = true,
        bone_vectors = true,
        skins_bodygroups = true,
        materials = true
    }
}

local function addLine(lines, text)
    lines[#lines + 1] = text
end

local function addBlank(lines)
    lines[#lines + 1] = ""
end

local function addBreak(lines, options)
    if options.labels and #lines > 0 then
        addBlank(lines)
    end
end

local function addSectionHeader(lines, options, title)
    if options.labels then
        addLine(lines, title)
    end
end

local function addField(lines, options, label, value)
    if options.labels then
        addLine(lines, label .. ": " .. tostring(value))
    else
        addLine(lines, tostring(value))
    end
end

local function formatVector(vec)
    if not vec then return "nil" end
    return string.format("%.2f %.2f %.2f", vec.x or 0, vec.y or 0, vec.z or 0)
end

local function formatAngle(ang)
    if not ang then return "nil" end
    return string.format("%.2f %.2f %.2f", ang.p or 0, ang.y or 0, ang.r or 0)
end

local function addEntitySummary(lines, ent, options)
    if not IsValid(ent) then
        addField(lines, options, "Entity", "invalid")
        return
    end

    if options.entity_index then
        addField(lines, options, "Entity index", ent:EntIndex())
    end

    if options.entity_class then
        addField(lines, options, "Class", ent.GetClass and ent:GetClass() or "unknown")
    end

    if options.model then
        addField(lines, options, "Model", ent.GetModel and ent:GetModel() or "unknown")
    end

    if options.skin and ent.GetSkin then
        addField(lines, options, "Skin", ent:GetSkin())
    end

    if options.model_scale and ent.GetModelScale then
        addField(lines, options, "Model scale", ent:GetModelScale())
    end

    if options.position then
        addField(lines, options, "Position", formatVector(ent:GetPos()))
    end

    if options.angles then
        addField(lines, options, "Angles", formatAngle(ent:GetAngles()))
    end

    if options.bounds then
        if ent.WorldSpaceCenter then
            addField(lines, options, "World center", formatVector(ent:WorldSpaceCenter()))
        end

        if ent.OBBMins and ent.OBBMaxs then
            addField(lines, options, "OBB mins", formatVector(ent:OBBMins()))
            addField(lines, options, "OBB maxs", formatVector(ent:OBBMaxs()))
        end
    end
end

local function addTraceInfo(lines, trace, options)
    addSectionHeader(lines, options, "Trace:")

    if options.trace then
        addField(lines, options, "  Hit", trace.Hit)
        addField(lines, options, "  Hit world", trace.HitWorld)
        addField(lines, options, "  Hit group", trace.HitGroup)
        addField(lines, options, "  Physics bone", trace.PhysicsBone)
    end

    if options.trace_vectors then
        addField(lines, options, "  Hit position", formatVector(trace.HitPos))
        addField(lines, options, "  Hit normal", formatVector(trace.HitNormal))
    end
end

local function addAttachmentInfo(lines, ent, options)
    addSectionHeader(lines, options, "Attachments:")

    local found = false
    if IsValid(ent) and ent.GetAttachments and ent.LookupAttachment and ent.GetAttachment then
        local attachments = ent:GetAttachments() or {}
        for _, attachment in ipairs(attachments) do
            found = true
            local id = attachment.id or ent:LookupAttachment(attachment.name or "")
            local line = string.format("  %d: %s", id or 0, tostring(attachment.name))

            if options.attachment_vectors and id and id > 0 then
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

local function addBoneInfo(lines, ent, options)
    addSectionHeader(lines, options, "Bones:")

    local found = false
    if IsValid(ent) and ent.GetBoneCount and ent.GetBoneName then
        local count = ent:GetBoneCount() or 0
        for i = 0, count - 1 do
            found = true
            local line = string.format("  %d: %s", i, tostring(ent:GetBoneName(i)))

            if options.bone_vectors and ent.GetBonePosition then
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

local function addSkinBodygroupInfo(lines, ent, options)
    addSectionHeader(lines, options, "Skins and bodygroups:")

    if not IsValid(ent) then
        addLine(lines, "  none")
        return
    end

    if ent.GetSkin then
        addField(lines, options, "  Current skin", ent:GetSkin())
    end

    if ent.SkinCount then
        addField(lines, options, "  Skin count", ent:SkinCount())
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

local function addMaterialInfo(lines, ent, options)
    addSectionHeader(lines, options, "Materials:")

    local found = false
    if IsValid(ent) and ent.GetMaterials then
        local materials = ent:GetMaterials() or {}
        for i, materialName in ipairs(materials) do
            found = true
            if options.labels then
                addLine(lines, string.format("  %d: %s", i, tostring(materialName)))
            else
                addLine(lines, tostring(materialName))
            end
        end
    end

    if IsValid(ent) and ent.GetMaterial and ent:GetMaterial() ~= "" then
        found = true
        addField(lines, options, "  Override", ent:GetMaterial())
    end

    if not found then
        addLine(lines, "  none")
    end
end

local function buildReport(trace, options)
    local ent = trace.Entity
    local lines = {}

    if options.header then
        addLine(lines, "[BetterLights] Model Lookup Tool")
        addBreak(lines, options)
    end

    addEntitySummary(lines, ent, options)

    if options.trace or options.trace_vectors then
        addBreak(lines, options)
        addTraceInfo(lines, trace, options)
    end

    if options.attachments then
        addBreak(lines, options)
        addAttachmentInfo(lines, ent, options)
    end

    if options.bones then
        addBreak(lines, options)
        addBoneInfo(lines, ent, options)
    end

    if options.skins_bodygroups then
        addBreak(lines, options)
        addSkinBodygroupInfo(lines, ent, options)
    end

    if options.materials then
        addBreak(lines, options)
        addMaterialInfo(lines, ent, options)
    end

    if #lines == 0 then
        addLine(lines, "[BetterLights] No lookup fields selected.")
    end

    return table.concat(lines, "\n")
end

local function buildLookupOptions(readNumber)
    local options = {}

    for _, name in ipairs(LOOKUP_OPTION_NAMES) do
        options[name] = readNumber(name, CLIENT_CONVAR_DEFAULTS[name]) ~= 0
    end

    return options
end

local function getValidatedOutput(output)
    if VALID_OUTPUTS[output] then return output end
    return CLIENT_CONVAR_DEFAULTS.output
end

local function sendReport(owner, report, output)
    net.Start(RESULT_MESSAGE)
    net.WriteString(report)
    net.WriteString(output)
    net.Send(owner)
end

if SERVER then
    local function getPlayerToolInfo(ply, name, defaultValue)
        if not (IsValid(ply) and ply.GetInfo) then return defaultValue end

        local value = ply:GetInfo(TOOL_CVAR_PREFIX .. name)
        if value == nil or value == "" then return defaultValue end
        return value
    end

    local function getPlayerToolNumber(ply, name, defaultValue)
        if not (IsValid(ply) and ply.GetInfoNum) then return tonumber(defaultValue) or 0 end

        return ply:GetInfoNum(TOOL_CVAR_PREFIX .. name, tonumber(defaultValue) or 0)
    end

    local function buildHeldWeaponTrace(weapon)
        local pos = weapon.WorldSpaceCenter and weapon:WorldSpaceCenter() or weapon:GetPos()

        return {
            Entity = weapon,
            Hit = true,
            HitWorld = false,
            HitPos = pos,
            HitNormal = Vector(0, 0, 1),
            HitGroup = 0,
            PhysicsBone = 0
        }
    end

    net.Receive(HELD_WEAPON_MESSAGE, function(_, ply)
        if not isDeveloperMode() then return end
        if not IsValid(ply) then return end

        local weapon = ply:GetActiveWeapon()
        if not IsValid(weapon) then
            sendReport(ply, "[BetterLights] No held weapon to inspect.", "console")
            return
        end

        local output = getValidatedOutput(getPlayerToolInfo(ply, "output", CLIENT_CONVAR_DEFAULTS.output))
        local options = buildLookupOptions(function(name, defaultValue)
            return getPlayerToolNumber(ply, name, defaultValue)
        end)

        sendReport(ply, buildReport(buildHeldWeaponTrace(weapon), options), output)
    end)
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
    if not isDeveloperMode() then return false end
    if not trace or not IsValid(trace.Entity) then return false end

    local owner = self:GetOwner()
    if not IsValid(owner) then return false end

    local output = getValidatedOutput(self:GetClientInfo("output"))
    local options = buildLookupOptions(function(name, defaultValue)
        local value = self:GetClientInfo(name)
        if value == nil or value == "" then return tonumber(defaultValue) or 0 end
        return tonumber(value) or 0
    end)
    local report = buildReport(trace, options)

    sendReport(owner, report, output)

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

    local function setToolBool(name, enabled)
        RunConsoleCommand(TOOL_CVAR_PREFIX .. name, enabled and "1" or "0")
    end

    local function applyPreset(name)
        local preset = LOOKUP_PRESETS[name]
        if not preset then return end

        for _, optionName in ipairs(LOOKUP_OPTION_NAMES) do
            setToolBool(optionName, preset[optionName] == true)
        end
    end

    local function addPresetButton(panel, labelKey, presetName)
        local button = vgui.Create("DButton")
        button:SetTall(28)
        button:SetText(language.GetPhrase(labelKey))
        button.DoClick = function()
            applyPreset(presetName)
        end
        panel:AddItem(button)
        return button
    end

    local function addOptionCheckbox(panel, labelKey, convarName)
        return panel:CheckBox(language.GetPhrase(labelKey), TOOL_CVAR_PREFIX .. convarName)
    end

    function TOOL.BuildCPanel(panel)
        panel:ClearControls()
        panel:Help(language.GetPhrase("betterlights.tool.model_lookup.desc"))

        local actions = vgui.Create("DForm")
        actions:SetName(language.GetPhrase("betterlights.tool.model_lookup.section.actions"))
        actions:SetExpanded(true)
        panel:AddItem(actions)

        local inspectHeldWeapon = vgui.Create("DButton")
        inspectHeldWeapon:SetTall(28)
        inspectHeldWeapon:SetText(language.GetPhrase("betterlights.tool.model_lookup.inspect_held_weapon"))
        inspectHeldWeapon:SetTooltip(language.GetPhrase("betterlights.tool.model_lookup.inspect_held_weapon.help"))
        inspectHeldWeapon.DoClick = function()
            net.Start(HELD_WEAPON_MESSAGE)
            net.SendToServer()
        end
        actions:AddItem(inspectHeldWeapon)

        local presets = vgui.Create("DForm")
        presets:SetName(language.GetPhrase("betterlights.tool.model_lookup.section.presets"))
        presets:SetExpanded(true)
        panel:AddItem(presets)

        addPresetButton(presets, "betterlights.tool.model_lookup.preset.model_only", "model_only")
        addPresetButton(presets, "betterlights.tool.model_lookup.preset.summary", "summary")
        addPresetButton(presets, "betterlights.tool.model_lookup.preset.full", "full")

        local output = vgui.Create("DForm")
        output:SetName(language.GetPhrase("betterlights.tool.model_lookup.section.output"))
        output:SetExpanded(true)
        panel:AddItem(output)

        local outputCombo = output:ComboBox(language.GetPhrase("betterlights.tool.model_lookup.output"), "betterlights_model_lookup_output")
        local currentOutput = getToolConVarValue("output", CLIENT_CONVAR_DEFAULTS.output)
        addChoice(outputCombo, "betterlights.tool.model_lookup.output.console", "console", currentOutput)
        addChoice(outputCombo, "betterlights.tool.model_lookup.output.clipboard", "clipboard", currentOutput)
        addChoice(outputCombo, "betterlights.tool.model_lookup.output.both", "both", currentOutput)

        local formatting = vgui.Create("DForm")
        formatting:SetName(language.GetPhrase("betterlights.tool.model_lookup.section.formatting"))
        formatting:SetExpanded(false)
        panel:AddItem(formatting)

        addOptionCheckbox(formatting, "betterlights.tool.model_lookup.field.labels", "labels")
        addOptionCheckbox(formatting, "betterlights.tool.model_lookup.field.header", "header")

        local fields = vgui.Create("DForm")
        fields:SetName(language.GetPhrase("betterlights.tool.model_lookup.section.fields"))
        fields:SetExpanded(true)
        panel:AddItem(fields)

        addOptionCheckbox(fields, "betterlights.tool.model_lookup.field.entity_index", "entity_index")
        addOptionCheckbox(fields, "betterlights.tool.model_lookup.field.entity_class", "entity_class")
        addOptionCheckbox(fields, "betterlights.tool.model_lookup.field.model", "model")
        addOptionCheckbox(fields, "betterlights.tool.model_lookup.field.skin", "skin")
        addOptionCheckbox(fields, "betterlights.tool.model_lookup.field.model_scale", "model_scale")
        addOptionCheckbox(fields, "betterlights.tool.model_lookup.field.position", "position")
        addOptionCheckbox(fields, "betterlights.tool.model_lookup.field.angles", "angles")
        addOptionCheckbox(fields, "betterlights.tool.model_lookup.field.bounds", "bounds")

        local traceFields = vgui.Create("DForm")
        traceFields:SetName(language.GetPhrase("betterlights.tool.model_lookup.section.trace"))
        traceFields:SetExpanded(false)
        panel:AddItem(traceFields)

        addOptionCheckbox(traceFields, "betterlights.tool.model_lookup.field.trace", "trace")
        addOptionCheckbox(traceFields, "betterlights.tool.model_lookup.field.trace_vectors", "trace_vectors")

        local expanded = vgui.Create("DForm")
        expanded:SetName(language.GetPhrase("betterlights.tool.model_lookup.section.expanded_fields"))
        expanded:SetExpanded(false)
        panel:AddItem(expanded)

        addOptionCheckbox(expanded, "betterlights.tool.model_lookup.field.attachments", "attachments")
        addOptionCheckbox(expanded, "betterlights.tool.model_lookup.field.attachment_vectors", "attachment_vectors")
        addOptionCheckbox(expanded, "betterlights.tool.model_lookup.field.bones", "bones")
        addOptionCheckbox(expanded, "betterlights.tool.model_lookup.field.bone_vectors", "bone_vectors")
        addOptionCheckbox(expanded, "betterlights.tool.model_lookup.field.skins_bodygroups", "skins_bodygroups")
        addOptionCheckbox(expanded, "betterlights.tool.model_lookup.field.materials", "materials")
        expanded:Help(language.GetPhrase("betterlights.tool.model_lookup.help"))
    end
end
