local L = LibStub("AceLocale-3.0"):GetLocale("ClassicCastbars")
local TestMode = CreateFrame("Frame", "ClassicCastbars_TestMode")
local activeFrames = ClassicCastbars.activeFrames

local dummySpellData = {
    spellName = GetSpellInfo(118),
    castText = GetSpellInfo(118),
    iconTexturePath = GetSpellTexture(118),
    spellID = 118,
    maxValue = 10,
    value = 5,
    castID = -1,
    isTesting = true,
    isActiveCast = true,
    isChanneled = false,
    isFailed = false,
    isInterrupted = false,
    isCastComplete = false,
}

local function PrintError(text)
    print(format("|cFFFF0000[ClassicCastbars] %s|r", text)) -- luacheck: ignore
end

-- Credits to stako & zork for this
-- https://www.wowinterface.com/forums/showthread.php?t=41819
local function CalcScreenGetPoint(frame)
    local parentX, parentY = frame:GetParent():GetCenter()
    local frameX, frameY = frame:GetCenter()
    local scale = frame:GetScale()

    frameX = ((frameX * scale) - parentX) / scale
    frameY = ((frameY * scale) - parentY) / scale

    -- round to 1 decimal place
    frameX = floor(frameX * 10 + 0.5 ) / 10
    frameY = floor(frameY * 10 + 0.5 ) / 10

    return frameX, frameY
end

local function OnDragStop(self)
    self:StopMovingOrSizing()
    if not self.unitType then return end

    -- Frame loses relativity to parent and is instead relative to UIParent after
    -- dragging so we can't just use self:GetPoint() here
    local x, y = CalcScreenGetPoint(self)
    ClassicCastbars.db[self.unitType].position = { "CENTER", x, y } -- Has to be center for CalcScreenGetPoint to work
    ClassicCastbars.db[self.unitType].autoPosition = false

    -- Reanchor from UIParent back to parent frame
    self:ClearAllPoints()
    self:SetParent(self.parent)
    self:SetPoint("CENTER", self.parent, x, y)
end

function TestMode:PrintErrNoTarget(unitType)
    if unitType == "target" or unitType == "focus" then
        PrintError(_G.ERR_GENERIC_NO_TARGET)
    elseif unitType == "party-testmode" then
        PrintError(_G.ERR_QUEST_PUSH_NOT_IN_PARTY_S)
    elseif unitType == "nameplate-testmode" then
        PrintError(L.NO_NAMEPLATE_VISIBLE)
    end
end

function TestMode:ToggleArenaContainer(showFlag, castbarParent)
    if UnitExists("arena1") then return end -- Already shown by blizzard
    if InCombatLockdown() then return PrintError(_G.ERR_NOT_IN_COMBAT) end

    if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
        EditModeManagerFrame.AccountSettings:SetArenaFramesShown(showFlag)
        EditModeManagerFrame.AccountSettings:RefreshArenaFrames()
    elseif ArenaEnemyFrames then
        ArenaEnemyFrames:SetShown(showFlag)

        if castbarParent and not castbarParent:IsProtected() then
            castbarParent:SetShown(showFlag)
        end
    end
end

function TestMode:TogglePartyContainer(showFlag, castbarParent)
    if UnitExists("party1") then return end -- Already shown by blizzard
    if InCombatLockdown() then return PrintError(_G.ERR_NOT_IN_COMBAT) end

    -- Show normal party frames, wont work with raid frames
    if castbarParent and not castbarParent:IsProtected() then
        castbarParent:SetAlpha(1)
        castbarParent:SetShown(showFlag)
    end

    -- TODO: show compactraidframe directly
    if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
        if showFlag and not UnitExists("party1") then
            ShowUIPanel(EditModeManagerFrame)
        else
            HideUIPanel(EditModeManagerFrame)
        end
    end
end

function TestMode:OnOptionChanged(unitType)
    if unitType == "nameplate" or unitType == "arena" or unitType == "party" then
        unitType = format("%s-testmode", unitType)
    end

    local castbar = activeFrames[unitType]
    if castbar and castbar.isTesting then
        Mixin(castbar, dummySpellData)
        castbar.unitType = unitType
        castbar:DisplayCastbar() -- Refresh full view
    end
end

function TestMode:ToggleCastbarMovable(unitType)
    if unitType == "nameplate" or unitType == "arena" or unitType == "party" then
        unitType = format("%s-testmode", unitType)
    end

    if unitType == "arena-testmode" and not IsAddOnLoaded("Blizzard_ArenaUI") then
        LoadAddOn("Blizzard_ArenaUI")
    end

    -- Display a movable testbar for the unitType's unitframe
    if activeFrames[unitType] and activeFrames[unitType].isTesting then
        self:SetCastbarImmovable(unitType)
    else
        self:SetCastbarMovable(unitType)
    end
end

function TestMode:SetCastbarMovable(unitType)
    local parentFrame = ClassicCastbars.AnchorManager:GetAnchor(unitType)
    if not parentFrame then return self:PrintErrNoTarget(unitType) end

    if unitType == "arena-testmode" then TestMode:ToggleArenaContainer(true, parentFrame) end
    if unitType == "party-testmode" then TestMode:TogglePartyContainer(true, parentFrame) end

    local castbar = ClassicCastbars:AcquireCastbarFrame(unitType)
    Mixin(castbar, dummySpellData)
    castbar.parent = parentFrame
    castbar.unitType = unitType
    castbar.isTesting = true
    castbar.isUninterruptible = IsModifierKeyDown() or (IsMetaKeyDown and IsMetaKeyDown())
    castbar.isDefaultUninterruptible = castbar.isUninterruptible

    if unitType ~= "nameplate-testmode" then -- drag restricted for nameplates :(
        castbar:SetMovable(true)
        castbar:SetClampedToScreen(true)
        castbar:EnableMouse(true)

        castbar.tooltip = castbar.tooltip or castbar:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        castbar.tooltip:SetPoint("TOP", castbar, 0, 15)
        castbar.tooltip:SetText(L.TEST_MODE_DRAG)
        castbar.tooltip:Show()

        castbar:SetScript("OnMouseDown", castbar.StartMoving)
        castbar:SetScript("OnMouseUp", OnDragStop)
    end

    castbar:DisplayCastbar()
end

function TestMode:SetCastbarImmovable(unitType)
    local castbar = activeFrames[unitType]
    if not castbar then return end

    if unitType == "arena-testmode" then TestMode:ToggleArenaContainer(false, castbar.parent) end
    if unitType == "party-testmode" then TestMode:TogglePartyContainer(false, castbar.parent) end

    if castbar.tooltip then
        castbar.tooltip:Hide()
    end

    castbar.parent = nil
    castbar.isActiveCast = false
    castbar.isTesting = false
    castbar:EnableMouse(false)
    castbar:Hide()
end

function TestMode:ReanchorOnTargetSwitch(unitID)
    if not activeFrames[unitID] or not activeFrames[unitID].isTesting then return end
    if not ClassicCastbars.db[ClassicCastbars:GetUnitType(unitID)].enabled then return end

    if UnitExists("target") and ClassicCastbars.AnchorManager:GetAnchor(unitID) then
        TestMode:SetCastbarMovable(unitID)
    else
        TestMode:SetCastbarImmovable(unitID)
    end
end

TestMode:RegisterEvent("PLAYER_TARGET_CHANGED")
TestMode:SetScript("OnEvent", function(self)
    -- Delay function call as GetNamePlateForUnit() is not
    -- ready immediately after PLAYER_TARGET_CHANGED is triggered
    if activeFrames["nameplate-testmode"] and activeFrames["nameplate-testmode"].isTesting then
        C_Timer.After(0.2, function()
            self:ReanchorOnTargetSwitch("nameplate-testmode")
        end)
    end
end)
