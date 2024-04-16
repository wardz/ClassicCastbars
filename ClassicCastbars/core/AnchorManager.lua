local _, namespace = ...

local AnchorManager = {}
namespace.AnchorManager = AnchorManager

-- Anchor list for unitframes.
-- Blizzard frame should always be last index.
local anchors = {
    target = {
        "SUFUnittarget",
        "XPerl_Target",
        "Perl_Target_Frame",
        "ElvUF_Target",
        "oUF_TukuiTarget",
        "btargetUnitFrame",
        "DUF_TargetFrame",
        "GwTargetUnitFrame",
        "PitBull4_Frames_Target",
        "oUF_Target",
        "SUI_targetFrame",
        "gUI4_UnitTarget",
        "oUF_Adirelle_Target",
        "oUF_AftermathhTarget",
        "LUFUnittarget",
        "oUF_LumenTarget",
        "TukuiTargetFrame",
        "CG_UnitFrame_2",
        "TargetFrame", -- Blizzard frame should always be last
    },

    party = {
        "SUFHeaderpartyUnitButton%d",
        "XPerl_party%d",
        "ElvUF_PartyGroup1UnitButton%d",
        "TukuiPartyUnitButton%d",
        "DUF_PartyFrame%d",
        "PitBull4_Groups_PartyUnitButton%d",
        "oUF_Raid%d",
        "GwPartyFrame%d",
        "gUI4_GroupFramesGroup5UnitButton%d",
        "PartyMemberFrame%d",
        "CompactPartyFrameMember%d",
        "CompactRaidFrame%d",
        "CompactRaidGroup1Member%d",
    },

    focus = {
        "SUFUnitfocus",
        "XPerl_Focushighlight",
        "ElvUF_Focus",
        "oUF_TukuiFocus",
        "bfocusUnitFrame",
        "DUF_FocusFrame",
        "GwFocusUnitFrame",
        "PitBull4_Frames_Focus",
        "oUF_Focus",
        "SUI_focusFrame",
        "gUI4_UnitFocus",
        "oUF_Adirelle_Focus",
        "oUF_AftermathhFocus",
        "LUFUnitfocus",
        "oUF_LumenFocus",
        "FocusFrame",
    },

    arena = {
        "sArenaEnemyFrame%d",
        "ArenaEnemyFrame%d",
        "ArenaEnemyMatchFrame%d",
    },
}

-- Upvalues frequently used
local _G = _G
local format = _G.string.format
local match = _G.string.match
local gsub = _G.string.gsub
local GetNamePlateForUnit = _G.C_NamePlate.GetNamePlateForUnit

local function GetUnitFrame(unitType, skipVisibleCheck)
    local anchorNames = anchors[unitType]
    if not anchorNames then return end

    local unitIndex = match(unitType, "%d+")

    for i = 1, #anchorNames do
        local frameName = unitIndex and format(anchorNames[i], unitIndex) or anchorNames[i]
        local unitFrame = _G[frameName]

        if unitFrame then
            if skipVisibleCheck or unitFrame:IsVisible() then
                return unitFrame, frameName
            end
        end
    end
end

local function GetPartyFrameForUnit(unitID)
    if GetNumGroupMembers() > 5 then return end -- Dont show party castbars in raid for now

    local guid = UnitGUID(unitID)
    if unitID ~= "party-testmode" and not guid then return end

    local useBlizzCompact = GetCVarBool("useCompactPartyFrames")
    if EditModeManagerFrame and EditModeManagerFrame.UseRaidStylePartyFrames then
        useBlizzCompact = EditModeManagerFrame:UseRaidStylePartyFrames()
    end

    if unitID == "party-testmode" then
        if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
            if useBlizzCompact then
                return GetUnitFrame("party1", true)
            else
                return GetUnitFrame("party1", false) or PartyFrame and PartyFrame.MemberFrame1
            end
        else
            if useBlizzCompact and not IsInGroup() then return end -- TODO: fix me
            return GetUnitFrame("party1", not useBlizzCompact)
        end
    end

    -- Compact/custom frames are recycled so frame10 might be party2 and so on, so we need
    -- to loop through them all and check if the unit matches.
    for i = 1, 40 do
        local frame, frameName = GetUnitFrame("party"..i)

        if frame then
            local unit = frame.realUnit or frame.displayedUnit or frame.unit or frame.unitID -- depends on addons

            if (unit and UnitGUID(unit) == guid) or (frame.unitGUID == guid or frame.lastGUID == guid) then
                if useBlizzCompact and frameName ~= "PartyMemberFrame"..i or not useBlizzCompact then
                    return frame
                end
            end
        end
    end

    -- Check new retail party frames
    if not useBlizzCompact then
        if PartyFrame and PartyFrame.PartyMemberFramePool then
            for frame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
                if frame.layoutIndex and frame:IsVisible() and UnitGUID("party" .. frame.layoutIndex) == guid then
                    return frame
                end
            end
        end
    end
end

local anchorCache = { player = UIParent }

function AnchorManager:GetAnchor(unitID)
    if anchorCache[unitID] then
        return anchorCache[unitID]
    end

    -- Static frames
    if unitID == "target" or unitID == "focus" then
        anchorCache[unitID] = GetUnitFrame(unitID)

        return anchorCache[unitID]
    end

    local unitType, matchCount = gsub(unitID, "%d", "") -- remove unit index if found

    if unitType == "nameplate" or unitType == "nameplate-testmode" then
        return GetNamePlateForUnit(matchCount and unitID or "target") -- 'target' for testmode
    elseif unitType == "party" or unitType == "party-testmode" then
        return GetPartyFrameForUnit(matchCount and unitID or "party1")
    elseif unitType == "arena" or unitType == "arena-testmode" then
        return GetUnitFrame(matchCount and unitID or "arena1", not matchCount)
    end
end
