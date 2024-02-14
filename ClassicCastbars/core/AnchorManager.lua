local _, namespace = ...

local AnchorManager = {}
namespace.AnchorManager = AnchorManager

 -- Anchors for custom unitframes
 -- Blizzard frame should always be listed last
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
        "Stuf.units.focus",
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

local _G = _G
local format = _G.string.format
local strmatch = _G.string.match
local strfind = _G.string.find
local gsub = _G.string.gsub
local GetNamePlateForUnit = _G.C_NamePlate.GetNamePlateForUnit

local function GetUnitFrame(unitType, unitID, hasNumberIndex, skipVisibleCheck)
    local anchorNames = anchors[unitType]
    if not anchorNames then return end

    for i = 1, #anchorNames do
        local name = anchorNames[i]
        if hasNumberIndex then
            name = format(name, strmatch(unitID, "%d+")) -- add unit index to unitframe name
        end

        local unitFrame = _G[name]
        if unitFrame then
            if not skipVisibleCheck then
                if unitFrame:IsVisible() then -- prioritize visible frame to get the correct active one
                    return unitFrame, name
                end
            else
                return unitFrame, name
            end
        end
    end
end

local function GetPartyFrameForUnit(unitID)
    if GetNumGroupMembers() > 5 then return end -- Dont show party castbars in raid for now

    local guid = UnitGUID(unitID == "party-testmode" and "player" or unitID)
    if not guid then return end

    local useBlizzCompact = GetCVarBool("useCompactPartyFrames")
    if EditModeManagerFrame and EditModeManagerFrame.UseRaidStylePartyFrames then
        useBlizzCompact = EditModeManagerFrame:UseRaidStylePartyFrames()
    end

    if unitID == "party-testmode" then
        if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
            if useBlizzCompact then
                return GetUnitFrame("party", "party1", true, true)
            else
                return PartyFrame.MemberFrame1
            end
        else
            if useBlizzCompact and not IsInGroup() then
                return print(format("|cFFFF0000[ClassicCastbars] %s|r", _G.ERR_QUEST_PUSH_NOT_IN_PARTY_S)) -- luacheck: ignore
            end
            return GetUnitFrame("party", "party1", true, not useBlizzCompact)
        end
    end

    -- Compact/custom frames are recycled so frame10 might be party2 and so on, so we need
    -- to loop through them all and check if the unit matches.
    for i = 1, 40 do
        local frame, frameName = GetUnitFrame("party", "party"..i, true)

        if frame and ((frame.unit and UnitGUID(frame.unit) == guid) or frame.lastGUID == guid) and frame:IsVisible() then
            if useBlizzCompact then
                if strfind(frameName, "PartyMemberFrame") == nil then
                    return frame
                end
            else
                return frame
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

    local unitType, count = gsub(unitID, "%d", "") -- "party1" to "party" etc

    local anchorFrame
    if unitType == "nameplate-testmode" then
        anchorFrame = GetNamePlateForUnit("target")
    elseif unitType == "nameplate" then
        anchorFrame = GetNamePlateForUnit(unitID)
    elseif unitType == "party" or unitType == "party-testmode" then
        anchorFrame = GetPartyFrameForUnit(unitID)
    elseif unitType == "arena-testmode" then
        anchorFrame = GetUnitFrame("arena", "arena1", true, true)
    else -- target/focus/arena
        anchorFrame = GetUnitFrame(unitType, unitID, count > 0)
    end

    if not anchorFrame then return end

    -- Cache static unitframes permanently
    if unitType == "target" or unitType == "focus" then
        anchorCache[unitID] = anchorFrame
    end

    return anchorFrame
end
