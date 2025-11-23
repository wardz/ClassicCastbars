local _, namespace = ...
local activeFrames = {}

local ClassicCastbars = CreateFrame("Frame", "ClassicCastbars")
ClassicCastbars:RegisterEvent("PLAYER_LOGIN")
ClassicCastbars:SetScript("OnEvent", function(self, event, ...)
    return self[event](self, ...)
end)
ClassicCastbars.AnchorManager = namespace.AnchorManager
ClassicCastbars.defaultConfig = namespace.defaultConfig
ClassicCastbars.activeFrames = activeFrames

local isClassicEra = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local isTBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC

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
    "UNIT_SPELLCAST_EMPOWER_START",
    "UNIT_SPELLCAST_EMPOWER_STOP",
    "UNIT_SPELLCAST_EMPOWER_UPDATE",
}

-- Upvalues
local PoolManager = namespace.PoolManager
local castImmunityBuffs = namespace.castImmunityBuffs
local channeledSpells = namespace.channeledSpells
local uninterruptibleList = namespace.uninterruptibleList
local npcID_uninterruptibleList = namespace.npcID_uninterruptibleList
local pushbackBlacklist = namespace.pushbackBlacklist
local GetBuffDataByIndex = _G.C_UnitAuras.GetBuffDataByIndex
local FindAuraByName = AuraUtil.FindAuraByName
local strmatch = _G.string.match
local strfind = _G.string.find
local UnitGUID = _G.UnitGUID
local UnitIsUnit = _G.UnitIsUnit
local max = _G.math.max
local next = _G.next

-- Note: don't add any major code reworks here, this codebase will soon be replaced with the player-castbar-v2 branch

function ClassicCastbars:GetUnitType(unitID)
    return unitID and strmatch(unitID, "^%a+") -- remove numbers and testmode suffix
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
            if not self.db.nameplate.showForPets and UnitIsOtherPlayersPet(unitID) then return end
        end

        return self:GetCastbarFrame(unitID)
    end
end

local function HideBlizzardSpellbar(spellbar)
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

local function GetDefaultUninterruptibleState(castbar, unitID) -- needed pre-wrath only
    local isUninterruptible = uninterruptibleList[castbar.spellID] or uninterruptibleList[castbar.spellName] or false

    if not isUninterruptible and not UnitIsPlayer(unitID) then
        local _, _, _, _, _, npcID = strsplit("-", UnitGUID(unitID))
        if npcID then
            isUninterruptible = npcID_uninterruptibleList[npcID .. castbar.spellName] or false
        end
    end

    return isUninterruptible
end

function ClassicCastbars:BindCurrentCastData(castbar, unitID, isChanneled, channelSpellID, isStartEvent)
    local casterUnit = (isClassicEra and UnitIsUnit("player", unitID)) and "player" or unitID
    local spellName, iconTexturePath, startTimeMS, endTimeMS, castID, notInterruptible, spellID, _

    if not isChanneled then
        spellName, _, iconTexturePath, startTimeMS, endTimeMS, _, castID, notInterruptible, spellID = UnitCastingInfo(casterUnit)
    else
        spellName, _, iconTexturePath, startTimeMS, endTimeMS, _, notInterruptible, spellID = UnitChannelInfo(casterUnit)

        -- UnitChannelInfo() doesn't return anything in Classic Era for others, so we get cast time using pre-stored data instead
        if isClassicEra and channelSpellID and not spellName then
            local info = C_Spell.GetSpellInfo(channelSpellID)
            if info then
                local castTime = channeledSpells[info.name]
                if castTime then
                    spellName = info.name
                    iconTexturePath = info.iconID
                    spellID = channelSpellID

                    endTimeMS = (GetTime() * 1000) + castTime
                    startTimeMS = GetTime() * 1000
                end
            end
        end
    end

    if not spellName then
        return
    end

    castbar.isActiveCast = true
    castbar.value = isChanneled and ((endTimeMS / 1000) - GetTime()) or (GetTime() - (startTimeMS / 1000))
    castbar.maxValue = (endTimeMS - startTimeMS) / 1000
    castbar.castID = castID
    castbar.spellName = spellName
    castbar.spellID = spellID
    castbar.icon = iconTexturePath
    castbar.isChanneled = isChanneled
    castbar.isFailed = nil
    castbar.isInterrupted = nil
    castbar.isCastComplete = nil
    castbar.pushbackValue = nil

    if isClassicEra or isTBC then
        if isStartEvent then -- ensure that its only triggered once per cast
            castbar.isDefaultUninterruptible = GetDefaultUninterruptibleState(castbar, unitID)
            castbar.isUninterruptible = castbar.isDefaultUninterruptible
        end
    else
        castbar.isUninterruptible = notInterruptible
    end

    castbar:SetMinMaxValues(0, castbar.maxValue)
    castbar:SetValue(castbar.value)
end

-- Check if cast is uninterruptible on buff faded or gained (needed pre-wrath)
function ClassicCastbars:CheckAuraModifiers(castbar, unitID)
    if not isClassicEra and not isTBC then return end
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
    self:RefreshBorderShield(castbar, unitID)
end

local BARKSKIN = C_Spell.GetSpellName(22812)
local FOCUSED_CASTING = C_Spell.GetSpellName(14743)
function ClassicCastbars:CastPushback(unitID, castbar)
    if not castbar or not castbar.isActiveCast or not unitID then return end
    if pushbackBlacklist[castbar.spellName] then return end

    if UnitIsUnit(unitID, "player") then return end
    if FindAuraByName(BARKSKIN, unitID, "HELPFUL") or FindAuraByName(FOCUSED_CASTING , unitID, "HELPFUL") then return end

    -- Calculate cast pushbacks for Classic Era
    if not castbar.isChanneled then
        -- https://wow.gamepedia.com/index.php?title=Interrupt&oldid=305918
        castbar.pushbackValue = castbar.pushbackValue or 1.0
        castbar.value = max(castbar.value - castbar.pushbackValue, 0)
        castbar.pushbackValue = max(castbar.pushbackValue - 0.5, 0.2)
    else
        -- channels are reduced by 25% per hit
        castbar.value = max(castbar.value - (castbar.maxValue * 25) / 100, 0)
    end
end

function ClassicCastbars:UNIT_AURA(unitID)
    self:CheckAuraModifiers(activeFrames[unitID], unitID)

    -- Auto position castbar around auras shown
    if unitID == "target" or unitID == "focus" then
        self:UNIT_TARGET(unitID)
    end
end

function ClassicCastbars:UNIT_TARGET(unitID) -- detect when your target changes his target (for positioning around targetoftarget frame)
    if activeFrames[unitID] and self.db[unitID] and self.db[unitID].autoPosition then
        local parentFrame = self.AnchorManager:GetAnchor(unitID)
        if parentFrame then
            self:SetTargetCastbarPosition(activeFrames[unitID], parentFrame)
        end
    end
end

function ClassicCastbars:PLAYER_TARGET_CHANGED()
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

    if isClassicEra and UnitIsUnit("player", "target") and UnitChannelInfo("player") then
        self:UNIT_SPELLCAST_CHANNEL_START("target")
    end
end

function ClassicCastbars:PLAYER_FOCUS_CHANGED()
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

local function BlizzNameplateCastbar_OnShow(frame)
    if frame:IsProtected() or frame:IsForbidden() then return end
    if not frame.unit or not strfind(frame.unit, "nameplate") then return end

    if ClassicCastbars.db.nameplate.enabled then
        frame:Hide()
    end
end

local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
function ClassicCastbars:NAME_PLATE_UNIT_ADDED(namePlateUnitToken)
    if UnitIsUnit("player", namePlateUnitToken) then return end -- personal resource display nameplate

    local plate = GetNamePlateForUnit(namePlateUnitToken)
    local plateCastbar = plate.UnitFrame.CastBar or plate.UnitFrame.castBar -- non-retail vs retail
    if plateCastbar then
        -- This causes taint sadly;
        -- plateCastbar.showCastbar = not self.db.nameplate.enabled

        -- Hide Blizz castbar
        if not plateCastbar.ClassicCastbarsHooked then
            plateCastbar.ClassicCastbarsHooked = true
            plateCastbar:HookScript("OnShow", BlizzNameplateCastbar_OnShow)
        end
        if ClassicCastbars.db.nameplate.enabled then
            -- hide immediately incase its already shown
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
    local castbar = activeFrames[namePlateUnitToken]
    if castbar then
        PoolManager:ReleaseFrame(castbar)
        activeFrames[namePlateUnitToken] = nil
    end
end

function ClassicCastbars:UNIT_SPELLCAST_START(unitID)
    local castbar = self:GetCastbarFrameIfEnabled(unitID)
    if not castbar then return end

    self:BindCurrentCastData(castbar, unitID, false, nil, true)
    self:CheckAuraModifiers(castbar, unitID)
    self:DisplayCastbar(castbar, unitID)
end

function ClassicCastbars:UNIT_SPELLCAST_CHANNEL_START(unitID, _, spellID)
    local castbar = self:GetCastbarFrameIfEnabled(unitID)
    if not castbar then return end

    self:BindCurrentCastData(castbar, unitID, true, spellID, true)
    self:CheckAuraModifiers(castbar, unitID)
    self:DisplayCastbar(castbar, unitID)
end
ClassicCastbars.UNIT_SPELLCAST_EMPOWER_START = ClassicCastbars.UNIT_SPELLCAST_CHANNEL_START

function ClassicCastbars:UNIT_SPELLCAST_STOP(unitID, castID)
    local castbar = activeFrames[unitID]
    if not castbar or not castbar.isActiveCast then return end
    if not castbar.isChanneled and castbar.castID ~= castID then return end -- required for player

    if not castbar.isInterrupted then
        castbar.isFailed = true
    end
    self:HideCastbar(castbar, unitID)
end

function ClassicCastbars:UNIT_SPELLCAST_INTERRUPTED(unitID, castID)
    local castbar = activeFrames[unitID]
    if not castbar or not castbar.isActiveCast then return end
    if not castbar.isChanneled and castbar.castID ~= castID then return end -- required for player

    castbar.isInterrupted = true
    castbar.isFailed = false
    self:HideCastbar(castbar, unitID)
end

function ClassicCastbars:UNIT_SPELLCAST_SUCCEEDED(unitID, castID)
    local castbar = activeFrames[unitID]
    if not castbar or not castbar.isActiveCast then return end
    if not castbar.isChanneled and castbar.castID ~= castID then return end

    castbar.isCastComplete = true
    if not castbar.isChanneled then -- _SUCCEEDED triggered every tick for channeled, let OnUpdate handle it instead
        self:HideCastbar(castbar, unitID)
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
    self:HideCastbar(castbar, unitID)
end

function ClassicCastbars:UNIT_SPELLCAST_CHANNEL_STOP(unitID)
    local castbar = activeFrames[unitID]
    if not castbar or not castbar.isActiveCast then return end

    castbar.isCastComplete = true
    self:HideCastbar(castbar, unitID)
end
ClassicCastbars.UNIT_SPELLCAST_EMPOWER_STOP = ClassicCastbars.UNIT_SPELLCAST_CHANNEL_STOP

function ClassicCastbars:UNIT_SPELLCAST_INTERRUPTIBLE(unitID)
    local castbar = activeFrames[unitID]
    if not castbar or not castbar.isActiveCast then return end

    castbar.isUninterruptible = true
    self:RefreshBorderShield(castbar, unitID)
end

function ClassicCastbars:UNIT_SPELLCAST_NOT_INTERRUPTIBLE(unitID)
    local castbar = activeFrames[unitID]
    if not castbar or not castbar.isActiveCast then return end

    castbar.isUninterruptible = false
    self:RefreshBorderShield(castbar, unitID)
end

function ClassicCastbars:GROUP_ROSTER_UPDATE()
    for i = 1, 5 do
        local unitID = "party"..i
        local castbar = activeFrames[unitID]

        if castbar then
            if UnitExists(unitID) then
                self:HideCastbar(castbar, unitID, true)
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
    PoolManager:GetFramePool():ReleaseAll()

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

    -- Remove old obsolete configs
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

        for _, unitType in pairs({ "player", "target", "focus", "party", "arena", "nameplate" }) do
            self.db[unitType].castFont = _G.STANDARD_TEXT_FONT
        end
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
local COMBATLOG_OBJECT_TYPE_PLAYER = _G.COMBATLOG_OBJECT_TYPE_PLAYER
local bit_band = _G.bit.band
function ClassicCastbars:COMBAT_LOG_EVENT_UNFILTERED()
    local _, eventType, _, _, _, _, _, dstGUID, _, dstFlags, _, _, _, _, _, _, extraSchool = CombatLogGetCurrentEventInfo()

    if eventType == "SPELL_INTERRUPT" then
        for unitID, castbar in next, activeFrames do
            if castbar:GetAlpha() > 0 then
                if UnitGUID(unitID) == dstGUID then
                    castbar.Text:SetText(string.format(LOSS_OF_CONTROL_DISPLAY_INTERRUPT_SCHOOL, GetSchoolString(extraSchool)))
                end
            end
        end
    elseif eventType == "SWING_DAMAGE" or eventType == "ENVIRONMENTAL_DAMAGE" or eventType == "RANGE_DAMAGE" or eventType == "SPELL_DAMAGE" then
        if isClassicEra and bit_band(dstFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0 then -- is player, and not pet
            for unitID, castbar in next, activeFrames do -- cba reworking this to work with GUID mappings so this'll have to do for now
                if castbar:GetAlpha() > 0 then
                    if UnitGUID(unitID) == dstGUID then
                        self:CastPushback(unitID, castbar)
                    end
                end
            end
        end
    end
end

ClassicCastbars:SetScript("OnUpdate", function(self, elapsed)
    for unit, castbar in next, activeFrames do
        if castbar.isActiveCast and castbar.value ~= nil and not castbar.isTesting then
            if castbar.isChanneled then
                castbar.value = castbar.value - elapsed
            else
                castbar.value = castbar.value + elapsed
            end

            castbar:SetValue(castbar.value)
            castbar.Timer:SetFormattedText("%.1f", castbar.isChanneled and castbar.value or not castbar.isChanneled and castbar.maxValue - castbar.value)

            local sparkPosition = (castbar.value / castbar.maxValue) * (castbar.currWidth or castbar:GetWidth())
            castbar.Spark:SetPoint("CENTER", castbar, "LEFT", sparkPosition, castbar.BorderShield:IsShown() and 3 or 0)

            -- Check if cast is complete
            if (castbar.isChanneled and castbar.value <= 0) or (not castbar.isChanneled and castbar.value >= castbar.maxValue) then
                if not castbar.fade or not castbar.fade:IsPlaying() then
                    castbar.isCastComplete = true
                    self:HideCastbar(castbar, unit)
                end
            end
        end
    end
end)
