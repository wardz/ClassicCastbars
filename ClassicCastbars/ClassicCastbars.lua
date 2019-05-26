local _, namespace = ...
local PoolManager = namespace.PoolManager
local channeledSpells = namespace.channeledSpells

local addon = CreateFrame("Frame")
addon:RegisterEvent("PLAYER_LOGIN")
addon:SetScript("OnEvent", function(self, event, ...)
    return self[event](self, ...)
end)

local activeGUIDs = {}
local activeTimers = {}
local activeFrames = {}

namespace.addon = addon
namespace.activeFrames = activeFrames
addon.AnchorManager = namespace.AnchorManager
ClassicCastbars = addon -- global ref for ClassicCastbars_Options

-- upvalues
local pairs = _G.pairs
local UnitGUID = _G.UnitGUID
local GetSpellInfo = _G.GetSpellInfo
local GetSpellTexture = _G.GetSpellTexture
local CombatLogGetCurrentEventInfo = _G.CombatLogGetCurrentEventInfo
local GetTime = _G.GetTime
local next = _G.next
local CastingInfo = _G.CastingInfo or _G.UnitCastingInfo

function addon:StartCast(unitGUID, unitID)
    if not activeTimers[unitGUID] then return end

    local castbar = self:GetCastbarFrame(unitID)
    if not castbar then return end

    castbar._data = activeTimers[unitGUID] -- set ref to current cast data
    self:DisplayCastbar(castbar, unitID)
end

function addon:StopCast(unitID)
    local castbar = activeFrames[unitID]
    if not castbar then return end

    castbar._data = nil
    if not castbar.isTesting then
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

function addon:StoreCast(unitGUID, spellName, iconTexturePath, castTime, spellRank, isChanneled)
    local currTime = GetTime()

    -- Store cast data from CLEU in an object, we can't store this in the castbar frame itself
    -- since nameplate frames are constantly recycled between different units.
    activeTimers[unitGUID] = {
        spellName = spellName,
        spellRank = spellRank,
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

function addon:CastPushback(unitGUID)
    local cast = activeTimers[unitGUID]
    if not cast then return end

    -- TODO: verify
    if not cast.isChanneled then
        cast.maxValue = cast.maxValue + 0.5
        cast.endTime = cast.endTime + 0.5
    else
        cast.maxValue = cast.maxValue - 0.5
        cast.endTime = cast.endTime - 0.5
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

    -- Reset old settings
    if ClassicCastbarsDB.version and ClassicCastbarsDB.version == "1" then
        wipe(ClassicCastbarsDB)
        print("ClassicCastbars: Settings reset due to major changes. See /castbar for new options.")
    end

    -- Copy any settings from default if they don't exist in current profile
    self.db = CopyDefaults(namespace.defaultConfig, ClassicCastbarsDB)
    self.db.version = namespace.defaultConfig.version

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

    -- Show castbar again if available
    self:StartCast(activeGUIDs.target, "target")
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
        local _, rank, icon, castTime = GetSpellInfo(spellID)
        if not castTime or castTime == 0 then return end
        -- print(rank) -- TODO: test if works on beta and with channels

        self:StoreCast(srcGUID, spellName, icon, castTime, rank)
    elseif eventType == "SPELL_CAST_SUCCESS" then
        -- Channeled spells are started on SPELL_CAST_SUCCESS instead of stopped
        -- Also there's no castTime returned from GetSpellInfo for channeled spells so we need to get it from our own list
        local castTime = channeledSpells[spellName]
        if castTime then
            self:StoreCast(srcGUID, spellName, GetSpellTexture(spellID), castTime * 1000, nil, true)
        else
            -- non-channeled spell, finish it
            self:DeleteCast(srcGUID)
        end
    elseif eventType == "SPELL_AURA_REMOVED" then
        -- Channeled spells has no SPELL__CAST_* event for channel stop
        -- so check if aura is gone instead since most (all?) channels has an aura effect
        if channeledSpells[spellName] then
            self:DeleteCast(srcGUID)
        end
    elseif eventType == "SPELL_CAST_FAILED" or eventType == "SPELL_INTERRUPT" then
        if srcGUID == self.PLAYER_GUID then
            -- Spamming cast keybinding triggers SPELL_CAST_FAILED so check if actually casting or not for the player
            if not CastingInfo("player") then
                self:DeleteCast(srcGUID)
            end
        else
            self:DeleteCast(srcGUID)
        end
    elseif eventType == "PARTY_KILL" or eventType == "UNIT_DIED" then
        -- no idea if this is needed tbh
        self:DeleteCast(dstGUID)
    elseif eventType == "SWING_DAMAGE" or eventType == "ENVIRONMENTAL_DAMAGE" or eventType == "RANGE_DAMAGE" or eventType == "SPELL_DAMAGE" then
        -- TODO: need to confirm which dmg types causes pushback
        self:CastPushback(dstGUID)
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
