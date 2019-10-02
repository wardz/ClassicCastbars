local L = LibStub("AceLocale-3.0"):GetLocale("ClassicCastbars")

local TestMode = CreateFrame("Frame")
TestMode.isTesting = {}
ClassicCastbars_TestMode = TestMode -- global ref for use in both addons

local dummySpellData = {
    spellName = GetSpellInfo(118),
    icon = GetSpellTexture(118),
    maxValue = 10,
    timeStart = GetTime(),
    endTime = GetTime() + 10,
    isChanneled = false,
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

    local unit = self.unitID
    if strfind(unit, "nameplate") then
        unit = "nameplate" -- make it match our DB key
    elseif strfind(unit, "party") then
        unit = "party"
    end

    -- Frame loses relativity to parent and is instead relative to UIParent after
    -- dragging so we can't just use self:GetPoint() here
    local x, y = CalcScreenGetPoint(self)
    ClassicCastbarsDB[unit].position[1] = "CENTER" -- has to be center for CalcScreenGetPoint to work
    ClassicCastbarsDB[unit].position[2] = x
    ClassicCastbarsDB[unit].position[3] = y
    ClassicCastbarsDB[unit].autoPosition = false

    -- Reanchor from UIParent back to parent frame
    self:SetParent(self.parent)
    self:ClearAllPoints()
    self:SetPoint("CENTER", self.parent, x, y)
end

function TestMode:ToggleCastbarMovable(unitID)
    if unitID == "nameplate" then
        unitID = "nameplate-testmode"
    elseif unitID == "party" then
        unitID = "party-testmode"
    end

    if self.isTesting[unitID] then
        self:SetCastbarImmovable(unitID)
        self.isTesting[unitID] = false
        if unitID == "nameplate-testmode" then
            self:UnregisterEvent("PLAYER_TARGET_CHANGED")
        end
    else
        self:SetCastbarMovable(unitID)
        self.isTesting[unitID] = true

        if ClassicCastbarsDB.nameplate.enabled and unitID == "nameplate-testmode" then
            self:RegisterEvent("PLAYER_TARGET_CHANGED")
        end
    end
end

function TestMode:OnOptionChanged(unitID)
    if unitID == "nameplate" then
        unitID = "nameplate-testmode"
    elseif unitID == "party" then
        unitID = "party-testmode"
    end

    if unitID == "player" then
        return ClassicCastbars:SkinPlayerCastbar()
    end

    -- Immediately update castbar display after changing an option
    local castbar = ClassicCastbars.activeFrames[unitID]
    if castbar and castbar.isTesting then
        castbar._data = dummySpellData
        ClassicCastbars:DisplayCastbar(castbar, unitID)
    end
end

function TestMode:SetCastbarMovable(unitID, parent)
    local castbar = ClassicCastbars:GetCastbarFrame(unitID)
    castbar:EnableMouse(true)
    castbar:SetMovable(true)
    castbar:SetClampedToScreen(true)

    castbar.tooltip = castbar.tooltip or castbar:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    castbar.tooltip:SetPoint("TOP", castbar, 0, 15)
    castbar.tooltip:SetText(L.TEST_MODE_DRAG)
    castbar.tooltip:Show()

    -- Note: we use OnMouseX instead of OnDragX as it's more accurate
    castbar:SetScript("OnMouseDown", castbar.StartMoving)
    castbar:SetScript("OnMouseUp", OnDragStop)

    local parentFrame = parent or ClassicCastbars.AnchorManager:GetAnchor(unitID)
    if not parentFrame then return end -- sanity check

    castbar._data = dummySpellData -- Set test data for :DisplayCastbar()
    castbar.parent = parentFrame
    castbar.unitID = unitID
    castbar.isTesting = true

    castbar:SetMinMaxValues(1, 10)
    castbar:SetValue(5)
    castbar.Timer:SetText("0.75")
    castbar.Spark:SetPoint("CENTER", castbar, "LEFT", (5 / 10) * castbar:GetWidth(), 0)

    if unitID == "party-testmode" then
        parentFrame:SetAlpha(1)
        parentFrame:Show()
    end

    if unitID == "player" then
        castbar:Show()
        castbar:SetAlpha(1)
    else
        ClassicCastbars:DisplayCastbar(castbar, unitID)
    end
end

function TestMode:SetCastbarImmovable(unitID)
    local castbar = ClassicCastbars:GetCastbarFrame(unitID)
    castbar:Hide()
    castbar.tooltip:Hide()

    castbar.unitID = nil
    castbar.parent = nil
    castbar.isTesting = nil
    castbar:EnableMouse(false)

    if unitID == "party-testmode" then
        local parentFrame = castbar.parent or ClassicCastbars.AnchorManager:GetAnchor(unitID)
        parentFrame:Hide()
    end
end

function TestMode:ReanchorOnNameplateTargetSwitch()
    if not ClassicCastbarsDB.nameplate.enabled then return end

    -- Reanchor castbar when we target a new nameplate/unit.
    -- We only want to show castbar for 1 nameplate at a time
    local anchor = C_NamePlate.GetNamePlateForUnit("target")
    if anchor then
        return TestMode:SetCastbarMovable("nameplate-testmode", anchor)
    end

    -- No nameplate available or player has no target
    TestMode:SetCastbarImmovable("nameplate-testmode")
end

TestMode:SetScript("OnEvent", function(self)
    -- Delay function call because GetNamePlateForUnit() is not
    -- ready immediately after PLAYER_TARGET_CHANGED is triggered
    if self.isTesting["nameplate-testmode"] then
        C_Timer.After(0.2, TestMode.ReanchorOnNameplateTargetSwitch)
    end
end)
