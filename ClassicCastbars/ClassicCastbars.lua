local _, namespace = ...
local castImmunityBuffs = namespace.castImmunityBuffs
local channeledSpells = namespace.channeledSpells
local activeFrames = {}

local framePool = CreateFramePool("Statusbar", nil, "ClassicCastbarsFrameTemplate", namespace.FramePoolResetterFunc)
framePool:SetResetDisallowedIfNew(true)

local ClassicCastbars = CreateFrame("Frame", "ClassicCastbars")
ClassicCastbars:RegisterEvent("PLAYER_LOGIN")
ClassicCastbars:SetScript("OnEvent", function(self, event, ...)
    return self[event](self, ...)
end)

-- Variables used in ClassicCastbars_Options
ClassicCastbars.AnchorManager = namespace.AnchorManager
ClassicCastbars.defaultConfig = namespace.defaultConfig
ClassicCastbars.activeFrames = activeFrames

-- Upvalues frequently used
local CombatLogGetCurrentEventInfo = _G.CombatLogGetCurrentEventInfo
local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
local GetBuffDataByIndex = _G.C_UnitAuras and _G.C_UnitAuras.GetBuffDataByIndex
local strmatch = _G.string.match

local unitCastEvents = {
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
    "UNIT_SPELLCAST_EMPOWER_START",
    "UNIT_SPELLCAST_EMPOWER_STOP",
    "UNIT_SPELLCAST_EMPOWER_UPDATE",
}

function ClassicCastbars:GetUnitType(unitID)
    return unitID and strmatch(unitID, "^%a+") -- remove numbers and testmode suffix
end

function ClassicCastbars:AcquireCastbarFrame(unitID)
    if activeFrames[unitID] then
        return activeFrames[unitID]
    end

    activeFrames[unitID] = framePool:Acquire()

    return activeFrames[unitID]
end

function ClassicCastbars:AcquireCastbarFrameIfEnabled(unitID)
    local unitType = self:GetUnitType(unitID)
    local cfg = self.db[unitType]
    if cfg and cfg.enabled then
        if unitType == "nameplate" then
            local isFriendly = UnitIsFriend("player", unitID)
            if not self.db.nameplate.showForFriendly and isFriendly then return end
            if not self.db.nameplate.showForEnemy and not isFriendly then return end
            if UnitIsUnit("player", unitID) then return end -- personal resource display nameplate
        end

        return self:AcquireCastbarFrame(unitID)
    end
end

function ClassicCastbars:ReleaseActiveFrames()
    wipe(activeFrames)
    framePool:ReleaseAll()
end

function ClassicCastbars:ToggleBlizzCastEvents(spellbar, unitID)
    local cfg = self.db[self:GetUnitType(unitID)]
    if not cfg then return end

    if cfg.enabled then
        if spellbar.showCastbar and spellbar:IsEventRegistered("UNIT_SPELLCAST_START") then
            spellbar:Hide()
            for _, event in ipairs(unitCastEvents) do
                if C_EventUtils.IsEventValid(event) then -- event valid for current game expansion
                    self:UnregisterEvent(event)
                end
            end
        end
    else
        if spellbar.showCastbar and not spellbar:IsEventRegistered("UNIT_SPELLCAST_START") then
            for _, event in ipairs(unitCastEvents) do
                if C_EventUtils.IsEventValid(event) then
                    self:RegisterEvent(event)
                end
            end
        end
    end
end

function ClassicCastbars:ToggleBlizzCastbars()
    for _, spellBar in pairs({ TargetFrameSpellBar, FocusFrameSpellBar, PlayerCastingBarFrame, CastingBarFrame }) do
        self:ToggleBlizzCastEvents(spellBar, spellBar.unit)
    end

    for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
        local nameplateCastbar = nameplate.UnitFrame.CastBar or nameplate.UnitFrame.castBar -- non-retail vs retail
        if nameplateCastbar then
            self:ToggleBlizzCastEvents(nameplateCastbar, nameplate.namePlateUnitToken)
        end
    end

    for i = 1, 5 do
        local spellBar = _G["ArenaEnemyFrame"..i.."CastingBar"] or _G["ArenaEnemyMatchFrame"..i.."CastingBar"]
        if spellBar then
            self:ToggleBlizzCastEvents(spellBar, "arena"..i)
        end
    end
end

local uninterruptibleList = namespace.uninterruptibleList
local npcID_uninterruptibleList = namespace.npcID_uninterruptibleList

local function GetDefaultUninterruptibleState(castbar, unitID) -- needed pre-wrath only
    local isUninterruptible = uninterruptibleList[castbar.spellID] or uninterruptibleList[castbar.spellName] or false

    if not isUninterruptible and not UnitIsPlayer(unitID) then
        local _, _, _, _, _, npcID = strsplit("-", UnitGUID(unitID))
        if npcID then
            if npcID == "209678" then -- Twilight Lord Kelris is immune at 35% hp (phase2)
                if ((UnitHealth(unitID) / UnitHealthMax(unitID)) * 100) <= 35 then
                    isUninterruptible = true
                end
            else
                isUninterruptible = npcID_uninterruptibleList[npcID .. castbar.spellName] or false
            end
        end
    end

    return isUninterruptible
end

function ClassicCastbars:BindCurrentCastData(castbar, unitID, isChanneled, channelSpellID, isStartEvent)
    local spellName, castText, iconTexturePath, startTimeMS, endTimeMS, castID, notInterruptible, spellID, _

    if not isChanneled then
        spellName, castText, iconTexturePath, startTimeMS, endTimeMS, _, castID, notInterruptible, spellID = UnitCastingInfo(unitID)
    else
        if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and UnitIsUnit("player", unitID) then
            -- Temp fix for classic era bug https://github.com/wardz/ClassicCastbars/issues/82
            spellName, castText, iconTexturePath, startTimeMS, endTimeMS, _, notInterruptible, spellID = UnitChannelInfo("player")
        else
            spellName, castText, iconTexturePath, startTimeMS, endTimeMS, _, notInterruptible, spellID = UnitChannelInfo(unitID)
        end

        -- Temp fix for classic era bug https://github.com/wardz/ClassicCastbars/issues/82
        if channelSpellID and not spellName then
            spellName, _, iconTexturePath = GetSpellInfo(channelSpellID)
            local channelCastTime = spellName and channeledSpells[spellName]
            if not channelCastTime then return end

            castText = spellName
            spellID = channelSpellID
            endTimeMS = (GetTime() * 1000) + channelCastTime
            startTimeMS = GetTime() * 1000
        end
    end

    if not spellName then return end

    castbar.isActiveCast = true -- is currently casting/channeling, data is not stale
    castbar.unitType = self:GetUnitType(unitID)
    castbar.value = isChanneled and ((endTimeMS / 1000) - GetTime()) or (GetTime() - (startTimeMS / 1000))
    castbar.maxValue = (endTimeMS - startTimeMS) / 1000
    castbar.castID = castID
    castbar.spellName = spellName
    castbar.spellID = spellID
    castbar.iconTexturePath = (iconTexturePath == 136235 and 136243 or iconTexturePath)
    castbar.isChanneled = isChanneled
    castbar.castText = castText
    castbar.isFailed = nil
    castbar.isInterrupted = nil
    castbar.isCastComplete = nil

    if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
        castbar.isUninterruptible = notInterruptible
    else
        if isStartEvent then -- ensure that its only triggered once per cast
            castbar.isDefaultUninterruptible = GetDefaultUninterruptibleState(castbar, unitID) -- static
            castbar.isUninterruptible = castbar.isDefaultUninterruptible -- dynamic
        end
    end

    castbar:SetMinMaxValues(0, castbar.maxValue)
end

-- Check if cast is uninterruptible on buff faded or gained (needed pre-wrath)
function ClassicCastbars:CheckAuraModifiers(castbar, unitID)
    if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then return end
    if not castbar or not castbar.isActiveCast then return end

    if castbar.isDefaultUninterruptible then return end -- always immune, no point checking further

    local immunityFound = false
    for i = 1, 40 do
        local auraData = GetBuffDataByIndex(unitID, i, "HELPFUL")
        if not auraData then break end -- no more buffs

        if castImmunityBuffs[auraData.spellId] then
            immunityFound = true
            break
        end
    end

    if castbar.isUninterruptible ~= immunityFound then
        castbar.isUninterruptible = immunityFound
        castbar:RefreshBorderShield()
    end
end

function ClassicCastbars:UNIT_AURA(unitID)
    self:CheckAuraModifiers(activeFrames[unitID], unitID)

    -- Auto position castbar around auras shown
    if unitID == "target" or unitID == "focus" then
        self:UNIT_TARGET(unitID)
    end
end

function ClassicCastbars:UNIT_TARGET(unitID) -- when your target changes or clears his target (for positioning around targetoftarget frame)
    local castbar = activeFrames[unitID]
    if not castbar or not castbar.isActiveCast then return end

    if self.db[unitID] and self.db[unitID].autoPosition then
        local parentFrame = namespace.AnchorManager:GetAnchor(unitID)
        if parentFrame then
            castbar:SetTargetOrFocusCastbarPosition(parentFrame)
        end
    end
end

function ClassicCastbars:PLAYER_TARGET_CHANGED()
    local castbar = activeFrames["target"]
    if castbar then
        -- Always hide first, then reshow after
        castbar:HideCastbarNoFade()
    end

    if UnitCastingInfo("target") then
        self:UNIT_SPELLCAST_START("target")
    elseif UnitChannelInfo("target") then
        self:UNIT_SPELLCAST_CHANNEL_START("target")
    end

    -- https://github.com/wardz/ClassicCastbars/issues/82
    if UnitIsUnit("player", "target") and UnitChannelInfo("player") then
        self:UNIT_SPELLCAST_CHANNEL_START("target")
    end
end

function ClassicCastbars:PLAYER_FOCUS_CHANGED()
    local castbar = activeFrames["focus"]
    if castbar then
        castbar:HideCastbarNoFade()
    end

    if UnitCastingInfo("focus") then
        self:UNIT_SPELLCAST_START("focus")
    elseif UnitChannelInfo("focus") then
        self:UNIT_SPELLCAST_CHANNEL_START("focus")
    end
end

function ClassicCastbars:NAME_PLATE_UNIT_ADDED(namePlateUnitToken)
    if UnitIsUnit("player", namePlateUnitToken) then return end -- personal resource display nameplate

    local nameplate = GetNamePlateForUnit(namePlateUnitToken)
    local nameplateCastbar = nameplate.UnitFrame.CastBar or nameplate.UnitFrame.castBar -- non-retail vs retail
    if nameplateCastbar then
        -- This seems to cause random taint sadly
        -- nameplateCastbar.showCastbar = not self.db.nameplate.enabled
        self:ToggleBlizzCastEvents(nameplateCastbar, namePlateUnitToken)
    end

    local castbar = activeFrames[namePlateUnitToken]
    if castbar then
        castbar:HideCastbarNoFade()
    end

    if UnitCastingInfo(namePlateUnitToken) then
        self:UNIT_SPELLCAST_START(namePlateUnitToken)
    elseif UnitChannelInfo(namePlateUnitToken) then
        self:UNIT_SPELLCAST_CHANNEL_START(namePlateUnitToken)
    end
end

function ClassicCastbars:NAME_PLATE_UNIT_REMOVED(namePlateUnitToken)
    local castbar = activeFrames[namePlateUnitToken]
    if not castbar then return end

    framePool:Release(castbar)
    activeFrames[namePlateUnitToken] = nil
end

function ClassicCastbars:GROUP_ROSTER_UPDATE()
    if not self.db.party.enabled then return end

    for i = 1, 5 do
        local unitID = "party"..i
        local castbar = activeFrames[unitID]

        if castbar then
            if UnitExists(unitID) then
                castbar:HideCastbarNoFade()
            else
                -- party member no longer exists, release castbar completely
                framePool:Release(castbar)
                activeFrames[unitID] = nil
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

function ClassicCastbars:UNIT_SPELLCAST_START(unitID)
    local castbar = self:AcquireCastbarFrameIfEnabled(unitID)
    if not castbar then return end

    self:BindCurrentCastData(castbar, unitID, false, nil, true)
    self:CheckAuraModifiers(castbar, unitID)

    castbar:DisplayCastbar()
end

function ClassicCastbars:UNIT_SPELLCAST_CHANNEL_START(unitID, _, spellID)
    local castbar = self:AcquireCastbarFrameIfEnabled(unitID)
    if not castbar then return end

    self:BindCurrentCastData(castbar, unitID, true, spellID, true)
    self:CheckAuraModifiers(castbar, unitID)

    castbar:DisplayCastbar()
end
ClassicCastbars.UNIT_SPELLCAST_EMPOWER_START = ClassicCastbars.UNIT_SPELLCAST_CHANNEL_START

function ClassicCastbars:UNIT_SPELLCAST_STOP(unitID, castID)
    local castbar = activeFrames[unitID]
    if not castbar or not castbar.isActiveCast then return end
    if not castbar.isChanneled and castbar.castID ~= castID then return end

    if not castbar.isInterrupted then
        castbar.isFailed = true
    end
    castbar:HideCastbar()
end

function ClassicCastbars:UNIT_SPELLCAST_INTERRUPTED(unitID, castID)
    local castbar = activeFrames[unitID]
    if not castbar or not castbar.isActiveCast then return end
    if not castbar.isChanneled and castbar.castID ~= castID then return end

    castbar.isInterrupted = true
    castbar.isFailed = false
    castbar:HideCastbar()
end

function ClassicCastbars:UNIT_SPELLCAST_SUCCEEDED(unitID, castID)
    local castbar = activeFrames[unitID]
    if not castbar or not castbar.isActiveCast then return end
    if not castbar.isChanneled and castbar.castID ~= castID then return end

    castbar.isCastComplete = true
    if not castbar.isChanneled then -- This event is triggered every tick for channeled, let OnUpdate handle stop instead
        castbar:HideCastbar()
    end
end

function ClassicCastbars:UNIT_SPELLCAST_DELAYED(unitID, castID)
    local castbar = activeFrames[unitID]
    if not castbar or not castbar.isActiveCast then return end
    if not castbar.isChanneled and castbar.castID ~= castID then return end

    self:BindCurrentCastData(castbar, unitID, false)
end

function ClassicCastbars:UNIT_SPELLCAST_CHANNEL_UPDATE(unitID, _, spellID)
    local castbar = activeFrames[unitID]
    if not castbar or not castbar.isActiveCast then return end

    self:BindCurrentCastData(castbar, unitID, true, spellID)
end
ClassicCastbars.UNIT_SPELLCAST_EMPOWER_UPDATE = ClassicCastbars.UNIT_SPELLCAST_CHANNEL_UPDATE

function ClassicCastbars:UNIT_SPELLCAST_FAILED(unitID, castID)
    local castbar = activeFrames[unitID]
    if not castbar or not castbar.isActiveCast then return end

    if not castbar.isChanneled and castbar.castID ~= castID then return end
    if castbar.isChanneled and castID ~= nil then return end

    if not castbar.isInterrupted then
        castbar.isFailed = true
    end
    castbar:HideCastbar()
end

function ClassicCastbars:UNIT_SPELLCAST_CHANNEL_STOP(unitID)
    local castbar = activeFrames[unitID]
    if not castbar or not castbar.isActiveCast then return end

    castbar.isCastComplete = true
    castbar:HideCastbar()
end
ClassicCastbars.UNIT_SPELLCAST_EMPOWER_STOP = ClassicCastbars.UNIT_SPELLCAST_CHANNEL_STOP

function ClassicCastbars:UNIT_SPELLCAST_INTERRUPTIBLE(unitID)
    local castbar = activeFrames[unitID]
    if not castbar or not castbar.isActiveCast then return end

    castbar.isUninterruptible = true
    castbar:RefreshBorderShield(unitID)
end

function ClassicCastbars:UNIT_SPELLCAST_NOT_INTERRUPTIBLE(unitID)
    local castbar = activeFrames[unitID]
    if not castbar or not castbar.isActiveCast then return end

    castbar.isUninterruptible = false
    castbar:RefreshBorderShield(unitID)
end

function ClassicCastbars:COMBAT_LOG_EVENT_UNFILTERED()
    local _, eventType, _, _, _, _, _, dstGUID, _, _, _, _, _, _, _, _, extraSchool = CombatLogGetCurrentEventInfo()

    if eventType == "SPELL_INTERRUPT" then
        for unitID, castbar in pairs(activeFrames) do
            if castbar:GetAlpha() > 0 then
                if UnitGUID(unitID) == dstGUID then
                    castbar.Text:SetText(string.format(LOSS_OF_CONTROL_DISPLAY_INTERRUPT_SCHOOL, GetSchoolString(extraSchool)))
                end
            end
        end
    end
end

function ClassicCastbars:PLAYER_ENTERING_WORLD(isInitialLogin)
    self:ToggleBlizzCastbars() -- Always run here incase arena frames are finally loaded

    if not isInitialLogin then
        self:ReleaseActiveFrames()
    end

    if self.db.party.enabled then
        self:GROUP_ROSTER_UPDATE()
    end

    if self.db.player.enabled then
        if UnitCastingInfo("player") then
            self:UNIT_SPELLCAST_START("player")
        elseif UnitChannelInfo("player") then
            self:UNIT_SPELLCAST_CHANNEL_START("player")
        end
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

    -- Fix conflicts with older data on addon update
    if self.db.version then
        if tonumber(self.db.version) < 45 then
            if self.db.party.castBorder == "Interface\\CastingBar\\UI-CastingBar-Border" then
                self.db.party.castBorder = "Interface\\CastingBar\\UI-CastingBar-Border-Small"
            end
            self.db.player = CopyTable(namespace.defaultConfig.player) -- TODO: better solution
            self.db.npcCastTimeCache = nil
            self.db.npcCastUninterruptibleCache = nil
        end
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

    -- Register all events we care about
    self:RegisterUnitEvent("UNIT_TARGET", "target", "focus")
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:RegisterEvent("PLAYER_FOCUS_CHANGED")
    self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    self:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("UNIT_AURA")

    for _, event in ipairs(unitCastEvents) do
        if C_EventUtils.IsEventValid(event) then
            self:RegisterEvent(event)
        end
    end
end
