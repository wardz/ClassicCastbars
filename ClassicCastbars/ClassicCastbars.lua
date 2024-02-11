local _, namespace = ...
local PoolManager = namespace.PoolManager
local castImmunityBuffs = namespace.castImmunityBuffs
local channeledSpells = namespace.channeledSpells
local activeFrames = {}
local activeGUIDs = {}

local ClassicCastbars = CreateFrame("Frame", "ClassicCastbars")
ClassicCastbars:RegisterEvent("PLAYER_LOGIN")
ClassicCastbars:SetScript("OnEvent", function(self, event, ...)
    return self[event](self, ...)
end)
ClassicCastbars.AnchorManager = namespace.AnchorManager
ClassicCastbars.defaultConfig = namespace.defaultConfig
ClassicCastbars.activeFrames = activeFrames

local castEvents = {
    "UNIT_SPELLCAST_START",
    "UNIT_SPELLCAST_STOP",
    "UNIT_SPELLCAST_INTERRUPTED",
    "UNIT_SPELLCAST_SUCCEEDED",
    "UNIT_SPELLCAST_DELAYED",
    "UNIT_SPELLCAST_FAILED",
    "UNIT_SPELLCAST_CHANNEL_START",
    "UNIT_SPELLCAST_CHANNEL_UPDATE",
    "UNIT_SPELLCAST_CHANNEL_STOP",
    "UNIT_SPELLCAST_INTERRUPTIBLE",
    "UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
}

local UnitAura = _G.UnitAura
local next = _G.next

-- UnitTokenFromGUID() doesn't exist in classic
function ClassicCastbars:GetFirstAvailableUnitIDByGUID(unitGUID)
    for unitID, guid in next, activeGUIDs do
        if guid == unitGUID then
            return unitID
        end
    end
end

local gsub = _G.string.gsub
function ClassicCastbars:GetUnitType(unitID)
    return gsub(gsub(unitID or "", "%d", ""), "-testmode", "") -- remove numbers and suffix
end

function ClassicCastbars:GetCastbarFrame(unitID)
    if unitID == "player" then return end

    if activeFrames[unitID] then
        return activeFrames[unitID]
    end

    activeFrames[unitID] = PoolManager:AcquireFrame()

    return activeFrames[unitID]
end

function ClassicCastbars:GetCastbarFrameIfEnabled(unitID)
    local unitType = self:GetUnitType(unitID)
    local cfg = self.db[unitType]
    if cfg and cfg.enabled then
        if unitType == "nameplate" then
            local isFriendly = UnitIsFriend("player", unitID)
            if not self.db.nameplate.showForFriendly and isFriendly then return end
            if not self.db.nameplate.showForEnemy and not isFriendly then return end
            if UnitIsUnit("player", unitID) then return end -- personal resource display nameplate
        end

        return ClassicCastbars:GetCastbarFrame(unitID)
    end
end

local function HideBlizzardSpellbar(spellbar)
    if spellbar.barType and spellbar.barType == "empowered" then return end -- special evoker castbar

    local cfg = ClassicCastbars.db[ClassicCastbars:GetUnitType(spellbar.unit)]
    if cfg and cfg.enabled then
        spellbar:Hide()
    end
end

function ClassicCastbars:DisableBlizzardCastbar()
    if not self.isSpellbarsHooked then
        self.isSpellbarsHooked = true

        TargetFrameSpellBar:HookScript("OnShow", HideBlizzardSpellbar)
        if FocusFrameSpellBar then
            FocusFrameSpellBar:HookScript("OnShow", HideBlizzardSpellbar)
        end
    end

    -- Arena frames are load on demand, hook if available
    if not self.isArenaSpellbarsHooked then
        for i = 1, 5 do
            local frame = _G["ArenaEnemyFrame"..i.."CastingBar"] or _G["ArenaEnemyMatchFrame"..i.."CastingBar"]
            if frame then
                frame:HookScript("OnShow", HideBlizzardSpellbar)
                self.isArenaSpellbarsHooked = true
            end
        end
    end
end

function ClassicCastbars:ADDON_LOADED(addonName)
    if addonName == "Blizzard_ArenaUI" then
        self:DisableBlizzardCastbar()
        self:UnregisterEvent("ADDON_LOADED")
        self.ADDON_LOADED = nil
    end
end

local npcID_uninterruptibleList = namespace.npcID_uninterruptibleList
local uninterruptibleList = namespace.uninterruptibleList
local strsplit = _G.string.split
local function GetDefaultUninterruptibleState(cast, unitID) -- needed pre-wrath only
    local isUninterruptible = uninterruptibleList[cast.spellID] or uninterruptibleList[cast.spellName] or false

    if not isUninterruptible and not cast.unitIsPlayer then
        local _, _, _, _, _, npcID = strsplit("-", UnitGUID(unitID))
        if npcID then
            if npcID == "209678" then -- Twilight Lord Kelris is immune at 35% hp (phase2)
                if ((UnitHealth(unitID) / UnitHealthMax(unitID)) * 100) <= 35 then
                    isUninterruptible = true
                else
                    isUninterruptible = false
                end
            else
                isUninterruptible = npcID_uninterruptibleList[npcID .. cast.spellName] or false
            end
        end
    end

    return isUninterruptible
end

function ClassicCastbars:BindCurrentCastData(castbar, unitID, isChanneled, channelSpellID)
    local spellName, iconTexturePath, startTimeMS, endTimeMS, castID, notInterruptible, spellID, _
    if not isChanneled then
        spellName, _, iconTexturePath, startTimeMS, endTimeMS, _, castID, notInterruptible, spellID = UnitCastingInfo(unitID)
    else
        if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and UnitIsUnit("player", unitID) then
            -- HACK: UnitChannelInfo is bugged for classic era, tmp fallback method
            spellName, _, iconTexturePath, startTimeMS, endTimeMS, _, notInterruptible, spellID = UnitChannelInfo("player")
        else
            spellName, _, iconTexturePath, startTimeMS, endTimeMS, _, notInterruptible, spellID = UnitChannelInfo(unitID)
        end

        if channelSpellID and not spellName then -- HACK: UnitChannelInfo is bugged for classic era, tmp fallback method
            spellName, _, iconTexturePath = GetSpellInfo(channelSpellID)
            local channelCastTime = spellName and channeledSpells[spellName]
            if not channelCastTime then return end

            spellID = channelSpellID
            endTimeMS = (GetTime() * 1000) + channelCastTime
            startTimeMS = GetTime() * 1000
        end
    end

    if not spellName then return end

    -- Leftovers from Classic Era pre 1.15.0 which had no cast API, otherwise we'd bind directly to our frame
    if not castbar._data then
        castbar._data = {}
    end

    local cast = castbar._data
    cast.castID = castID
    cast.maxValue = (endTimeMS - startTimeMS) / 1000
    cast.endTime = endTimeMS / 1000
    cast.spellName = spellName
    cast.spellID = spellID
    cast.icon = iconTexturePath
    cast.isChanneled = isChanneled
    cast.timeStart = startTimeMS / 1000
    cast.unitIsPlayer = UnitIsPlayer(unitID)
    cast.isUninterruptible = notInterruptible or nil
    cast.isFailed = nil
    cast.isInterrupted = nil
    cast.isCastComplete = nil

    -- Check if cast is uninterruptible on start
    if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
        cast.isUninterruptible = GetDefaultUninterruptibleState(cast, unitID)

        if not cast.isUninterruptible then
            -- Check for any temp cast BUFF immunities
            for i = 1, 40 do
                local _, _, _, _, _, _, _, _, _, id = UnitAura(unitID, i, "HELPFUL") -- FIXME: deprecated
                if not id then break end -- no more buffs

                if castImmunityBuffs[id] then
                    cast.isUninterruptible = true
                    break
                end
            end
        end
    end
end

function ClassicCastbars:UNIT_AURA(unitID)
    -- Auto position castbar around auras shown
    if unitID == "target" or unitID == "focus" then
        if self.db[unitID] and self.db[unitID].autoPosition then
            if activeFrames[unitID] then
                local parentFrame = self.AnchorManager:GetAnchor(unitID)
                if parentFrame then
                    self:SetTargetCastbarPosition(activeFrames[unitID], parentFrame)
                end
            end
        end
    end

    -- Check if cast is uninterruptible on buff faded or gained (i.e bubble)
    if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
        local castbar = self:GetCastbarFrameIfEnabled(unitID)
        if not castbar then return end

        local cast = castbar._data
        if not cast or cast.endTime == nil then return end

        -- Set initial bool state
        local prevValue = cast.isUninterruptible
        cast.isUninterruptible = GetDefaultUninterruptibleState(cast, unitID)
        if prevValue ~= cast.isUninterruptible then
            self:RefreshBorderShield(castbar, unitID)
        end

        if cast.isUninterruptible then return end -- no point checking further if its found above

        -- Check for any temp cast BUFF immunities
        -- FIXME: use updateInfo payload instead once all classic clients support it
        for i = 1, 40 do
            local _, _, _, _, _, _, _, _, _, spellID = UnitAura(unitID, i, "HELPFUL")
            if not spellID then break end -- no more buffs

            if castImmunityBuffs[spellID] then
                cast.isUninterruptible = true

                return self:RefreshBorderShield(castbar, unitID)
            end
        end
    end
end

function ClassicCastbars:UNIT_TARGET(unitID) -- detect when your target changes his target (for positioning around targetoftarget frame)
    if self.db[unitID] and self.db[unitID].autoPosition then
        if activeFrames[unitID] then
            local parentFrame = self.AnchorManager:GetAnchor(unitID)
            if parentFrame then
                self:SetTargetCastbarPosition(activeFrames[unitID], parentFrame)
            end
        end
    end
end

function ClassicCastbars:PLAYER_TARGET_CHANGED() -- when you change your own target
    activeGUIDs.target = UnitGUID("target") or nil

    -- Always hide first, then reshow after
    local castbar = activeFrames["target"]
    if castbar then
        self:HideCastbar(castbar, "target", true)
    end

    if UnitCastingInfo("target") then
        self:UNIT_SPELLCAST_START("target")
    elseif UnitChannelInfo("target") then
        self:UNIT_SPELLCAST_CHANNEL_START("target")
    end

    if UnitIsUnit("player", "target") and UnitChannelInfo("player") then -- HACK: UnitChannelInfo is bugged, tmp fallback method for when player is target
        self:UNIT_SPELLCAST_CHANNEL_START("target")
    end
end

function ClassicCastbars:PLAYER_FOCUS_CHANGED()
    activeGUIDs.focus = UnitGUID("target") or nil

    local castbar = activeFrames["focus"]
    if castbar then
        self:HideCastbar(castbar, "focus", true)
    end

    if UnitCastingInfo("focus") then
        self:UNIT_SPELLCAST_START("focus")
    elseif UnitChannelInfo("focus") then
        self:UNIT_SPELLCAST_CHANNEL_START("focus")
    end
end

local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
function ClassicCastbars:NAME_PLATE_UNIT_ADDED(namePlateUnitToken)
    if UnitIsUnit("player", namePlateUnitToken) then return end -- personal resource display nameplate

    activeGUIDs[namePlateUnitToken] = UnitGUID(namePlateUnitToken) or nil

    local plate = GetNamePlateForUnit(namePlateUnitToken)
    local plateCastbar = plate.UnitFrame.CastBar or plate.UnitFrame.castBar -- non-retail vs retail
    if plateCastbar then
        plateCastbar.showCastbar = not self.db.nameplate.enabled
        if self.db.nameplate.enabled then
            -- Hide blizzard's castbar
            plateCastbar:Hide()
        end
    end

    local castbar = activeFrames[namePlateUnitToken]
    if castbar then
        self:HideCastbar(castbar, namePlateUnitToken, true)
    end

    if UnitCastingInfo(namePlateUnitToken) then
        self:UNIT_SPELLCAST_START(namePlateUnitToken)
    elseif UnitChannelInfo(namePlateUnitToken) then
        self:UNIT_SPELLCAST_CHANNEL_START(namePlateUnitToken)
    end
end

function ClassicCastbars:NAME_PLATE_UNIT_REMOVED(namePlateUnitToken)
    if activeGUIDs[namePlateUnitToken] then
        activeGUIDs[namePlateUnitToken] = nil
    end

    local castbar = activeFrames[namePlateUnitToken]
    if castbar then
        PoolManager:ReleaseFrame(castbar)
        activeFrames[namePlateUnitToken] = nil
    end
end

function ClassicCastbars:UNIT_SPELLCAST_START(unitID)
    local castbar = self:GetCastbarFrameIfEnabled(unitID)
    if not castbar then return end

    self:BindCurrentCastData(castbar, unitID, false)
    self:DisplayCastbar(castbar, unitID)
end

function ClassicCastbars:UNIT_SPELLCAST_CHANNEL_START(unitID, _, spellID)
    local castbar = self:GetCastbarFrameIfEnabled(unitID)
    if not castbar then return end

    self:BindCurrentCastData(castbar, unitID, true, spellID)
    self:DisplayCastbar(castbar, unitID)
end

function ClassicCastbars:UNIT_SPELLCAST_STOP(unitID, castID)
    local castbar = activeFrames[unitID]
    if not castbar then return end

    if not castbar.isTesting then
        local cast = castbar._data
        if cast then
            if not cast.isChanneled and cast.castID ~= castID then return end -- required for player
            if not cast.isInterrupted then
                cast.isFailed = true
            end
        end
        self:HideCastbar(castbar, unitID)
    end

    castbar._data = nil
end

function ClassicCastbars:UNIT_SPELLCAST_INTERRUPTED(unitID, castID)
    local castbar = activeFrames[unitID]
    if not castbar then return end

    if not castbar.isTesting then
        local cast = castbar._data
        if cast then
            if not cast.isChanneled and cast.castID ~= castID then return end -- required for player
            cast.isInterrupted = true
            cast.isFailed = false
        end
        self:HideCastbar(castbar, unitID)
    end

    castbar._data = nil
end

function ClassicCastbars:UNIT_SPELLCAST_SUCCEEDED(unitID, castID)
    local castbar = activeFrames[unitID]
    if not castbar then return end

    if not castbar.isTesting then
        local cast = castbar._data
        if cast then
            if not cast.isChanneled and cast.castID ~= castID then return end
            cast.isCastComplete = true
            if cast.isChanneled then return end -- _SUCCEEDED triggered every tick for channeled, let OnUpdate handle it instead
        end
        self:HideCastbar(castbar, unitID)
    end

    castbar._data = nil
end

function ClassicCastbars:UNIT_SPELLCAST_DELAYED(unitID, castID)
    local castbar = self:GetCastbarFrameIfEnabled(unitID)
    if not castbar then return end

    local cast = castbar._data
    if cast then
        if not cast.isChanneled and cast.castID ~= castID then return end
    end

    self:BindCurrentCastData(castbar, unitID, false)
end

function ClassicCastbars:UNIT_SPELLCAST_CHANNEL_UPDATE(unitID, _, spellID)
    local castbar = self:GetCastbarFrameIfEnabled(unitID)
    if not castbar then return end

    self:BindCurrentCastData(castbar, unitID, true, spellID)
end

function ClassicCastbars:UNIT_SPELLCAST_FAILED(unitID, castID)
    local castbar = activeFrames[unitID]
    if not castbar then return end

    if not castbar.isTesting then
        local cast = castbar._data
        if cast then
            if not cast.isChanneled and cast.castID ~= castID then return end -- required for player
            if cast.isChanneled and castID ~= nil then return end
            if not castbar._data.isInterrupted then
                castbar._data.isFailed = true
            end
        end
        self:HideCastbar(castbar, unitID)
    end

    castbar._data = nil
end

function ClassicCastbars:UNIT_SPELLCAST_CHANNEL_STOP(unitID)
    local castbar = activeFrames[unitID]
    if not castbar then return end

    if not castbar.isTesting then
        self:HideCastbar(castbar, unitID)
    end

    castbar._data = nil
end

function ClassicCastbars:UNIT_SPELLCAST_INTERRUPTIBLE(unitID)
    local castbar = self:GetCastbarFrameIfEnabled(unitID)
    if not castbar then return end

    if castbar._data then
        castbar._data.isUninterruptible = true
        self:RefreshBorderShield(castbar, unitID)
    end
end

function ClassicCastbars:UNIT_SPELLCAST_NOT_INTERRUPTIBLE(unitID)
    local castbar = self:GetCastbarFrameIfEnabled(unitID)
    if not castbar then return end

    if castbar._data then
        castbar._data.isUninterruptible = false
        self:RefreshBorderShield(castbar, unitID)
    end
end

function ClassicCastbars:GROUP_ROSTER_UPDATE()
    for i = 1, 5 do
        local unitID = "party"..i
        local castbar = activeFrames[unitID]
        activeGUIDs[unitID] = UnitGUID(unitID) or nil

        if castbar then
            if UnitExists(unitID) then
                castbar:Hide()
                castbar:ClearAllPoints()
                castbar._data = nil
            else
                -- party member no longer exists, release castbar completely
                PoolManager:ReleaseFrame(castbar)
                activeFrames["party"..i] = nil
            end
        end

        -- Restart any active casts
        if UnitCastingInfo(unitID) then
            self:UNIT_SPELLCAST_START(unitID)
        elseif UnitChannelInfo(unitID) then
            self:UNIT_SPELLCAST_CHANNEL_START(unitID)
        end
    end
end

function ClassicCastbars:ToggleUnitEvents(shouldReset)
    self:RegisterUnitEvent("UNIT_TARGET", "target", "focus")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:RegisterEvent("PLAYER_FOCUS_CHANGED")
    self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    self:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    self:RegisterEvent("UNIT_AURA")

    if self.db.party.enabled then
        self:RegisterEvent("GROUP_ROSTER_UPDATE")
    else
        self:UnregisterEvent("GROUP_ROSTER_UPDATE")
    end

    for _, event in ipairs(castEvents) do
        if C_EventUtils.IsEventValid(event) then
            self:RegisterEvent(event)
        end
    end

    if shouldReset then
        self:PLAYER_ENTERING_WORLD() -- wipe all data
    end
end

function ClassicCastbars:PLAYER_ENTERING_WORLD(isInitialLogin)
    if isInitialLogin then return end

    -- Reset all data on loading screens
    wipe(activeFrames)
    wipe(activeGUIDs)
    PoolManager:GetFramePool():ReleaseAll() -- also removes castbar._data references

    if self.db.party.enabled then
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

function ClassicCastbars:PLAYER_LOGIN()
    ClassicCastbarsDB = ClassicCastbarsDB or {}

    -- Copy any settings from defaults if they don't exist in current profile
    if ClassicCastbarsCharDB and ClassicCastbarsCharDB.usePerCharacterSettings then
        self.db = CopyDefaults(namespace.defaultConfig, ClassicCastbarsCharDB)
    else
        self.db = CopyDefaults(namespace.defaultConfig, ClassicCastbarsDB)
    end

    if self.db.version then
        if tonumber(self.db.version) < 43 then
            if self.db.player.statusColorSuccess[2] == 0.7 then
                self.db.player.statusColorSuccess = { 0, 1, 0, 1 }
            end
        end
        self.db.npcCastTimeCache = nil
        self.db.npcCastUninterruptibleCache = nil
    end
    self.db.version = namespace.defaultConfig.version

    -- Reset locale dependent stuff on game locale switched
    if self.db.locale ~= GetLocale() then
        self.db.locale = GetLocale()
        self.db.target.castFont = _G.STANDARD_TEXT_FONT
        self.db.nameplate.castFont = _G.STANDARD_TEXT_FONT
        self.db.focus.castFont = _G.STANDARD_TEXT_FONT
        self.db.arena.castFont = _G.STANDARD_TEXT_FONT
        self.db.party.castFont = _G.STANDARD_TEXT_FONT
        self.db.player.castFont = _G.STANDARD_TEXT_FONT
    end

    if self.db.player.enabled then
        if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
            PlayerCastingBarFrame:SetLook("CLASSIC")
        end
        self:SkinPlayerCastbar()
    end

    self.PLAYER_GUID = UnitGUID("player")
    self:ToggleUnitEvents()
    self:DisableBlizzardCastbar()
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("ADDON_LOADED")

    self:UnregisterEvent("PLAYER_LOGIN")
    self.PLAYER_LOGIN = nil
end

local CombatLogGetCurrentEventInfo = _G.CombatLogGetCurrentEventInfo
function ClassicCastbars:COMBAT_LOG_EVENT_UNFILTERED()
    local _, eventType, _, _, _, _, _, dstGUID, _, _, _, _, _, _, _, _, extraSchool = CombatLogGetCurrentEventInfo()

    if eventType == "SPELL_INTERRUPT" then
        for unitID, castbar in next, activeFrames do
            if castbar:GetAlpha() > 0 then
                if UnitGUID(unitID) == dstGUID then
                    castbar.Text:SetText(string.format(LOSS_OF_CONTROL_DISPLAY_INTERRUPT_SCHOOL, GetSchoolString(extraSchool)))
                end
            end
        end
    end
end

local GetTime = _G.GetTime
ClassicCastbars:SetScript("OnUpdate", function(self)
    local currTime = GetTime() -- TODO: use elapsed calculations instead

    -- Update all shown castbars in a single OnUpdate call
    for unit, castbar in next, activeFrames do
        local cast = castbar._data
        if cast and cast.endTime ~= nil then
            local castTime = cast.endTime - currTime

            if (castTime >= 0) then
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
            else
                if castbar.fade and not castbar.fade:IsPlaying() and not castbar.isTesting then
                    cast.isCastComplete = true
                    self:HideCastbar(castbar, unit)
                    castbar._data = nil
                end
            end
        end
    end
end)
