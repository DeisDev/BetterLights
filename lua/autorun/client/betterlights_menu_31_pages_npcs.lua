if CLIENT then
    local MENU = BetterLights.Menu
    local phrase = MENU.Phrase
    local setupPage = MENU.SetupPage
    local addSection = MENU.AddSection
    local addHelpText = MENU.AddHelpText
    local addBulkToggleSection = MENU.AddBulkToggleSection
    local addLightControls = MENU.AddLightControls
    local addModelElightControls = MENU.AddModelElightControls
    local addColorMixerControl = MENU.AddColorMixerControl
    local addResetButton = MENU.AddResetButton

    local function buildNPCRagdollLightsPage(panel)
        setupPage(panel, "page.npc_remains.title", "page.npc_remains.desc")

        local persistence = addSection(panel, "section.npc_remains", "section.npc_remains.desc", true)
        persistence.BetterLightsSkipAutoState = true
        persistence:CheckBox(
            phrase("control.keep_npc_eye_lights_after_death"),
            "betterlights_npc_ragdoll_eye_lights_enable"
        )
        persistence:CheckBox(
            phrase("control.keep_npc_ambient_lights_after_death"),
            "betterlights_npc_ragdoll_ambient_lights_enable"
        )
        persistence:NumSlider(
            phrase("control.maximum_lit_remains"),
            "betterlights_npc_ragdoll_max_lit_remains",
            0,
            32,
            0
        )
        addHelpText(persistence, phrase("help.npc_remains_supported"))
        addHelpText(persistence, phrase("help.npc_remains_budget"))

        addResetButton(panel, {
            betterlights_npc_ragdoll_eye_lights_enable = 0,
            betterlights_npc_ragdoll_ambient_lights_enable = 0,
            betterlights_npc_ragdoll_max_lit_remains = 8,
        })
    end
    local function addRollerminePanel(panel)
        setupPage(panel, "page.rollermines.title", "page.rollermines.desc")

        addBulkToggleSection(panel, {
            "betterlights_rollermine_enable",
            "betterlights_rollermine_hacked_enable"
        })

        local standard = addSection(
            panel,
            "section.rollermine_standard",
            "section.rollermine_standard.desc",
            true
        )
        addLightControls(standard, "betterlights_rollermine", {
            radiusMax = 400,
            modelElight = true,
            modelElightLabel = "control.add_model_elight"
        })
        addColorMixerControl(
            standard,
            "rollermine.default",
            "betterlights_rollermine_color_r",
            "betterlights_rollermine_color_g",
            "betterlights_rollermine_color_b",
            110,
            190,
            255
        )
        local hacked = addSection(
            panel,
            "section.rollermine_hacked",
            "section.rollermine_hacked.desc",
            true
        )
        addLightControls(hacked, "betterlights_rollermine_hacked", {
            radiusMax = 400,
            modelElight = true,
            modelElightLabel = "control.add_model_elight"
        })
        addColorMixerControl(
            hacked,
            "rollermine.hacked",
            "betterlights_rollermine_skin1_color_r",
            "betterlights_rollermine_skin1_color_g",
            "betterlights_rollermine_skin1_color_b",
            255,
            220,
            60
        )
        addColorMixerControl(
            hacked,
            "rollermine.power_down",
            "betterlights_rollermine_skin2_color_r",
            "betterlights_rollermine_skin2_color_g",
            "betterlights_rollermine_skin2_color_b",
            255,
            80,
            80
        )

        addResetButton(panel, {
            betterlights_rollermine_enable = 1,
            betterlights_rollermine_size = 110,
            betterlights_rollermine_brightness = 0.6,
            betterlights_rollermine_decay = 2000,
            betterlights_rollermine_models_elight = 1,
            betterlights_rollermine_models_elight_size_mult = 1.0,
            betterlights_rollermine_hacked_enable = 1,
            betterlights_rollermine_hacked_size = 110,
            betterlights_rollermine_hacked_brightness = 0.6,
            betterlights_rollermine_hacked_decay = 2000,
            betterlights_rollermine_hacked_models_elight = 1,
            betterlights_rollermine_hacked_models_elight_size_mult = 1.0,
            betterlights_rollermine_color_r = 110,
            betterlights_rollermine_color_g = 190,
            betterlights_rollermine_color_b = 255,
            betterlights_rollermine_skin1_color_r = 255,
            betterlights_rollermine_skin1_color_g = 220,
            betterlights_rollermine_skin1_color_b = 60,
            betterlights_rollermine_skin2_color_r = 255,
            betterlights_rollermine_skin2_color_g = 80,
            betterlights_rollermine_skin2_color_b = 80,
        })
    end

    local function addAntlionPanel(panel)
        setupPage(panel, "page.antlions.title", "page.antlions.desc")

        local grub = addSection(panel, "page.antlion_grub.title", "page.antlion_grub.desc", true)
        grub:CheckBox(phrase("control.enable"), "betterlights_antlion_grub_enable")
        grub:NumSlider(phrase("control.radius"), "betterlights_antlion_grub_size", 0, 400, 0)
        grub:NumSlider(phrase("control.brightness"), "betterlights_antlion_grub_brightness", 0, 5, 2)
        grub:NumSlider(phrase("control.decay"), "betterlights_antlion_grub_decay", 0, 5000, 0)
        addColorMixerControl(grub, "control.color", "betterlights_antlion_grub_color_r", "betterlights_antlion_grub_color_g", "betterlights_antlion_grub_color_b")

        local squashedGrub = addSection(panel, "section.squashed_body_glow", nil, false)
        squashedGrub:CheckBox(phrase("control.enable"), "betterlights_antlion_grub_squashed_enable")
        squashedGrub:NumSlider(phrase("control.radius"), "betterlights_antlion_grub_squashed_size", 0, 200, 0)
        squashedGrub:NumSlider(phrase("control.brightness"), "betterlights_antlion_grub_squashed_brightness", 0, 1, 2)
        squashedGrub:NumSlider(phrase("control.decay"), "betterlights_antlion_grub_squashed_decay", 0, 5000, 0)

        local guardian = addSection(panel, "page.antlion_guardian.title", "page.antlion_guardian.desc", true)
        guardian:CheckBox(phrase("control.enable"), "betterlights_antlion_guardian_enable")
        guardian:NumSlider(phrase("control.radius"), "betterlights_antlion_guardian_size", 0, 800, 0)
        guardian:NumSlider(phrase("control.brightness"), "betterlights_antlion_guardian_brightness", 0, 5, 2)
        guardian:NumSlider(phrase("control.decay"), "betterlights_antlion_guardian_decay", 0, 5000, 0)
        addColorMixerControl(guardian, "control.color", "betterlights_antlion_guardian_color_r", "betterlights_antlion_guardian_color_g", "betterlights_antlion_guardian_color_b")

        local worker = addSection(panel, "page.antlion_worker.title", "page.antlion_worker.desc", true)
        worker:CheckBox(phrase("control.enable"), "betterlights_antlion_worker_enable")
        worker:NumSlider(phrase("control.radius"), "betterlights_antlion_worker_size", 0, 800, 0)
        worker:NumSlider(phrase("control.brightness"), "betterlights_antlion_worker_brightness", 0, 5, 2)
        worker:NumSlider(phrase("control.decay"), "betterlights_antlion_worker_decay", 0, 5000, 0)
        addColorMixerControl(worker, "control.color", "betterlights_antlion_worker_color_r", "betterlights_antlion_worker_color_g", "betterlights_antlion_worker_color_b")

        local spitGlow = addSection(panel, "section.spit_projectile", "section.spit_projectile.desc", true)
        spitGlow:CheckBox(phrase("control.enable_glow"), "betterlights_antlion_spit_enable")
        spitGlow:NumSlider(phrase("control.radius"), "betterlights_antlion_spit_size", 0, 400, 0)
        spitGlow:NumSlider(phrase("control.brightness"), "betterlights_antlion_spit_brightness", 0, 5, 2)
        spitGlow:NumSlider(phrase("control.decay"), "betterlights_antlion_spit_decay", 0, 5000, 0)
        addColorMixerControl(spitGlow, "control.glow_color", "betterlights_antlion_spit_color_r", "betterlights_antlion_spit_color_g", "betterlights_antlion_spit_color_b")

        local spitFlash = addSection(panel, "section.impact_flash", nil, true)
        spitFlash:CheckBox(phrase("control.flash_on_impact"), "betterlights_antlion_spit_flash_enable")
        spitFlash:NumSlider(phrase("control.radius"), "betterlights_antlion_spit_flash_size", 0, 800, 0)
        spitFlash:NumSlider(phrase("control.brightness"), "betterlights_antlion_spit_flash_brightness", 0, 10, 2)
        spitFlash:NumSlider(phrase("control.duration"), "betterlights_antlion_spit_flash_time", 0, 1, 2)
        addColorMixerControl(spitFlash, "control.flash_color", "betterlights_antlion_spit_flash_color_r", "betterlights_antlion_spit_flash_color_g", "betterlights_antlion_spit_flash_color_b")

        addResetButton(panel, {
            betterlights_antlion_grub_enable = 1,
            betterlights_antlion_grub_size = 70,
            betterlights_antlion_grub_brightness = 0.35,
            betterlights_antlion_grub_decay = 2000,
            betterlights_antlion_grub_color_r = 120,
            betterlights_antlion_grub_color_g = 255,
            betterlights_antlion_grub_color_b = 120,
            betterlights_antlion_grub_squashed_enable = 1,
            betterlights_antlion_grub_squashed_size = 42,
            betterlights_antlion_grub_squashed_brightness = 0.08,
            betterlights_antlion_grub_squashed_decay = 2000,
            betterlights_antlion_guardian_enable = 1,
            betterlights_antlion_guardian_size = 180,
            betterlights_antlion_guardian_brightness = 0.6,
            betterlights_antlion_guardian_decay = 2000,
            betterlights_antlion_guardian_color_r = 120,
            betterlights_antlion_guardian_color_g = 255,
            betterlights_antlion_guardian_color_b = 140,
            betterlights_antlion_worker_enable = 1,
            betterlights_antlion_worker_size = 120,
            betterlights_antlion_worker_brightness = 0.55,
            betterlights_antlion_worker_decay = 2000,
            betterlights_antlion_worker_color_r = 180,
            betterlights_antlion_worker_color_g = 240,
            betterlights_antlion_worker_color_b = 120,
            betterlights_antlion_spit_enable = 1,
            betterlights_antlion_spit_size = 100,
            betterlights_antlion_spit_brightness = 1.0,
            betterlights_antlion_spit_decay = 1800,
            betterlights_antlion_spit_color_r = 120,
            betterlights_antlion_spit_color_g = 255,
            betterlights_antlion_spit_color_b = 140,
            betterlights_antlion_spit_flash_enable = 1,
            betterlights_antlion_spit_flash_size = 160,
            betterlights_antlion_spit_flash_brightness = 1.5,
            betterlights_antlion_spit_flash_time = 1.0,
            betterlights_antlion_spit_flash_color_r = 180,
            betterlights_antlion_spit_flash_color_g = 255,
            betterlights_antlion_spit_flash_color_b = 120,
        })
    end

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
    registerPage("NPCs", "BL_NPCRemains", "menu.npc_remains", buildNPCRagdollLightsPage)

    registerPage("NPCs", "BL_Strider", "menu.strider", function(panel)
            setupPage(panel, "page.strider.title", "page.strider.desc")

            local muzzle = addSection(panel, "section.muzzle_flash", nil, true)
            muzzle:CheckBox(phrase("control.flash_on_fire"), "betterlights_strider_muzzle_flash_enable")
            muzzle:NumSlider(phrase("control.radius"), "betterlights_strider_muzzle_flash_size", 0, 1000, 0)
            muzzle:NumSlider(phrase("control.brightness"), "betterlights_strider_muzzle_flash_brightness", 0, 10, 2)
            muzzle:NumSlider(phrase("control.duration"), "betterlights_strider_muzzle_flash_time", 0, 1, 2)
            addColorMixerControl(muzzle, "control.flash_color", "betterlights_strider_muzzle_flash_color_r", "betterlights_strider_muzzle_flash_color_g", "betterlights_strider_muzzle_flash_color_b")

            local impact = addSection(panel, "section.impact_flash", nil, true)
            impact:CheckBox(phrase("control.flash_on_impact"), "betterlights_strider_bullet_impact_enable")
            impact:NumSlider(phrase("control.radius"), "betterlights_strider_bullet_impact_size", 0, 400, 0)
            impact:NumSlider(phrase("control.brightness"), "betterlights_strider_bullet_impact_brightness", 0, 5, 2)
            impact:NumSlider(phrase("control.duration"), "betterlights_strider_bullet_impact_time", 0, 1, 2)
            addColorMixerControl(impact, "control.flash_color", "betterlights_strider_bullet_impact_color_r", "betterlights_strider_bullet_impact_color_g", "betterlights_strider_bullet_impact_color_b")

            addResetButton(panel, {
                betterlights_strider_muzzle_flash_enable = 1,
                betterlights_strider_muzzle_flash_size = 320,
                betterlights_strider_muzzle_flash_brightness = 2.4,
                betterlights_strider_muzzle_flash_time = 0.08,
                betterlights_strider_muzzle_flash_color_r = 80,
                betterlights_strider_muzzle_flash_color_g = 210,
                betterlights_strider_muzzle_flash_color_b = 255,
                betterlights_strider_bullet_impact_enable = 1,
                betterlights_strider_bullet_impact_size = 90,
                betterlights_strider_bullet_impact_brightness = 0.45,
                betterlights_strider_bullet_impact_time = 0.14,
                betterlights_strider_bullet_impact_color_r = 80,
                betterlights_strider_bullet_impact_color_g = 210,
                betterlights_strider_bullet_impact_color_b = 255,
            })
        end)

    registerPage("NPCs", "BL_Hunter", "menu.hunter", function(panel)
            setupPage(panel, "page.hunter.title", "page.hunter.desc")

            local body = addSection(panel, "section.body_glow", nil, true)
            addLightControls(body, "betterlights_hunter", {
                radiusMax = 400,
                modelElight = true,
                modelElightLabel = "control.add_model_elight"
            })
            addColorMixerControl(body, "control.glow_color", "betterlights_hunter_color_r", "betterlights_hunter_color_g", "betterlights_hunter_color_b")

            local projectile = addSection(panel, "section.flechette_glow", "section.flechette_glow.desc", true)
            projectile:CheckBox(phrase("control.enable_glow"), "betterlights_hunter_flechette_enable")
            projectile:NumSlider(phrase("control.radius"), "betterlights_hunter_flechette_size", 0, 400, 0)
            projectile:NumSlider(phrase("control.brightness"), "betterlights_hunter_flechette_brightness", 0, 5, 2)
            projectile:NumSlider(phrase("control.decay"), "betterlights_hunter_flechette_decay", 0, 5000, 0)
            addColorMixerControl(projectile, "control.glow_color", "betterlights_hunter_flechette_color_r", "betterlights_hunter_flechette_color_g", "betterlights_hunter_flechette_color_b")

            local muzzle = addSection(panel, "section.muzzle_flash", nil, true)
            muzzle:CheckBox(phrase("control.flash_on_fire"), "betterlights_hunter_muzzle_flash_enable")
            muzzle:NumSlider(phrase("control.radius"), "betterlights_hunter_muzzle_flash_size", 0, 800, 0)
            muzzle:NumSlider(phrase("control.brightness"), "betterlights_hunter_muzzle_flash_brightness", 0, 10, 2)
            muzzle:NumSlider(phrase("control.duration"), "betterlights_hunter_muzzle_flash_time", 0, 1, 2)
            addColorMixerControl(muzzle, "control.flash_color", "betterlights_hunter_muzzle_flash_color_r", "betterlights_hunter_muzzle_flash_color_g", "betterlights_hunter_muzzle_flash_color_b")

            local blast = addSection(panel, "section.blast_flash", nil, true)
            blast:CheckBox(phrase("control.flash_on_explosion"), "betterlights_hunter_flechette_blast_enable")
            blast:NumSlider(phrase("control.radius"), "betterlights_hunter_flechette_blast_size", 0, 800, 0)
            blast:NumSlider(phrase("control.brightness"), "betterlights_hunter_flechette_blast_brightness", 0, 10, 2)
            blast:NumSlider(phrase("control.duration"), "betterlights_hunter_flechette_blast_time", 0, 1, 2)
            addColorMixerControl(blast, "control.flash_color", "betterlights_hunter_flechette_blast_color_r", "betterlights_hunter_flechette_blast_color_g", "betterlights_hunter_flechette_blast_color_b")

            addResetButton(panel, {
                betterlights_hunter_enable = 1,
                betterlights_hunter_size = 55,
                betterlights_hunter_brightness = 0.45,
                betterlights_hunter_decay = 2000,
                betterlights_hunter_models_elight = 1,
                betterlights_hunter_models_elight_size_mult = 1.0,
                betterlights_hunter_color_r = 30,
                betterlights_hunter_color_g = 230,
                betterlights_hunter_color_b = 255,
                betterlights_hunter_flechette_enable = 1,
                betterlights_hunter_flechette_size = 90,
                betterlights_hunter_flechette_brightness = 1.25,
                betterlights_hunter_flechette_decay = 1800,
                betterlights_hunter_flechette_color_r = 0,
                betterlights_hunter_flechette_color_g = 235,
                betterlights_hunter_flechette_color_b = 255,
                betterlights_hunter_muzzle_flash_enable = 1,
                betterlights_hunter_muzzle_flash_size = 220,
                betterlights_hunter_muzzle_flash_brightness = 2.0,
                betterlights_hunter_muzzle_flash_time = 0.08,
                betterlights_hunter_muzzle_flash_color_r = 70,
                betterlights_hunter_muzzle_flash_color_g = 220,
                betterlights_hunter_muzzle_flash_color_b = 255,
                betterlights_hunter_flechette_blast_enable = 1,
                betterlights_hunter_flechette_blast_size = 260,
                betterlights_hunter_flechette_blast_brightness = 2.4,
                betterlights_hunter_flechette_blast_time = 0.35,
                betterlights_hunter_flechette_blast_color_r = 80,
                betterlights_hunter_flechette_blast_color_g = 230,
                betterlights_hunter_flechette_blast_color_b = 255,
            })
        end)

    registerPage("NPCs", "BL_HunterChopper", "menu.hunter_chopper", function(panel)
            setupPage(panel, "page.hunter_chopper.title", "page.hunter_chopper.desc")

            local muzzle = addSection(panel, "section.muzzle_flash", nil, true)
            muzzle:CheckBox(phrase("control.flash_on_fire"), "betterlights_hunter_chopper_muzzle_flash_enable")
            muzzle:NumSlider(phrase("control.radius"), "betterlights_hunter_chopper_muzzle_flash_size", 0, 1000, 0)
            muzzle:NumSlider(phrase("control.brightness"), "betterlights_hunter_chopper_muzzle_flash_brightness", 0, 10, 2)
            muzzle:NumSlider(phrase("control.duration"), "betterlights_hunter_chopper_muzzle_flash_time", 0, 1, 2)
            addColorMixerControl(muzzle, "control.flash_color", "betterlights_hunter_chopper_muzzle_flash_color_r", "betterlights_hunter_chopper_muzzle_flash_color_g", "betterlights_hunter_chopper_muzzle_flash_color_b")

            local impact = addSection(panel, "section.impact_flash", nil, true)
            impact:CheckBox(phrase("control.flash_on_impact"), "betterlights_hunter_chopper_bullet_impact_enable")
            impact:NumSlider(phrase("control.radius"), "betterlights_hunter_chopper_bullet_impact_size", 0, 400, 0)
            impact:NumSlider(phrase("control.brightness"), "betterlights_hunter_chopper_bullet_impact_brightness", 0, 5, 2)
            impact:NumSlider(phrase("control.duration"), "betterlights_hunter_chopper_bullet_impact_time", 0, 1, 2)
            addColorMixerControl(impact, "control.flash_color", "betterlights_hunter_chopper_bullet_impact_color_r", "betterlights_hunter_chopper_bullet_impact_color_g", "betterlights_hunter_chopper_bullet_impact_color_b")

            local spotlight = addSection(panel, "section.spotlight", "section.spotlight.desc", true)
            spotlight:CheckBox(phrase("control.enable_spotlight"), "betterlights_hunter_chopper_spotlight_enable")
            spotlight:CheckBox(phrase("control.cast_shadows"), "betterlights_hunter_chopper_spotlight_shadows")
            spotlight:NumSlider(phrase("control.fov"), "betterlights_hunter_chopper_spotlight_fov", 1, 175, 0)
            spotlight:NumSlider(phrase("control.distance"), "betterlights_hunter_chopper_spotlight_distance", 0, 3000, 0)
            spotlight:NumSlider(phrase("control.near_z"), "betterlights_hunter_chopper_spotlight_near", 0, 128, 0)
            spotlight:NumSlider(phrase("control.brightness"), "betterlights_hunter_chopper_spotlight_brightness", 0, 2, 2)
            addColorMixerControl(spotlight, "control.spotlight_color", "betterlights_hunter_chopper_spotlight_color_r", "betterlights_hunter_chopper_spotlight_color_g", "betterlights_hunter_chopper_spotlight_color_b")

            addResetButton(panel, {
                betterlights_hunter_chopper_muzzle_flash_enable = 1,
                betterlights_hunter_chopper_muzzle_flash_size = 260,
                betterlights_hunter_chopper_muzzle_flash_brightness = 2.2,
                betterlights_hunter_chopper_muzzle_flash_time = 0.08,
                betterlights_hunter_chopper_muzzle_flash_color_r = 80,
                betterlights_hunter_chopper_muzzle_flash_color_g = 210,
                betterlights_hunter_chopper_muzzle_flash_color_b = 255,
                betterlights_hunter_chopper_bullet_impact_enable = 1,
                betterlights_hunter_chopper_bullet_impact_size = 80,
                betterlights_hunter_chopper_bullet_impact_brightness = 0.4,
                betterlights_hunter_chopper_bullet_impact_time = 0.12,
                betterlights_hunter_chopper_bullet_impact_color_r = 80,
                betterlights_hunter_chopper_bullet_impact_color_g = 210,
                betterlights_hunter_chopper_bullet_impact_color_b = 255,
                betterlights_hunter_chopper_spotlight_enable = 1,
                betterlights_hunter_chopper_spotlight_shadows = 1,
                betterlights_hunter_chopper_spotlight_fov = 34,
                betterlights_hunter_chopper_spotlight_distance = 1400,
                betterlights_hunter_chopper_spotlight_near = 8,
                betterlights_hunter_chopper_spotlight_brightness = 0.85,
                betterlights_hunter_chopper_spotlight_color_r = 210,
                betterlights_hunter_chopper_spotlight_color_g = 235,
                betterlights_hunter_chopper_spotlight_color_b = 255,
            })
        end)

    registerPage("NPCs", "BL_CombineMine", "menu.combine_mine", function(panel)
            setupPage(panel, "page.combine_mine.title", "page.combine_mine.desc")
            local alert = addSection(panel, "section.alert_glow", "section.alert_glow.desc", true)
            alert:CheckBox(phrase("control.enable"), "betterlights_combine_mine_enable")
            alert:NumSlider(phrase("control.detection_range"), "betterlights_combine_mine_range", 0, 1024, 0)
            alert:NumSlider(phrase("control.radius"), "betterlights_combine_mine_size", 0, 400, 0)
            alert:NumSlider(phrase("control.brightness"), "betterlights_combine_mine_brightness", 0, 5, 2)
            alert:NumSlider(phrase("control.decay"), "betterlights_combine_mine_decay", 0, 5000, 0)
            addColorMixerControl(alert, "control.alert_color", "betterlights_combine_mine_alert_color_r", "betterlights_combine_mine_alert_color_g", "betterlights_combine_mine_alert_color_b")

            local idle = addSection(panel, "section.idle_glow", "section.idle_glow.desc", false)
            idle:CheckBox(phrase("control.idle_glow"), "betterlights_combine_mine_idle_enable")
            idle:NumSlider(phrase("control.radius"), "betterlights_combine_mine_idle_size", 0, 400, 0)
            idle:NumSlider(phrase("control.brightness"), "betterlights_combine_mine_idle_brightness", 0, 2, 2)
            addColorMixerControl(idle, "control.idle_color", "betterlights_combine_mine_idle_color_r", "betterlights_combine_mine_idle_color_g", "betterlights_combine_mine_idle_color_b")

            local behavior = addSection(panel, "section.pulse_model_light", nil, false)
            behavior:CheckBox(phrase("control.pulse_on_alert"), "betterlights_combine_mine_pulse_enable")
            behavior:NumSlider(phrase("control.pulse_amount"), "betterlights_combine_mine_pulse_amount", 0, 1, 2)
            behavior:NumSlider(phrase("control.pulse_speed"), "betterlights_combine_mine_pulse_speed", 0, 30, 1)
            addModelElightControls(behavior, "betterlights_combine_mine", "control.add_model_elight")
            addResetButton(panel, {
                betterlights_combine_mine_enable = 1,
                betterlights_combine_mine_range = 260,
                betterlights_combine_mine_size = 140,
                betterlights_combine_mine_brightness = 1.2,
                betterlights_combine_mine_decay = 2000,
                betterlights_combine_mine_idle_enable = 1,
                betterlights_combine_mine_idle_size = 80,
                betterlights_combine_mine_idle_brightness = 0.25,
                betterlights_combine_mine_idle_color_r = 90,
                betterlights_combine_mine_idle_color_g = 180,
                betterlights_combine_mine_idle_color_b = 255,
                betterlights_combine_mine_alert_color_r = 255,
                betterlights_combine_mine_alert_color_g = 60,
                betterlights_combine_mine_alert_color_b = 60,
                betterlights_combine_mine_pulse_enable = 1,
                betterlights_combine_mine_pulse_amount = 0.15,
                betterlights_combine_mine_pulse_speed = 6.0,
                betterlights_combine_mine_models_elight = 1,
                betterlights_combine_mine_models_elight_size_mult = 1.0,
            })
        end)

    registerPage("NPCs", "BL_CombineMineResistance", "menu.resistance_mine", function(panel)
            setupPage(panel, "page.resistance_mine.title", "page.resistance_mine.desc")
            panel:CheckBox(phrase("control.enable"), "betterlights_combine_mine_resistance_enable")
            panel:NumSlider(phrase("control.alert_radius"), "betterlights_combine_mine_resistance_size", 0, 400, 0)
            panel:NumSlider(phrase("control.alert_brightness"), "betterlights_combine_mine_resistance_brightness", 0, 5, 2)
            panel:NumSlider(phrase("control.decay"), "betterlights_combine_mine_resistance_decay", 0, 5000, 0)
            addColorMixerControl(panel, "control.alert_color", "betterlights_combine_mine_resistance_color_r", "betterlights_combine_mine_resistance_color_g", "betterlights_combine_mine_resistance_color_b")
            addResetButton(panel, {
                betterlights_combine_mine_resistance_enable = 1,
                betterlights_combine_mine_resistance_size = 140,
                betterlights_combine_mine_resistance_brightness = 1.0,
                betterlights_combine_mine_resistance_decay = 2000,
                betterlights_combine_mine_resistance_color_r = 60,
                betterlights_combine_mine_resistance_color_g = 255,
                betterlights_combine_mine_resistance_color_b = 100,
            })
        end)

    registerPage("NPCs", "BL_Manhack", "menu.manhack", function(panel)
            setupPage(panel, "page.manhack.title", "page.manhack.desc")
            panel:CheckBox(phrase("control.enable"), "betterlights_manhack_enable")
            panel:NumSlider(phrase("control.radius"), "betterlights_manhack_size", 0, 400, 0)
            panel:NumSlider(phrase("control.brightness"), "betterlights_manhack_brightness", 0, 5, 2)
            panel:NumSlider(phrase("control.decay"), "betterlights_manhack_decay", 0, 5000, 0)
            panel:CheckBox(phrase("control.add_model_elight"), "betterlights_manhack_models_elight")
            panel:NumSlider(phrase("control.model_elight_radius"), "betterlights_manhack_models_elight_size_mult", 0, 3, 2)
            addColorMixerControl(panel, "control.hostile_color", "betterlights_manhack_color_r", "betterlights_manhack_color_g", "betterlights_manhack_color_b")
            addColorMixerControl(panel, "control.hacked_color", "betterlights_manhack_hacked_color_r", "betterlights_manhack_hacked_color_g", "betterlights_manhack_hacked_color_b")
            addResetButton(panel, {
                betterlights_manhack_enable = 1,
                betterlights_manhack_size = 70,
                betterlights_manhack_brightness = 0.6,
                betterlights_manhack_decay = 2000,
                betterlights_manhack_models_elight = 1,
                betterlights_manhack_models_elight_size_mult = 1.0,
                betterlights_manhack_color_r = 255,
                betterlights_manhack_color_g = 60,
                betterlights_manhack_color_b = 60,
                betterlights_manhack_hacked_color_r = 60,
                betterlights_manhack_hacked_color_g = 255,
                betterlights_manhack_hacked_color_b = 60,
            })
        end)

    registerPage("NPCs", "BL_Antlions", "menu.antlions", function(panel)
            addAntlionPanel(panel)
        end)

    registerPage("NPCs", "BL_Rollermines", "menu.rollermines", function(panel)
            addRollerminePanel(panel)
        end)

    registerPage("NPCs", "BL_CScanner", "menu.cscanner", function(panel)
            setupPage(panel, "page.cscanner.title", "page.cscanner.desc")

            local function addScannerGlowSection(titleKey, prefix)
                local glow = addSection(panel, titleKey, nil, true)
                addLightControls(glow, prefix, {
                    radiusMax = 600,
                    modelElight = true,
                    modelElightLabel = "control.add_model_elight"
                })
                addColorMixerControl(glow, "control.glow_color", prefix .. "_color_r", prefix .. "_color_g", prefix .. "_color_b")
            end

            local function addScannerSearchlightSection(titleKey, prefix)
                local searchlight = addSection(panel, titleKey, "section.searchlight.desc", true)
                searchlight:CheckBox(phrase("control.enable_searchlight"), prefix .. "_searchlight_enable")
                searchlight:CheckBox(phrase("control.cast_shadows"), prefix .. "_searchlight_shadows")
                searchlight:NumSlider(phrase("control.fov"), prefix .. "_searchlight_fov", 1, 175, 0)
                searchlight:NumSlider(phrase("control.distance"), prefix .. "_searchlight_distance", 0, 3000, 0)
                searchlight:NumSlider(phrase("control.near_z"), prefix .. "_searchlight_near", 0, 128, 0)
                searchlight:NumSlider(phrase("control.brightness"), prefix .. "_searchlight_brightness", 0, 2, 2)
                searchlight:NumSlider(phrase("control.falloff"), prefix .. "_searchlight_falloff", 0, 100, 0)
                addColorMixerControl(searchlight, "control.searchlight_color", prefix .. "_searchlight_color_r", prefix .. "_searchlight_color_g", prefix .. "_searchlight_color_b")
            end

            addScannerGlowSection("section.city_scanner_glow", "betterlights_cscanner")
            addScannerSearchlightSection("section.city_scanner_searchlight", "betterlights_cscanner")
            addScannerGlowSection("section.shield_scanner_glow", "betterlights_shieldscanner")
            addScannerSearchlightSection("section.shield_scanner_searchlight", "betterlights_shieldscanner")

            addResetButton(panel, {
                betterlights_cscanner_enable = 1,
                betterlights_cscanner_size = 120,
                betterlights_cscanner_brightness = 0.7,
                betterlights_cscanner_decay = 2000,
                betterlights_cscanner_models_elight = 1,
                betterlights_cscanner_models_elight_size_mult = 1.0,
                betterlights_cscanner_color_r = 180,
                betterlights_cscanner_color_g = 230,
                betterlights_cscanner_color_b = 255,
                betterlights_cscanner_searchlight_enable = 1,
                betterlights_cscanner_searchlight_shadows = 1,
                betterlights_cscanner_searchlight_fov = 38,
                betterlights_cscanner_searchlight_distance = 900,
                betterlights_cscanner_searchlight_near = 8,
                betterlights_cscanner_searchlight_brightness = 1.25,
                betterlights_cscanner_searchlight_falloff = 25,
                betterlights_cscanner_searchlight_color_r = 255,
                betterlights_cscanner_searchlight_color_g = 255,
                betterlights_cscanner_searchlight_color_b = 255,
                betterlights_shieldscanner_enable = 1,
                betterlights_shieldscanner_size = 120,
                betterlights_shieldscanner_brightness = 0.7,
                betterlights_shieldscanner_decay = 2000,
                betterlights_shieldscanner_models_elight = 1,
                betterlights_shieldscanner_models_elight_size_mult = 1.0,
                betterlights_shieldscanner_color_r = 180,
                betterlights_shieldscanner_color_g = 230,
                betterlights_shieldscanner_color_b = 255,
                betterlights_shieldscanner_searchlight_enable = 1,
                betterlights_shieldscanner_searchlight_shadows = 1,
                betterlights_shieldscanner_searchlight_fov = 38,
                betterlights_shieldscanner_searchlight_distance = 900,
                betterlights_shieldscanner_searchlight_near = 8,
                betterlights_shieldscanner_searchlight_brightness = 1.25,
                betterlights_shieldscanner_searchlight_falloff = 25,
                betterlights_shieldscanner_searchlight_color_r = 255,
                betterlights_shieldscanner_searchlight_color_g = 255,
                betterlights_shieldscanner_searchlight_color_b = 255,
            })
        end)

    MENU.RegisterPages("BetterLights_Menu_NPCEffects", pages)
end
