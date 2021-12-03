std = "lua51"
max_line_length = false

exclude_files = {
    "ClassicCastbars_Options/Libs/",
    ".luacheckrc",
}

ignore = {
    "11./SLASH_.*", -- Setting an undefined (Slash handler) global variable
    "113/CastingBarFrame_.*", -- Accessing an undefined (CastingBarFrame) global variable.
    "212/self", -- Unused argument self
    "212/pool",
    "212/cast",
    "213", -- Unused loop variable
}

not_globals = { "print" } -- force error on print() to help catch forgotten debug statements

globals = {
    "ClassicCastbars",
    "ClassicCastbars_TestMode",
    "ClassicCastbarsDB",
    "ClassicCastbarsCharDB",

    "CastingBarFrame",
    "TargetFrameSpellBar",
    "FocusFrameSpellBar",
    "SlashCmdList",
}

read_globals = {
    "ArenaEnemyFrames",
    "C_NamePlate",
    "C_Timer",
    "CopyTable",
    "CreateFrame",
    "CreateFramePool",
    "date",
    "DoEmote",
    "floor",
    "format",
    "GameMenuFrame",
    "GetAddOnMetadata",
    "GetCVarBool",
    "GetLocale",
    "GetSpellInfo",
    "GetSpellTexture",
    "GetTickTime",
    "GetTime",
    "hooksecurefunc",
    "IsAddOnLoaded",
    "IsAddOnLoadOnDemand",
    "IsInGroup",
    "IsInRaid",
    "IsMetaKeyDown",
    "IsModifierKeyDown",
    "LibStub",
    "LoadAddOn",
    "RAID_CLASS_COLORS",
    "ReloadUI",
    "STANDARD_TEXT_FONT",
    "strfind",
    "TargetFrame",
    "UIParent",
    "UnitClass",
    "UnitExists",
    "UnitGUID",
    "UnitIsDeadOrGhost",
    "UnitIsPlayer",
    "UnitName",
    "wipe",
    "PlayerFrame_AdjustAttachments",
}
