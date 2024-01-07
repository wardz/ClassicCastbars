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
local strmatch = _G.string.match
local strfind = _G.string.find
local gsub = _G.string.gsub
local UnitGUID = _G.UnitGUID
local GetNamePlateForUnit = _G.C_NamePlate.GetNamePlateForUnit
local GetNumGroupMembers = _G.GetNumGroupMembers

local function GetUnitFrameForUnit(unitType, unitID, hasNumberIndex, skipVisibleCheck)
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
                if unitFrame:IsVisible() then
                    return unitFrame, name
                end
            else
                return unitFrame, name
            end
        end
    end
end

local function GetPartyFrameForUnit(unitID)
    if GetNumGroupMembers() > 5 then return end -- Dont show party castbars in raid

    local guid = UnitGUID(unitID)
    if unitID == "party-testmode" then guid = UnitGUID("player") end
    if not guid then return end

    local useBlizzCompact = GetCVarBool("useCompactPartyFrames")
    if EditModeManagerFrame.UseRaidStylePartyFrames then
        useBlizzCompact = EditModeManagerFrame:UseRaidStylePartyFrames()
    end

    if unitID == "party-testmode" then
        if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then -- TODO: check if still needed
            if useBlizzCompact then
                return GetUnitFrameForUnit("party", "party1", true, true)
            else
                return PartyFrame.MemberFrame1
            end
        else
            if useBlizzCompact and not IsInGroup() then
                return print(format("|cFFFF0000[ClassicCastbars] %s|r", _G.ERR_QUEST_PUSH_NOT_IN_PARTY_S)) -- luacheck: ignore
            end
            return GetUnitFrameForUnit("party", "party1", true, not useBlizzCompact)
        end
    end

    -- raid frames are recycled so frame10 might be party2 and so on, so we need
    -- to loop through them all and check if the unit matches. Same thing with party
    -- frames for custom addons
    for i = 1, 40 do
        local frame, frameName = GetUnitFrameForUnit("party", "party"..i, true)

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
    if PartyFrame and PartyFrame.PartyMemberFramePool and not useBlizzCompact then
        for frame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
            if frame.layoutIndex and frame:IsVisible() and UnitGUID("party" .. frame.layoutIndex) == guid then
                return frame
            end
        end
    end
end

local anchorCache = { player = UIParent }
function AnchorManager:GetAnchor(unitID)
    if anchorCache[unitID] then
        return anchorCache[unitID]
    end

    local unitType, count = gsub(unitID, "%d", "") -- party1 -> party etc

    local frame
    if unitType == "nameplate-testmode" then
        frame = GetNamePlateForUnit("target")
    elseif unitType == "nameplate" then
        frame = GetNamePlateForUnit(unitID)
    elseif unitType == "party" or unitType == "party-testmode" then
        frame = GetPartyFrameForUnit(unitID)
    elseif unitType == "arena-testmode" then
        frame = GetUnitFrameForUnit("arena", "arena1", true, true)
    else -- target/focus/arena
        frame = GetUnitFrameForUnit(unitType, unitID, count > 0)
    end

    if not frame then return end

    -- Cache frequently used static unitframes permanently
    if unitType == "target" or unitType == "focus" then
        anchorCache[unitID] = frame
    end

    return frame
end
