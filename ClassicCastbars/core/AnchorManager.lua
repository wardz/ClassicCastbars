local _, namespace = ...
local AnchorManager = {}
namespace.AnchorManager = AnchorManager

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
        "CompactRaidFrame%d",
        "CompactPartyFrameMember%d",
        "CompactRaidGroup1Member%d",
    },
}

local cache = {}
local _G = _G
local strmatch = _G.strmatch
local strfind = _G.string.find
local UnitGUID = _G.UnitGUID
local GetNamePlateForUnit = _G.C_NamePlate.GetNamePlateForUnit

local function GetUnitFrameForUnit(unitType, unitID, hasNumberIndex)
    local anchorNames = anchors[unitType]
    if not anchorNames then return end

    for i = 1, #anchorNames do
        local name = anchorNames[i]
        if hasNumberIndex then
            name = format(name, strmatch(unitID, "%d+")) -- add unit index to unitframe name
        end

        local frame = _G[name]
        if frame then
            if unitType == "party" then
                return _G[name], name
            end

            if frame:IsVisible() then
                return _G[name], name
            end
        end
    end
end

local function GetPartyFrameForUnit(unitID)
    if unitID == "party-testmode" then
        return GetUnitFrameForUnit("party", "party1", true)
    end

    local guid = UnitGUID(unitID)
    if not guid then return end

    local compact = GetCVarBool("useCompactPartyFrames")

    -- raid frames are recycled so frame10 might be party2 and so on, so we need
    -- to loop through them all and check if the unit matches
    for i = 1, 40 do
        local frame, frameName = GetUnitFrameForUnit("party", "party"..i, true)
        if frame and frame.unit and UnitGUID(frame.unit) == guid and frame:IsVisible() then
            if compact then
                if strfind(frameName, "PartyMemberFrame") == nil then
                    return frame
                end
            else
                return frame
            end
        end
    end
end

function AnchorManager:GetAnchor(unitID)
    if cache[unitID] then
        return cache[unitID]
    end

    if unitID == "player" then
        return UIParent
    end

    local unitType, count = unitID:gsub("%d", "") -- party1 -> party etc

    local frame
    if unitID == "nameplate-testmode" then
        frame = GetNamePlateForUnit("target")
    elseif unitType == "nameplate" then
        frame = GetNamePlateForUnit(unitID)
    elseif unitType == "party" or unitType == "party-testmode" then
        frame = GetPartyFrameForUnit(unitID)
    else -- target
        frame = GetUnitFrameForUnit(unitType, unitID, count > 0)
    end

    if frame and unitType == "target" then
        anchors[unitID] = nil
        cache[unitID] = frame
    end

    return frame
end
