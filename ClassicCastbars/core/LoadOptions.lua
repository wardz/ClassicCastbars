SLASH_CLASSICCASTBARS1 = "/castbars"
SLASH_CLASSICCASTBARS2 = "/castbar"
SLASH_CLASSICCASTBARS3 = "/classiccastbar"
SLASH_CLASSICCASTBARS4 = "/classiccastbars"
SLASH_CLASSICCASTBARS5 = "/classicastbar"
SLASH_CLASSICCASTBARS6 = "/classicastbars"

local isLoaded = false

GameMenuFrame:HookScript("OnShow", function()
    if not isLoaded and not IsAddOnLoaded("ClassicCastbars_Options") then
        local loaded, reason = LoadAddOn("ClassicCastbars_Options")
        if not loaded and reason == "DISABLED" then
            isLoaded = true -- disabled, dont attempt to load it anymore
            return
        end

        isLoaded = loaded
    end
end)

SlashCmdList["CLASSICCASTBARS"] = function()
    if not IsAddOnLoaded("ClassicCastbars_Options") then
        if not isLoaded then
            local loaded, reason = LoadAddOn("ClassicCastbars_Options")
            if not loaded and reason == "DISABLED" then
                isLoaded = true -- disabled, dont attempt to load it anymore
                return
            end
            isLoaded = loaded
            if isLoaded then
                C_Timer.After(GetTickTime(), SlashCmdList.CLASSICCASTBARS) -- Run again next frame to actually open the options
            end
        end
    else
        LibStub("AceConfigDialog-3.0"):Open("ClassicCastbars")
        if LibStub("AceConfigDialog-3.0").OpenFrames["ClassicCastbars"] then
            LibStub("AceConfigDialog-3.0").OpenFrames["ClassicCastbars"]:SetStatusText("https://www.curseforge.com/wow/addons/classiccastbars")
        end
    end
end
