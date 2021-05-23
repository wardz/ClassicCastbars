if _G.WOW_PROJECT_ID ~= (_G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC or 5) then
    return print("|cFFFF0000[ERROR] You're using the TBC version of ClassicCastbars on a non-TBC client. Please download the correct version.|r") -- luacheck: ignore
end

local _, namespace = ...
local PoolManager = namespace.PoolManager
local activeFrames = {}

local addon = CreateFrame("Frame", "ClassicCastbars")
addon:RegisterEvent("PLAYER_LOGIN")
addon:SetScript("OnEvent", function(self, event, ...)
    return self[event](self, ...)
end)
addon.AnchorManager = namespace.AnchorManager
addon.defaultConfig = namespace.defaultConfig
addon.activeFrames = activeFrames
namespace.addon = addon

local GetNamePlateForUnit = _G.C_NamePlate.GetNamePlateForUnit
local UnitIsFriend = _G.UnitIsFriend
local UnitCastingInfo = _G.UnitCastingInfo
local UnitChannelInfo = _G.UnitChannelInfo
local gsub = _G.string.gsub

local castEvents = {
    "UNIT_SPELLCAST_START",
    "UNIT_SPELLCAST_STOP",
    "UNIT_SPELLCAST_INTERRUPTED",
    "UNIT_SPELLCAST_SUCCEEDED",
    "UNIT_SPELLCAST_DELAYED",
    "UNIT_SPELLCAST_FAILED",
    "UNIT_SPELLCAST_FAILED_QUIET",
    "UNIT_SPELLCAST_CHANNEL_START",
    "UNIT_SPELLCAST_CHANNEL_UPDATE",
    "UNIT_SPELLCAST_CHANNEL_STOP",
}

function addon:GetUnitType(unitID)
    local unit = gsub(unitID or "", "%d", "") -- remove numbers
    if unit == "nameplate-testmode" then
        unit = "nameplate"
    elseif unit == "arena-testmode" then
        unit = "arena"
    elseif unit == "party-testmode" then
        unit = "party"
    end

    return unit
end

function addon:GetCastbarFrameIfEnabled(unitID)
    local cfg = self.db[self:GetUnitType(unitID)]
    if cfg and cfg.enabled then
        if self:GetUnitType(unitID) == "nameplate" then
            local isFriendly = UnitIsFriend("player", unitID)
            if not self.db.nameplate.showForFriendly and isFriendly then return end
            if not self.db.nameplate.showForEnemy and not isFriendly then return end
        end

        return addon:GetCastbarFrame(unitID)
    end
end

-- TODO: cleanup
function addon:DisableBlizzardCastbar(unitID, disable)
    if not disable then
        if unitID == "target" then
            for i = 1, #castEvents do
                TargetFrameSpellBar:RegisterEvent(castEvents[i])
            end
            TargetFrameSpellBar.showCastbar = true
        elseif unitID == "focus" then
            for i = 1, #castEvents do
                FocusFrameSpellBar:RegisterEvent(castEvents[i])
            end
            FocusFrameSpellBar.showCastbar = true
        elseif self:GetUnitType(unitID) == "arena" then
            for i = 1, 5 do
                local frame = _G["ArenaEnemyFrame"..i.."CastingBar"]
                if frame then
                    frame.showCastbar = true
                    for j = 1, #castEvents do
                        frame:RegisterEvent(castEvents[j])
                    end
                end
            end
        end
    else
        if unitID == "target" then
            TargetFrameSpellBar.showCastbar = false
            TargetFrameSpellBar:SetAlpha(0)
            TargetFrameSpellBar:SetValue(0)
            TargetFrameSpellBar:Hide()
            for i = 1, #castEvents do
                TargetFrameSpellBar:UnregisterEvent(castEvents[i])
            end
        elseif unitID == "focus" then
            FocusFrameSpellBar.showCastbar = false
            FocusFrameSpellBar:SetAlpha(0)
            FocusFrameSpellBar:SetValue(0)
            FocusFrameSpellBar:Hide()
            for i = 1, #castEvents do
                FocusFrameSpellBar:UnregisterEvent(castEvents[i])
            end
        elseif self:GetUnitType(unitID) == "arena" then
            for i = 1, 5 do
                local frame = _G["ArenaEnemyFrame"..i.."CastingBar"]
                if frame then
                    frame.showCastbar = false
                    for j = 1, #castEvents do
                        frame:UnregisterEvent(castEvents[j])
                    end
                end
            end
        end
    end
end

function addon:BindCurrentCastData(castbar, unitID, isChanneled)
    castbar._data = castbar._data or {}
    local cast = castbar._data

    local GetCastingInfo = isChanneled and UnitChannelInfo or UnitCastingInfo
    local spellName, _, iconTexturePath, startTimeMS, endTimeMS, _, _, _, spellID = GetCastingInfo(unitID)
    cast.maxValue = (endTimeMS - startTimeMS) / 1000
    cast.endTime = endTimeMS / 1000
    cast.spellName = spellName
    cast.spellID = spellID
    cast.icon = iconTexturePath
    cast.isChanneled = isChanneled
    cast.timeStart = startTimeMS / 1000
    cast.isUninterruptible = nil
    cast.isFailed = nil
    cast.isInterrupted = nil
    cast.isCastComplete = nil
end

function addon:PLAYER_TARGET_CHANGED()
    if UnitCastingInfo("target") then
        self:UNIT_SPELLCAST_START("target")
    elseif UnitChannelInfo("target") then
        self:UNIT_SPELLCAST_CHANNEL_START("target")
    else
        local castbar = activeFrames["target"]
        if castbar then -- this seems to be needed for race conditions
            self:HideCastbar(castbar, "target", true)
        end
    end
end

function addon:PLAYER_FOCUS_CHANGED()
    if UnitCastingInfo("focus") then
        self:UNIT_SPELLCAST_START("focus")
    elseif UnitChannelInfo("focus") then
        self:UNIT_SPELLCAST_CHANNEL_START("focus")
    else
        local castbar = activeFrames["focus"]
        if castbar then
            self:HideCastbar(castbar, "focus", true)
        end
    end
end

function addon:NAME_PLATE_UNIT_ADDED(namePlateUnitToken)
    local plate = GetNamePlateForUnit(namePlateUnitToken)
    plate.UnitFrame.CastBar.showCastbar = not self.db.nameplate.enabled
    if self.db.nameplate.enabled then
        plate.UnitFrame.CastBar:Hide()
    end

    if UnitCastingInfo(namePlateUnitToken) then
        self:UNIT_SPELLCAST_START(namePlateUnitToken)
    elseif UnitChannelInfo(namePlateUnitToken) then
        self:UNIT_SPELLCAST_CHANNEL_START(namePlateUnitToken)
    else
        local castbar = activeFrames[namePlateUnitToken]
        if castbar then -- this seems to be needed for race conditions
            self:HideCastbar(castbar, namePlateUnitToken, true)
        end
    end
end

function addon:NAME_PLATE_UNIT_REMOVED(namePlateUnitToken)
    local castbar = activeFrames[namePlateUnitToken]
    if castbar then
        PoolManager:ReleaseFrame(castbar)
        activeFrames[namePlateUnitToken] = nil
    end
end

function addon:UNIT_SPELLCAST_START(unitID)
    local castbar = self:GetCastbarFrameIfEnabled(unitID)
    if not castbar then return end

    self:BindCurrentCastData(castbar, unitID, false)
    self:DisplayCastbar(castbar, unitID)
end

function addon:UNIT_SPELLCAST_CHANNEL_START(unitID)
    local castbar = self:GetCastbarFrameIfEnabled(unitID)
    if not castbar then return end

    self:BindCurrentCastData(castbar, unitID, true)
    self:DisplayCastbar(castbar, unitID)
end

function addon:UNIT_SPELLCAST_STOP(unitID)
    local castbar = activeFrames[unitID]
    if not castbar then return end

    if not castbar.isTesting then
        if castbar._data then
            if not castbar._data.isInterrupted then
                castbar._data.isFailed = true
            end
        end
        self:HideCastbar(castbar, unitID)
    end

    castbar._data = nil
end

function addon:UNIT_SPELLCAST_INTERRUPTED(unitID)
    local castbar = activeFrames[unitID]
    if not castbar then return end

    if not castbar.isTesting then
        if castbar._data then
            castbar._data.isInterrupted = true
            castbar._data.isFailed = false
        end
        self:HideCastbar(castbar, unitID)
    end

    castbar._data = nil
end

function addon:UNIT_SPELLCAST_SUCCEEDED(unitID)
    local castbar = activeFrames[unitID]
    if not castbar then return end

    if not castbar.isTesting then
        if castbar._data then
            castbar._data.isCastComplete = true
            if castbar._data.isChanneled then return end -- _SUCCEEDED triggered every tick for channeled
        end
        self:HideCastbar(castbar, unitID)
    end

    castbar._data = nil
end

function addon:UNIT_SPELLCAST_DELAYED(unitID)
    local castbar = self:GetCastbarFrameIfEnabled(unitID)
    if not castbar then return end

    self:BindCurrentCastData(castbar, unitID, false)
end

function addon:UNIT_SPELLCAST_CHANNEL_UPDATE(unitID)
    local castbar = self:GetCastbarFrameIfEnabled(unitID)
    if not castbar then return end

    self:BindCurrentCastData(castbar, unitID, true)
end

function addon:UNIT_SPELLCAST_FAILED(unitID)
    local castbar = activeFrames[unitID]
    if not castbar then return end

    if not castbar.isTesting then
        if castbar._data then
            if not castbar._data.isInterrupted then
                castbar._data.isFailed = true
            end
        end
        self:HideCastbar(castbar, unitID)
    end

    castbar._data = nil
end
addon.UNIT_SPELLCAST_FAILED_QUIET = addon.UNIT_SPELLCAST_FAILED

function addon:UNIT_SPELLCAST_CHANNEL_STOP(unitID)
    local castbar = activeFrames[unitID]
    if not castbar then return end

    if not castbar.isTesting then
        self:HideCastbar(castbar, unitID)
    end

    castbar._data = nil
end

function addon:UNIT_AURA(unitID)
    if not self.db[unitID].autoPosition then return end
    -- TODO: aurarows

    -- Update target castbar position based on amount of auras currently shown
    if activeFrames[unitID] and UnitExists(unitID) then
        local parentFrame = self.AnchorManager:GetAnchor(unitID)
        if parentFrame then
            self:SetTargetCastbarPosition(activeFrames[unitID], parentFrame)
        end
    end
end

function addon:ToggleUnitEvents(shouldReset)
    if self.db.target.enabled or self.db.focus.enabled then
        if self.db.target.autoPosition or self.db.focus.autoPosition then
            self:RegisterUnitEvent("UNIT_AURA", "target", "focus")
        end
    else
        self:UnregisterEvent("UNIT_AURA")
    end

    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:RegisterEvent("PLAYER_FOCUS_CHANGED")

    if self.db.party.enabled then
        self:RegisterEvent("GROUP_ROSTER_UPDATE")
        self:RegisterEvent("GROUP_JOINED")
    else
        self:UnregisterEvent("GROUP_ROSTER_UPDATE")
        self:UnregisterEvent("GROUP_JOINED")
    end

    --if self.db.nameplate.enabled then
        self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
        self:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    --[[else
        self:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
        self:UnregisterEvent("NAME_PLATE_UNIT_REMOVED")
    end]]

    for i = 1, #castEvents do
        self:RegisterEvent(castEvents[i])
    end

    if shouldReset then
        self:PLAYER_ENTERING_WORLD() -- wipe all data
    end
end

function addon:PLAYER_ENTERING_WORLD(isInitialLogin)
    if isInitialLogin then return end

    -- Reset all data on loading screens
    wipe(activeFrames)
    PoolManager:GetFramePool():ReleaseAll() -- also removes castbar._data references

    if self.db.party.enabled and IsInGroup() then
        self:GROUP_ROSTER_UPDATE()
    end
end

-- Copies table values from src to dst if they don't exist in dst
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
    ClassicCastbarsDB = ClassicCastbarsDB or {}

    -- Copy any settings from defaults if they don't exist in current profile
    if ClassicCastbarsCharDB and ClassicCastbarsCharDB.usePerCharacterSettings then
        self.db = CopyDefaults(namespace.defaultConfig, ClassicCastbarsCharDB)
    else
        self.db = CopyDefaults(namespace.defaultConfig, ClassicCastbarsDB)
    end
    self.db.version = namespace.defaultConfig.version

    -- Reset certain stuff on game locale switched
    if self.db.locale ~= GetLocale() then
        self.db.locale = GetLocale()
        self.db.target.castFont = _G.STANDARD_TEXT_FONT
        self.db.nameplate.castFont = _G.STANDARD_TEXT_FONT
        self.db.focus.castFont = _G.STANDARD_TEXT_FONT
        self.db.arena.castFont = _G.STANDARD_TEXT_FONT
        self.db.party.castFont = _G.STANDARD_TEXT_FONT
    end

    -- config is not needed anymore if options are not loaded
    if not IsAddOnLoaded("ClassicCastbars_Options") then
        self.defaultConfig = nil
        namespace.defaultConfig = nil
    end

    if self.db.player.enabled then
        self:SkinPlayerCastbar()
    end

    self:DisableBlizzardCastbar("target", self.db.target.enabled)
    self:DisableBlizzardCastbar("focus", self.db.focus.enabled)

    self.PLAYER_GUID = UnitGUID("player")
    self:ToggleUnitEvents()
    --self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:UnregisterEvent("PLAYER_LOGIN")
    self.PLAYER_LOGIN = nil
end

function addon:GROUP_ROSTER_UPDATE()
    for i = 1, 5 do
        if UnitExists("party"..i) then
            if activeFrames["party"..i] then
                activeFrames["party"..i]:Hide()
            end
        else
            -- party member no longer exists, release castbar
            local castbar = activeFrames["party"..i]
            if castbar then
                PoolManager:ReleaseFrame(castbar)
                activeFrames["party"..i] = nil
            end
        end
    end
end
addon.GROUP_JOINED = addon.GROUP_ROSTER_UPDATE

function addon:COMBAT_LOG_EVENT_UNFILTERED()
    -- TODO: CLEU auto learn uninterruptible casts
end

addon:SetScript("OnUpdate", function(self)
    local currTime = GetTime()

    -- Update all shown castbars in a single OnUpdate call
    for unit, castbar in next, activeFrames do
        local cast = castbar._data
        if cast then
            local castTime = cast.endTime - currTime

            if (castTime > 0) then
                local maxValue = cast.endTime - cast.timeStart
                local value = currTime - cast.timeStart
                if cast.isChanneled then -- inverse
                    value = maxValue - value
                end

                castbar:SetMinMaxValues(0, maxValue)
                castbar:SetValue(value)
                castbar.Timer:SetFormattedText("%.1f", castTime)
                local sparkPosition = (value / maxValue) * (castbar.currWidth or castbar:GetWidth())
                castbar.Spark:SetPoint("CENTER", castbar, "LEFT", sparkPosition, 0)
            end
        end
    end
end)
