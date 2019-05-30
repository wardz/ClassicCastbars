local _, namespace = ...
local GetSpellInfo = _G.GetSpellInfo

-- Channeled spells does not return cast time, so we have to build our own list.
--
-- We use GetSpellInfo here to get the localized spell name,
-- that way we don't have to list every spellID for an ability (diff ranks have diff id)
namespace.channeledSpells = {
    -- MISC
    [GetSpellInfo(746)] = 7,        -- First Aid
    [GetSpellInfo(13278)] = 4,      -- Gnomish Death Ray
    [GetSpellInfo(20577)] = 10,     -- Cannibalize

    -- DRUID
    [GetSpellInfo(17401)] = 9.5,    -- Hurricane
    [GetSpellInfo(740)] = 9.5,      -- Tranquility

    -- HUNTER
    [GetSpellInfo(6197)] = 60,      -- Eagle Eye
    [GetSpellInfo(1002)] = 60,      -- Eyes of the Beast
    [GetSpellInfo(20900)] = 3,      -- Aimed Shot TODO: verify

    -- MAGE
    [GetSpellInfo(5143)] = 4.5,     -- Arcane Missiles
    [GetSpellInfo(10)] = 7.5,       -- Blizzard
    [GetSpellInfo(12051)] = 8,      -- Evocation

    -- PRIEST
    [GetSpellInfo(15407)] = 3,      -- Mind Flay
    [GetSpellInfo(2096)] = 60,      -- Mind Vision
    [GetSpellInfo(605)] = 3,        -- Mind Control

    -- WARLOCK
    [GetSpellInfo(689)] = 4.5,      -- Drain Life
    [GetSpellInfo(5138)] = 4.5,     -- Drain Mana
    [GetSpellInfo(1120)] = 14.5,    -- Drain Soul
    [GetSpellInfo(5740)] = 7.5,     -- Rain of Fire
    [GetSpellInfo(755)] = 10,       -- Health Funnel
}

-- List of abilities that makes cast time slower.
-- Spells here have different % reduction based on spell rank,
-- so list by spellID instead of name here so we can diff between ranks
namespace.castTimeDecreases = {
    -- WARLOCK
    [1714] = 50,    -- Curse of Tongues Rank 1
    [11719] = 60,   -- Curse of Tongues Rank 2

    -- ROGUE
    [5760] = 40,    -- Mind-Numbing Poison Rank 1
    [8692] = 50,    -- Mind-Numbing Poison Rank 2
    [25810] = 50,   -- Mind-Numbing Poison Rank 2 incorrect?
    [11398] = 60,   -- Mind-Numbing Poison Rank 3

    -- ITEMS
    [17331] = 10,   -- Fang of the Crystal Spider
}

--[[
namespace.castTimeIncreases = {
    -- HUNTER
    [GetSpellInfo(3045)] = 45,    -- Rapid Fire

    -- MAGE
    [GetSpellInfo(23723)] = 33,   -- Mind Quickening
}

namespace.pushbackImmunities = {
    -- PRIEST
    [GetSpellInfo(14743)] = 1, -- Focused Casting
}]]

-- Savedvariables
namespace.defaultConfig = {
    version = "2", -- settings version, always bump this after adding new things
    pushbackDetect = false,

    nameplate = {
        enabled = true,
        position = { "CENTER", -5.5, -35 },
        width = 150,
        height = 14,
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
