local _, namespace = ...
local castImmunityBuffs = namespace.castImmunityBuffs
local channeledSpells = namespace.channeledSpells
local npcID_uninterruptibleList = namespace.npcID_uninterruptibleList
local uninterruptibleList = namespace.uninterruptibleList

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

-- Upvalues
local CombatLogGetCurrentEventInfo = _G.CombatLogGetCurrentEventInfo
local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
local GetBuffDataByIndex = _G.C_UnitAuras and _G.C_UnitAuras.GetBuffDataByIndex
local next = _G.next
local gsub = _G.string.gsub

function ClassicCastbars:GetUnitType(unitID)
    return gsub(gsub(unitID or "", "%d", ""), "-testmode", "") -- remove numbers and suffix
end

function ClassicCastbars:GetCastbarFrame(unitID)
    if activeFrames[unitID] then
        return activeFrames[unitID]
    end

    activeFrames[unitID] = framePool:Acquire()

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

        return self:GetCastbarFrame(unitID)
    end
end

function ClassicCastbars:ReleaseActiveFrames()
    wipe(activeFrames)
    framePool:ReleaseAll()
end

local function ToggleBlizzardSpellbar(spellbar)
    local cfg = ClassicCastbars.db[ClassicCastbars:GetUnitType(spellbar.unit)]
    if cfg and cfg.enabled then
        --spellbar.showCastbar = false
        spellbar.casting = nil
        spellbar.channeling = nil
        spellbar.reverseChanneling = nil
        spellbar:Hide()
    end
end

function ClassicCastbars:HookBlizzardCastbars()
    if not self.isSpellbarsHooked then
        self.isSpellbarsHooked = true

        for _, spellBar in pairs({ TargetFrameSpellBar, FocusFrameSpellBar, PlayerCastingBarFrame, CastingBarFrame }) do
            spellBar:HookScript("OnShow", ToggleBlizzardSpellbar)
        end
    end

    -- Arena frames are load on demand, hook if available
    if not self.isArenaSpellbarsHooked then
        for i = 1, 5 do
            local frame = _G["ArenaEnemyFrame"..i.."CastingBar"] or _G["ArenaEnemyMatchFrame"..i.."CastingBar"]
            if frame then
                frame:HookScript("OnShow", ToggleBlizzardSpellbar)
                self.isArenaSpellbarsHooked = true
            end
        end
    end
end

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

    castbar.isUninterruptible = immunityFound
    castbar:RefreshBorderShield(unitID)
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
        nameplateCastbar.showCastbar = not self.db.nameplate.enabled
        nameplateCastbar:SetShown(nameplateCastbar.showCastbar)
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
    local castbar = self:GetCastbarFrameIfEnabled(unitID)
    if not castbar then return end

    self:BindCurrentCastData(castbar, unitID, false, nil, true)
    self:CheckAuraModifiers(castbar, unitID)
    castbar:DisplayCastbar(unitID)
end

function ClassicCastbars:UNIT_SPELLCAST_CHANNEL_START(unitID, _, spellID)
    local castbar = self:GetCastbarFrameIfEnabled(unitID)
    if not castbar then return end

    self:BindCurrentCastData(castbar, unitID, true, spellID, true)
    self:CheckAuraModifiers(castbar, unitID)
    castbar:DisplayCastbar(unitID)
end
ClassicCastbars.UNIT_SPELLCAST_EMPOWER_START = ClassicCastbars.UNIT_SPELLCAST_CHANNEL_START

function ClassicCastbars:UNIT_SPELLCAST_STOP(unitID, castID)
    local castbar = activeFrames[unitID]
    if not castbar or not castbar.isActiveCast then return end
    if not castbar.isChanneled and castbar.castID ~= castID then return end

    if not castbar.isInterrupted then
        castbar.isFailed = true
    end
    castbar:HideCastbar(unitID)
end

function ClassicCastbars:UNIT_SPELLCAST_INTERRUPTED(unitID, castID)
    local castbar = activeFrames[unitID]
    if not castbar or not castbar.isActiveCast then return end
    if not castbar.isChanneled and castbar.castID ~= castID then return end

    castbar.isInterrupted = true
    castbar.isFailed = false
    castbar:HideCastbar(unitID)
end

function ClassicCastbars:UNIT_SPELLCAST_SUCCEEDED(unitID, castID)
    local castbar = activeFrames[unitID]
    if not castbar or not castbar.isActiveCast then return end
    if not castbar.isChanneled and castbar.castID ~= castID then return end

    castbar.isCastComplete = true
    if not castbar.isChanneled then -- This event is triggered every tick for channeled, let OnUpdate handle stop instead
        castbar:HideCastbar(unitID)
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
    castbar:HideCastbar(unitID)
end

function ClassicCastbars:UNIT_SPELLCAST_CHANNEL_STOP(unitID)
    local castbar = activeFrames[unitID]
    if not castbar or not castbar.isActiveCast then return end

    castbar.isCastComplete = true
    castbar:HideCastbar(unitID)
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

function ClassicCastbars:PLAYER_ENTERING_WORLD(isInitialLogin)
    self:HookBlizzardCastbars() -- Always run here incase arena frames are finally loaded

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
            self.db.player = CopyTable(namespace.defaultConfig.player)
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

    local events = {
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
        "COMBAT_LOG_EVENT_UNFILTERED",
        "PLAYER_ENTERING_WORLD",
        "PLAYER_TARGET_CHANGED",
        "PLAYER_FOCUS_CHANGED",
        "NAME_PLATE_UNIT_ADDED",
        "NAME_PLATE_UNIT_REMOVED",
        "GROUP_ROSTER_UPDATE",
        "UNIT_AURA",
    }

    -- Register all events we care about
    self:RegisterUnitEvent("UNIT_TARGET", "target", "focus")
    for _, event in ipairs(events) do
        if C_EventUtils.IsEventValid(event) then
            self:RegisterEvent(event)
        end
    end
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

ClassicCastbars:SetScript("OnUpdate", function(self, elapsed)
    for unitID, castbar in next, activeFrames do
        if castbar.isActiveCast and castbar.value ~= nil and not castbar.isTesting then
            if castbar.isChanneled then
                castbar.value = castbar.value - elapsed
            else
                castbar.value = castbar.value + elapsed
            end

            if castbar.timerTextFormat then
                if castbar.isChanneled then
                    castbar.Timer:SetFormattedText(castbar.timerTextFormat, castbar.value, castbar.maxValue)
                else
                    castbar.Timer:SetFormattedText(castbar.timerTextFormat, castbar.maxValue - castbar.value, castbar.maxValue)
                end
            end

            local sparkPosition = (castbar.value / castbar.maxValue) * castbar:GetWidth()
            castbar.Spark:SetPoint("CENTER", castbar, "LEFT", sparkPosition, 0)
            castbar:SetValue(castbar.value)

            -- Check if cast has expired
            if (castbar.isChanneled and castbar.value <= 0) or (not castbar.isChanneled and castbar.value >= castbar.maxValue) then
                if not castbar.FadeOutAnim:IsPlaying() then
                    castbar.isCastComplete = true
                    castbar:HideCastbar(unitID)
                end
            end
        end
    end
end)
