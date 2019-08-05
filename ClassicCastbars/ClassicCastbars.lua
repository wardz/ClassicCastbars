local _, namespace = ...
local PoolManager = namespace.PoolManager

local addon = CreateFrame("Frame")
addon:RegisterEvent("PLAYER_LOGIN")
addon:SetScript("OnEvent", function(self, event, ...)
    -- this will basically trigger addon:EVENT_NAME(arguments) on any event happening
    return self[event](self, ...)
end)

local activeGUIDs = {}
local activeTimers = {}
local activeFrames = {}

addon.AnchorManager = namespace.AnchorManager
addon.defaultConfig = namespace.defaultConfig
addon.activeFrames = activeFrames
namespace.addon = addon
ClassicCastbars = addon -- global ref for ClassicCastbars_Options

-- upvalues for speed
local pairs = _G.pairs
local UnitGUID = _G.UnitGUID
local GetSpellInfo = _G.GetSpellInfo
local GetSpellTexture = _G.GetSpellTexture
local CombatLogGetCurrentEventInfo = _G.CombatLogGetCurrentEventInfo
local GetTime = _G.GetTime
local max = _G.math.max
local next = _G.next
local GetSpellSubtext = _G.GetSpellSubtext
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
        --[[if not noFadeOut then
            -- TODO: verify this doesn't cause side effects or performance issues
            UIFrameFadeOut(castbar, 0.1, 1, 0)
        else]]
            castbar:Hide()
        --end
    end
end

function addon:StartAllCasts(unitGUID)
    if not activeTimers[unitGUID] then return end

    for unitID, guid in pairs(activeGUIDs) do
        if guid == unitGUID then
            self:StartCast(guid, unitID)
        end
    end
end

function addon:StopAllCasts(unitGUID)
    for unitID, guid in pairs(activeGUIDs) do
        if guid == unitGUID then
            self:StopCast(unitID)
        end
    end
end

function addon:StoreCast(unitGUID, spellName, iconTexturePath, castTime, spellRank, isChanneled)
    local currTime = GetTime()

    -- Store cast data from CLEU in an object, we can't store this in the castbar frame itself
    -- since frames are constantly recycled between different units.
    -- TODO: we can prob reuse objects here
    activeTimers[unitGUID] = {
        spellName = spellName,
        spellRank = spellRank,
        icon = iconTexturePath,
        maxValue = castTime / 1000,
        --timeStart = currTime,
        endTime = currTime + (castTime / 1000),
        unitGUID = unitGUID,
        isChanneled = isChanneled,
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

-- Spaghetti code inc, you're warned
function addon:SetCastDelay(unitGUID, percentageAmount, auraFaded)
    if not self.db.pushbackDetect then return end
    local cast = activeTimers[unitGUID]
    if not cast then return end

    -- if cast.prevCurrTimeModValue then print("stored total:", #cast.prevCurrTimeModValue) end

    -- Set cast time modifier (i.e Curse of Tongues)
    if not auraFaded and percentageAmount and percentageAmount > 0 then
        if not cast.currTimeModValue or cast.currTimeModValue < percentageAmount then -- run only once unless % changed to higher val
            if cast.currTimeModValue then -- already was reduced
                -- if existing modifer is e.g 50% and new is 60%, we only want to adjust cast by 10%
                percentageAmount = percentageAmount - cast.currTimeModValue

                -- Store previous lesser modifier that was active incase new one expires first or gets dispelled
                cast.prevCurrTimeModValue = cast.prevCurrTimeModValue or {}
                cast.prevCurrTimeModValue[#cast.prevCurrTimeModValue + 1] = cast.currTimeModValue
                -- print("stored lesser modifier")
            end

            -- print("refreshing timer", percentageAmount)
            cast.currTimeModValue = (cast.currTimeModValue or 0) + percentageAmount -- highest active modifier
            cast.maxValue = cast.maxValue + (cast.maxValue * percentageAmount) / 100
            cast.endTime = cast.endTime + (cast.maxValue * percentageAmount) / 100
        elseif cast.currTimeModValue == percentageAmount then
            -- new modifier has same percentage as current active one, just store it for later
            -- print("same percentage, storing")
            cast.prevCurrTimeModValue = cast.prevCurrTimeModValue or {}
            cast.prevCurrTimeModValue[#cast.prevCurrTimeModValue + 1] = percentageAmount
        end
    elseif auraFaded and percentageAmount then
        -- Reset cast time modifier
        if cast.currTimeModValue == percentageAmount then
            cast.maxValue = cast.maxValue - (cast.maxValue * percentageAmount) / 100
            cast.endTime = cast.endTime - (cast.maxValue * percentageAmount) / 100
            cast.currTimeModValue = nil

            -- Reset to lesser modifier if available
            if cast.prevCurrTimeModValue then
                local highest, index = 0
                for i = 1, #cast.prevCurrTimeModValue do
                    if cast.prevCurrTimeModValue[i] and cast.prevCurrTimeModValue[i] > highest then
                        highest, index = cast.prevCurrTimeModValue[i], i
                    end
                end

                if index then
                    cast.prevCurrTimeModValue[index] = nil
                    -- print("resetting to lesser modifier", highest)
                    return self:SetCastDelay(unitGUID, highest)
                end
            end
        end

        if cast.prevCurrTimeModValue then
            -- Delete 1 old modifier (doesn't matter which one aslong as its the same %)
            for i = 1, #cast.prevCurrTimeModValue do
                if cast.prevCurrTimeModValue[i] == percentageAmount then
                    -- print("deleted lesser modifier, new total:", #cast.prevCurrTimeModValue - 1)
                    cast.prevCurrTimeModValue[i] = nil
                    return
                end
            end
        end
    else -- normal pushback
        self:CastPushback(cast)
    end
end

function addon:CastPushback(cast)
    if not cast.isChanneled then
        -- https://wow.gamepedia.com/index.php?title=Interrupt&oldid=305918
        cast.pushbackValue = cast.pushbackValue or 1.0
        cast.maxValue = cast.maxValue + cast.pushbackValue
        cast.endTime = cast.endTime + cast.pushbackValue
        cast.pushbackValue = max(cast.pushbackValue - 0.2, 0.2)
    else
        -- channels are reduced by 25% per hit afaik
        cast.maxValue = cast.maxValue - (cast.maxValue * 25) / 100
        cast.endTime = cast.endTime - (cast.maxValue * 25) / 100
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

    -- Reset very old settings
    -- TODO: remove this in v1.0.1
    if ClassicCastbarsDB.version and ClassicCastbarsDB.version == "1" or
        ClassicCastbarsDB.nameplate and not ClassicCastbarsDB.version then
        wipe(ClassicCastbarsDB)
        print("ClassicCastbars: All settings reset due to major changes. See /castbar for new options.")
    end

    -- Copy any settings from defaults if they don't exist in current profile
    self.db = CopyDefaults(namespace.defaultConfig, ClassicCastbarsDB)
    self.db.version = namespace.defaultConfig.version

    -- Reset fonts on game locale switched (fonts only works for certain locales)
    if self.db.locale ~= GetLocale() then
        self.db.locale = GetLocale()
        self.db.target.castFont = _G.STANDARD_TEXT_FONT
        self.db.nameplate.castFont = _G.STANDARD_TEXT_FONT
    end

    -- config is not needed anymore if options are not loaded
    if not IsAddOnLoaded("ClassicCastbars_Options") then
        self.defaultConfig = nil
        namespace.defaultConfig = nil
    end

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

    self:StopCast("target", true) -- always hide previous target's castbar
    self:StartCast(activeGUIDs.target, "target") -- Show castbar again if available
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

local channeledSpells = namespace.channeledSpells
local castTimeIncreases = namespace.castTimeIncreases
local castTimeTalentDecreases = namespace.castTimeTalentDecreases
local crowdControls = namespace.crowdControls
local bit_band = _G.bit.band
local COMBATLOG_OBJECT_TYPE_PLAYER = _G.COMBATLOG_OBJECT_TYPE_PLAYER

function addon:COMBAT_LOG_EVENT_UNFILTERED()
    local _, eventType, _, srcGUID, _, srcFlags, _, dstGUID,  _, dstFlags, _, spellID, spellName, _, _, _, _, resisted, blocked, absorbed = CombatLogGetCurrentEventInfo()

    if eventType == "SPELL_CAST_START" then
        local _, _, icon, castTime = GetSpellInfo(spellID)
        if not castTime or castTime == 0 then return end
        local rank = GetSpellSubtext(spellID) -- queries async from server unless cached, so won't work first try but thats okay

        -- Reduce cast time for certain spells
        local reducedTime = castTimeTalentDecreases[spellName]
        if reducedTime then
            if bit_band(srcFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0 then -- only reduce cast time for player casted ability
                castTime = castTime - (reducedTime * 1000)
            end
        end

        -- using return here will make the next function (StoreCast) reuse the current stack frame which is slightly more performant
        return self:StoreCast(srcGUID, spellName, icon, castTime, rank)
    elseif eventType == "SPELL_CAST_SUCCESS" then -- spell finished
        -- Channeled spells are started on SPELL_CAST_SUCCESS instead of stopped
        -- Also there's no castTime returned from GetSpellInfo for channeled spells so we need to get it from our own list
        local castTime = channeledSpells[spellName]
        if castTime then
            return self:StoreCast(srcGUID, spellName, GetSpellTexture(spellID), castTime * 1000, nil, true)
        end

        -- non-channeled spell, finish it.
        -- We also check the expiration timer in OnUpdate script just incase this event doesn't trigger when i.e unit is no longer in range.
        -- Note: It's still possible to get a memory leak here since OnUpdate is only ran for active frames, but adding extra
        -- timer checks just to save a few kb extra memory in extremly rare situations is not really worth the performance hit.
        -- All data is cleared on loading screens anyways.
        return self:DeleteCast(srcGUID)
    elseif eventType == "SPELL_AURA_APPLIED" then
        if castTimeIncreases[spellID] then
            -- Aura that slows casting speed was applied
            return self:SetCastDelay(dstGUID, namespace.castTimeIncreases[spellID])
        elseif crowdControls[spellName] then
            -- Aura that interrupts cast was applied
            return self:DeleteCast(dstGUID)
        end
    elseif eventType == "SPELL_AURA_REMOVED" then
        -- Channeled spells has no SPELL_CAST_* event for channel stop,
        -- so check if aura is gone instead since most (all?) channels has an aura effect.
        if channeledSpells[spellName] then
            return self:DeleteCast(srcGUID)
        elseif castTimeIncreases[spellID] then
            -- Aura that slows casting speed was removed.
            return self:SetCastDelay(dstGUID, castTimeIncreases[spellID], true)
        end
    elseif eventType == "SPELL_CAST_FAILED" then
        if srcGUID == self.PLAYER_GUID then
            -- Spamming cast keybinding triggers SPELL_CAST_FAILED so check if actually casting or not for the player
            if not CastingInfo("player") then
                return self:DeleteCast(srcGUID)
            end
        else
            return self:DeleteCast(srcGUID)
        end
    elseif eventType == "PARTY_KILL" or eventType == "UNIT_DIED" or eventType == "SPELL_INTERRUPT" then
        return self:DeleteCast(dstGUID)
    elseif eventType == "SWING_DAMAGE" or eventType == "ENVIRONMENTAL_DAMAGE" or eventType == "RANGE_DAMAGE" or eventType == "SPELL_DAMAGE" then
        if resisted or blocked or absorbed then return end

        if bit_band(dstFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0 then -- is player
            return self:SetCastDelay(dstGUID)
        end
    end
end

addon:SetScript("OnUpdate", function(self)
    if not next(activeTimers) then return end

    local currTime = GetTime()
    local pushbackEnabled = self.db.pushbackDetect

    -- Update all shown castbars in a single OnUpdate call
    for unit, castbar in pairs(activeFrames) do
        local cast = castbar._data

        if cast then
            local castTime = cast.endTime - currTime

            if (castTime > 0) then
                if not cast.showCastInfoOnly then
                    local value = cast.maxValue - castTime
                    if cast.isChanneled then -- inverse
                        value = cast.maxValue - value
                    end

                    if pushbackEnabled then
                        -- maxValue is only updated dynamically when pushback detect is enabled
                        castbar:SetMinMaxValues(0, cast.maxValue)
                    end

                    castbar:SetValue(value)
                    castbar.Timer:SetFormattedText("%.1f", castTime)
                    local sparkPosition = (value / cast.maxValue) * castbar:GetWidth()
                    castbar.Spark:SetPoint("CENTER", castbar, "LEFT", sparkPosition, 0)
                end
            else
                -- Delete cast incase stop event wasn't detected in CLEU
                self:DeleteCast(cast.unitGUID)
            end
        end
    end
end)
