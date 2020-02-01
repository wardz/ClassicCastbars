std = "lua51"
max_line_length = false

ignore = {
    "11./SLASH_.*", -- Setting an undefined (Slash handler) global variable
    "213", -- Unused loop variable
    "212/self", -- Unused argument self
    "113/CastingBarFrame_.*",
    "212/pool",
    "212/cast",
}

globals = {
    -- Addon globals
    "ClassicCastbars_TestMode",
    "ClassicCastbarsDB",
    "ClassicCastbars",
    "LibStub",

    -- WoW globals
    "hooksecurefunc",
    "ReloadUI",
    "UnitRace",
    "TargetFrame",
    "CastingBarFrame",
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
    "SlashCmdList",
    "UnitExists",
    "STANDARD_TEXT_FONT",
    "UnitIsDeadOrGhost",
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
