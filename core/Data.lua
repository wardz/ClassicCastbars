local _, namespace = ...

namespace.channeledSpells = {
    -- MISC
    ['First Aid'] = 7,
    ['Gnomish Death Ray'] = 4,

    -- DRUID
    ['Hurricane'] = 9.5,
    ['Tranquility'] = 10,

    -- HUNTER
    ['Eagle Eye'] = 60,
    ['Eyes of the Beast'] = 60,

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
    version = "2",

    nameplate = {
        enabled = true,
        position = { "BOTTOMLEFT", 15, -18 },
        width = 150,
        height = 10,
    },

    target = {
        enabled = true,
        dynamicTargetPosition = true,
        position = { "BOTTOMLEFT", 25, -60 },
        width = 150,
        height = 10,
    }
}
