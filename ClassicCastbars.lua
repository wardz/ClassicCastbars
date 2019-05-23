local _, namespace = ...
local AnchorManager = namespace.AnchorManager
local PoolManager = namespace.PoolManager
local channeledSpells = namespace.channeledSpells

-- CastingInfo()
-- UNIT_SPELL available?
-- TODO: show if cast is interruptible?
-- TODO: add optional castbars for party frames
-- TODO: height/width options?

local addon = CreateFrame("Frame")
addon:RegisterEvent("PLAYER_LOGIN")
addon:SetScript("OnEvent", function(self, event, ...)
    return self[event](self, ...)
end)

local activeGUIDs = {}
local activeTimers = {}
local activeFrames = {}

-- upvalues
local pairs = _G.pairs
local UnitGUID = _G.UnitGUID
local GetSpellInfo = _G.GetSpellInfo
local GetSpellTexture = _G.GetSpellTexture
local CombatLogGetCurrentEventInfo = _G.CombatLogGetCurrentEventInfo
local GetTime = _G.GetTime
local next = _G.next
local CastingInfo = _G.CastingInfo

function addon:GetCastbarFrame(unitID)
    -- PoolManager:DebugInfo()

    if activeFrames[unitID] then
        return activeFrames[unitID]
    end

    -- store reference, refs are deleted on frame recycled.
    -- This allows us to not have to Release & Acquire a frame everytime a
    -- castbar is shown/hidden for the *same* unit
    activeFrames[unitID] = PoolManager:AcquireFrame()

    return activeFrames[unitID]
end

function addon:AdjustTargetCastbarPosition(castbar, parentFrame)
    if not self.db.target.dynamicTargetPosition then
        local pos = self.db.target.position
        castbar:SetPoint(pos[1], parentFrame, pos[2], pos[3])
        return
    end

    if parentFrame.haveToT then
        if parentFrame.buffsOnTop or parentFrame.auraRows <= 1 then
            castbar:SetPoint("BOTTOMLEFT", parentFrame, 25, -15)
        else
            castbar:SetPoint("BOTTOMLEFT", parentFrame, 20, -60)
        end
    elseif parentFrame.haveElite then
        if parentFrame.buffsOnTop or parentFrame.auraRows <= 1 then
            castbar:SetPoint("BOTTOMLEFT", parentFrame, 25, -15)
        else
            castbar:SetPoint("BOTTOMLEFT", parentFrame, 25, -60)
        end
    else
        if ((not parentFrame.buffsOnTop) and parentFrame.auraRows > 0) then
            castbar:SetPoint("BOTTOMLEFT", parentFrame, 25, -60)
        else
            castbar:SetPoint("BOTTOMLEFT", parentFrame, 25, -3)
        end
    end
end

function addon:StartCast(unitGUID, unitID)
    if not activeTimers[unitGUID] then return end

    local castbar = self:GetCastbarFrame(unitID)
    if not castbar then return end

    local parentFrame = AnchorManager:GetAnchor(unitID)
    if not parentFrame then return end -- sanity check

    castbar._data = activeTimers[unitGUID] -- set ref to current cast data
    castbar:SetParent(parentFrame)

    if unitID == "target" then
        -- TODO: we should call this in OnUpdate/OnEvent aswell
        self:AdjustTargetCastbarPosition(castbar, parentFrame)
        castbar:SetScale(1)
    else -- nameplates
        local pos = self.db.nameplate.position
        castbar:SetPoint(pos[1], parentFrame, pos[2], pos[3])
        castbar:SetScale(0.7)
    end

    local cast = castbar._data
    if castbar.Text:GetText() ~= cast.spellName then
        castbar.Text:SetText(cast.spellName)
        castbar.Icon:SetTexture(cast.icon)
    end

    castbar:SetMinMaxValues(0, cast.maxValue)
    castbar:Show() -- The OnUpdate script will handle the rest
end

function addon:StopCast(unitID)
    local castbar = activeFrames[unitID]
    if castbar then
        castbar._data = nil
        castbar:Hide()
    end
end

function addon:StartAllCasts(unitGUID)
    if not activeTimers[unitGUID] then return end

    -- partyX, nameplateX and target might be the same guid, so we need to loop through them all
    -- and start the castbar for each frame found
    for unit, guid in pairs(activeGUIDs) do
        if guid == unitGUID then
            self:StartCast(guid, unit)
        end
    end
end

function addon:StopAllCasts(unitGUID)
    for unit, guid in pairs(activeGUIDs) do
        if guid == unitGUID then
            self:StopCast(unit)
        end
    end
end

function addon:StoreCast(unitGUID, spellName, iconTexturePath, castTime, isChanneled)
    local currTime = GetTime()

    -- Store cast data from CLEU in an object, we can't store this in the castbar frame itself
    -- since nameplate activeFrames are constantly recycled between different units.
    activeTimers[unitGUID] = {
        spellName = spellName,
        icon = iconTexturePath,
        maxValue = castTime / 1000,
        timeStart = currTime,
        endTime = currTime + (castTime / 1000),
        unitGUID = unitGUID,
        isChanneled = isChanneled, -- TODO: inverse castbar values if this is true
    }

    self:StartAllCasts(unitGUID)
end

-- Delete cast data for unit, and stop any active castbars
function addon:DeleteCast(unitGUID)
    if unitGUID then -- sanity check
        self:StopAllCasts(unitGUID)
        activeTimers[unitGUID] = nil
    end
end

function addon:COMBAT_LOG_EVENT_UNFILTERED()
    local _, eventType, _, srcGUID, _, _, _, dstGUID,  _, _, _, spellID, spellName, _, failedType = CombatLogGetCurrentEventInfo()

    if eventType == "SPELL_CAST_START" then
        local _, _, icon, castTime = GetSpellInfo(spellID)
        if not castTime or castTime == 0 then return end

        self:StoreCast(srcGUID, spellName, icon, castTime)
    elseif eventType == "SPELL_CAST_SUCCESS" then
        -- Channeled spells are started on SPELL_CAST_SUCCESS instead of stopped
        -- Also there's no castTime returned from GetSpellInfo for channeled spells so we need to get it from our own list
        local castTime = channeledSpells[spellName]
        if castTime then
            self:StoreCast(srcGUID, spellName, GetSpellTexture(spellID), castTime * 1000, true)
        else
            -- Normal spell, finish it
            self:DeleteCast(srcGUID)
        end
    elseif eventType == "SPELL_AURA_REMOVED" then
        -- Channeled spells has no SPELL__CAST_* event for channel stop
        -- so check if aura is gone instead
        if channeledSpells[spellName] then
            self:DeleteCast(srcGUID)
        end
    elseif eventType == "SPELL_CAST_FAILED" or eventType == "SPELL_INTERRUPT" then
        if srcGUID == self.PLAYER_GUID then
            -- Spamming cast keybinding triggers SPELL_CAST_FAILED so check if actually casting or not for the player
            if not CastingInfo() then
                self:DeleteCast(srcGUID)
            end
        else
            self:DeleteCast(srcGUID)
        end
    elseif eventType == "PARTY_KILL" or eventType == "UNIT_DIED" then
        self:DeleteCast(dstGUID)
    end
end

function addon:PLAYER_ENTERING_WORLD()
    -- Reset all data on loading screens
    wipe(activeGUIDs)
    wipe(activeTimers)
    wipe(activeFrames)

    PoolManager:GetFramePool():ReleaseAll() -- also wipes castbar._data
end

function addon:ToggleUnitEvents(shouldReset)
    if self.db.target.enabled then
        self:RegisterEvent("PLAYER_TARGET_CHANGED")
    else
        self:UnregisterEvent("PLAYER_TARGET_CHANGED")
    end

    if self.db.nameplate.enabled then
        self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
        self:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    else
        self:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
        self:UnregisterEvent("NAME_PLATE_UNIT_REMOVED")
    end

    if shouldReset then
        self:PLAYER_ENTERING_WORLD() -- reset all data
    end
end

function addon:PLAYER_LOGIN()
    ClassicCastbarsDB = ClassicCastbarsDB and next(ClassicCastbarsDB) and ClassicCastbarsDB or {
        version = "1", -- config version, not same as addon version

        nameplate = {
            enabled = true,
            position = { "BOTTOMLEFT", 15, -18 },
        },

        target = {
            enabled = true,
            dynamicTargetPosition = true,
            position = { "BOTTOMLEFT", 25, -60 },
        }
    }

    self.db = ClassicCastbarsDB
    self.PLAYER_GUID = UnitGUID("player")
    self:ToggleUnitEvents()
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:UnregisterEvent("PLAYER_LOGIN")
    self.PLAYER_LOGIN = nil
end

-- Bind unitIDs to unitGUIDs so we can efficiently get unitIDs in CLEU events
function addon:PLAYER_TARGET_CHANGED()
    activeGUIDs.target = UnitGUID("target") or nil
    self:StopCast("target") -- always hide previous target's castbar

    --if activeFrames.target then
        -- Show castbar again if available
        self:StartCast(activeGUIDs.target, "target")
    --end
end

function addon:NAME_PLATE_UNIT_ADDED(namePlateUnitToken)
    local unitGUID = UnitGUID(namePlateUnitToken)
    activeGUIDs[namePlateUnitToken] = unitGUID

    self:StartCast(unitGUID, namePlateUnitToken)
end

function addon:NAME_PLATE_UNIT_REMOVED(namePlateUnitToken)
    activeGUIDs[namePlateUnitToken] = nil

    -- Release frame, but do not delete cast data
    local castbar = activeFrames[namePlateUnitToken]
    if castbar then
        PoolManager:ReleaseFrame(castbar)
        activeFrames[namePlateUnitToken] = nil
    end
end

-- FIXME: we should make this dynamic incase user changes width ingame
local CASTBAR_WIDTH = 150

addon:SetScript("OnUpdate", function(self)
    if not next(activeTimers) then return end
    local currTime = GetTime()

    -- Update all active castbars in a single OnUpdate call
    for unit, castbar in pairs(activeFrames) do
        local cast = castbar._data

        if cast then
            local castTime = cast.endTime - currTime

            if (castTime > 0) then
                local value = currTime - cast.timeStart
                castbar:SetValue(value)
                castbar.Timer:SetFormattedText("%.1f", castTime)

                local sparkPosition = (value / cast.maxValue) * CASTBAR_WIDTH
                castbar.Spark:SetPoint("CENTER", castbar, "LEFT", sparkPosition, 0)
            else
                -- Delete cast incase it wasn't detected in CLEU (i.e unit out of range)
                self:DeleteCast(cast.unitGUID)
            end
        end
    end
end)

-- Options Slash Commands
SLASH_CLASSICCASTBARS1 = "/castbars"
SLASH_CLASSICCASTBARS2 = "/castbar"
SLASH_CLASSICCASTBARS3 = "/classiccastbars"
SLASH_CLASSICCASTBARS4 = "/classicastbars"
SlashCmdList["CLASSICCASTBARS"] = function(msg)
    local cmd, value, value2, value3 = strsplit(" ", msg:sub(1):trim())

    if cmd == "nameplate" and value == "pos" and tonumber(value2) and tonumber(value3) then
        addon.db.nameplate.position[2] = tonumber(value2)
        addon.db.nameplate.position[3] = tonumber(value3)
        print(format("Nameplate castbar position set to X=%d, Y=%d.", value2, value3))
    elseif cmd == "target" and value == "pos" and value2 == "dynamic" then
        addon.db.target.dynamicTargetPosition = not addon.db.target.dynamicTargetPosition
        print(format("Target castbar dynamic position: %s", tostring(addon.db.target.dynamicTargetPosition)))
    elseif cmd == "target" and value == "pos" and tonumber(value2) and tonumber(value3) then
        addon.db.target.position[2] = tonumber(value2)
        addon.db.target.position[3] = tonumber(value3)
        addon.db.target.dynamicTargetPosition = false
        print(format("Target castbar position set to X=%d, Y=%d.", value2, value3))
    elseif cmd == "nameplate"  and value == "enable" then
        addon.db.nameplate.enabled = not addon.db.nameplate.enabled
        addon:ToggleUnitEvents(true)
        print(format("Nameplate castbars enabled: %s", tostring(addon.db.nameplate.enabled)))
    elseif cmd == "target" and value == "enable" then
        addon.db.target.enabled = not addon.db.target.enabled
        addon:ToggleUnitEvents(true)
        print(format("Target castbar enabled: %s", tostring(addon.db.target.enabled)))
    else
        print("Valid commands are:\n/castbar nameplate enable\n/castbar target enable\n/castbar target pos dynamic\n/castbar target pos xValue yValue\n/castbar nameplate pos xValue yValue")
        print("See addon download page for command descriptions.")
    end
end
