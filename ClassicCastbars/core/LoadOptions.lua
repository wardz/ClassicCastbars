if not IsAddOnLoadOnDemand("ClassicCastbars_Options") then return end -- check if deleted or disabled

SLASH_CLASSICCASTBARS1 = "/castbars"
SLASH_CLASSICCASTBARS2 = "/castbar"
SLASH_CLASSICCASTBARS3 = "/classiccastbar"
SLASH_CLASSICCASTBARS4 = "/classiccastbars"
SLASH_CLASSICCASTBARS5 = "/classicastbar"
SLASH_CLASSICCASTBARS6 = "/classicastbars"

local isLoaded = false

if InterfaceOptionsFrame then -- sanity check
    InterfaceOptionsFrame:HookScript("OnShow", function()
        if not isLoaded and not IsAddOnLoaded("ClassicCastbars_Options") then
            isLoaded = LoadAddOn("ClassicCastbars_Options")
        end
    end)
end

SlashCmdList["CLASSICCASTBARS"] = function()
    if not IsAddOnLoaded("ClassicCastbars_Options") then
        if not isLoaded and LoadAddOn("ClassicCastbars_Options") then
            isLoaded = true
            C_Timer.After(GetTickTime(), SlashCmdList.CLASSICCASTBARS) -- Run again next frame to actually open the options
        end
    else
        LibStub("AceConfigDialog-3.0"):Open("ClassicCastbars")
        if LibStub("AceConfigDialog-3.0").OpenFrames["ClassicCastbars"] then
            LibStub("AceConfigDialog-3.0").OpenFrames["ClassicCastbars"]:SetStatusText("https://www.curseforge.com/wow/addons/classiccastbars")
        end
    end
end
