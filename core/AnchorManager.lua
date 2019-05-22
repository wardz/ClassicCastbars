local _, namespace = ...
local AnchorManager = {}
namespace.AnchorManager = AnchorManager

local anchors = {
    target = {
        "SUFUnittarget",
        "XPerl_TargetportraitFrame",
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
        "TargetFrame", -- Blizzard frame should always be last
    },

    --[[party = {
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
    },]]
}

-- upvalues
local cache = {}
local _G = _G
local strmatch = _G.string.match
local format = _G.string.format
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
        if frame then return frame end
    end
end

function AnchorManager:GetAnchor(unitID, getDefault)
    if cache[unitID] and not getDefault then
        return cache[unitID]
    end

    local unitType, count = unitID:gsub("%d", "") -- party1 -> party

    if unitType == "nameplate" then
        --[[if unitID == "nameplate-testmode" then
            unitID = "target"
        end]]

        return GetNamePlateForUnit(unitID)
    end

    local frame = GetUnitFrameForUnit(unitType, unitID, count > 0)
    if frame and not getDefault then
        cache[unitID] = frame
    end

    return frame
end
