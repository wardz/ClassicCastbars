local _, namespace = ...
local AnchorManager = namespace.AnchorManager
local PoolManager = namespace.PoolManager

-- CastingInfo()
-- UNIT_SPELL available?
-- TODO: if target has too many auras, adjust castbar position
-- TODO: show if cast is interruptible?
-- TODO: add optional castbars for party frames

local addon = CreateFrame("Frame")
addon:RegisterEvent("PLAYER_LOGIN")
addon:SetScript("OnEvent", function(self, event, ...)
    return self[event](self, ...)
end)

local activeGUIDs = {}
local activeTimers = {}
local frames = {}

-- upvalues
local pairs = _G.pairs
local UnitGUID = _G.UnitGUID
local GetSpellInfo = _G.GetSpellInfo
local CombatLogGetCurrentEventInfo = _G.CombatLogGetCurrentEventInfo
local GetTime = _G.GetTime
local floor = _G.math.floor
local mod = _G.mod
local next = _G.next

function addon:GetCastbarFrame(unitID)
    -- PoolManager:DebugInfo()

    if frames[unitID] then
        return frames[unitID]
    end

    -- cache reference, refs are deleted on frame recycled
    frames[unitID] = PoolManager:AcquireFrame()

    return frames[unitID]
end

function addon:StartCast(unitGUID, unitID)
    if not activeTimers[unitGUID] then return end

    local castbar = self:GetCastbarFrame(unitID)
    if not castbar then return end

    local parentFrame = AnchorManager:GetAnchor(unitID)
    if not parentFrame then return end

    -- Position frame, the OnUpdate script will handle the rest
    castbar._data = activeTimers[unitGUID] -- set ref to current cast data
    castbar:SetParent(parentFrame)

    if unitID == "target" then
        local pos = self.db.target.position
        castbar:SetPoint(pos[1], parentFrame, pos[2], pos[3])
    else
        local pos = self.db.nameplate.position
        castbar:SetPoint(pos[1], parentFrame, pos[2], pos[3])
    end
end

function addon:StopCast(unitID)
    local castbar = frames[unitID]
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

function addon:StoreCast(unitGUID, spellName, icon, castTime)
    -- Store cast data from CLEU in an object, we can't bind this to the frame itself
    -- since nameplate frames are constantly recycled between different units.
    activeTimers[unitGUID] = {
        spellName = spellName,
        icon = icon,
        castTime = castTime,
        timeStart = GetTime(),
        endTime = GetTime() + (castTime / 1000),
        unitGUID = unitGUID,
    }

    self:StartAllCasts(unitGUID)
end

-- Delete cast data for unit, and stop any active castbars
function addon:DeleteCast(unitGUID)
    self:StopAllCasts(unitGUID)
    activeTimers[unitGUID] = nil
end

function addon:COMBAT_LOG_EVENT_UNFILTERED()
    local _, eventType, _, srcGUID, _, _, _, dstGUID,  _, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()

    if eventType == "SPELL_CAST_START" then
        -- local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo(unit)
        local _, _, icon, castTime = GetSpellInfo(spellID)
        if not castTime or castTime == 0 then return end

        self:StoreCast(srcGUID, spellName, icon, castTime)
    elseif eventType == "SPELL_CAST_SUCCESS" or eventType == "SPELL_CAST_FAILED" or eventType == "SPELL_INTERRUPT" then
        -- TODO: some channeled spells are started here, not ended
        self:DeleteCast(srcGUID)
    elseif eventType == "PARTY_KILL" or eventType == "UNIT_DIED" then
        self:DeleteCast(dstGUID)
    end
end

function addon:PLAYER_ENTERING_WORLD()
    -- Reset all data on loading screens
    wipe(activeGUIDs)
    wipe(activeTimers)
    wipe(frames)
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
        self:PLAYER_ENTERING_WORLD() -- reset any active frames & casts
    end
end

function addon:PLAYER_LOGIN()
    ClassicCastbarsDB = ClassicCastbarsDB and next(ClassicCastbarsDB) and ClassicCastbarsDB or {
        nameplate = {
            enabled = true,
            position = { "BOTTOMLEFT", 0, 5 },
        },

        target = {
            enabled = true,
            position = { "BOTTOMLEFT", 25, -60 },
        }
    }

    self.db = ClassicCastbarsDB
    self:ToggleUnitEvents()
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:UnregisterEvent("PLAYER_LOGIN")
    self.PLAYER_LOGIN = nil
end

-- Bind unitIDs to unitGUIDs so we can efficiently get unitID in CLEU events
function addon:PLAYER_TARGET_CHANGED()
    activeGUIDs.target = UnitGUID("target") or nil
    self:StopCast("target") -- always hide previous target's castbar

    if frames.target then
        -- Show castbar again if available
        self:StartCast(activeGUIDs.target, "target")
    end
end

function addon:NAME_PLATE_UNIT_ADDED(namePlateUnitToken)
    local unitGUID = UnitGUID(namePlateUnitToken)
    activeGUIDs[namePlateUnitToken] = unitGUID

    self:StartCast(unitGUID, namePlateUnitToken)
end

function addon:NAME_PLATE_UNIT_REMOVED(namePlateUnitToken)
    activeGUIDs[namePlateUnitToken] = nil

    -- Release frame, but do not delete cast data
    local castbar = frames[namePlateUnitToken]
    if castbar then
        PoolManager:ReleaseFrame(castbar)
        frames[namePlateUnitToken] = nil
    end
end

local function Round(num)
    local idp = num > 3 and 0 or 1
    local mult = 10^(idp or 0)

    return floor(num * mult + 0.5) / mult
end

addon:SetScript("OnUpdate", function(self)
    if not next(activeTimers) then return end
    local currTime = GetTime()

    for unit, castbar in pairs(frames) do
        local cast = castbar._data

        if cast then
            local maxValue = cast.castTime / 1000
            local castTime = cast.endTime - currTime

            if (castTime > 0) then
                local value = mod((currTime - cast.timeStart), cast.endTime - cast.timeStart)
                castbar:SetMinMaxValues(0, maxValue)
                castbar:SetValue(value)
                castbar.timer:SetText(Round(castTime, 3))

                if castbar.Text:GetText() ~= cast.spellName then
                    castbar.Text:SetText(cast.spellName)
                    castbar.Icon:SetTexture(cast.icon)
                end

                local sparkPosition = (value / maxValue) * castbar:GetWidth()
                castbar.Spark:SetPoint("CENTER", castbar, "LEFT", sparkPosition, 0)
                castbar:Show()
            else
                self:DeleteCast(cast.unitGUID)
            end
        end
    end
end)

SLASH_CLASSICCASTBARS1 = "/classiccastbars"
SLASH_CLASSICCASTBARS2 = "/classicastbars"
SLASH_CLASSICCASTBARS3 = "/castbars"
SlashCmdList["CLASSICCASTBARS"] = function(msg)
    local cmd, value = strsplit(" ", msg:sub(1):trim())

    if cmd == "nameplate" or cmd == "nameplates" then
        addon.db.nameplate.enabled = not addon.db.nameplate.enabled
        addon:ToggleUnitEvents(true)
        print(format("Nameplate castbars enabled: %s", addon.db.nameplate.enabled))
    elseif cmd == "target" then
        addon.db.target.enabled = not addon.db.target.enabled
        addon:ToggleUnitEvents(true)
        print(format("Target castbar enabled: %s", addon.db.nameplate.enabled))
    elseif cmd == "position" then
        print("Position mode enabled. Click and drag a castbar to move.\nType /castbar position again to save & exit.")
        -- TODO: addme
    else
        print("Valid commands are:\n/castbars nameplate\n/castbars target\n/castbars position")
    end
end
