local L = LibStub("AceLocale-3.0"):GetLocale("ClassicCastbars")
local TestMode = CreateFrame("Frame", "ClassicCastbars_TestMode")
TestMode.isTesting = {}

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

local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local CastingBarFrame = isRetail and _G.PlayerCastingBarFrame or _G.CastingBarFrame

-- Note: don't add any major code reworks here, this codebase will soon be replaced with the player-castbar-v2 branch

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
    local unit = ClassicCastbars:GetUnitType(self.unitID)
    local x, y = CalcScreenGetPoint(self)
    ClassicCastbars.db[unit].position = { "CENTER", x, y } -- Has to be center for CalcScreenGetPoint to work
    ClassicCastbars.db[unit].autoPosition = false

    -- Reanchor from UIParent back to parent frame
    self:SetParent(self.parent)
    self:ClearAllPoints()
    self:SetPoint("CENTER", self.parent, x, y)
end

function TestMode:ToggleArenaContainer(showFlag)
    if EditModeManagerFrame and EditModeManagerFrame.AccountSettings then -- Dragonflight UI
        EditModeManagerFrame.AccountSettings:SetArenaFramesShown(showFlag)
        EditModeManagerFrame.AccountSettings:RefreshArenaFrames()
    elseif ArenaEnemyFrames then
        ArenaEnemyFrames:SetShown(showFlag)
    end
end

function TestMode:TogglePartyContainer(showFlag)
    if EditModeManagerFrame and EditModeManagerFrame.AccountSettings then -- Dragonflight UI
        if showFlag then
            ShowUIPanel(EditModeManagerFrame)
        else
            HideUIPanel(EditModeManagerFrame)
        end
    end
end

function TestMode:OnOptionChanged(unitID)
    if unitID == "nameplate" then
        unitID = "nameplate-testmode"
    elseif unitID == "arena" then
        unitID = "arena-testmode"
    elseif unitID == "party" then
        unitID = "party-testmode"
    end

    if unitID == "player" then
        return ClassicCastbars:SkinPlayerCastbar()
    end

    -- Immediately update castbar display after changing an option
    local castbar = ClassicCastbars.activeFrames[unitID]
    if castbar and castbar:IsVisible() then
        if castbar.isTesting then
            for key, value in pairs(dummySpellData) do
                castbar[key] = value
            end
        end
        ClassicCastbars:DisplayCastbar(castbar, unitID)
    end
end

function TestMode:ToggleCastbarMovable(unitID)
    if unitID == "nameplate" then
        unitID = "nameplate-testmode"
    elseif unitID == "arena" then
        unitID = "arena-testmode"
    elseif unitID == "party" then
        unitID = "party-testmode"
    end

    if unitID == "arena-testmode" and not IsAddOnLoaded("Blizzard_ArenaUI") then
        LoadAddOn("Blizzard_ArenaUI")
    end

    if self.isTesting[unitID] then
        self:SetCastbarImmovable(unitID)
        self.isTesting[unitID] = false
        --if unitID == "nameplate-testmode" then
            --self:UnregisterEvent("PLAYER_TARGET_CHANGED")
        --end
    else
        if self:SetCastbarMovable(unitID) then
            self.isTesting[unitID] = true

            if (ClassicCastbars.db.nameplate.enabled and unitID == "nameplate-testmode") or (ClassicCastbars.db.target.enabled and unitID == "target") then
                self:RegisterEvent("PLAYER_TARGET_CHANGED")
            end
        end
    end
end

function TestMode:SetCastbarMovable(unitID, parent)
    local parentFrame = parent or ClassicCastbars.AnchorManager:GetAnchor(unitID)
    if not parentFrame then
        if unitID == "target" or unitID == "focus" then
            print(format("|cFFFF0000[ClassicCastbars] %s|r", _G.ERR_GENERIC_NO_TARGET)) -- luacheck: ignore
        elseif unitID == "nameplate-testmode" then
            print(format("|cFFFF0000[ClassicCastbars] %s|r", L.NO_NAMEPLATE_VISIBLE)) -- luacheck: ignore
        end
        return false
    end

    local castbar = unitID == "player" and CastingBarFrame or ClassicCastbars:GetCastbarFrame(unitID)
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

    -- Set test data for :DisplayCastbar()
    for key, value in pairs(dummySpellData) do
        castbar[key] = value
    end
    castbar.parent = parentFrame
    castbar.unitID = unitID
    castbar.isTesting = true

    castbar:SetMinMaxValues(0, castbar.maxValue)
    castbar:SetValue(castbar.value)
    castbar.Timer:SetFormattedText("%.1f", castbar.isChanneled and castbar.value or not castbar.isChanneled and castbar.maxValue - castbar.value)

    local sparkPosition = (castbar.value / castbar.maxValue) * (castbar.currWidth or castbar:GetWidth())
    castbar.Spark:SetPoint("CENTER", castbar, "LEFT", sparkPosition, castbar.BorderShield:IsShown() and 3 or 0)

    if IsModifierKeyDown() or (IsMetaKeyDown and IsMetaKeyDown()) then
        castbar.isUninterruptible = true
    else
        castbar.isUninterruptible = false
    end

    if unitID == "party-testmode" or unitID == "arena-testmode" then
        if unitID == "arena-testmode" then TestMode:ToggleArenaContainer(true) end
        if unitID == "party-testmode" then TestMode:TogglePartyContainer(true) end
        parentFrame:SetAlpha(1)
        parentFrame:Show()
    end

    if unitID == "player" then
        castbar.Text:SetText(dummySpellData.spellName)
        castbar.Icon:SetTexture(dummySpellData.icon)
        castbar.Flash:SetAlpha(0)
        castbar.casting = nil
        castbar.channeling = nil
        castbar.holdTime = 0
        castbar.fadeOut = nil
        castbar.flash = nil
        castbar.playCastFX = false

        if IsModifierKeyDown() or (IsMetaKeyDown and IsMetaKeyDown()) then
            --castbar:SetStatusBarColor(castbar.nonInterruptibleColor:GetRGB())
            castbar:SetStatusBarColor(unpack(ClassicCastbars.db.player.statusColorUninterruptible))
        else
            --castbar:SetStatusBarColor(castbar.startCastColor:GetRGB())
            castbar:SetStatusBarColor(unpack(ClassicCastbars.db.player.statusColor))
        end

        castbar:SetAlpha(1)
        castbar:Show()
    else
        ClassicCastbars:DisplayCastbar(castbar, unitID)
    end

    return true
end

function TestMode:SetCastbarImmovable(unitID)
    local castbar = unitID == "player" and CastingBarFrame or ClassicCastbars:GetCastbarFrame(unitID)
    castbar:Hide()
    if castbar.tooltip then
        castbar.tooltip:Hide()
    end

    castbar.isActiveCast = false
    castbar.unitID = nil
    castbar.parent = nil
    castbar.isTesting = false
    castbar.holdTime = 0
    castbar:EnableMouse(false)

    if unitID == "party-testmode" then
        local parentFrame = castbar.parent or ClassicCastbars.AnchorManager:GetAnchor(unitID)
        if parentFrame then
            TestMode:TogglePartyContainer(false)
            if not UnitExists("party1") then
                parentFrame:Hide()
            end
        end
    elseif unitID == "arena-testmode" then
        local parentFrame = castbar.parent or ClassicCastbars.AnchorManager:GetAnchor(unitID)
        if parentFrame and not UnitExists("arena1") then
            TestMode:ToggleArenaContainer(false)
            parentFrame:Hide()
        end
    end
end

function TestMode:ReanchorOnNameplateTargetSwitch()
    if not ClassicCastbars.db.nameplate.enabled then return end

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

    if self.isTesting["target"] and ClassicCastbars.db.target.enabled then
        local anchor = ClassicCastbars.AnchorManager:GetAnchor("target")
        if anchor then
            TestMode:SetCastbarMovable("target", anchor)
        else
            TestMode:SetCastbarImmovable("target")
        end
    end
end)
