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

-- Player silence effects (not interrupts)
namespace.playerSilences = {
    [18469] = true, -- Counterspell - Silenced
    [18425] = true, -- Kick - Silenced
    [24259] = true, -- Spell Lock
    [15487] = true, -- Silence
    [34490] = CLIENT_IS_TBC or nil, -- Silencing Shot
}

-- Cast immunity auras that gives full interrupt protection
namespace.castImmunityBuffs = {
    [642] = true, -- Divine Shield (Rank 1)
    [1020] = true, -- Divine Shield (Rank 2)
    [13874] = true, -- Divine Shield (PvE)
    [498] = true, -- Divine Protection (Rank 1)
    [5573] = true, -- Divine Protection (Rank 2)
    [13007] = true, -- Divine Protection (PvE)
}

-- Cast immunity against physical classes only
if physicalClasses[select(2, UnitClass("player"))] then
    namespace.castImmunityBuffs[1022] = true -- Blessing of Protection (Rank 1)
    namespace.castImmunityBuffs[5599] = true -- Blessing of Protection (Rank 2)
    namespace.castImmunityBuffs[10278] = true -- Blessing of Protection (Rank 3)
    namespace.castImmunityBuffs[3169] = CLIENT_IS_CLASSIC_ERA or nil -- Limited Invulnerability Potion
else
    -- Cast immunity against magical classes only
    namespace.castImmunityBuffs[7121] = true -- Anti-Magic Shield (PvE 1)
    namespace.castImmunityBuffs[24021] = true -- Anti-Magic Shield (PvE 2)
    namespace.castImmunityBuffs[19645] = true -- Anti-Magic Shield (PvE 3)
    namespace.castImmunityBuffs[41451] = CLIENT_IS_TBC or nil -- Blessing of Spell Warding
end

-- Spells that can't be interrupted.
-- This table accepts both spellIDs and spellNames.
-- See also npcCastUninterruptibleCache in SavedVariables.lua for NPC tied spells.
namespace.uninterruptibleList = {
    [34120] = CLIENT_IS_TBC or nil, -- Steady Shot
    [19821] = true, -- Arcane Bomb
    [4068] = true, -- Iron Grenade
    [19769] = true, -- Thorium Grenade
    [13808] = true, -- M73 Frag Grenade
    [4069] = true, -- Big Iron Bomb
    [12543] = true, -- Hi-Explosive Bomb
    [4064] = true, -- Rough Copper Bomb
    [12421] = true, -- Mithril Frag Bomb
    [19784] = true, -- Dark Iron Bomb
    [4067] = true, -- Big Bronze Bomb
    [4066] = true, -- Small Bronze Bomb
    [4065] = true, -- Large Copper Bomb
    [4061] = true, -- Coarse Dynamite
    [4054] = true, -- Rough Dynamite
    [8331] = true, -- EZ-Thro Dynamite
    [23000] = true, -- EZ-Thro Dynamite II
    [4062] = true, -- Heavy Dynamite
    [23063] = true, -- Dense Dynamite
    [12419] = true, -- Solid Dynamite
    [13278] = true, -- Gnomish Death Ray
    [23041] = true, -- Call Anathema
    [20589] = true, -- Escape Artist
    [20549] = true, -- War Stomp
    [1510] = true, -- Volley
    [20904] = true, -- Aimed Shot
    [11605] = true, -- Slam
    [1804] = true, -- Pick Lock
    [1842] = true, -- Disarm Trap
    [2641] = true, -- Dismiss Pet
    [11202] = true, -- Crippling Poison
    [3421] = true, -- Crippling Poison II
    [2835] = true, -- Deadly Poison
    [2837] = true, -- Deadly Poison II
    [11355] = true, -- Deadly Poison III
    [11356] = true, -- Deadly Poison IV
    [25347] = true, -- Deadly Poison V
    [8681] = true, -- Instant Poison
    [8686] = true, -- Instant Poison II
    [8688] = true, -- Instant Poison III
    [11338] = true, -- Instant Poison IV
    [11339] = true, -- Instant Poison V
    [11343] = true, -- Instant Poison VI
    [5761] = true, -- Mind-numbing Poison
    [8693] = true, -- Mind-numbing Poison II
    [11399] = true, -- Mind-numbing Poison III
    [13220] = true, -- Wound Poison
    [13228] = true, -- Wound Poison II
    [13229] = true, -- Wound Poison III
    [13230] = true, -- Wound Poison IV
    [22999] = true, -- Defibrillate
    [746] = true, -- First Aid
    [20577] = true, -- Cannibalize
    [16075] = true, -- Throw Axe
    [6925] = true, -- Gift of the Xavian
    [4979] = true, -- Quick Flame Ward
    [4980] = true, -- Quick Frost Ward
    [8800] = true, -- Dynamite
    [7978] = true, -- Throw Dynamite
    [5106] = true, -- Crystal Flash
    [7279] = true, -- Black Sludge
    [13692] = true, -- Dire Growl
    [9612] = true, -- Ink Spray
    [22661] = true, -- Enervate
    [22421] = true, -- Massive Geyser
    [22662] = true, -- Wither
    [1050] = true, -- Sacrifice 1 (Non-English)
    [22651] = true, -- Sacrifice 2 (English)
    [22478] = true, -- Intense Pain
    [24189] = true, -- Force Punch
    [24314] = true, -- Threatening Gaze
    [24024] = true, -- Unstable Concoction
    [21188] = true, -- Stun Bomb Attack
    [22372] = true, -- Demon Portal
    [26102] = true, -- Sand Blast
    [25748] = true, -- Poison Stinger
    [21097] = true, -- Manastorm
    [785] = true, -- True Fulfillment
    [28615] = true, -- Spike Volley
    [28614] = true, -- Pointy Spike
    [28089] = true, -- Polarity Shift
    [28785] = true, -- Locust Swarm
    [18159] = true, -- Curse of the Fallen Magram

    -- Spells with duplicate versions/ranks that doesn't need to be tied to NPC ids
    [GetSpellInfo(10436)] = true,-- Attack (Totems)
    [GetSpellInfo(8858)] = true, -- Bomb
    [GetSpellInfo(9483)] = true, -- Boulder
    [GetSpellInfo(14146)] = true, -- Clone
    [GetSpellInfo(16594)] = true, -- Crypt Scarabs
    [GetSpellInfo(8995)] = true, -- Shoot
    [GetSpellInfo(2764)] = true, -- Throw
    [GetSpellInfo(1510)] = true, -- Volley
    [GetSpellInfo(18431)] = true, -- Bellowing Roar
    [GetSpellInfo(18500)] = true, -- Wing Buffet
    [GetSpellInfo(22539)] = true, -- Shadow Flame
    [GetSpellInfo(16868)] = true, -- Banshee Wail
    [GetSpellInfo(22479)] = true, -- Frost Breath
    [GetSpellInfo(26134)] = true, -- Eye Beam
    [GetSpellInfo(26103)] = true, -- Sweep
    [GetSpellInfo(30732)] = true, -- Worm Sweep
    [GetSpellInfo(15847)] = true, -- Tail Sweep
    [GetSpellInfo(7588)] = true, -- Void Bolt
    [GetSpellInfo(26381)] = true, -- Burrow
    [GetSpellInfo(27794)] = true, -- Cleave
    [GetSpellInfo(28995)] = true, -- Stoneskin
    [GetSpellInfo(28783)] = true, -- Impale
}

if CLIENT_IS_CLASSIC_ERA then
    namespace.uninterruptibleList[GetSpellInfo(2480)] = true -- Shoot Bow
    namespace.uninterruptibleList[GetSpellInfo(7918)] = true -- Shoot Gun
    namespace.uninterruptibleList[GetSpellInfo(7919)] = true -- Shoot Crossbow
elseif CLIENT_IS_TBC then
    namespace.uninterruptibleList[GetSpellInfo(29121)] = true -- Shoot Bow
    namespace.uninterruptibleList[GetSpellInfo(33808)] = true -- Shoot Gun
end
