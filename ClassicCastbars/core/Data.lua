local _, namespace = ...
local GetSpellInfo = _G.GetSpellInfo

-- Channeled spells does not return cast time, so we have to build our own list.
-- We use GetSpellInfo here to get the localized spell name,
-- that way we don't have to list every spellID for an ability (diff ranks have diff id)
namespace.channeledSpells = {
    -- MISC
    [GetSpellInfo(746)] = 7,        -- First Aid
    [GetSpellInfo(13278)] = 4,      -- Gnomish Death Ray
    [GetSpellInfo(20577)] = 10,     -- Cannibalize
    [GetSpellInfo(10797)] = 6,      -- Starshards

    -- DRUID
    [GetSpellInfo(17401)] = 9.5,    -- Hurricane
    [GetSpellInfo(740)] = 9.5,      -- Tranquility

    -- HUNTER
    [GetSpellInfo(6197)] = 60,      -- Eagle Eye
    [GetSpellInfo(1002)] = 60,      -- Eyes of the Beast
    [GetSpellInfo(20900)] = 3,      -- Aimed Shot
    [GetSpellInfo(1510)] = 6,       -- Volley

    -- MAGE
    [GetSpellInfo(5143)] = 4.5,     -- Arcane Missiles
    [GetSpellInfo(10)] = 7.5,       -- Blizzard
    [GetSpellInfo(12051)] = 8,      -- Evocation

    -- PRIEST
    [GetSpellInfo(15407)] = 3,      -- Mind Flay
    [GetSpellInfo(2096)] = 60,      -- Mind Vision
    [GetSpellInfo(605)] = 3,        -- Mind Control

    -- WARLOCK
    [GetSpellInfo(126)] = 45,       -- Eye of Kilrogg
    [GetSpellInfo(689)] = 4.5,      -- Drain Life
    [GetSpellInfo(5138)] = 4.5,     -- Drain Mana
    [GetSpellInfo(1120)] = 14.5,    -- Drain Soul
    [GetSpellInfo(5740)] = 7.5,     -- Rain of Fire
    [GetSpellInfo(1949)] = 15,      -- Hellfire
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

-- Spells that often have cast time reduced by talents.
namespace.castTimeTalentDecreases = {
    [GetSpellInfo(403)] = 1,        -- Lightning Bolt
    [GetSpellInfo(421)] = 1,        -- Chain Lightning
    [GetSpellInfo(6353)] = 2,       -- Soul Fire
    [GetSpellInfo(116)] = 0.5,      -- Frostbolt
--  [GetSpellInfo(133)] = 0.5,      -- Fireball
    [GetSpellInfo(686)] = 0.5,      -- Shadow Bolt
    [GetSpellInfo(348)] = 0.5,      -- Immolate
    [GetSpellInfo(331)] = 0.5,      -- Healing Wave
    [GetSpellInfo(585)] = 0.5,      -- Smite
    [GetSpellInfo(14914)] = 0.5,    -- Holy Fire
    [GetSpellInfo(2054)] = 0.5,     -- Heal
    [GetSpellInfo(25314)] = 0.5,    -- Greater Heal
    [GetSpellInfo(8129)] = 0.5,     -- Mana Burn
    [GetSpellInfo(5176)] = 0.5,     -- Wrath
    [GetSpellInfo(2912)] = 0.5,     -- Starfire
    [GetSpellInfo(5185)] = 0.5,     -- Healing Touch
    [GetSpellInfo(2645)] = 2,       -- Ghost Wolf
    [GetSpellInfo(691)] = 4,        -- Summon Felhunter
    [GetSpellInfo(688)] = 4,        -- Summon Imp
    [GetSpellInfo(697)] = 4,        -- Summon Voidwalker
    [GetSpellInfo(712)] = 4,        -- Summon Succubus
}

-- List of player crowd controls.
-- We want to stop the castbar when these auras are detected
-- as SPELL_CAST_FAILED is not triggered when a player gets CC'ed.
namespace.crowdControls = {
    [GetSpellInfo(5211)] = 1,       -- Bash
    [GetSpellInfo(24394)] = 1,      -- Intimidation
    [GetSpellInfo(853)] = 1,        -- Hammer of Justice
    [GetSpellInfo(22703)] = 1,      -- Inferno Effect (Summon Infernal)
    [GetSpellInfo(408)] = 1,        -- Kidney Shot
    [GetSpellInfo(12809)] = 1,      -- Concussion Blow
    [GetSpellInfo(20253)] = 1,      -- Intercept Stun
    [GetSpellInfo(20549)] = 1,      -- War Stomp
    [GetSpellInfo(2637)] = 1,       -- Hibernate
    [GetSpellInfo(3355)] = 1,       -- Freezing Trap
    [GetSpellInfo(19386)] = 1,      -- Wyvern Sting
    [GetSpellInfo(118)] = 1,        -- Polymorph
    [GetSpellInfo(28271)] = 1,      -- Polymorph: Turtle
    [GetSpellInfo(28272)] = 1,      -- Polymorph: Pig
    [GetSpellInfo(20066)] = 1,      -- Repentance
    [GetSpellInfo(1776)] = 1,       -- Gouge
    [GetSpellInfo(6770)] = 1,       -- Sap
    [GetSpellInfo(1513)] = 1,       -- Scare Beast
    [GetSpellInfo(8122)] = 1,       -- Psychic Scream
    [GetSpellInfo(2094)] = 1,       -- Blind
    [GetSpellInfo(5782)] = 1,       -- Fear
    [GetSpellInfo(5484)] = 1,       -- Howl of Terror
    [GetSpellInfo(6358)] = 1,       -- Seduction
    [GetSpellInfo(5246)] = 1,       -- Intimidating Shout
    [GetSpellInfo(6789)] = 1,       -- Death Coil
    [GetSpellInfo(9005)] = 1,       -- Pounce
    [GetSpellInfo(1833)] = 1,       -- Cheap Shot
    [GetSpellInfo(16922)] = 1,      -- Improved Starfire
    [GetSpellInfo(19410)] = 1,      -- Improved Concussive Shot
    [GetSpellInfo(12355)] = 1,      -- Impact
    [GetSpellInfo(20170)] = 1,      -- Seal of Justice Stun
    [GetSpellInfo(15269)] = 1,      -- Blackout
    [GetSpellInfo(18093)] = 1,      -- Pyroclasm
    [GetSpellInfo(12798)] = 1,      -- Revenge Stun
    [GetSpellInfo(5530)] = 1,       -- Mace Stun
    [GetSpellInfo(19503)] = 1,      -- Scatter Shot
    [GetSpellInfo(605)] = 1,        -- Mind Control
    [GetSpellInfo(7922)] = 1,       -- Charge Stun
    [GetSpellInfo(18469)] = 1,      -- Counterspell - Silenced
    [GetSpellInfo(15487)] = 1,      -- Silence
    [GetSpellInfo(18425)] = 1,      -- Kick - Silenced
    [GetSpellInfo(24259)] = 1,      -- Spell Lock
    [GetSpellInfo(18498)] = 1,      -- Shield Bash - Silenced

    -- ITEMS
    [GetSpellInfo(13327)] = 1,      -- Reckless Charge
    [GetSpellInfo(1090)] = 1,       -- Sleep
    [GetSpellInfo(5134)] = 1,       -- Flash Bomb Fear
    [GetSpellInfo(19821)] = 1,      -- Arcane Bomb Silence
    [GetSpellInfo(4068)] = 1,       -- Iron Grenade
    [GetSpellInfo(19769)] = 1,      -- Thorium Grenade
    [GetSpellInfo(13808)] = 1,      -- M73 Frag Grenade
    [GetSpellInfo(4069)] = 1,       -- Big Iron Bomb
    [GetSpellInfo(12543)] = 1,      -- Hi-Explosive Bomb
    [GetSpellInfo(4064)] = 1,       -- Rough Copper Bomb
    [GetSpellInfo(12421)] = 1,      -- Mithril Frag Bomb
    [GetSpellInfo(19784)] = 1,      -- Dark Iron Bomb
    [GetSpellInfo(4067)] = 1,       -- Big Bronze Bomb
    [GetSpellInfo(4066)] = 1,       -- Small Bronze Bomb
    [GetSpellInfo(4065)] = 1,       -- Large Copper Bomb
    [GetSpellInfo(13237)] = 1,      -- Goblin Mortar
    [GetSpellInfo(835)] = 1,        -- Tidal Charm
    [GetSpellInfo(13181)] = 1,      -- Gnomish Mind Control Cap
    [GetSpellInfo(12562)] = 1,      -- The Big One
    [GetSpellInfo(15283)] = 1,      -- Stunning Blow (Weapon Proc)
    [GetSpellInfo(56)] = 1,         -- Stun (Weapon Proc)
    [GetSpellInfo(26108)] = 1,      -- Glimpse of Madness
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
    version = "4", -- settings version, always bump this after adding new options
    pushbackDetect = false,
    locale = GetLocale(),

    nameplate = {
        enabled = true,
        position = { "CENTER", -5.5, -35 },
        width = 150,
        height = 14,
        showTimer = true,
        showCastInfoOnly = false,
        showSpellRank = false,
        autoPosition = false,
        simpleStyle = false,
        iconSize = 16,
        castFont = _G.STANDARD_TEXT_FONT,
        castFontSize = 10,
        castStatusBar = "Interface\\TargetingFrame\\UI-StatusBar",
        castBorder = "Interface\\CastingBar\\UI-CastingBar-Border-Small",
    },

    target = {
        enabled = true,
        position = { "CENTER", -18, -87 },
        width = 150,
        height = 14,
        showCastInfoOnly = false,
        showTimer = true,
        showSpellRank = false,
        autoPosition = true,
        simpleStyle = false,
        iconSize = 16,
        castFont = _G.STANDARD_TEXT_FONT,
        castFontSize = 10,
        castStatusBar = "Interface\\TargetingFrame\\UI-StatusBar",
        castBorder = "Interface\\CastingBar\\UI-CastingBar-Border-Small",
    },
}
