local L = LibStub("AceLocale-3.0"):GetLocale("ClassicCastbars")
local LSM = LibStub("LibSharedMedia-3.0")

local function GetLSMTable(lsmType)
    local tbl = CopyTable(LSM:HashTable(lsmType)) -- copy to prevent modifying LSM table

    -- Add custom media to LSM options that'll be used only in our addon.
    -- These are the default borders/fonts etc for ClassicCastbars
    if lsmType == "border" then
        tbl[L.DEFAULT] = "Interface\\CastingBar\\UI-CastingBar-Border-Small"
    elseif lsmType == "font" then
        tbl[L.DEFAULT] = _G.STANDARD_TEXT_FONT
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

local function CreateUnitTabGroup(unitID, localizedUnit, order)
    return {
        name = format("%s Castbar", localizedUnit), -- TODO: localize 'Castbar'
        order = order,
        type = "group",
        get = function(info)
            return ClassicCastbarsDB[info[1]][info[3]]
        end,
        set = function(info, value)
            ClassicCastbarsDB[info[1]][info[3]] = value -- db.unit.x = value
            ClassicCastbars_TestMode:OnOptionChanged(unitID)
        end,

        args = {
            general = {
                order = 1,
                name = L.GENERAL,
                type = "group",
                inline = false,

                args = {
                    -- keys here has to match savedvariables key
                    -- Or else you have to set a new 'get' and 'set' func
                    enabled = {
                        order = 1,
                        name = L.TOGGLE_CASTBAR,
                        desc = L.TOGGLE_CASTBAR_TOOLTIP,
                        width = "full", -- these have to be full to not truncate text in non-english locales
                        type = "toggle",
                        set = function(_, value)
                            ClassicCastbarsDB[unitID].enabled = value
                            ClassicCastbars:ToggleUnitEvents(true)
                        end,
                    },
                    autoPosition = {
                        order = 2,
                        width = "full",
                        name = L.AUTO_POS_BAR,
                        desc = L.AUTO_POS_BAR_TOOLTIP,
                        type = "toggle",
                        hidden = unitID == "nameplate"
                    },
                    showTimer = {
                        order = 3,
                        width = "full",
                        name = L.SHOW_TIMER,
                        desc = L.SHOW_TIMER_TOOLTIP,
                        type = "toggle",
                    },
                    showCastInfoOnly = {
                        order = 5,
                        width = "full",
                        name = L.SHOW_CAST_INFO_ONLY,
                        desc = L.SHOW_CAST_INFO_ONLY_TOOLTIP,
                        type = "toggle",
                    },
                    pushbackDetect = {
                        order = 6,
                        width = "full",
                        name = L.PUSHBACK,
                        desc = L.PUSHBACK_TOOLTIP,
                        type = "toggle",
                        set = function(_, value) -- temp, we'll remove this option later
                            ClassicCastbarsDB.pushbackDetect = value
                        end,
                        get = function() return ClassicCastbarsDB.pushbackDetect end,
                    },
                    simpleStyle = {
                        order = 7,
                        width = "full",
                        name = L.SIMPLE_STYLE,
                        desc = L.SIMPLE_STYLE_TOOLTIP,
                        type = "toggle",
                    },
                },
            },

            ----------------------------------------------------

            sizing = {
                order = 2,
                name = L.CASTBAR_SIZING,
                type = "group",
                inline = false,

                args = {
                    width = {
                        order = 1,
                        name = L.WIDTH,
                        desc = L.WIDTH_TOOLTIP,
                        type = "range",
                        min = 0.1,
                        max = 300,
                        step = 1,
                        bigStep = 10,
                    },
                    height = {
                        order = 2,
                        name = L.HEIGHT,
                        desc = L.HEIGHT_TOOLTIP,
                        type = "range",
                        min = 0.1,
                        max = 60,
                        step = 1,
                        bigStep = 10,
                    },
                    iconSize = {
                        order = 2,
                        name = L.ICON_SIZE,
                        desc = L.ICON_SIZE_TOOLTIP,
                        type = "range",
                        min = 0.1,
                        max = 60,
                        bigStep = 1,
                    },
                    castFontSize = {
                        order = 3,
                        name = L.FONT_SIZE,
                        desc = L.FONT_SIZE_TOOLTIP,
                        type = "range",
                        min = 6,
                        max = 30,
                        bigStep = 1,
                    },
                },
            },

            ----------------------------------------------------

            sharedMedia = {
                order = 3,
                name = L.CASTBAR_TEXTURE_FONT,
                type = "group",
                inline = false,

                args = {
                    castFont = {
                        order = 1,
                        width = "double",
                        type = "select",
                        dialogControl = "LSM30_Font",
                        name = L.CAST_FONT,
                        desc = L.CAST_FONT_TOOLTIP,
                        values = GetLSMTable("font"),
                        get = function(info)
                            -- We store texture path instead of name in savedvariables so ClassicCastbars can still work
                            -- without LibSharedMedia or ClassicCastbars_Options loaded
                            return GetLSMNameByTexture("font", ClassicCastbarsDB[info[1]][info[3]])
                        end,
                        set = function(info, value)
                            ClassicCastbarsDB[info[1]][info[3]] = GetLSMTable("font")[value]
                            ClassicCastbars_TestMode:OnOptionChanged(unitID)
                        end,
                    },
                    castStatusBar = {
                        order = 2,
                        width = "double",
                        type = "select",
                        dialogControl = "LSM30_Statusbar",
                        name = L.CAST_STATUSBAR,
                        desc = L.CAST_STATUSBAR_TOOLTIP,
                        values = GetLSMTable("statusbar"),
                        get = function(info)
                            return GetLSMNameByTexture("statusbar", ClassicCastbarsDB[info[1]][info[3]])
                        end,
                        set = function(info, value)
                            ClassicCastbarsDB[info[1]][info[3]] = LSM:HashTable("statusbar")[value]
                            ClassicCastbars_TestMode:OnOptionChanged(unitID)
                        end,
                    },
                    castBorder = {
                        order = 3,
                        width = "double",
                        type = "select",
                        dialogControl = "LSM30_Border",
                        name = L.CAST_BORDER,
                        desc = L.CAST_BORDER_TOOLTIP,
                        values = GetLSMTable("border"),
                        get = function(info)
                            return GetLSMNameByTexture("border", ClassicCastbarsDB[info[1]][info[3]])
                        end,
                        set = function(info, value)
                            ClassicCastbarsDB[info[1]][info[3]] = GetLSMTable("border")[value]
                            ClassicCastbars_TestMode:OnOptionChanged(unitID)
                        end,
                    },
                    notes = {
                        order = 4,
                        type = "description",
                        name = L.LSM_TEXTURE_NOTE,
                    },
                },
           },

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
                        desc = unitID == "target" and L.TEST_TARGET_TOOLTIP or L.TEST_PLATE_TOOLTIP,
                        type = "execute",
                        disabled = function() return not ClassicCastbarsDB[unitID].enabled end,
                        func = function()
                            ClassicCastbars_TestMode:ToggleCastbarMovable(unitID)
                        end,
                    },
                    notes = {
                        order = 2,
                        name = unitID == "target" and L.TEST_TARGET_TOOLTIP or L.TEST_PLATE_TOOLTIP,
                        type = "description",
                    },
                },
            },
        },
    }
end

local function GetOptionsTable()
    return { -- only create table on demand
        type = "group",
        childGroups = "tab",
        name = "ClassicCastbars " .. GetAddOnMetadata("ClassicCastbars", "version"),

        args = {
            target = CreateUnitTabGroup("target", L.TARGET, 1),
            nameplate = CreateUnitTabGroup("nameplate", L.NAMEPLATE, 2),

            resetAllSettings = {
                order = 3,
                name = L.RESET_ALL,
                type = "execute",
                confirm = true,
                func = function()
                    -- Reset savedvariables to default
                    ClassicCastbarsDB = CopyTable(ClassicCastbars.defaultConfig)
                    ClassicCastbars.db = ClassicCastbarsDB -- update pointer
                    ClassicCastbars_TestMode:OnOptionChanged("target")
                    ClassicCastbars_TestMode:OnOptionChanged("nameplate")
                end,
            },
        },
    }
end

-- Initialize option panel
LibStub("AceConfig-3.0"):RegisterOptionsTable("ClassicCastbars", GetOptionsTable)
LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ClassicCastbars")

-- Slash commands to open panel
SLASH_CLASSICCASTBARS1 = "/castbars"
SLASH_CLASSICCASTBARS2 = "/castbar"
SLASH_CLASSICCASTBARS3 = "/classiccastbars"
SLASH_CLASSICCASTBARS4 = "/classicastbars"
SlashCmdList["CLASSICCASTBARS"] = function()
    LibStub("AceConfigDialog-3.0"):Open("ClassicCastbars")
end
