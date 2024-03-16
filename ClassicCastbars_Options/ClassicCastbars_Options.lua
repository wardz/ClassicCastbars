local L = LibStub("AceLocale-3.0"):GetLocale("ClassicCastbars")
local LSM = LibStub("LibSharedMedia-3.0")

local isClassicEra = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC

local TEXT_POINTS = {
    ["CENTER"] = "CENTER",
    ["RIGHT"] = "RIGHT",
    ["LEFT"] = "LEFT",
}

local TEXT_OUTLINES = { -- font flags
    [""] = _G.DEFAULT,
    ["OUTLINE"] = "OUTLINE",
    ["THICK"] = "THICK",
    ["THICK,OUTLINE"] = "THICK OUTLINE",
    ["MONOCHROME"] = "MONOCHROME",
    ["MONOCHROME,OUTLINE"] = "MONOCHROME OUTLINE",
    ["MONOCHROME,THICK"] = "MONOCHROME THICK",
}

local CASTBAR_FRAME_STRATAS = {
    ["HIGH"] = "HIGH",
    ["MEDIUM"] = "MEDIUM",
    ["LOW"] = "LOW",
    ["BACKGROUND"] = "BACKGROUND",
}

local function GetLSMTable(lsmType)
    local tbl = CopyTable(LSM:HashTable(lsmType)) -- copy to prevent modifying LSM table

    -- Add custom media to LSM options that'll be used only in our addon.
    -- These are the default borders/fonts etc for ClassicCastbars
    if lsmType == "border" then
        tbl[_G.DEFAULT] = "Interface\\CastingBar\\UI-CastingBar-Border-Small"
        tbl[_G.DEFAULT .. " " .. _G.LARGE] = "Interface\\CastingBar\\UI-CastingBar-Border"
    elseif lsmType == "font" then
        tbl[_G.DEFAULT] = _G.STANDARD_TEXT_FONT
    end

    return tbl
end

local function GetLSMNameByTexture(lsmType, texturePath)
    for name, texture in pairs(GetLSMTable(lsmType)) do
        if texture == texturePath then
            return name
        end
    end
end

local function CreateUnitTabGroup(unitType, localizedUnit, order)
    local function ModuleIsDisabled()
        return not ClassicCastbars.db[unitType].enabled
    end

    local function GetStatusColoredEnableText()
        if ClassicCastbars.db[unitType].enabled then
            return "|cFF20C000" .. L.TOGGLE_CASTBAR .. "|r"
        else
            return "|cFFFF0000" .. L.TOGGLE_CASTBAR .. "|r"
        end
    end

    -- https://www.wowace.com/projects/ace3/pages/ace-config-3-0-options-tables
    return {
        name = format("%s %s", L.CASTBAR, localizedUnit),
        order = order,
        type = "group",
        get = function(info)
            return ClassicCastbars.db[unitType][info[3]]
        end,
        set = function(info, value)
            ClassicCastbars.db[unitType][info[3]] = value
            ClassicCastbars_TestMode:OnOptionChanged(unitType)
        end,

        args = {
            general = {
                order = 1,
                name = L.GENERAL,
                type = "group",
                inline = false,

                args = {
                    -- Keys here has to match savedvariables/db key names,
                    -- or else you have to set a new 'get' and 'set' func to override the main ones above
                    enabled = {
                        order = 1,
                        name = GetStatusColoredEnableText(),
                        desc = L.TOGGLE_CASTBAR_TOOLTIP,
                        width = "full", -- these have to be full to not truncate text in non-english locales
                        type = "toggle",
                        set = function(_, value)
                            ClassicCastbars.db[unitType].enabled = value
                            ClassicCastbars:ReleaseActiveFrames()
                        end,
                    },
                    showForFriendly = {
                        order = 2,
                        width = "full",
                        name = L.SHOW_FOR_FRIENDLY,
                        desc = "Note: does NOT work inside dungeons or raids due to Blizzard API limitations.",
                        type = "toggle",
                        disabled = ModuleIsDisabled,
                        hidden = unitType ~= "nameplate",
                    },
                    showForEnemy = {
                        order = 3,
                        width = "full",
                        name = L.SHOW_FOR_ENEMY,
                        type = "toggle",
                        disabled = ModuleIsDisabled,
                        hidden = unitType ~= "nameplate",
                    },
                    autoPosition = {
                        order = 4,
                        width = "full",
                        name = L.AUTO_POS_BAR,
                        desc = unitType ~= "player" and L.AUTO_POS_BAR_TOOLTIP or "",
                        type = "toggle",
                        hidden = unitType == "nameplate" or unitType == "party" or unitType == "arena",
                        disabled = ModuleIsDisabled,
                    },
                    showTimer = {
                        order = 5,
                        width = "full",
                        name = L.SHOW_TIMER,
                        desc = L.SHOW_TIMER_TOOLTIP,
                        type = "toggle",
                        disabled = ModuleIsDisabled,
                    },
                    showTotalTimer = {
                        order = 5,
                        width = "full",
                        name = L.SHOW_TOTAL_TIMER,
                        desc = L.SHOW_TOTAL_TIMER_TOOLTIP,
                        type = "toggle",
                        disabled = ModuleIsDisabled,
                    },
                    showSpark = {
                        order = 6,
                        width = "full",
                        name = L.SHOW_SPARK,
                        type = "toggle",
                        disabled = ModuleIsDisabled,
                    },
                    showBorderShield = {
                        order = 7,
                        width = "full",
                        name = L.BORDERSHIELD,
                        desc = L.BORDERSHIELD_TOOLTIP,
                        type = "toggle",
                        disabled = ModuleIsDisabled,
                        hidden = unitType == "player",
                    },
                    ignoreParentAlpha = {
                        order = 8,
                        width = "full",
                        name = L.IGNORE_PARENT_ALPHA,
                        desc = L.IGNORE_PARENT_ALPHA_TOOLTIP,
                        type = "toggle",
                        disabled = ModuleIsDisabled,
                        hidden = unitType == "player",
                    },
                    -- Position slider X for nameplate castbars only
                    posX = {
                        order = 9,
                        name = L.POS_X,
                        desc = L.POSXY_TOOLTIP,
                        width = 2,
                        type = "range",
                        min = -500,
                        max = 500,
                        step = 1,
                        bigStep = 5,
                        hidden = unitType ~= "nameplate",
                        get = function() return ClassicCastbars.db[unitType].position[2] end,
                        set = function(_, value)
                            ClassicCastbars.db[unitType].position[2] = value
                            local bar = ClassicCastbars.activeFrames["nameplate-testmode"]
                            if bar and bar.parent then
                                bar:SetPoint("CENTER", bar.parent, value, ClassicCastbars.db[unitType].position[3])
                            end
                        end,
                    },
                    -- Position slider Y for nameplate castbars only
                    posY = {
                        order = 10,
                        name = L.POS_Y,
                        desc = L.POSXY_TOOLTIP,
                        width = 2,
                        type = "range",
                        min = -500,
                        max = 500,
                        step = 1,
                        bigStep = 5,
                        hidden = unitType ~= "nameplate",
                        get = function()
                            return ClassicCastbars.db[unitType].position[3]
                        end,
                        set = function(_, value)
                            ClassicCastbars.db[unitType].position[3] = value
                            local bar = ClassicCastbars.activeFrames["nameplate-testmode"]
                            if bar and bar.parent then
                                bar:SetPoint("CENTER", bar.parent, ClassicCastbars.db[unitType].position[2], value)
                            end
                        end,
                    },
                },
            },

            ----------------------------------------------------
            -- Castbar Size Options Tab
            ----------------------------------------------------
            sizing = {
                order = 2,
                name = L.CASTBAR_SIZING,
                type = "group",
                inline = false,
                disabled = ModuleIsDisabled,

                args = {
                    width = {
                        order = 1,
                        name = L.WIDTH,
                        width = 2,
                        type = "range",
                        min = 1,
                        max = 500,
                        step = 1,
                        bigStep = 10,
                    },
                    height = {
                        order = 2,
                        name = L.HEIGHT,
                        width = 2,
                        type = "range",
                        min = 1,
                        max = 200,
                        step = 1,
                        bigStep = 10,
                    },
                    borderPaddingHeight = {
                        order = 3,
                        name = L.BORDER_PADDING_HEIGHT,
                        width = 2,
                        type = "range",
                        min = 0.001,
                        max = 5.0,
                        step = 0.001,
                        bigStep = 0.001,
                    },
                    borderPaddingWidth = {
                        order = 4,
                        name = L.BORDER_PADDING_WIDTH,
                        width = 2,
                        type = "range",
                        min = 0.001,
                        max = 5.0,
                        step = 0.001,
                        bigStep = 0.001,
                    },
                },
            },

            ----------------------------------------------------
            -- Castbar Icon Options Tab
            ----------------------------------------------------
            castIcon = {
                order = 3,
                name = L.CASTBAR_ICON,
                type = "group",
                inline = false,
                disabled = ModuleIsDisabled,

                args = {
                    showIcon = {
                        order = 1,
                        width = "full",
                        name = L.ICON_SHOW,
                        type = "toggle",
                    },
                    hideIconBorder = {
                        order = 2,
                        width = "full",
                        name = L.ICON_HIDE_BORDER,
                        type = "toggle",
                    },
                    iconSize = {
                        order = 3,
                        name = L.ICON_SIZE,
                        desc = L.ICON_SIZE_TOOLTIP,
                        type = "range",
                        width = "double",
                        min = 1,
                        max = 100,
                        bigStep = 1,
                    },
                    iconPositionX = {
                        order = 4,
                        name = L.POS_X,
                        desc = L.POSXY_TOOLTIP,
                        type = "range",
                        min = -200,
                        max = 200,
                        bigStep = 5,
                    },
                    iconPositionY = {
                        order = 5,
                        name = L.POS_Y,
                        desc = L.POSXY_TOOLTIP,
                        type = "range",
                        min = -200,
                        max = 200,
                        bigStep = 5,
                    },
                },
            },

            ----------------------------------------------------
            -- Castbar Color Options Tab
            ----------------------------------------------------
            colors = {
                order = 4,
                name = L.CASTBAR_COLORS,
                type = "group",
                inline = false,
                disabled = ModuleIsDisabled,
                get = function(info)
                    return unpack(ClassicCastbars.db[unitType][info[3]])
                end,
                set = function(info, r, g, b, a)
                    local cfg = ClassicCastbars.db[unitType][info[3]]
                    cfg[1] = r -- reuse table, ran very frequently
                    cfg[2] = g
                    cfg[3] = b
                    cfg[4] = a
                    ClassicCastbars_TestMode:OnOptionChanged(unitType)
                end,

                args = {
                    groupCastBarHeader = {
                        order = 0,
                        type = "header",
                        name = L.CASTBAR_COLORS,
                    },
                    borderColor = {
                        name = L.BORDER_COLOR,
                        order = 1,
                        width = 1.2,
                        hasAlpha = true,
                        type = "color",
                    },
                    textColor = {
                        name = L.TEXT_COLOR,
                        order = 2,
                        width = 1.2,
                        hasAlpha = true,
                        type = "color",
                    },
                    statusBackgroundColor = {
                        name = L.STATUS_BG_COLOR,
                        order = 3,
                        width = 1.2,
                        hasAlpha = true,
                        type = "color",
                    },
                    spacer = {
                        order = 4,
                        type = "description",
                        name = "\n\n\n",
                    },
                    groupCastFillHeader = {
                        order = 5,
                        type = "header",
                        name = L.CAST_FILL_HEADER,
                    },
                    statusColor = {
                        name = L.STATUS_COLOR,
                        order = 6,
                        width = 1.2,
                        hasAlpha = true,
                        type = "color",
                    },
                    statusColorSuccess = {
                        name = L.STATUS_SUCCESS_COLOR,
                        order = 7,
                        width = 1.2,
                        hasAlpha = true,
                        type = "color",
                    },
                    statusColorFailed = {
                        name = L.STATUS_FAILED_COLOR,
                        order = 8,
                        width = 1.2,
                        hasAlpha = true,
                        type = "color",
                    },
                    statusColorChannel = {
                        name = L.STATUS_CHANNEL_COLOR,
                        order = 9,
                        width = 1.2,
                        hasAlpha = true,
                        type = "color",
                    },
                    statusColorUninterruptible ={
                        name = L.STATUS_UNINTERRUPTIBLE_COLOR,
                        order = 10,
                        width = 1.2,
                        hasAlpha = true,
                        type = "color",
                    },
                },
            },

            ----------------------------------------------------
            -- Castbar Font Options Tab
            ----------------------------------------------------
            fonts = {
                order = 5,
                name = L.CASTBAR_FONTS,
                type = "group",
                inline = false,
                disabled = ModuleIsDisabled,

                args = {
                    castFontSize = {
                        order = 3,
                        name = L.FONT_SIZE,
                        desc = L.FONT_SIZE_TOOLTIP,
                        type = "range",
                        width = "double",
                        min = 1,
                        max = 50,
                        bigStep = 1,
                    },
                    textPositionX = {
                        order = 4,
                        name = L.POS_X,
                        desc = L.POSXY_TOOLTIP,
                        type = "range",
                        min = -300,
                        max = 300,
                        bigStep = 1,
                    },
                    textPositionY = {
                        order = 5,
                        name = L.POS_Y,
                        desc = L.POSXY_TOOLTIP,
                        type = "range",
                        min = -300,
                        max = 300,
                        bigStep = 1,
                    },
                    textPoint = {
                        order = 6,
                        name = L.TEXT_POINT,
                        type = "select",
                        values = TEXT_POINTS,
                    },
                    textOutline = {
                        order = 7,
                        name = L.TEXT_OUTLINE,
                        type = "select",
                        values = TEXT_OUTLINES,
                    },
                },
            },

            ----------------------------------------------------
            -- Castbar Textures Options Tab
            ----------------------------------------------------
            sharedMedia = {
                order = 6,
                name = L.CASTBAR_TEXTURE_FONT,
                type = "group",
                inline = false,
                disabled = ModuleIsDisabled,

                get = function(info)
                    if strfind(info.option.dialogControl or "", "LSM30_") then -- LibSharedMedia override
                        local type = strlower(info.option.dialogControl:gsub("LSM30_", "")) -- font, border, statusbar

                        return GetLSMNameByTexture(type, ClassicCastbars.db[unitType][info[3]])
                    end

                    return ClassicCastbars.db[unitType][info[3]]
                end,

                set = function(info, value)
                    if strfind(info.option.dialogControl or "", "LSM30_") then -- LibSharedMedia override
                        local type = strlower(info.option.dialogControl:gsub("LSM30_", "")) -- font, border, statusbar

                        -- We store the path instead of name so ClassicCastbars can still work
                        -- with LibSharedMedia/ClassicCastbars_Options disabled
                        ClassicCastbars.db[unitType][info[3]] = GetLSMTable(type)[value]
                    else
                        ClassicCastbars.db[unitType][info[3]] = value
                    end

                    ClassicCastbars_TestMode:OnOptionChanged(unitType)
                end,

                args = {
                    castFont = {
                        order = 1,
                        width = "double",
                        type = "select",
                        dialogControl = "LSM30_Font",
                        name = L.CAST_FONT,
                        desc = L.CAST_FONT_TOOLTIP,
                        values = GetLSMTable("font"),
                    },
                    spacer1 = {
                        order = 2,
                        type = "description",
                        name = "\n\n",
                    },
                    castStatusBar = {
                        order = 3,
                        width = "double",
                        type = "select",
                        dialogControl = "LSM30_Statusbar",
                        name = L.CAST_STATUSBAR,
                        desc = L.CAST_STATUSBAR_TOOLTIP,
                        values = GetLSMTable("statusbar"),
                    },
                    spacer2 = {
                        order = 4,
                        type = "description",
                        name = "\n\n",
                    },
                    castBorder = {
                        order = 5,
                        width = "double",
                        type = "select",
                        dialogControl = "LSM30_Border",
                        name = L.CAST_BORDER,
                        desc = L.CAST_BORDER_TOOLTIP,
                        values = GetLSMTable("border"),
                    },
                    edgeSizeLSM = {
                        order = 6,
                        name = L.EDGE_SIZE_LSM,
                        type = "range",
                        width = "double",
                        min = 3,
                        max = 32,
                        bigStep = 1,
                    },
                    spacer3 = {
                        order = 7,
                        type = "description",
                        name = "\n\n",
                    },
                    frameLevel = {
                        order = 8,
                        name = L.FRAME_LEVEL,
                        desc = L.FRAME_LEVEL_DESC,
                        type = "range",
                        min = 0,
                        max = 99,
                        bigStep = 5,
                    },
                    frameStrata = {
                        order = 9,
                        name = L.FRAME_STRATA,
                        desc = L.FRAME_STRATA_DESC,
                        type = "select",
                        values = CASTBAR_FRAME_STRATAS,
                    },
                },
           },

            ----------------------------------------------------
            -- Test Button
            ----------------------------------------------------
           testing = {
                order = -1,
                name = "",
                inline = true,
                type = "group",

                args = {
                    test = {
                        order = 1,
                        width = 1.4,
                        name = format("%s %s", L.TEST, localizedUnit),
                        desc = string.match(L.BORDERSHIELD_TOOLTIP, "|cffffff00(.*)|r"),
                        type = "execute",
                        disabled = ModuleIsDisabled,
                        func = function() ClassicCastbars_TestMode:ToggleCastbarMovable(unitType) end,
                    },
                    spacer = {
                        order = 2,
                        name = "\n",
                        type = "description",
                    },
                },
            },
        },
    }
end

local optionsTable
local function GetOptionsTable()
    optionsTable = optionsTable or { -- create table on demand
        type = "group",
        childGroups = "tab",
        name = "ClassicCastbars " .. GetAddOnMetadata("ClassicCastbars", "version"),

        args = {
            target = CreateUnitTabGroup("target", _G.TARGET, 1),
            nameplate = CreateUnitTabGroup("nameplate", _G.UNIT_NAMEPLATES, 2),
            party = CreateUnitTabGroup("party", _G.PARTY, 3),
            player = CreateUnitTabGroup("player", _G.PLAYER, 4),
            focus = not isClassicEra and CreateUnitTabGroup("focus", _G.FOCUS, 5) or nil,
            arena = not isClassicEra and CreateUnitTabGroup("arena", _G.ARENA, 6) or nil,

            resetAllSettings = {
                order = 7,
                name = L.RESET_ALL,
                type = "execute",
                confirm = function() return _G.CONFIRM_RESET_SETTINGS end,
                func = function()
                    ClassicCastbarsCharDB = {}
                    ClassicCastbarsDB = CopyTable(ClassicCastbars.defaultConfig)
                    ClassicCastbars.db = ClassicCastbarsDB
                    ClassicCastbars:ReleaseActiveFrames()
                end,
            },

            usePerCharacterSettings = {
                order = 8,
                width = 1.3,
                type = "toggle",
                name = L.PER_CHARACTER,
                desc = L.PER_CHARACTER_TOOLTIP,
                get = function() return ClassicCastbarsCharDB and ClassicCastbarsCharDB.usePerCharacterSettings end,
                set = function(_, value)
                    if not next(ClassicCastbarsCharDB or {}) then
                        ClassicCastbarsCharDB = CopyTable(ClassicCastbarsDB)
                    end
                    ClassicCastbarsCharDB.usePerCharacterSettings = value

                    ClassicCastbars:ReleaseActiveFrames()
                    ClassicCastbars:PLAYER_LOGIN()
                end,
            },
        },
    }

    return optionsTable
end

LibStub("AceConfig-3.0"):RegisterOptionsTable("ClassicCastbars", GetOptionsTable)
LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ClassicCastbars")
