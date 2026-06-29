if CLIENT then

    local MENU = BetterLights.Menu

    function MENU.RegisterAboutPanel()
        local phrase = MENU.Phrase
        local phraseFormat = MENU.PhraseFormat
        local setupPage = MENU.SetupPage
        local addSection = MENU.AddSection
        local addStyledButton = MENU.AddStyledButton
        local styleButton = MENU.StyleButton
        local addHelpText = MENU.AddHelpText
        local registerPage = MENU.RegisterPage

        registerPage("About", "BL_About", "menu.about", function(panel)
            setupPage(panel, "page.about.title", "page.about.desc")

            local version = BetterLights.VERSION
            local author = vgui.Create("DPanel")
            author:SetTall(96)
            author.Paint = nil

            local avatar = vgui.Create("AvatarImage", author)
            avatar:Dock(LEFT)
            avatar:DockMargin(14, 14, 14, 14)
            avatar:SetWide(64)
            avatar:SetSteamID("76561199216202475", 64)

            local authorInfo = vgui.Create("DPanel", author)
            authorInfo:Dock(FILL)
            authorInfo:DockMargin(0, 12, 12, 12)
            authorInfo.Paint = nil

            local title = vgui.Create("DLabel", authorInfo)
            title:Dock(TOP)
            title:SetTall(22)
            title:SetText(phraseFormat("about.version", version))
            title:SetFont("DermaDefaultBold")
            title:SetDark(true)

            local byline = vgui.Create("DLabel", authorInfo)
            byline:Dock(TOP)
            byline:SetTall(20)
            byline:SetText(phrase("about.byline"))
            byline:SetDark(true)

            local profileBtn = styleButton(vgui.Create("DButton", authorInfo))
            profileBtn:Dock(BOTTOM)
            profileBtn:SetTall(26)
            profileBtn:SetText(phrase("button.open_steam_profile"))
            profileBtn.DoClick = function()
                gui.OpenURL("https://steamcommunity.com/id/catsniffermeow/")
            end

            panel:AddItem(author)
            addHelpText(panel, phrase("about.report_help"))
            addHelpText(panel, phrase("about.support_help"))
            addHelpText(panel, phrase("about.license_help"))

            local links = addSection(panel, "section.links", nil, true)
            local issueBtn = addStyledButton(links, phrase("button.report_issue"))
            issueBtn.DoClick = function()
                gui.OpenURL("https://github.com/DeisDev/BetterLights/issues/new/choose")
            end

            local sourceBtn = addStyledButton(links, phrase("button.view_source"))
            sourceBtn.DoClick = function()
                gui.OpenURL("https://github.com/DeisDev/BetterLights")
            end

            local licenseBtn = addStyledButton(links, phrase("button.view_license"))
            licenseBtn.DoClick = function()
                gui.OpenURL("https://github.com/DeisDev/BetterLights/blob/main/LICENSE.md")
            end

            local workshopBtn = addStyledButton(links, phrase("button.steam_workshop"))
            workshopBtn.DoClick = function()
                gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/?id=3597784225")
            end

            local changelogBtn = addStyledButton(links, phrase("button.changelog"))
            changelogBtn.DoClick = function()
                if MENU.OpenChangelogWindow then
                    MENU.OpenChangelogWindow()
                end
            end

            local otherAddonsBtn = addStyledButton(links, phrase("button.other_addons"))
            otherAddonsBtn.DoClick = function()
                gui.OpenURL("https://steamcommunity.com/workshop/filedetails/?id=3551812511")
            end
        end)
    end
end
