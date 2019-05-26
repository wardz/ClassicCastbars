local _, namespace = ...

namespace.channeledSpells = {
    -- MISC
    ['First Aid'] = 7, -- cast time in seconds,
    ['Gnomish Death Ray'] = 4,
    ['Cannibalize'] = 10,

    -- DRUID
    ['Hurricane'] = 9.5,
    ['Tranquility'] = 10,

    -- HUNTER
    ['Eagle Eye'] = 60,
    ['Eyes of the Beast'] = 60,
    ['Aimed Shot'] = 3, -- TODO: verify

    -- MAGE
    ['Arcane Missile'] = 2.5,
    ['Arcane Missiles'] = 4.5,
    ['Blizzard'] = 7.5,
    ['Evocation'] = 8,

    -- PRIEST
    ['Mind Flay'] = 3,
    ['Mind Vision'] = 30,
    ['Mind Control'] = 3,

    -- WARLOCK
    ['Drain Life'] = 4.5,
    ['Drain Mana'] = 4.5,
    ['Drain Soul'] = 14.5,
    ['Rain of Fire'] = 7.5,
    ['Health Funnel'] = 10,
}

namespace.defaultConfig = {
    version = "2", -- settings version, always bump this after adding new things

    nameplate = {
        enabled = true,
        position = { "CENTER", 15, -18 },
        width = 130,
        height = 11,
        showTimer = true,
        showSpellRank = false,
        autoPosition = false,
        simpleStyle = false,
        iconSize = 16,
    },

    target = {
        enabled = true,
        position = { "CENTER", -18, -87 },
        width = 150,
        height = 14,
        showTimer = true,
        showSpellRank = false,
        autoPosition = true,
        simpleStyle = false,
        iconSize = 16,
    },
}
