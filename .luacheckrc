std = "lua51"
max_line_length = false

ignore = {
    "11./SLASH_.*", -- Setting an undefined (Slash handler) global variable
    "213", -- Unused loop variable
    "212/self", -- Unused argument self
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
    "CopyTable",
    "GetLocale",
    "GetSpellSubtext",
    "GetSpellInfo",
    "IsAddOnLoaded",
    "GetAddOnMetadata",
    "GetSpellTexture",
    "UnitGUID",
    "strfind",
    "C_NamePlate",
    "C_Timer",
    "ResetCursor",
    "SetCursor",
    "SlashCmdList",
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
    "strsplit",
    "floor",
}
