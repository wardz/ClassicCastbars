local _, namespace = ...

local CLIENT_IS_TBC = WOW_PROJECT_ID == (WOW_PROJECT_BURNING_CRUSADE_CLASSIC or 5)
local CLIENT_IS_CLASSIC_ERA = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
if not CLIENT_IS_TBC and not CLIENT_IS_CLASSIC_ERA then return end

local physicalClasses = {
    ["WARRIOR"] = true,
    ["ROGUE"] = true,
    ["DRUID"] = true,
    ["HUNTER"] = true,
    ["PALADIN"] = true,
}

-- Player silence effects, not interrupts
namespace.playerSilences = {
    [GetSpellInfo(18469)] = 1, -- Counterspell - Silenced
    [GetSpellInfo(18425)] = 1, -- Kick - Silenced
    [GetSpellInfo(24259)] = 1, -- Spell Lock
    [GetSpellInfo(15487)] = 1, -- Silence
}
if CLIENT_IS_TBC then
    namespace.playerSilences[GetSpellInfo(34490)] = 1 -- Silencing Shot
end

-- Cast immunity auras that gives physical or magical interrupt protection
namespace.castImmunityBuffs = {
    [GetSpellInfo(642)] = true, -- Divine Shield
    [GetSpellInfo(498)] = true, -- Divine Protection
}

-- Immunity against physical classes only
if physicalClasses[select(2, UnitClass("player"))] then
    namespace.castImmunityBuffs[GetSpellInfo(1022)] = true -- Blessing of Protection

    if CLIENT_IS_CLASSIC_ERA then
        namespace.castImmunityBuffs[GetSpellInfo(3169)] = true -- Limited Invulnerability Potion
    end
else
    -- Immunity against magical classes only
    namespace.castImmunityBuffs[GetSpellInfo(24021)] = true -- Anti Magic Shield

    if CLIENT_IS_TBC then
        namespace.castImmunityBuffs[GetSpellInfo(41451)] = true -- Blessing of Spell Warding
    end
end

-- Spells that can't be interrupted
namespace.uninterruptibleList = {
    [GetSpellInfo(19821)] = 1,      -- Arcane Bomb
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
    [GetSpellInfo(4061)] = 1,       -- Coarse Dynamite
    [GetSpellInfo(4054)] = 1,       -- Rough Dynamite
    [GetSpellInfo(8331)] = 1,       -- EZ-Thro Dynamite
    [GetSpellInfo(23000)] = 1,      -- EZ-Thro Dynamite II
    [GetSpellInfo(4062)] = 1,       -- Heavy Dynamite
    [GetSpellInfo(23063)] = 1,      -- Dense Dynamite
    [GetSpellInfo(12419)] = 1,      -- Solid Dynamite
    [GetSpellInfo(13278)] = 1,      -- Gnomish Death Ray
    [GetSpellInfo(23041)] = 1,      -- Call Anathema
    [GetSpellInfo(20589)] = 1,      -- Escape Artist
    [GetSpellInfo(20549)] = 1,      -- War Stomp
    [GetSpellInfo(1510)] = 1,       -- Volley
    [GetSpellInfo(20904)] = 1,      -- Aimed Shot
    [GetSpellInfo(11605)] = 1,      -- Slam
    [GetSpellInfo(1804)] = 1,       -- Pick Lock
    [GetSpellInfo(1842)] = 1,       -- Disarm Trap
    [GetSpellInfo(2641)] = 1,       -- Dismiss Pet
    [GetSpellInfo(11202)] = 1,      -- Crippling Poison
    [GetSpellInfo(3421)] = 1,       -- Crippling Poison II
    [GetSpellInfo(2835)] = 1,       -- Deadly Poison
    [GetSpellInfo(2837)] = 1,       -- Deadly Poison II
    [GetSpellInfo(11355)] = 1,      -- Deadly Poison III
    [GetSpellInfo(11356)] = 1,      -- Deadly Poison IV
    [GetSpellInfo(25347)] = 1,      -- Deadly Poison V
    [GetSpellInfo(8681)] = 1,       -- Instant Poison
    [GetSpellInfo(8686)] = 1,       -- Instant Poison II
    [GetSpellInfo(8688)] = 1,       -- Instant Poison III
    [GetSpellInfo(11338)] = 1,      -- Instant Poison IV
    [GetSpellInfo(11339)] = 1,      -- Instant Poison V
    [GetSpellInfo(11343)] = 1,      -- Instant Poison VI
    [GetSpellInfo(5761)] = 1,       -- Mind-numbing Poison
    [GetSpellInfo(8693)] = 1,       -- Mind-numbing Poison II
    [GetSpellInfo(11399)] = 1,      -- Mind-numbing Poison III
    [GetSpellInfo(13227)] = 1,      -- Wound Poison
    [GetSpellInfo(13228)] = 1,      -- Wound Poison II
    [GetSpellInfo(13229)] = 1,      -- Wound Poison III
    [GetSpellInfo(13230)] = 1,      -- Wound Poison IV
    [GetSpellInfo(10436)] = 1,      -- Attack (Totems)

    -- these are technically uninterruptible but breaks on dmg
    [GetSpellInfo(22999)] = 1,      -- Defibrillate
    [GetSpellInfo(746)] = 1,        -- First Aid
    [GetSpellInfo(20577)] = 1,      -- Cannibalize

    -- NPC spells that doesn't need to be tied to npcIDs (see npcCastUninterruptibleCache)
    [GetSpellInfo(2764)] = 1, -- Throw
    [GetSpellInfo(8995)] = 1, -- Shoot
    [GetSpellInfo(6925)] = 1, -- Gift of the Xavian
    [GetSpellInfo(4979)] = 1, -- Quick Flame Ward
    [GetSpellInfo(4980)] = 1, -- Quick Frost Ward
    [GetSpellInfo(8800)] = 1, -- Dynamite
    [GetSpellInfo(8858)] = 1, -- Bomb
    [GetSpellInfo(9483)] = 1, -- Boulder
    [GetSpellInfo(5106)] = 1, -- Crystal Flash
    [GetSpellInfo(7279)] = 1, -- Black Sludge
    [GetSpellInfo(14146)] = 1, -- Clone
    [GetSpellInfo(13692)] = 1, -- Dire Growl
    [GetSpellInfo(9612)] = 1, -- Ink Spray
    [GetSpellInfo(16075)] = 1, -- Throw Axe
    [GetSpellInfo(16594)] = 1, -- Crypt Scarabs
}

if CLIENT_IS_TBC then
    namespace.uninterruptibleList[GetSpellInfo(34120)] = 1 -- Steady Shot
else
    namespace.uninterruptibleList[GetSpellInfo(2480)] = 1 -- Shoot Bow
    namespace.uninterruptibleList[GetSpellInfo(7918)] = 1 -- Shoot Gun
    namespace.uninterruptibleList[GetSpellInfo(7919)] = 1 -- Shoot Crossbow
end
