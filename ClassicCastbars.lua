local _, namespace = ...
local PoolManager = namespace.PoolManager
local channeledSpells = namespace.channeledSpells

-- TODO: show if cast is interruptible?
-- TODO: add optional castbars for party frames
-- TODO: show spell rank option
-- TODO: pushback detection
-- TODO: show/hide time countdown option
-- TODO: status colors flash

local addon = CreateFrame("Frame")
addon:RegisterEvent("PLAYER_LOGIN")
addon:SetScript("OnEvent", function(self, event, ...)
    return self[event](self, ...)
end)

local activeGUIDs = {}
local activeTimers = {}
local activeFrames = {}
namespace.activeFrames = activeFrames
namespace.addon = addon

-- upvalues
local pairs = _G.pairs
local UnitGUID = _G.UnitGUID
local GetSpellInfo = _G.GetSpellInfo
local GetSpellTexture = _G.GetSpellTexture
local CombatLogGetCurrentEventInfo = _G.CombatLogGetCurrentEventInfo
local GetTime = _G.GetTime
local next = _G.next
local CastingInfo = _G.CastingInfo

function addon:StartCast(unitGUID, unitID)
    if not activeTimers[unitGUID] then return end

    local castbar = self:GetCastbarFrame(unitID)
    if not castbar then return end

    castbar._data = activeTimers[unitGUID] -- set ref to current cast data
    self:DisplayCastbar(castbar, unitID)
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
    -- since nameplate frames are constantly recycled between different units.
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

function addon:PLAYER_ENTERING_WORLD(isInitialLogin)
    if isInitialLogin then return end

    -- Reset all data on loading screens
    wipe(activeGUIDs)
    wipe(activeTimers)
    wipe(activeFrames)
    PoolManager:GetFramePool():ReleaseAll() -- also wipes castbar._data
end

local function CopyDefaults(src, dst)
    if type(src) ~= "table" then return {} end
    if type(dst) ~= "table" then dst = {} end

    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = CopyDefaults(v, dst[k])
        elseif type(v) ~= type(dst[k]) then
            dst[k] = v
        end
    end

    return dst
end

function addon:PLAYER_LOGIN()
    ClassicCastbarsDB = next(ClassicCastbarsDB or {}) and ClassicCastbarsDB or namespace.defaultConfig

    -- Copy any settings from default if they don't exist in current profile
    -- TODO: try metatable index instead of CopyDefaults
    self.db = CopyDefaults(namespace.defaultConfig, ClassicCastbarsDB)

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

function addon:COMBAT_LOG_EVENT_UNFILTERED()
    local _, eventType, _, srcGUID, _, _, _, dstGUID,  _, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()

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
            -- non-channeled spell, finish it
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
            -- Note: we could also use 'failedType' CLEU arg but it's not unlocalized so easier to use CastingInfo
            if not CastingInfo() then
                self:DeleteCast(srcGUID)
            end
        else
            self:DeleteCast(srcGUID)
        end
    elseif eventType == "PARTY_KILL" or eventType == "UNIT_DIED" then
        -- no idea if this is needed tbh
        self:DeleteCast(dstGUID)
    end
end

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

                local sparkPosition = (value / cast.maxValue) * castbar:GetWidth()
                castbar.Spark:SetPoint("CENTER", castbar, "LEFT", sparkPosition, 0)
            else
                -- Delete cast incase stop event wasn't detected in CLEU (i.e unit out of range)
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
