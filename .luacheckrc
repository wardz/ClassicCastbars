std = "lua51"
max_line_length = false

ignore = {
    "11./SLASH_.*", -- Setting an undefined (Slash handler) global variable
    "113/CastingBarFrame_.*", -- Accessing an undefined (CastingBarFrame) global variable.
    "212/self", -- Unused argument self
    "212/pool",
    "212/cast",
    "213", -- Unused loop variable
}

not_globals = { "print" } -- just to help not forgetting to remove debug print statements

globals = {
    "ClassicCastbars_TestMode",
    "ClassicCastbarsDB",
    "ClassicCastbarsCharDB",
    "ClassicCastbars",
    "SlashCmdList",
    "CastingBarFrame",
    "TargetFrameSpellBar",
    "FocusFrameSpellBar",
}

read_globals = {
    "PlayerFrame_AdjustAttachments",
    "ArenaEnemyFrames",
    "LoadAddOn",
    "IsModifierKeyDown",
    "IsMetaKeyDown",
    "LibStub",
    "hooksecurefunc",
    "ReloadUI",
    "TargetFrame",
    "GetCVarBool",
    "CopyTable",
    "IsInGroup",
    "GetLocale",
    "GetSpellInfo",
    "IsAddOnLoaded",
    "GetAddOnMetadata",
    "GetSpellTexture",
    "UnitGUID",
    "strfind",
    "C_NamePlate",
    "C_Timer",
    "UnitExists",
    "STANDARD_TEXT_FONT",
    "UnitIsDeadOrGhost",
    "IsInRaid",
    "CreateFramePool",
    "DoEmote",
    "date",
    "CreateFrame",
    "wipe",
    "format",
    "GetTime",
    "UIParent",
    "floor",
    "UnitName",
    "UnitIsPlayer",
    "UnitClass",
    "RAID_CLASS_COLORS",
}
