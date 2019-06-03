local L = LibStub("AceLocale-3.0"):GetLocale("ClassicCastbars")
local LSM = LibStub("LibSharedMedia-3.0")

local function CopyTable(src, dest)
    if type(dest) ~= "table" then dest = {} end
    if type(src) == "table" then
        for k, v in pairs(src) do
            if type(v) == "table" then
                v = CopyTable(v, dest[k])
            end
            dest[k] = v
        end
    end
    return dest
end

local function CreateUnitTabGroup(unitID, localizedUnit, order)
    local function GetLSMTable(lsmType)
        local tbl = CopyTable(LSM:HashTable(lsmType)) -- copy to prevent modifying LSM table

        local default
        if lsmType == "border" then
            default = "Interface\\CastingBar\\UI-CastingBar-Border-Small"
        elseif lsmType == "font" then
            local loc = GetLocale()
            default = loc == "zhCN" or loc == "zhTW" and "Fonts\\ARHei.ttf" or "Fonts\\2002.ttf"
        end

        tbl[L.DEFAULT] = default
        return tbl
    end

    local function GetLSMNameByTexture(lsmType, texturePath)
        for name, texture in pairs(GetLSMTable(lsmType)) do
            if texture == texturePath then
                return name
            end
        end
    end

    return {
        name = format("%s Castbar", localizedUnit),
        order = order,
        type = "group",
        get = function(info) return ClassicCastbarsDB[info[1]][info[3]] end, -- db.target.height for example
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
                        width = "full",
                        type = "toggle",
                        set = function(_, val)
                            ClassicCastbarsDB[unitID].enabled = val
                            ClassicCastbars:ToggleUnitEvents(true)
                        end,
                    },
                    showTimer = {
                        order = 2,
                        width = "full",
                        name = L.SHOW_TIMER,
                        desc = L.SHOW_TIMER_TOOLTIP,
                        type = "toggle",
                    },
                    autoPosition = {
                        order = 3,
                        width = "full",
                        name = L.AUTO_POS_BAR,
                        desc = L.AUTO_POS_BAR_TOOLTIP,
                        type = "toggle",
                        hidden = unitID == "nameplate"
                    },
                    showSpellRank = {
                        order = unitID == "target" and 4 or 5,
                        width = "full",
                        name = L.SHOW_RANK,
                        desc = L.SHOW_RANK_TOOLTIP,
                        type = "toggle",
                    },
                    pushbackDetect = {
                        order = unitID == "target" and 5 or 4,
                        width = "full",
                        name = L.PUSHBACK,
                        desc = L.PUSHBACK_TOOLTIP,
                        type = "toggle",
                        set = function(_, val) -- temp, we'll remove this later
                            ClassicCastbarsDB.pushbackDetect = val
                        end,
                        get = function() return ClassicCastbarsDB.pushbackDetect end,
                    },
                    simpleStyle = {
                        order = 6,
                        width = "full",
                        name = L.SIMPLE_STYLE,
                        desc = L.SIMPLE_STYLE_TOOLTIP,
                        type = "toggle",
                    },
                    testing = {
                        order = -1,
                        name = L.TEST_MODE,
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
            },

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
                        min = 50,
                        max = 300,
                        step = 1,
                        bigStep = 10,
                    },
                    height = {
                        order = 2,
                        name = L.HEIGHT,
                        desc = L.HEIGHT_TOOLTIP,
                        type = "range",
                        min = 4,
                        max = 50,
                        step = 1,
                        bigStep = 10,
                    },
                    iconSize = {
                        order = 2,
                        name = L.ICON_SIZE,
                        desc = L.ICON_SIZE_TOOLTIP,
                        type = "range",
                        min = 10,
                        max = 50,
                        step = 1,
                    },
                    castFontSize = {
                        order = 3,
                        name = L.FONT_SIZE,
                        desc = L.FONT_SIZE_TOOLTIP,
                        type = "range",
                        min = 6,
                        max = 30,
                        step = 1,
                    },
                },
            },

            sharedMedia = {
                order = 3,
                name = L.CASTBAR_TEXTURE_FONT,
                type = "group",
                inline = false,

                args = {
                    castFont = {
                        order = 1,
                        width = "double",
                        type = 'select',
                        dialogControl = 'LSM30_Font',
                        name = L.CAST_FONT,
                        desc = L.CAST_FONT_TOOLTIP,
                        values = GetLSMTable("font"),
                        get = function(info)
                            -- We store texture path in savedvariables so ClassicCastbars can still work without
                            -- LibSharedMedia or ClassicCastbars_Options loaded, but since LSM/SharedMediaWidgets
                            -- uses name instead of texture path internally for tables we have to loop and scan for it
                            return GetLSMNameByTexture("font", ClassicCastbarsDB[info[1]][info[3]])
                        end,
                        set = function(info, val)
                            ClassicCastbarsDB[info[1]][info[3]] = LSM:HashTable("font")[val]
                            ClassicCastbars_TestMode:OnOptionChanged(unitID)
                        end,
                    },
                    castStatusBar = {
                        order = 2,
                        width = "double",
                        type = 'select',
                        dialogControl = 'LSM30_Statusbar',
                        name = L.CAST_STATUSBAR,
                        desc = L.CAST_STATUSBAR_TOOLTIP,
                        values = GetLSMTable("statusbar"),
                        get = function(info)
                            return GetLSMNameByTexture("statusbar", ClassicCastbarsDB[info[1]][info[3]])
                        end,
                        set = function(info, val)
                            ClassicCastbarsDB[info[1]][info[3]] = LSM:HashTable("statusbar")[val]
                            ClassicCastbars_TestMode:OnOptionChanged(unitID)
                        end,
                    },
                    castBorder = {
                        order = 3,
                        width = "double",
                        type = 'select',
                        dialogControl = 'LSM30_Border',
                        name = L.CAST_BORDER,
                        desc = L.CAST_BORDER_TOOLTIP,
                        values = GetLSMTable("border"),
                        get = function(info)
                            return GetLSMNameByTexture("border", ClassicCastbarsDB[info[1]][info[3]])
                        end,
                        set = function(info, val)
                            if val == L.DEFAULT then
                                ClassicCastbarsDB[info[1]][info[3]] = "Interface\\CastingBar\\UI-CastingBar-Border-Small"
                            else
                                ClassicCastbarsDB[info[1]][info[3]] = LSM:HashTable("border")[val]
                            end
                            ClassicCastbars_TestMode:OnOptionChanged(unitID)
                        end,
                    },
                    notes = {
                        order = 4,
                        type = "description",
                        name = "Note: If you use a custom third-party texture/font and delete it later on from your PC, you'll need to manually reset the texture or font here.",
                    }
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
            -- party = CreateUnitTabGroup("party", 3),

            reset = {
                order = 3,
                name = L.RESET_ALL,
                type = "execute",
                confirm = true,
                func = function()
                    -- Reset savedvariables to default
                    ClassicCastbarsDB = CopyTable(ClassicCastbars.defaultConfig, ClassicCastbarsDB)
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
