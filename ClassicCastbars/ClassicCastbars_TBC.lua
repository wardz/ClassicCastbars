if not _G.WOW_PROJECT_ID or (_G.WOW_PROJECT_ID ~= _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC) then
    --return print("|cFFFF0000[ERROR] This version of ClassicCastbars only supports The Burning Crusade. Download the classic version instead for vanilla.|r") -- luacheck: ignore
    return
end

------------------------------
-- EARLY PROTOTYPE STUFF, NOTHING HERE WORKS YET !!!

-- luacheck: ignore

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

local UnitCastingInfo = _G.UnitCastingInfo
local UnitChannelInfo = _G.UnitChannelInfo
local gsub = _G.string.gsub

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

local origGetCastbarFrame = addon.GetCastbarFrame
function addon:GetCastbarFrame(unitID)
    -- TODO: will this work?
    if self.db[self:GetUnitType(unitID)].enabled then
        return origGetCastbarFrame(unitID)
    end
end

function addon:BindCurrentCastData(castbar, unitID, isChanneled)
    castbar._data = castbar._data or {}
    local cast = castbar._data

    local GetCastingInfo = isChanneled and UnitChannelInfo or UnitCastingInfo
    local spellName, _, iconTexturePath, startTimeMS, endTimeMS, _, _, _, spellID = GetCastingInfo(unitID)
    cast.maxValue = endTimeMS - startTimeMS
    cast.endTime = endTimeMS
    cast.spellName = spellName
    cast.spellID = spellID
    cast.icon = iconTexturePath
    cast.isChanneled = isChanneled
    cast.timeStart = startTimeMS
    cast.isUninterruptible = nil
    cast.isFailed = nil
    cast.isInterrupted = nil
    cast.isCastComplete = nil
end

function addon:UNIT_SPELLCAST_START(unitID)
    local castbar = self:GetCastbarFrame(unitID)
    if not castbar then return end

    self:BindCurrentCastData(castbar, unitID, false)
    self:DisplayCastbar(castbar, unitID)
end

function addon:UNIT_SPELLCAST_CHANNEL_START(unitID)
    local castbar = self:GetCastbarFrame(unitID)
    if not castbar then return end

    self:BindCurrentCastData(castbar, unitID, true)
    self:DisplayCastbar(castbar, unitID)
end

function addon:UNIT_SPELLCAST_STOP(unitID, castGUID, spellID)
    local castbar = activeFrames[unitID]
    if not castbar then return end

    if not castbar.isTesting then
        self:HideCastbar(castbar, unitID)
    end

    castbar._data = nil
end

function addon:UNIT_SPELLCAST_INTERRUPTED(unitID, castGUID, spellID)
    local castbar = activeFrames[unitID]
    if not castbar then return end

    if not castbar.isTesting then
        castbar._data.isInterrupted = true
        self:HideCastbar(castbar, unitID)
    end

    castbar._data = nil
end

function addon:UNIT_SPELLCAST_SUCCEEDED(unitID, castGUID, spellID)
    local castbar = activeFrames[unitID]
    if not castbar then return end

    if not castbar.isTesting then
        castbar._data.isCastComplete = true
        self:HideCastbar(castbar, unitID)
    end

    castbar._data = nil
end

function addon:UNIT_SPELLCAST_DELAYED(unitID, castGUID, spellID)
    local castbar = self:GetCastbarFrame(unitID)
    if not castbar then return end

    self:BindCurrentCastData(castbar, unitID, false)
    --self:DisplayCastbar(castbar, unitID)
end

function addon:UNIT_SPELLCAST_CHANNEL_UPDATE(unitID, castGUID, spellID)
    local castbar = self:GetCastbarFrame(unitID)
    if not castbar then return end

    self:BindCurrentCastData(castbar, unitID, true)
end

function addon:UNIT_SPELLCAST_FAILED(unitID, castGUID, spellID)
    local castbar = activeFrames[unitID]
    if not castbar then return end

    if not castbar.isTesting then
        castbar._data.isFailed = true
        self:HideCastbar(castbar, unitID)
    end

    castbar._data = nil
end
addon.UNIT_SPELLCAST_FAILED_QUIET = addon.UNIT_SPELLCAST_FAILED

function addon:UNIT_SPELLCAST_CHANNEL_STOP(unitID, castGUID, spellID)
    local castbar = activeFrames[unitID]
    if not castbar then return end

    if not castbar.isTesting then
        --castbar._data.isFailed = true
        self:HideCastbar(castbar, unitID)
    end

    castbar._data = nil
end

local auraRows = 0
function addon:UNIT_AURA()
    if not self.db.target.autoPosition then return end
    if auraRows == TargetFrame.auraRows then return end
    auraRows = TargetFrame.auraRows

    -- Update target castbar position based on amount of auras currently shown
    if activeFrames.target and UnitExists("target") then
        local parentFrame = self.AnchorManager:GetAnchor("target")
        if parentFrame then
            self:SetTargetCastbarPosition(activeFrames.target, parentFrame)
        end
    end
end

function addon:ToggleUnitEvents(shouldReset)
    if self.db.target.enabled then
        if self.db.target.autoPosition then
            -- TODO: focus
            self:RegisterUnitEvent("UNIT_AURA", "target")
        end
    else
        self:UnregisterEvent("UNIT_AURA")
    end

    if self.db.party.enabled then
        self:RegisterEvent("GROUP_ROSTER_UPDATE")
        self:RegisterEvent("GROUP_JOINED")
    else
        self:UnregisterEvent("GROUP_ROSTER_UPDATE")
        self:UnregisterEvent("GROUP_JOINED")
    end

    self:RegisterEvent("UNIT_SPELLCAST_START")
    self:RegisterEvent("UNIT_SPELLCAST_STOP")
    self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:RegisterEvent("UNIT_SPELLCAST_DELAYED")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")

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

    self.PLAYER_GUID = UnitGUID("player")
    self:ToggleUnitEvents()
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:UnregisterEvent("PLAYER_LOGIN")
    self.PLAYER_LOGIN = nil
end

--[[function addon:GROUP_ROSTER_UPDATE()
    for i = 1, 5 do
        if UnitExists("party"..i) then
            -- hide castbar incase party frames were shifted around
            self:StopCast("party"..i, true) -- TODO: add me
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
addon.GROUP_JOINED = addon.GROUP_ROSTER_UPDATE]]

-- TODO: cleu auto learn uninterruptible casts
-- TODO: self.db.nameplate.showForFriendly

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
