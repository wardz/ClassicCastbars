std = "lua51"
max_line_length = false

exclude_files = {
    "ClassicCastbars_Options/Libs/",
    "ClassicCastbars/Libs/",
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
    "SlashCmdList",
}

read_globals = {
    "WOW_PROJECT_ID",
    "WOW_PROJECT_CLASSIC",
    "WOW_PROJECT_BURNING_CRUSADE_CLASSIC",
    "WOW_PROJECT_MAINLINE",
    "UIParentBottomManagedFrameContainer",
    "CastingBarFrame",
    "PlayerCastingBarFrame",
    "TargetFrameSpellBar",
    "FocusFrameSpellBar",
    "PartyFrame",
    "EditModeManagerFrame",
    "ShowUIPanel",
    "HideUIPanel",
    "ArenaEnemyFrames",
    "C_NamePlate",
    "C_Timer",
    "CopyTable",
    "CreateFrame",
    "CreateFramePool",
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
    "IsInGroup",
    "IsMetaKeyDown",
    "IsModifierKeyDown",
    "LibStub",
    "LoadAddOn",
    "ReloadUI",
    "STANDARD_TEXT_FONT",
    "TargetFrame",
    "UIParent",
    "UnitClass",
    "UnitExists",
    "UnitGUID",
    "UnitIsPlayer",
    "wipe",
    "PlayerFrame_AdjustAttachments",
    "C_EventUtils",
    "GetNumGroupMembers",
    "LOSS_OF_CONTROL_DISPLAY_INTERRUPT_SCHOOL",
    "GetSchoolString",
    "UnitIsUnit",
    "UnitHealth",
    "UnitHealthMax",
    "UnitCastingInfo",
    "UnitChannelInfo",
    "UnitIsFriend",
    "strsplit",
    "C_AddOns",
    "C_Spell",
}
