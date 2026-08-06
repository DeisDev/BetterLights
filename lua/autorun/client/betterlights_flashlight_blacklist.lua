if CLIENT then
    local BL = BetterLights
    local FL = BL.Flashlight

    local BLACKLIST_PATH = "betterlights/flashlight_attachment_blacklist.json"
    local SCHEMA_VERSION = 1
    local MAX_CLASS_LENGTH = 128
    local MAX_CLASSES = 512
    local BUILTIN_CLASSES = {
        has_hands = true,
        weapon_crowbar = true
    }

    FL._weaponAttachmentBlacklistClasses = FL._weaponAttachmentBlacklistClasses or {}

    local function normalizeClassName(value)
        if IsValid(value) and value.GetClass then
            value = value:GetClass()
        end

        value = string.lower(string.Trim(tostring(value or "")))
        if value == "" or #value > MAX_CLASS_LENGTH then return nil end
        if string.find(value, "%s") then return nil end

        for i = 1, #value do
            local byte = string.byte(value, i)
            if byte < 33 or byte > 126 then return nil end
        end

        return value
    end

    local function getSortedClasses(classMap)
        local classes = {}
        for className in pairs(classMap) do
            classes[#classes + 1] = className
        end

        table.sort(classes)
        return classes
    end

    local function countClasses(classMap)
        local count = 0
        for _ in pairs(classMap) do
            count = count + 1
        end

        return count
    end

    local function copyClasses(classMap)
        local copy = {}
        for className in pairs(classMap) do
            copy[className] = true
        end

        return copy
    end

    local function buildClassMap(classes)
        if type(classes) ~= "table" then return nil, "invalid_classes" end

        local classMap = {}
        local count = 0

        for i = 1, #classes do
            local className = normalizeClassName(classes[i])
            if not className then return nil, "invalid_class" end

            if not BUILTIN_CLASSES[className] and not classMap[className] then
                count = count + 1
                if count > MAX_CLASSES then return nil, "too_many_classes" end
                classMap[className] = true
            end
        end

        return classMap
    end

    local function saveClasses(classMap)
        local encoded = util.TableToJSON({
            schemaVersion = SCHEMA_VERSION,
            classes = getSortedClasses(classMap)
        }, true)
        if not encoded then return false, "encode_failed" end

        file.CreateDir("betterlights")
        if not file.Write(BLACKLIST_PATH, encoded) then return false, "write_failed" end

        return true
    end

    local function loadClasses()
        local source = file.Read(BLACKLIST_PATH, "DATA")
        if not source or source == "" then
            FL._weaponAttachmentBlacklistClasses = {}
            return true
        end

        local decoded = util.JSONToTable(source)
        if type(decoded) ~= "table" then return false, "invalid_json" end
        if decoded.schemaVersion ~= SCHEMA_VERSION then return false, "unsupported_schema" end

        local classMap, err = buildClassMap(decoded.classes)
        if not classMap then return false, err end

        FL._weaponAttachmentBlacklistClasses = classMap
        return true
    end

    local function getEntries()
        local entries = {}

        for className in pairs(BUILTIN_CLASSES) do
            entries[#entries + 1] = {
                className = className,
                builtin = true
            }
        end

        for className in pairs(FL._weaponAttachmentBlacklistClasses) do
            entries[#entries + 1] = {
                className = className,
                builtin = false
            }
        end

        table.sort(entries, function(a, b)
            return a.className < b.className
        end)

        return entries
    end

    local function addClass(value)
        local className = normalizeClassName(value)
        if not className then return false, "invalid_class" end
        if BUILTIN_CLASSES[className] then return false, "builtin", className end

        local current = FL._weaponAttachmentBlacklistClasses
        if current[className] then return false, "already_exists", className end
        if countClasses(current) >= MAX_CLASSES then return false, "too_many_classes" end

        local nextClasses = copyClasses(current)
        nextClasses[className] = true

        local saved, err = saveClasses(nextClasses)
        if not saved then return false, err end

        FL._weaponAttachmentBlacklistClasses = nextClasses
        return true, nil, className
    end

    local function removeClass(value)
        local className = normalizeClassName(value)
        if not className then return false, "invalid_class" end
        if BUILTIN_CLASSES[className] then return false, "builtin", className end

        local current = FL._weaponAttachmentBlacklistClasses
        if not current[className] then return false, "not_found", className end

        local nextClasses = copyClasses(current)
        nextClasses[className] = nil

        local saved, err = saveClasses(nextClasses)
        if not saved then return false, err end

        FL._weaponAttachmentBlacklistClasses = nextClasses
        return true, nil, className
    end

    function FL.IsWeaponAttachmentBlacklisted(value)
        local className = normalizeClassName(value)
        if not className then return false end

        return BUILTIN_CLASSES[className] == true
            or FL._weaponAttachmentBlacklistClasses[className] == true
    end

    function FL.ClearWeaponAttachmentBlacklist()
        local nextClasses = {}
        local saved, err = saveClasses(nextClasses)
        if not saved then return false, err end

        FL._weaponAttachmentBlacklistClasses = nextClasses
        return true
    end

    local function notify(key, kind, ...)
        local MENU = BL.Menu
        local message = select("#", ...) > 0 and MENU.PhraseFormat(key, ...) or MENU.Phrase(key)
        notification.AddLegacy(message, kind or NOTIFY_GENERIC, 4)
        surface.PlaySound(kind == NOTIFY_ERROR and "buttons/button10.wav" or "buttons/button14.wav")
    end

    local function notifyFailure(reason, className)
        if reason == "builtin" then
            notify("notice.flashlight_attachment_blacklist_builtin", NOTIFY_ERROR, className)
        elseif reason == "already_exists" then
            notify("notice.flashlight_attachment_blacklist_exists", NOTIFY_ERROR, className)
        elseif reason == "too_many_classes" then
            notify("notice.flashlight_attachment_blacklist_full", NOTIFY_ERROR)
        elseif reason == "write_failed" or reason == "encode_failed" then
            notify("notice.flashlight_attachment_blacklist_save_failed", NOTIFY_ERROR)
        else
            notify("notice.flashlight_attachment_blacklist_invalid", NOTIFY_ERROR)
        end
    end

    function FL.BuildWeaponAttachmentBlacklistEditor(panel)
        local MENU = BL.Menu
        local list = vgui.Create("DListView")
        list:SetTall(170)
        list:SetMultiSelect(false)
        list:AddColumn(MENU.Phrase("label.weapon_class"))
        list:AddColumn(MENU.Phrase("label.entry_type"))
        panel:AddItem(list)

        local status = vgui.Create("DLabel")
        status:SetTall(18)
        status:SetDark(true)
        panel:AddItem(status)

        local entry = vgui.Create("DTextEntry")
        entry:SetTall(24)
        entry:SetPlaceholderText(MENU.Phrase("placeholder.weapon_class_blacklist"))
        panel:AddItem(entry)

        local removeSelected
        local clearCustom

        local function refreshList()
            list:Clear()

            local entries = getEntries()
            local customCount = 0

            for i = 1, #entries do
                local blacklistEntry = entries[i]
                local sourceKey = blacklistEntry.builtin and "label.builtin" or "label.custom"
                local row = list:AddLine(blacklistEntry.className, MENU.Phrase(sourceKey))
                row.BetterLightsBuiltin = blacklistEntry.builtin

                if not blacklistEntry.builtin then customCount = customCount + 1 end
            end

            status:SetText(MENU.PhraseFormat("label.flashlight_attachment_custom_count", customCount))

            if IsValid(removeSelected) then
                removeSelected:SetEnabled(false)
                removeSelected:SetTooltip(MENU.Phrase("tooltip.select_custom_blacklist_entry"))
            end

            if IsValid(clearCustom) then clearCustom:SetEnabled(customCount > 0) end
        end

        local function addWeaponClass(className)
            local added, reason, normalized = addClass(className)
            if not added then
                notifyFailure(reason, normalized)
                return false
            end

            entry:SetText("")
            refreshList()
            notify("notice.flashlight_attachment_blacklist_added", NOTIFY_GENERIC, normalized)
            return true
        end

        local addTyped = MENU.AddStyledButton(panel, MENU.Phrase("button.add_weapon_class"))
        addTyped.DoClick = function()
            addWeaponClass(entry:GetText())
        end

        entry.OnEnter = function()
            addWeaponClass(entry:GetText())
        end

        local addHeld = MENU.AddStyledButton(panel, MENU.Phrase("button.blacklist_held_weapon"))
        addHeld.DoClick = function()
            local ply = LocalPlayer()
            local weapon = IsValid(ply) and ply:Alive() and ply:GetActiveWeapon() or nil
            if not (IsValid(weapon) and weapon.IsWeapon and weapon:IsWeapon()) then
                notify("notice.flashlight_attachment_blacklist_no_weapon", NOTIFY_ERROR)
                return
            end

            addWeaponClass(weapon:GetClass())
        end

        removeSelected = MENU.AddStyledButton(
            panel,
            MENU.Phrase("button.remove_selected"),
            MENU.Phrase("tooltip.select_custom_blacklist_entry")
        )
        removeSelected:SetEnabled(false)
        removeSelected.DoClick = function()
            local _, row = list:GetSelectedLine()
            if not (IsValid(row) and not row.BetterLightsBuiltin) then return end

            local className = row:GetColumnText(1)
            local removed, reason, normalized = removeClass(className)
            if not removed then
                notifyFailure(reason, normalized)
                return
            end

            entry:SetText("")
            refreshList()
            notify("notice.flashlight_attachment_blacklist_removed", NOTIFY_GENERIC, normalized)
        end

        list.OnRowSelected = function(_, _, row)
            entry:SetText(row:GetColumnText(1))
            removeSelected:SetEnabled(not row.BetterLightsBuiltin)
            removeSelected:SetTooltip(MENU.Phrase(
                row.BetterLightsBuiltin
                    and "tooltip.builtin_blacklist_entry"
                    or "tooltip.remove_custom_blacklist_entry"
            ))
        end

        clearCustom = MENU.AddStyledButton(
            panel,
            MENU.Phrase("button.clear_flashlight_attachment_blacklist"),
            MENU.Phrase("tooltip.clear_flashlight_attachment_blacklist")
        )
        clearCustom.DoClick = function()
            Derma_Query(
                MENU.Phrase("dialog.clear_flashlight_attachment_blacklist.message"),
                MENU.Phrase("dialog.clear_flashlight_attachment_blacklist.title"),
                MENU.Phrase("button.clear_flashlight_attachment_blacklist"),
                function()
                    local cleared, reason = FL.ClearWeaponAttachmentBlacklist()
                    if not cleared then
                        notifyFailure(reason)
                        return
                    end

                    entry:SetText("")
                    refreshList()
                    notify("notice.flashlight_attachment_blacklist_cleared", NOTIFY_GENERIC)
                end,
                MENU.Phrase("button.cancel")
            )
        end

        refreshList()
    end

    local loaded, loadError = loadClasses()
    if not loaded then
        ErrorNoHalt("[BetterLights] Could not load the flashlight attachment blacklist: " .. tostring(loadError) .. "\n")
    end
end
