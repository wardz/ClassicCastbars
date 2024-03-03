local L = LibStub("AceLocale-3.0"):GetLocale("ClassicCastbars")
local TestMode = CreateFrame("Frame", "ClassicCastbars_TestMode")
local activeFrames = ClassicCastbars.activeFrames

local dummySpellData = {
    spellName = GetSpellInfo(118),
    icon = GetSpellTexture(118),
    spellID = 118,
    maxValue = 10,
    value = 5,
    isChanneled = false,
    isActiveCast = true,
    castID = nil,
}

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

    -- Frame loses relativity to parent and is instead relative to UIParent after
    -- dragging so we can't just use self:GetPoint() here
    local unitType = ClassicCastbars:GetUnitType(self.unitID)
    local x, y = CalcScreenGetPoint(self)
    ClassicCastbars.db[unitType].position = { "CENTER", x, y } -- Has to be center for CalcScreenGetPoint to work
    ClassicCastbars.db[unitType].autoPosition = false

    -- Reanchor from UIParent back to parent frame
    self:SetParent(self.parent)
    self:ClearAllPoints()
    self:SetPoint("CENTER", self.parent, x, y)
end

function TestMode:ToggleArenaContainer(showFlag)
    if EditModeManagerFrame and EditModeManagerFrame.AccountSettings then
        EditModeManagerFrame.AccountSettings:SetArenaFramesShown(showFlag)
        EditModeManagerFrame.AccountSettings:RefreshArenaFrames()
    elseif ArenaEnemyFrames then
        ArenaEnemyFrames:SetShown(showFlag)
    end
end

function TestMode:TogglePartyContainer(showFlag)
    if EditModeManagerFrame and EditModeManagerFrame.AccountSettings then
        if showFlag then
            ShowUIPanel(EditModeManagerFrame)
        else
            HideUIPanel(EditModeManagerFrame)
        end
    end
end

function TestMode:PrintErrNoTarget(unitID)
    if unitID == "target" or unitID == "focus" then
        print(format("|cFFFF0000[ClassicCastbars] %s|r", _G.ERR_GENERIC_NO_TARGET)) -- luacheck: ignore
    elseif unitID == "party-testmode" then
        print(format("|cFFFF0000[ClassicCastbars] %s|r", _G.ERR_QUEST_PUSH_NOT_IN_PARTY_S)) -- luacheck: ignore
    elseif unitID == "nameplate-testmode" then
        print(format("|cFFFF0000[ClassicCastbars] %s|r", L.NO_NAMEPLATE_VISIBLE)) -- luacheck: ignore
    end
end

function TestMode:OnOptionChanged(unitID)
    if unitID == "nameplate" or unitID == "arena" or unitID == "party" then
        unitID = format("%s-testmode", unitID)
    end

    local castbar = activeFrames[unitID]
    if castbar and castbar.isTesting then
        Mixin(castbar, dummySpellData)
        ClassicCastbars:DisplayCastbar(castbar, unitID)
    end
end

function TestMode:ToggleCastbarMovable(unitID)
    if unitID == "nameplate" or unitID == "arena" or unitID == "party" then
        unitID = format("%s-testmode", unitID)
    end

    if unitID == "arena-testmode" and not IsAddOnLoaded("Blizzard_ArenaUI") then
        LoadAddOn("Blizzard_ArenaUI")
    end

    if activeFrames[unitID] and activeFrames[unitID].isTesting then
        self:SetCastbarImmovable(unitID)
    else
        self:SetCastbarMovable(unitID)
    end
end

function TestMode:SetCastbarMovable(unitID)
    local parentFrame = ClassicCastbars.AnchorManager:GetAnchor(unitID)
    if not parentFrame then return self:PrintErrNoTarget(unitID) end

    if unitID == "party-testmode" or unitID == "arena-testmode" then
        if unitID == "arena-testmode" then TestMode:ToggleArenaContainer(true) end
        if unitID == "party-testmode" then TestMode:TogglePartyContainer(true) end
        parentFrame:SetAlpha(1)
        parentFrame:Show()
    end

    local castbar = ClassicCastbars:GetCastbarFrame(unitID)
    Mixin(castbar, dummySpellData)
    castbar.parent = parentFrame
    castbar.unitID = unitID
    castbar.isTesting = true
    castbar.isUninterruptible = IsModifierKeyDown() or (IsMetaKeyDown and IsMetaKeyDown())

    if unitID ~= "nameplate-testmode" then -- Blizzard broke drag functionality for frames that are anchored to restricted frames :(
        castbar:SetMovable(true)
        castbar:SetClampedToScreen(true)
        castbar:EnableMouse(true)

        castbar.tooltip = castbar.tooltip or castbar:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        castbar.tooltip:SetPoint("TOP", castbar, 0, 15)
        castbar.tooltip:SetText(L.TEST_MODE_DRAG)
        castbar.tooltip:Show()

        -- Note: we use OnMouseX instead of OnDragX as it's more precise when dragging small distances
        castbar:SetScript("OnMouseDown", castbar.StartMoving)
        castbar:SetScript("OnMouseUp", OnDragStop)
    end

    ClassicCastbars:DisplayCastbar(castbar, unitID)
end

function TestMode:SetCastbarImmovable(unitID)
    local castbar = ClassicCastbars.activeFrames[unitID]
    if not castbar then return end

    if unitID == "party-testmode" then
        TestMode:TogglePartyContainer(false)
        if castbar.parent and not UnitExists("party1") then
            castbar.parent:Hide()
        end
    elseif unitID == "arena-testmode" then
        TestMode:ToggleArenaContainer(false)
        if castbar.parent and not UnitExists("arena1") then
            castbar.parent:Hide()
        end
    end

    if castbar.tooltip then
        castbar.tooltip:Hide()
    end

    castbar.isActiveCast = false
    castbar.unitID = nil
    castbar.parent = nil
    castbar.isTesting = false
    castbar:EnableMouse(false)
    castbar:Hide()
end

function TestMode:ReanchorOnTargetSwitch(unitID)
    if not activeFrames[unitID] or not activeFrames[unitID].isTesting then return end
    if not ClassicCastbars.db[ClassicCastbars:GetUnitType(unitID)].enabled then return end

    if ClassicCastbars.AnchorManager:GetAnchor(unitID) then
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
