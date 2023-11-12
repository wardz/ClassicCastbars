if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then return end
if select(7, GetBuildInfo()) >= 11500 then return end -- Patch 1.15.0 now has built in castbars

local _, namespace = ...
local PoolManager = namespace.PoolManager

local activeGUIDs = {} -- unitID to unitGUID mappings
local activeTimers = {} -- unitGUID to cast data mappings
local activeFrames = {} -- unitID to cached castbar frame mappings
local npcCastTimeCacheStart = {}

local addon = CreateFrame("Frame", "ClassicCastbars")
addon:RegisterEvent("PLAYER_LOGIN")
addon:SetScript("OnEvent", function(self, event, ...)
    return self[event](self, ...)
end)
addon.AnchorManager = namespace.AnchorManager
addon.defaultConfig = namespace.defaultConfig
addon.activeFrames = activeFrames
addon.activeTimers = activeTimers

-- upvalues for speed
local strsplit = _G.string.split
local gsub = _G.string.gsub
local pairs = _G.pairs
local UnitGUID = _G.UnitGUID
local UnitAura = _G.UnitAura
local GetSpellTexture = _G.GetSpellTexture
local GetSpellInfo = _G.GetSpellInfo
local GetTime = _G.GetTime
local max = _G.math.max
local abs = _G.math.abs
local next = _G.next
local floor = _G.math.floor
local GetUnitSpeed = _G.GetUnitSpeed
local IsFalling = _G.IsFalling
local UnitIsFriend = _G.UnitIsFriend
local CastingInfo = _G.CastingInfo
local ChannelInfo = _G.ChannelInfo
local castTimeIncreases = namespace.castTimeIncreases
local pushbackBlacklist = namespace.pushbackBlacklist
local unaffectedCastModsSpells = namespace.unaffectedCastModsSpells
local uninterruptibleList = namespace.uninterruptibleList
local castModifiers = namespace.castModifiers
local castImmunityBuffs = namespace.castImmunityBuffs
local playerIsPhysical = namespace.physicalClasses[select(2, UnitClass("player"))]

local BARKSKIN = GetSpellInfo(22812)
local FOCUSED_CASTING = GetSpellInfo(14743)

function addon:GetUnitType(unitID)
    local unit = gsub(unitID or "", "%d", "") -- remove numbers
    if unit == "nameplate-testmode" then
        unit = "nameplate"
    elseif unit == "party-testmode" then
        unit = "party"
    end

    return unit
end

function addon:CheckCastModifiers(unitID, cast)
    if not cast then return end
    if unitID == "focus" then return end

    local shouldCheckHasteModifiers = not unaffectedCastModsSpells[cast.spellID] and cast.unitGUID ~= self.PLAYER_GUID

    -- Debuffs
    if shouldCheckHasteModifiers and not cast.isChanneled and not cast.hasCastSlowModified then
        for i = 1, 40 do -- 16 in classic era but 40 in season of mastery
            local _, _, _, _, _, _, _, _, _, spellID = UnitAura(unitID, i, "HARMFUL")
            if not spellID then break end -- no more debuffs

            local slow = castTimeIncreases[spellID]
            if slow then -- note: multiple slows stack
                local continue = true
                if cast.spellID == 20904 then -- hack for Aimed Shot
                    if spellID ~= 89 and spellID ~= 19365 and spellID ~= 17331 then
                        -- dont continue if the modifier doesnt modify RANGED attacks
                        continue = false
                    end
                end

                if continue then
                    cast.endTime = cast.timeStart + (cast.endTime - cast.timeStart) * ((slow / 100) + 1)
                    cast.hasCastSlowModified = true
                end
            end
        end
    end

    -- Buffs
    local libCD = LibStub and LibStub("LibClassicDurations", true) -- For enemy buffs if available
    local GetUnitAura = libCD and libCD.UnitAuraDirect or UnitAura
    for i = 1, 40 do
        local name = GetUnitAura(unitID, i, "HELPFUL")
        if not name then break end -- no more buffs

        if shouldCheckHasteModifiers then
            local modifier = castModifiers[name]
            if modifier and not cast.activeModifiers[name] then
                local continue = true
                if modifier.condition then
                    continue = modifier.condition(cast)
                end

                if continue then
                    cast.activeModifiers[name] = true

                    if modifier.percentage then
                        cast.endTime = cast.endTime - ((cast.endTime - cast.timeStart) * modifier.value / 100)
                    else
                        cast.endTime = cast.endTime + modifier.value
                    end
                end
            end
        end

        -- Special cases
        if name == FOCUSED_CASTING or name == BARKSKIN then
            cast.hasPushbackImmuneModifier = true
        elseif castImmunityBuffs[name] and not cast.isUninterruptible then
            cast.origIsUninterruptibleValue = cast.isUninterruptible
            cast.isUninterruptible = true
        elseif cast.origIsUninterruptibleValue then
            cast.isUninterruptible = cast.origIsUninterruptibleValue
            cast.origIsUninterruptibleValue = nil
        end
    end
end

function addon:StartCast(unitGUID, unitID)
    if not unitGUID then return end

    local cast = activeTimers[unitGUID]
    if not cast then return end

    if cast.endTime - GetTime() <= 0 then return end -- expired

    local castbar = self:GetCastbarFrame(unitID)
    if not castbar then return end

    castbar._data = cast -- set ref to current cast data
    self:CheckCastModifiers(unitID, cast)
    self:DisplayCastbar(castbar, unitID)
end

function addon:StopCast(unitID, noFadeOut)
    local castbar = activeFrames[unitID]
    if not castbar then return end

    if not castbar.isTesting then
        self:HideCastbar(castbar, unitID, noFadeOut)
    end

    castbar._data = nil
end

function addon:StartAllCasts(unitGUID)
    if not activeTimers[unitGUID] then return end

    for unitID, guid in pairs(activeGUIDs) do
        if guid == unitGUID then
            self:StartCast(guid, unitID)
        end
    end
end

function addon:StopAllCasts(unitGUID, noFadeOut)
    for unitID, guid in pairs(activeGUIDs) do
        if guid == unitGUID then
            self:StopCast(unitID, noFadeOut)
        end
    end
end

-- Store or refresh new cast data for unit, and start castbar(s)
function addon:StoreCast(unitGUID, spellName, spellID, iconTexturePath, castTime, isPlayer, isChanneled)
    local currTime = GetTime()

    if not activeTimers[unitGUID] then
        activeTimers[unitGUID] = {}
    end

    local cast = activeTimers[unitGUID]
    cast.maxValue = castTime / 1000
    cast.endTime = currTime + (castTime / 1000)
    cast.spellName = spellName
    cast.spellID = spellID
    cast.icon = iconTexturePath
    cast.isChanneled = isChanneled
    cast.unitGUID = unitGUID
    cast.timeStart = currTime
    cast.isPlayer = isPlayer

    cast.isUninterruptible = uninterruptibleList[spellName]
    if not cast.isUninterruptible and not isPlayer then
        local _, _, _, _, _, npcID = strsplit("-", unitGUID)
        if npcID then
            if npcID == "12457" then -- Blackwing Spellbinder, immune magic only
                cast.isUninterruptible = not playerIsPhysical
            else
                cast.isUninterruptible = self.db.npcCastUninterruptibleCache[npcID .. spellName]
            end
        end
    end

    -- Quick hack for NPC's Deadly Poison vs Rogue Deadly Poison
    if cast.isUninterruptible and spellID == 2835 and not isPlayer then
        cast.isUninterruptible = false
    end

    -- just nil previous values to avoid overhead of wiping() table
    cast.interruptedSchool = nil
    cast.origIsUninterruptibleValue = nil
    cast.hasCastSlowModified = nil
    cast.hasPushbackImmuneModifier = nil
    cast.activeModifiers = {}
    cast.pushbackValue = nil
    cast.isInterrupted = nil
    cast.isCastComplete = nil
    cast.isFailed = nil
    cast.isUnknownState = nil

    self:StartAllCasts(unitGUID)
end

-- Delete cast data for unit, and stop any active castbars
function addon:DeleteCast(unitGUID, isInterrupted, skipDeleteCache, isCastComplete, noFadeOut)
    if not unitGUID then return end -- may be nil when called from OnUpdate script (rare)

    local cast = activeTimers[unitGUID]
    if cast then
        cast.isInterrupted = isInterrupted
        cast.isCastComplete = isCastComplete -- SPELL_CAST_SUCCESS
        self:StopAllCasts(unitGUID, noFadeOut)
        activeTimers[unitGUID] = nil
    end

    -- Always delete cache unless ran from OnUpdate script
    if not skipDeleteCache and npcCastTimeCacheStart[unitGUID] then
        npcCastTimeCacheStart[unitGUID] = nil
    end
end

function addon:CastPushback(unitGUID)
    local cast = activeTimers[unitGUID]
    if not cast or cast.hasPushbackImmuneModifier then return end
    if pushbackBlacklist[cast.spellName] then return end

    if not cast.isChanneled then
        -- https://wow.gamepedia.com/index.php?title=Interrupt&oldid=305918
        cast.pushbackValue = cast.pushbackValue or 1.0
        cast.maxValue = cast.maxValue + cast.pushbackValue
        cast.endTime = cast.endTime + cast.pushbackValue
        cast.pushbackValue = max(cast.pushbackValue - 0.5, 0.2)
    else
        -- channels are reduced by 25% per hit
        cast.maxValue = cast.maxValue - (cast.maxValue * 25) / 100
        cast.endTime = cast.endTime - (cast.maxValue * 25) / 100
    end
end

-- custom focus castbar for classic era
hooksecurefunc("FocusUnit", function(msg)
    local unitID = msg
    if unitID ~= "mouseover" then
        -- always redirect to target
        unitID = "target"
    end

    local tarGUID = UnitGUID(unitID)
    if tarGUID then
        activeGUIDs.focus = tarGUID
        addon:StopCast("focus", true)
        addon:StartCast(tarGUID, "focus")
        addon:SetFocusDisplay(UnitName(unitID), unitID)
    else
        SlashCmdList["CLEARFOCUS"]()
    end
end)

hooksecurefunc("ClearFocus", function()
    if activeGUIDs.focus then
        activeGUIDs.focus = nil
        addon:StopCast("focus", true)
        addon:SetFocusDisplay(nil)
    end
end)

local function GetSpellCastInfo(spellID)
    local _, _, icon, castTime = GetSpellInfo(spellID)
    if not castTime then return end

    if not unaffectedCastModsSpells[spellID] then
        local _, _, _, hCastTime = GetSpellInfo(8690) -- Hearthstone, normal cast time 10s
        if hCastTime and hCastTime ~= 10000 and hCastTime ~= 0 then -- If current HS cast time is not 10s it means the player has a casting speed modifier aura applied on himself.
            -- Since the return values by GetSpellInfo() are affected by the modifier, we need to remove so it doesn't give modified casttimes for other peoples casts.
            return floor(castTime * 10000 / hCastTime), icon
        end
    end

    return castTime, icon
end

function addon:ToggleUnitEvents(shouldReset)
    if self.db.target.enabled then
        self:RegisterEvent("PLAYER_TARGET_CHANGED")
        self:RegisterUnitEvent("UNIT_TARGET", "target")
        if self.db.target.autoPosition then
            self:RegisterUnitEvent("UNIT_AURA", "target")
        end
    else
        self:UnregisterEvent("PLAYER_TARGET_CHANGED")
        self:UnregisterEvent("UNIT_TARGET")
        self:UnregisterEvent("UNIT_AURA")
    end

    if self.db.nameplate.enabled then
        self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
        self:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    else
        self:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
        self:UnregisterEvent("NAME_PLATE_UNIT_REMOVED")
    end

    if self.db.party.enabled then
        self:RegisterEvent("GROUP_ROSTER_UPDATE")
    else
        self:UnregisterEvent("GROUP_ROSTER_UPDATE")
    end

    if shouldReset then
        self:PLAYER_ENTERING_WORLD() -- wipe all data
    end
end

function addon:PLAYER_ENTERING_WORLD(isInitialLogin)
    if isInitialLogin then return end

    -- Reset all data on loading screens
    wipe(activeGUIDs)
    wipe(activeTimers)
    wipe(activeFrames)
    PoolManager:GetFramePool():ReleaseAll() -- also removes castbar._data references
    self:SetFocusDisplay(nil)

    if self.db.party.enabled then
        self:GROUP_ROSTER_UPDATE()
    end
end

function addon:ZONE_CHANGED_NEW_AREA()
    wipe(npcCastTimeCacheStart)
    if self.db.clearCastTimeCachePerZone then
        self.db.npcCastTimeCache = CopyTable(namespace.defaultConfig.npcCastTimeCache)
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

    if self.db.version then
        if tonumber(self.db.version) < 36 then
            self.db.npcCastTimeCache = CopyTable(namespace.defaultConfig.npcCastTimeCache)
        end
        if tonumber(self.db.version) < 41 then
            if self.db.player.statusColorSuccess[2] == 0.7 then
                self.db.player.statusColorSuccess = { 0, 1, 0, 1 }
            end
        end
    end
    self.db.version = namespace.defaultConfig.version

    -- Reset locale specific settings on game locale switched
    if self.db.locale ~= GetLocale() then
        self.db.locale = GetLocale()
        self.db.target.castFont = _G.STANDARD_TEXT_FONT
        self.db.nameplate.castFont = _G.STANDARD_TEXT_FONT
        self.db.focus.castFont = _G.STANDARD_TEXT_FONT
        self.db.arena.castFont = _G.STANDARD_TEXT_FONT
        self.db.party.castFont = _G.STANDARD_TEXT_FONT
        self.db.npcCastUninterruptibleCache = CopyTable(namespace.defaultConfig.npcCastUninterruptibleCache)
        self.db.npcCastTimeCache = CopyTable(namespace.defaultConfig.npcCastTimeCache)
    end

    -- Reset certain stuff on savedvariables file copied from different expansion
    if self.db.arena.enabled or self.db.focus.autoPosition then -- not supported in classic era
        self.db.arena.enabled = false
        self.db.focus.autoPosition = false
        self.db.focus.position = { "TOPLEFT", 275, -260 }
    end

    if self.db.player.enabled then
        self:SkinPlayerCastbar()
    end

    self.PLAYER_GUID = UnitGUID("player")
    self:ToggleUnitEvents()
    self:ADDON_LOADED("LibClassicDurations") -- incase its already loaded
    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self:UnregisterEvent("PLAYER_LOGIN")
    self.PLAYER_LOGIN = nil
end

-- Enable enemy buff tracking in LibClassicDurations if available
function addon:ADDON_LOADED(addonName)
    if addonName == "LibClassicDurations" or addonName == "ClassicAuraDurations" then
        local LibClassicDurations = LibStub and LibStub("LibClassicDurations", true)
        if LibClassicDurations and not self.LibClassicDurationsInitialized then
            LibClassicDurations:Register("ClassicCastbars")
            LibClassicDurations.RegisterCallback("ClassicCastbars", "UNIT_BUFF", function() end) -- ensure .OnUsed() is triggered
            self.LibClassicDurationsInitialized = true
            self:UnregisterEvent("ADDON_LOADED")
        end
    end
end

function addon:UNIT_TARGET(unitID) -- detect target of target
    if self.db[unitID] and self.db[unitID].autoPosition then
        if activeFrames[unitID] then
            local parentFrame = self.AnchorManager:GetAnchor(unitID)
            if parentFrame then
                self:SetTargetCastbarPosition(activeFrames[unitID], parentFrame)
            end
        end
    end
end

local auraRows = 0
function addon:UNIT_AURA()
    if not self.db.target.autoPosition then return end
    if auraRows == TargetFrame.auraRows then return end
    auraRows = TargetFrame.auraRows

    -- Update target castbar position based on amount of auras currently shown
    if activeFrames.target and activeGUIDs.target then
        local parentFrame = self.AnchorManager:GetAnchor("target")
        if parentFrame then
            self:SetTargetCastbarPosition(activeFrames.target, parentFrame)
        end
    end
end

-- Bind unitIDs to unitGUIDs so we can efficiently get unitIDs in CLEU events
function addon:PLAYER_TARGET_CHANGED()
    activeGUIDs.target = UnitGUID("target") or nil

    self:StopCast("target", true) -- always hide previous target's castbar
    self:StartCast(activeGUIDs.target, "target") -- Show castbar again if available
end

function addon:NAME_PLATE_UNIT_ADDED(namePlateUnitToken)
    local isFriendly = UnitIsFriend("player", namePlateUnitToken)
    if not self.db.nameplate.showForFriendly and isFriendly then return end
    if not self.db.nameplate.showForEnemy and not isFriendly then return end

    local unitGUID = UnitGUID(namePlateUnitToken)
    activeGUIDs[namePlateUnitToken] = unitGUID

    self:StopCast(namePlateUnitToken, true)
    self:StartCast(unitGUID, namePlateUnitToken)
end

function addon:NAME_PLATE_UNIT_REMOVED(namePlateUnitToken)
    activeGUIDs[namePlateUnitToken] = nil

    -- Hide & release frame
    local castbar = activeFrames[namePlateUnitToken]
    if castbar then
        PoolManager:ReleaseFrame(castbar)
        activeFrames[namePlateUnitToken] = nil
    end
end

function addon:GROUP_ROSTER_UPDATE()
    for i = 1, 5 do
        local unitID = "party"..i
        activeGUIDs[unitID] = UnitGUID(unitID) or nil

        if activeGUIDs[unitID] then
            self:StopCast(unitID, true) -- always hide castbar incase party frames were shifted around
            self:StartCast(activeGUIDs[unitID], unitID) -- restart any potential casts
        else
            -- party member no longer exists, release castbar
            local castbar = activeFrames[unitID]
            if castbar then
                PoolManager:ReleaseFrame(castbar)
                activeFrames[unitID] = nil
            end
        end
    end
end

-- Upvalues for combat log events
local bit_band = _G.bit.band
local CombatLogGetCurrentEventInfo = _G.CombatLogGetCurrentEventInfo
local COMBATLOG_OBJECT_CONTROL_PLAYER = _G.COMBATLOG_OBJECT_CONTROL_PLAYER
local COMBATLOG_OBJECT_TYPE_PLAYER = _G.COMBATLOG_OBJECT_TYPE_PLAYER
local castTimeTalentDecreases = namespace.castTimeTalentDecreases
local crowdControls = namespace.crowdControls
local stopCastOnDamageList = namespace.stopCastOnDamageList
local playerInterrupts = namespace.playerInterrupts
local channeledSpells = namespace.channeledSpells
local castedSpells = namespace.castedSpells
local ARCANE_MISSILES = GetSpellInfo(5143)
local ARCANE_MISSILE = GetSpellInfo(7268)

function addon:COMBAT_LOG_EVENT_UNFILTERED()
    local _, eventType, _, srcGUID, _, srcFlags, _, dstGUID, _, dstFlags, _, _, spellName, _, missType, _, extraSchool = CombatLogGetCurrentEventInfo()

    if eventType == "SPELL_CAST_START" then
        local spellID = castedSpells[spellName]
        if not spellID then return end

        local castTime, icon = GetSpellCastInfo(spellID)
        if not castTime then return end

        -- is player or player pet or mind controlled
        local isSrcPlayer = bit_band(srcFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) > 0

        if srcGUID ~= self.PLAYER_GUID then
            if isSrcPlayer then
                -- Use hardcoded talent reduced cast time for certain player spells
                local reducedTime = castTimeTalentDecreases[spellName]
                if reducedTime then
                    castTime = reducedTime
                end
            else
                local unitType, _, _, _, _, npcID = strsplit("-", srcGUID)
                if npcID and (unitType == "Creature" or unitType == "Pet") then
                    local cachedTime = self.db.npcCastTimeCache[npcID .. spellName]
                    if cachedTime then
                        -- Use cached time stored from earlier sightings for NPCs.
                        -- This is because mobs have various cast times, e.g a lvl 20 mob casting Frostbolt might have
                        -- 3.5 cast time but another lvl 40 mob might have 2.5 cast time instead for Frostbolt.
                        castTime = cachedTime
                    else
                        npcCastTimeCacheStart[srcGUID] = GetTime()
                    end
                end
            end
        else -- player/self
            local _, _, _, startTime, endTime = CastingInfo()
            if endTime and startTime then
                castTime = endTime - startTime
            end
        end

        -- Start the non-channeled cast
        return self:StoreCast(srcGUID, spellName, spellID, icon, castTime, isSrcPlayer)
    elseif eventType == "SPELL_CAST_SUCCESS" then
        local channelCast = channeledSpells[spellName]
        local spellID = castedSpells[spellName]

        if not channelCast and not spellID then
            -- Stop current cast on any new non-cast ability used
            if activeTimers[srcGUID] and GetTime() - activeTimers[srcGUID].timeStart > 0.25 then
                return self:StopAllCasts(srcGUID)
            end

            return -- spell was not a cast nor channel
        end

        local isSrcPlayer = bit_band(srcFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) > 0

        -- Auto correct cast times for mobs (only non-channels)
        if not isSrcPlayer and not channelCast then
            local unitType, _, _, _, _, srcNpcID = strsplit("-", srcGUID)
            if srcNpcID and (unitType == "Creature" or unitType == "Pet") then
                local cachedTime = self.db.npcCastTimeCache[srcNpcID .. spellName]
                if not cachedTime then
                    local cast = activeTimers[srcGUID]
                    if not cast or (cast and not cast.hasCastSlowModified and not next(cast.activeModifiers)) then
                        -- TODO: if the cast speed is modified we can prob just subtract it instead of skipping cast
                        -- TODO: since we're no longer using npc names, we should switch to the 'fake' spellID aswell so localization check is not needed
                        local restoredStartTime = npcCastTimeCacheStart[srcGUID]
                        if restoredStartTime then
                            local castTime = (GetTime() - restoredStartTime) * 1000
                            local origCastTime = GetSpellCastInfo(spellID) or 0

                            -- Whatever time was detected between SPELL_CAST_START and SPELL_CAST_SUCCESS will be the new cast time
                            local castTimeDiff = abs(castTime - origCastTime)
                            if castTimeDiff <= 4000 and castTimeDiff >= 225 then -- take lag into account
                                self.db.npcCastTimeCache[srcNpcID .. spellName] = floor(castTime)
                                npcCastTimeCacheStart[srcGUID] = nil
                            end
                        end
                    end
                end
            end
        end

        -- Channeled spells are started on SPELL_CAST_SUCCESS, and generally stops on SPELL_AURA_REMOVED instead.
        -- Also there's no castTime returned from GetSpellInfo for channeled spells so we need to get it from our own list
        if channelCast then
            if spellName == ARCANE_MISSILES or spellName == ARCANE_MISSILE then
                -- Arcane Missiles triggers this event for every tick so ignore after first tick has been detected
                local cast = activeTimers[srcGUID]
                if cast and (cast.spellName == ARCANE_MISSILES or cast.spellName == ARCANE_MISSILE) then return end
            end

            -- Channeled spell, add it
            return self:StoreCast(srcGUID, spellName, spellID, GetSpellTexture(spellID), channelCast, isSrcPlayer, true)
        end

        -- Non-channeled spell, finish it.
        -- We also check the expiration timer in OnUpdate script just incase this event doesn't trigger when i.e unit is no longer in range.
        return self:DeleteCast(srcGUID, nil, nil, true)
    elseif eventType == "SPELL_AURA_APPLIED" then
        local cast = activeTimers[dstGUID]
        if not cast then return end

        if crowdControls[spellName] then
            -- Aura that interrupts cast was applied
            cast.isFailed = true
            return self:DeleteCast(dstGUID)
        elseif castTimeIncreases[spellName] then
            -- Cast modifiers doesnt modify already active casts, only the next time the player casts.
            -- So we force set this to true here to prevent modifying current cast later on
            cast.hasCastSlowModified = true
        elseif castImmunityBuffs[spellName] and not cast.isUninterruptible then
            -- Aura that give uninterruptible cast gained
            cast.origIsUninterruptibleValue = cast.isUninterruptible
            cast.isUninterruptible = true
            return self:StartAllCasts(srcGUID) -- Hack: Restart cast to update border shield
        end
    elseif eventType == "SPELL_AURA_REMOVED" then
        -- Channeled spells has no proper event for channel stop,
        -- so check if aura is gone instead since most channels has an aura effect.
        if srcGUID == dstGUID and channeledSpells[spellName] then
            return self:DeleteCast(srcGUID, nil, nil, true)
        end

        -- Aura that give uninterruptible cast expired
        if castImmunityBuffs[spellName] then
            local cast = activeTimers[srcGUID]
            if not cast then return end

            cast.isUninterruptible = cast.origIsUninterruptibleValue or false
            return self:StartAllCasts(srcGUID) -- Hack: Restart cast to update border shield
        end
    elseif eventType == "SPELL_CAST_FAILED" then
        local cast = activeTimers[srcGUID]
        if not cast then return end

        if srcGUID == self.PLAYER_GUID then
            if CastingInfo() or ChannelInfo() then return end
        end

        -- channels shows finish anim on cast failed
        cast.isFailed = not cast.isChanneled and true or false
        return self:DeleteCast(srcGUID, nil, nil, cast.isChanneled)
    elseif eventType == "SPELL_INTERRUPT" or eventType == "UNIT_DIED" or eventType == "UNIT_DESTROYED" or eventType == "UNIT_DISSIPATES" then
        if eventType == "SPELL_INTERRUPT" then
            local cast = activeTimers[dstGUID]
            if cast then
                --cast.isInterrupted = true
                cast.interruptedSchool = extraSchool or nil
            end
        end

        return self:DeleteCast(dstGUID, eventType == "SPELL_INTERRUPT")
    elseif eventType == "SWING_DAMAGE" or eventType == "ENVIRONMENTAL_DAMAGE" or eventType == "RANGE_DAMAGE" or eventType == "SPELL_DAMAGE" then
        if bit_band(dstFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0 then -- is player, and not pet
            local cast = activeTimers[dstGUID]
            if not cast then return end

            if stopCastOnDamageList[cast.spellName] then
                cast.isFailed = true
                return self:DeleteCast(dstGUID)
            end

            return self:CastPushback(dstGUID)
        end
    elseif eventType == "SPELL_MISSED" then
        -- Auto learn if a spell is uninterruptible for NPCs by checking if an interrupt was immuned
        -- FIXME: as of patch 14.4.4 this seems to no longer work, atleast not with basic Counterspell on low lvl mobs
        if missType == "IMMUNE" and playerInterrupts[spellName] then
            local cast = activeTimers[dstGUID]
            if not cast then return end

            if bit_band(dstFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) <= 0 then -- dest unit is not a player
                if bit_band(srcFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) > 0 then -- source unit is player
                    local _, _, _, _, _, npcID = strsplit("-", dstGUID)
                    if not npcID or npcID == "12457" or npcID == "11830" then return end -- Blackwing Spellbinder or Hakkari Priest
                    if self.db.npcCastUninterruptibleCache[npcID .. cast.spellName] then return end -- already added

                    -- Check for temp immunity like bubble
                    local libCD = LibStub and LibStub("LibClassicDurations", true)
                    if libCD and libCD.buffCache then
                        local buffCacheHit = libCD.buffCache[dstGUID]
                        if buffCacheHit then
                            for i = 1, #buffCacheHit do
                                local name = buffCacheHit[i].name
                                if castImmunityBuffs[name] then
                                    return
                                end
                            end
                        end
                    end

                    self.db.npcCastUninterruptibleCache[npcID .. cast.spellName] = true
                end
            end
        end
    end
end

local refresh = 0
local castStopBlacklist = namespace.castStopBlacklist
addon:SetScript("OnUpdate", function(self, elapsed)
    if not next(activeTimers) then return end
    local currTime = GetTime()

    -- Check if an unit is moving so we can stop the castbar, thanks to Cordankos for this idea.
    refresh = refresh - elapsed
    if refresh < 0 then
        for unitID, castbar in next, activeFrames do
            if unitID ~= "focus" then -- ignoure our fake custom focus castbar
                local cast = castbar._data
                -- Only stop cast for players since some mobs runs while casting, also because
                -- of lag we have to only stop it if the cast has been active for atleast 0.15 sec
                if cast and cast.isPlayer and currTime - cast.timeStart > 0.15 then
                    if not castStopBlacklist[cast.spellName] and (GetUnitSpeed(unitID) ~= 0 or IsFalling(unitID)) then
                        local castAlmostFinishied = ((currTime - cast.timeStart) > cast.maxValue - 0.1)
                        -- due to lag its possible that the cast is successfuly casted but still shows interrupted
                        -- unless we ignore the last few miliseconds here
                        if not castAlmostFinishied then
                            if not cast.isChanneled then
                                cast.isFailed = true
                            end
                            self:DeleteCast(castbar._data.unitGUID, nil, nil, cast.isChanneled)
                        end
                    end
                end
            end
        end
        refresh = 0.1 -- Run every 0.1s instead of every rendered frame
    end

    -- Update the display for all active castbars
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
            else
                if not cast.isCastComplete and not cast.isInterrupted and not cast.isFailed then
                    castbar.Spark:SetAlpha(0)
                    if cast.isChanneled then
                        castbar:SetValue(0)
                    else
                        castbar:SetMinMaxValues(0, 1)
                        castbar:SetValue(1)
                    end

                    -- Delete cast incase stop event wasn't detected in CLEU
                    if castTime <= -0.17 then
                        if not cast.isChanneled then
                            cast.isFailed = not cast.isPlayer -- show failed for npcs only
                            self:DeleteCast(cast.unitGUID, false, true, false, false)
                        else
                            self:DeleteCast(cast.unitGUID, false, true, true, false)
                        end
                    end
                end
            end
        end
    end
end)
