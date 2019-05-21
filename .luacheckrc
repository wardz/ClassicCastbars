std = "lua51"
max_line_length = false

ignore = {
    "11./SLASH_.*", -- Setting an undefined (Slash handler) global variable
    "213", -- Unused loop variable
    "212/self", -- Unused argument self
    "212/pool", -- Unused argument pool
}

globals = {
    "ClassicCastbarsDB",

    "SlashCmdList",
    "STANDARD_TEXT_FONT",
    "CreateFramePool",
    "CreateFrame",
    "wipe",
    "format",
    "GetTime",
    "UIParent",
    "strsplit",
}
