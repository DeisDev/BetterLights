if CLIENT then
    local MENU = BetterLights.Menu
    local phrase = MENU.Phrase
    local phraseFormat = MENU.PhraseFormat
    local setupPage = MENU.SetupPage
    local addSection = MENU.AddSection
    local addHelpText = MENU.AddHelpText
    local addFlashlightCheckbox = MENU.AddFlashlightCheckbox
    local addFlashlightSlider = MENU.AddFlashlightSlider
    local addFlashlightColorMixer = MENU.AddFlashlightColorMixer
    local addFlashlightResetButton = MENU.AddFlashlightResetButton
    local beginControlGroup = MENU.BeginControlGroup
    local getEffectiveFlashlightBool = MENU.GetEffectiveFlashlightBool
    local getEffectiveFlashlightString = MENU.GetEffectiveFlashlightString
    local isFlashlightSettingForced = MENU.IsFlashlightSettingForced
    local addServerControlledHelp = MENU.AddServerControlledHelp
    local styleButton = MENU.StyleButton
    local addStyledButton = MENU.AddStyledButton
    local copyText = MENU.CopyText
    local addCurrentTexturePreview = MENU.AddCurrentTexturePreview
    local addTextureGrid = MENU.AddTextureGrid
    local populateFlashlightVisualPanel
    local activeFlashlightVisualPanel
    local activeFlashlightVisualFilter

    populateFlashlightVisualPanel = function(panel, filterText)
        setupPage(panel, "page.flashlight_visuals.title", "page.flashlight_visuals.desc")
        activeFlashlightVisualPanel = panel
        activeFlashlightVisualFilter = filterText

        local beam = addSection(panel, "section.beam", "section.beam.desc", true)
        addFlashlightCheckbox(beam, phrase("control.cast_shadows"), "betterlights_flashlight_shadows")
        addFlashlightCheckbox(beam, phrase("control.flicker"), "betterlights_flashlight_flicker")
        addFlashlightSlider(beam, phrase("control.flicker_amount"), "betterlights_flashlight_flicker_amount", 0, 0.3, 2)
        addFlashlightCheckbox(beam, phrase("control.flashlight_sway"), "betterlights_flashlight_sway")
        addFlashlightSlider(beam, phrase("control.sway_intensity"), "betterlights_flashlight_sway_intensity", 0, 3, 2)
        addFlashlightSlider(beam, phrase("control.brightness"), "betterlights_flashlight_brightness", 0.1, 5, 2)
        addFlashlightSlider(beam, phrase("control.fov"), "betterlights_flashlight_fov", 10, 120, 0)
        addFlashlightSlider(beam, phrase("control.beam_length"), "betterlights_flashlight_distance", 128, 4096, 0)

        local advancedShadows = addSection(panel, "section.advanced_shadows", "section.advanced_shadows.desc", false)
        local shadowsForced = isFlashlightSettingForced("betterlights_flashlight_shadows")
        beginControlGroup(advancedShadows, "betterlights_flashlight_shadows", function()
            return getEffectiveFlashlightBool("betterlights_flashlight_shadows")
        end, shadowsForced and {
            disabledHelpKey = "state.feature_disabled_by_server",
            disabledTitleKey = "state.section_disabled_by_server",
            highlighted = true
        } or nil)
        addHelpText(advancedShadows, phrase("help.advanced_shadow_settings"))
        addFlashlightSlider(advancedShadows, phrase("control.shadow_depth_bias"), "betterlights_flashlight_shadow_depth_bias", 0, 0.005, 5)
        addFlashlightSlider(advancedShadows, phrase("control.shadow_slope_scale_depth_bias"), "betterlights_flashlight_shadow_slope_scale_depth_bias", 0, 8, 2)
        addFlashlightSlider(advancedShadows, phrase("control.shadow_filter"), "betterlights_flashlight_shadow_filter", 0, 4, 2)

        local flare = addSection(panel, "section.flare", "section.flare.desc", true)
        addFlashlightCheckbox(flare, phrase("control.flashlight_flare"), "betterlights_flashlight_flare_enable")
        addFlashlightCheckbox(flare, phrase("control.show_other_flashlight_flares"), "betterlights_flashlight_flare_others")
        addHelpText(flare, phrase("help.show_other_flashlight_flares"))
        addFlashlightSlider(flare, phrase("control.flare_size"), "betterlights_flashlight_flare_size", 0.25, 3, 2)
        addFlashlightSlider(flare, phrase("control.flare_opacity"), "betterlights_flashlight_flare_opacity", 0, 255, 0)

        local colorSection = addSection(panel, "section.color", "section.color.desc", true)
        addFlashlightColorMixer(colorSection, "control.flashlight_color", "betterlights_flashlight_color_r", "betterlights_flashlight_color_g", "betterlights_flashlight_color_b")

        local texture = addSection(panel, "section.texture", "section.texture.desc", true)

        local currentCvar = GetConVar("betterlights_flashlight_texture")
        local textureForced = isFlashlightSettingForced("betterlights_flashlight_texture")
        local typedPath = textureForced and getEffectiveFlashlightString("betterlights_flashlight_texture")
            or (currentCvar and currentCvar:GetString() or "effects/flashlight001")
        local currentPath = BetterLights.GetFlashlightTexturePath()

        addHelpText(texture, phraseFormat("help.current_texture", currentPath))
        if textureForced then
            addServerControlledHelp(texture)
        end
        addCurrentTexturePreview(texture, currentPath)

        local manualEntry = vgui.Create("DTextEntry")
        manualEntry:SetText(typedPath)
        manualEntry:SetUpdateOnType(false)
        manualEntry:SetEnabled(not textureForced)
        texture:AddItem(manualEntry)

        local manualButtons = vgui.Create("DPanel")
        manualButtons:SetTall(28)
        manualButtons.Paint = nil

        local useManual = styleButton(vgui.Create("DButton", manualButtons))
        useManual:Dock(LEFT)
        useManual:SetWide(76)
        useManual:SetText(phrase("button.use"))
        useManual:SetEnabled(not textureForced)
        useManual.DoClick = function()
            local path = BetterLights.NormalizeFlashlightTexturePath(manualEntry:GetText())
            if BetterLights.SetFlashlightTexturePath(path) then
                notification.AddLegacy(phrase("notice.flashlight_texture_changed"), NOTIFY_GENERIC, 3)
                surface.PlaySound("buttons/button15.wav")
                return
            end

            notification.AddLegacy(phrase("notice.texture_not_found"), NOTIFY_ERROR, 4)
            surface.PlaySound("buttons/button10.wav")
        end

        local copyCurrent = styleButton(vgui.Create("DButton", manualButtons))
        copyCurrent:Dock(LEFT)
        copyCurrent:DockMargin(6, 0, 0, 0)
        copyCurrent:SetWide(76)
        copyCurrent:SetText(phrase("button.copy"))
        copyCurrent.DoClick = function()
            copyText(currentPath)
        end

        local useDefault = styleButton(vgui.Create("DButton", manualButtons))
        useDefault:Dock(LEFT)
        useDefault:DockMargin(6, 0, 0, 0)
        useDefault:SetWide(76)
        useDefault:SetText(phrase("button.default"))
        useDefault:SetEnabled(not textureForced)
        useDefault.DoClick = function()
            BetterLights.SetFlashlightTexturePath("effects/flashlight001")
        end

        texture:AddItem(manualButtons)

        local recent = BetterLights.GetFlashlightRecentTextures()
        if #recent > 0 then
            local recentSection = addSection(panel, "section.recent_textures", nil, false)
            addTextureGrid(recentSection, recent, not textureForced)

            local clearRecent = addStyledButton(recentSection, phrase("button.clear_recent_textures"))
            clearRecent.DoClick = function()
                BetterLights.ClearFlashlightRecentTextures()

                populateFlashlightVisualPanel(panel, filterText)
            end
        end

        local knownSection = addSection(panel, "section.known_textures", "section.known_textures.desc", false)

        local refreshTextures = addStyledButton(knownSection, phrase("button.refresh_textures"))
        refreshTextures.DoClick = function()
            BetterLights.ClearFlashlightKnownTextureCache()

            populateFlashlightVisualPanel(panel, filterText)
        end

        local filterRow = vgui.Create("DPanel")
        filterRow:SetTall(28)
        filterRow.Paint = nil

        local filter = vgui.Create("DTextEntry", filterRow)
        filter:Dock(FILL)
        filter:SetPlaceholderText(phrase("placeholder.search_texture_paths"))
        filter:SetText(filterText or "")

        local applyFilter = styleButton(vgui.Create("DButton", filterRow))
        applyFilter:Dock(RIGHT)
        applyFilter:SetWide(72)
        applyFilter:SetText(phrase("button.search"))
        applyFilter.DoClick = function()
            populateFlashlightVisualPanel(panel, filter:GetText())
        end

        filter.OnEnter = applyFilter.DoClick
        knownSection:AddItem(filterRow)

        local known = BetterLights.GetFlashlightKnownTextures()
        local filtered = {}
        local needle = string.lower(string.Trim(filterText or ""))

        for _, path in ipairs(known) do
            if needle == "" or string.find(string.lower(path), needle, 1, true) then
                filtered[#filtered + 1] = path
            end
        end

        if #filtered > 0 then
            addTextureGrid(knownSection, filtered, not textureForced)
        else
            addHelpText(knownSection, phrase("help.no_matching_textures"))
        end

        addFlashlightResetButton(panel, {
            betterlights_flashlight_brightness = 1.35,
            betterlights_flashlight_fov = 45,
            betterlights_flashlight_distance = 1200,
            betterlights_flashlight_shadows = 1,
            betterlights_flashlight_flicker = 0,
            betterlights_flashlight_flicker_amount = 0.05,
            betterlights_flashlight_sway = 1,
            betterlights_flashlight_sway_intensity = 1,
            betterlights_flashlight_flare_enable = 1,
            betterlights_flashlight_flare_others = 1,
            betterlights_flashlight_flare_size = 1,
            betterlights_flashlight_flare_opacity = 90,
            betterlights_flashlight_shadow_depth_bias = 0.001,
            betterlights_flashlight_shadow_slope_scale_depth_bias = 4,
            betterlights_flashlight_shadow_filter = 1.25,
            betterlights_flashlight_color_r = 255,
            betterlights_flashlight_color_g = 245,
            betterlights_flashlight_color_b = 225,
            betterlights_flashlight_texture = "effects/flashlight001",
        }, phrase("button.reset_visual_settings"))
    end

    cvars.RemoveChangeCallback("betterlights_flashlight_texture", "BetterLights_FlashlightVisualRefresh")
    cvars.AddChangeCallback("betterlights_flashlight_texture", function()
        timer.Simple(0, function()
            if not IsValid(activeFlashlightVisualPanel) then return end
            populateFlashlightVisualPanel(activeFlashlightVisualPanel, activeFlashlightVisualFilter)
        end)
    end, "BetterLights_FlashlightVisualRefresh")

    local pages = {}
    local function registerPage(category, id, titleKey, buildPanel, descriptionKey, options)
        local page = {}
        for key, value in pairs(options or {}) do
            page[key] = value
        end
        page.category = category
        page.id = id
        page.titleKey = titleKey
        page.buildPanel = buildPanel
        page.descriptionKey = descriptionKey
        pages[#pages + 1] = page
    end
    registerPage("Flashlight", "BL_FlashlightGeneral", "menu.general", function(panel)
            setupPage(panel, "page.player_flashlight.title", "page.player_flashlight.desc")
            local behavior = addSection(panel, "section.behavior", nil, true)
            addFlashlightCheckbox(behavior, phrase("control.replace_flashlight"), "betterlights_flashlight_player_enable")
            addFlashlightCheckbox(behavior, phrase("control.use_flashlight_sounds"), "betterlights_flashlight_custom_sounds")
            addHelpText(behavior, phrase("help.default_flashlight_sounds"))

            addFlashlightResetButton(panel, {
                betterlights_flashlight_player_enable = 0,
                betterlights_flashlight_custom_sounds = 1,
            })
        end, "page.player_flashlight.desc")

    registerPage("Flashlight", "BL_FlashlightPosition", "menu.position", function(panel)
            setupPage(panel, "page.flashlight_position.title", "page.flashlight_position.desc")
            local firstPerson = addSection(
                panel,
                "section.flashlight_position_first_person",
                "section.flashlight_position_first_person.desc",
                true
            )
            addFlashlightCheckbox(firstPerson, phrase("control.attach_beam_to_weapon"), "betterlights_flashlight_weapon_attachment")
            addHelpText(firstPerson, phrase("help.attach_beam_to_weapon"))
            addFlashlightSlider(firstPerson, phrase("control.forward_offset"), "betterlights_flashlight_forward_offset", -32, 96, 1)
            addHelpText(firstPerson, phrase("help.forward_offset"))
            addFlashlightSlider(firstPerson, phrase("control.attached_side_offset"), "betterlights_flashlight_attachment_offset", -24, 24, 1)
            addHelpText(firstPerson, phrase("help.attached_side_offset"))
            addFlashlightSlider(firstPerson, phrase("control.view_origin_side_offset"), "betterlights_flashlight_fallback_offset", -24, 24, 1)
            addHelpText(firstPerson, phrase("help.view_origin_side_offset"))

            local world = addSection(
                panel,
                "section.flashlight_position_world",
                "section.flashlight_position_world.desc",
                true
            )
            addFlashlightCheckbox(world, phrase("control.attach_beam_to_weapon"), "betterlights_flashlight_world_weapon_attachment")
            addHelpText(world, phrase("help.attach_beam_to_weapon"))
            addFlashlightSlider(world, phrase("control.forward_offset"), "betterlights_flashlight_world_forward_offset", -32, 96, 1)
            addHelpText(world, phrase("help.forward_offset"))
            addFlashlightSlider(world, phrase("control.attached_side_offset"), "betterlights_flashlight_world_attachment_offset", -24, 24, 1)
            addHelpText(world, phrase("help.attached_side_offset"))
            addFlashlightSlider(world, phrase("control.view_origin_side_offset"), "betterlights_flashlight_world_fallback_offset", -24, 24, 1)
            addHelpText(world, phrase("help.view_origin_side_offset"))

            local spill = addSection(
                panel,
                "section.flashlight_world_spill",
                "section.flashlight_world_spill.desc",
                true
            )
            addFlashlightCheckbox(spill, phrase("control.flashlight_world_spill"), "betterlights_flashlight_world_spill")
            local spillForced = isFlashlightSettingForced("betterlights_flashlight_world_spill")
            beginControlGroup(spill, "betterlights_flashlight_world_spill", function()
                return getEffectiveFlashlightBool("betterlights_flashlight_world_spill")
            end, spillForced and {
                disabledHelpKey = "state.feature_disabled_by_server",
                disabledTitleKey = "state.section_disabled_by_server",
                highlighted = true
            } or nil)
            addFlashlightCheckbox(spill, phrase("control.flashlight_world_spill_match"), "betterlights_flashlight_world_spill_match")
            addHelpText(spill, phrase("help.flashlight_world_spill_match"))
            addFlashlightSlider(spill, phrase("control.flashlight_world_spill_size"), "betterlights_flashlight_world_spill_size", 32, 512, 0)
            addFlashlightSlider(spill, phrase("control.flashlight_world_spill_brightness"), "betterlights_flashlight_world_spill_brightness", 0.1, 5, 2)
            addFlashlightColorMixer(
                spill,
                "control.flashlight_world_spill_color",
                "betterlights_flashlight_world_spill_color_r",
                "betterlights_flashlight_world_spill_color_g",
                "betterlights_flashlight_world_spill_color_b",
                255,
                245,
                225
            )

            addFlashlightResetButton(panel, {
                betterlights_flashlight_weapon_attachment = 1,
                betterlights_flashlight_forward_offset = 0,
                betterlights_flashlight_attachment_offset = 2,
                betterlights_flashlight_fallback_offset = 0,
                betterlights_flashlight_world_weapon_attachment = 1,
                betterlights_flashlight_world_forward_offset = 16,
                betterlights_flashlight_world_attachment_offset = 2,
                betterlights_flashlight_world_fallback_offset = 0,
                betterlights_flashlight_world_spill = 0,
                betterlights_flashlight_world_spill_match = 1,
                betterlights_flashlight_world_spill_size = 128,
                betterlights_flashlight_world_spill_brightness = 0.47,
                betterlights_flashlight_world_spill_color_r = 255,
                betterlights_flashlight_world_spill_color_g = 245,
                betterlights_flashlight_world_spill_color_b = 225,
            })

            local blacklist = addSection(
                panel,
                "section.flashlight_attachment_blacklist",
                "section.flashlight_attachment_blacklist.desc",
                false
            )
            BetterLights.Flashlight.BuildWeaponAttachmentBlacklistEditor(blacklist)
        end, "page.flashlight_position.desc")

    registerPage("Flashlight", "BL_FlashlightVisual", "menu.visual", function(panel)
            BetterLights.ClearFlashlightKnownTextureCache()

            populateFlashlightVisualPanel(panel)
        end, "page.flashlight_visuals.desc")

    MENU.RegisterPages("BetterLights_Menu_Flashlight", pages)
end
