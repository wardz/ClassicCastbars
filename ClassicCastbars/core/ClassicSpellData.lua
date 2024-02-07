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

-- Spells that can't be interrupted, not tied to npcIDs.
-- This table accepts both spellIDs and spellNames.
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
    [GetSpellInfo(7951)] = true, -- Toxic Spit
    [GetSpellInfo(7054)] = true, -- Forsaken Skills
}

if CLIENT_IS_CLASSIC_ERA then -- these ids only exists in classic era build
    namespace.uninterruptibleList[GetSpellInfo(2480)] = true -- Shoot Bow
    namespace.uninterruptibleList[GetSpellInfo(7918)] = true -- Shoot Gun
    namespace.uninterruptibleList[GetSpellInfo(7919)] = true -- Shoot Crossbow
    namespace.uninterruptibleList[GetSpellInfo(433797)] = true -- Bladestorm
    namespace.uninterruptibleList[GetSpellInfo(404373)] = true -- Bubble Beam
    namespace.uninterruptibleList[GetSpellInfo(404316)] = true -- Greater Frostbolt
    namespace.uninterruptibleList[GetSpellInfo(414370)] = true -- Aqua Shell
    namespace.uninterruptibleList[GetSpellInfo(407819)] = true -- Frost Arrow
    namespace.uninterruptibleList[GetSpellInfo(407568)] = true -- Freezing Arrow
elseif CLIENT_IS_TBC then
    namespace.uninterruptibleList[GetSpellInfo(29121)] = true -- Shoot Bow
    namespace.uninterruptibleList[GetSpellInfo(33808)] = true -- Shoot Gun
end

if CLIENT_IS_CLASSIC_ERA then
    -- NPC spells that can't be interrupted, tied to npcIDs unlike `uninterruptibleList` above.
    -- Atm this only accepts npcID + spellName, not spellIDs as idk the correct ones.
    namespace.npcID_uninterruptibleList = {
        ["12459" .. GetSpellInfo(25417)] = true, -- Blackwing Warlock Shadowbolt
        ["12264" .. GetSpellInfo(1449)] = true, -- Shazzrah Arcane Explosion
        ["11983" .. GetSpellInfo(18500)] = true, -- Firemaw Wing Buffet
        ["12265" .. GetSpellInfo(133)] = true, -- Lava Spawn Fireball
        ["10438" .. GetSpellInfo(116)] = true, -- Maleki the Pallid Frostbolt
        ["12465" .. GetSpellInfo(22425)] = true, -- Death Talon Wyrmkin Fireball Volley
        ["14020" .. GetSpellInfo(23310)] = true, -- Chromaggus Time Lapse
        ["14020" .. GetSpellInfo(23316)] = true, -- Chromaggus Ignite Flesh
        ["14020" .. GetSpellInfo(23309)] = true, -- Chromaggus Incinerate
        ["14020" .. GetSpellInfo(23187)] = true, -- Chromaggus Frost Burn
        ["14020" .. GetSpellInfo(23314)] = true, -- Chromaggus Corrosive Acid
        ["12468" .. GetSpellInfo(2120)] = true, -- Death Talon Hatcher Flamestrike
        ["13020" .. GetSpellInfo(9573)] = true, -- Vaelastrasz the Corrupt Flame Breath
        ["12435" .. GetSpellInfo(22425)] = true, -- Razorgore the Untamed Fireball Volley
        ["12118" .. GetSpellInfo(20604)] = true, -- Lucifron Dominate Mind
        ["10184" .. GetSpellInfo(9573)] = true, -- Onyxia Flame Breath
        ["10184" .. GetSpellInfo(133)] = true, -- Onyxia Fireball
        ["11492" .. GetSpellInfo(9616)] = true, -- Alzzin the Wildshaper Wild Regeneration
        ["11359" .. GetSpellInfo(16430)] = true, -- Soulflayer Soul Tap
        ["11372" .. GetSpellInfo(24011)] = true, -- Razzashi Adder Venom Spit
        ["14834" .. GetSpellInfo(24322)] = true, -- Hakkar Blood Siphon
        ["12259" .. GetSpellInfo(686)] = true, -- Gehennas Shadow Bolt
        ["14507" .. GetSpellInfo(14914)] = true, -- High Priest Venoxis Holy Fire
        ["12119" .. GetSpellInfo(20604)] = true, -- Flamewaker Protector Dominate Mind
        ["12557" .. GetSpellInfo(14515)] = true, -- Grethok the Controller Dominate Mind
        ["15276" .. GetSpellInfo(26006)] = true, -- Emperor Vek'lor Shadow Bolt
        ["12397" .. GetSpellInfo(15245)] = true, -- Lord Kazzak Shadow Bolt Volley
        ["14887" .. GetSpellInfo(16247)] = true, -- Ysondre Curse of Thorns
        ["15246" .. GetSpellInfo(11981)] = true, -- Qiraji Mindslayer Mana Burn
        ["15246" .. GetSpellInfo(17194)] = true, -- Qiraji Mindslayer Mind Blast
        ["15246" .. GetSpellInfo(22919)] = true, -- Qiraji Mindslayer Mind Flay
        ["15311" .. GetSpellInfo(26069)] = true, -- Anubisath Warder Silence
        ["15311" .. GetSpellInfo(11922)] = true, -- Anubisath Warder Entangling Roots
        ["15311" .. GetSpellInfo(12542)] = true, -- Anubisath Warder Fear
        ["15311" .. GetSpellInfo(26072)] = true, -- Anubisath Warder Dust Cloud
        ["15335" .. GetSpellInfo(21067)] = true, -- Flesh Hunter Poison Bolt
        ["15247" .. GetSpellInfo(11981)] = true, -- Qiraji Brainwasher Mana Burn
        ["15247" .. GetSpellInfo(16568)] = true, -- Qiraji Brainwasher Mind Flay
        ["11729" .. GetSpellInfo(19452)] = true, -- Hive'Zora Hive Sister Toxic Spit
        ["16146" .. GetSpellInfo(17473)] = true, -- Death Knight Raise Dead
        ["16368" .. GetSpellInfo(9081)] = true, -- Necropolis Acolyte Shadow Bolt Volley
        ["16022" .. GetSpellInfo(16568)] = true, -- Surgical Assistant Mind Flay
        ["16021" .. GetSpellInfo(1397)] = true, -- Living Monstrosity Fear
        ["16021" .. GetSpellInfo(1339)] = true, -- Living Monstrosity Chain Lightning
        ["16021" .. GetSpellInfo(28294)] = true, -- Living Monstrosity Lightning Totem
        ["16215" .. GetSpellInfo(1467)] = true, -- Unholy Staff Arcane Explosion
        ["16452" .. GetSpellInfo(1467)] = true, -- Necro Knight Guardian Arcane Explosion
        ["16452" .. GetSpellInfo(11829)] = true, -- Necro Knight Guardian Flamestrike
        ["16165" .. GetSpellInfo(1467)] = true, -- Necro Knight Arcane Explosion
        ["16165" .. GetSpellInfo(11829)] = true, -- Necro Knight Flamestrike
        ["8519" .. GetSpellInfo(16554)] = true, -- Blighted Surge Toxic Bolt
        ["212969" .. GetSpellInfo(429825)] = true, -- Kazragore Chain Lightning
        ["213334" .. GetSpellInfo(429168)] = true, -- Aku'mai Corrosive Blast
        ["213334" .. GetSpellInfo(429356)] = true, -- Aku'mai Void Blast
    }

    -- UnitChannelInfo() currently doesn't work in Classic Era 1.15.0, but the channel events still work for the current target.
    -- We use this table data to retrieve spell cast times inside the channel events.
    namespace.channeledSpells = {
        -- MISC
        [GetSpellInfo(746)] = 8000,      -- First Aid
        [GetSpellInfo(13278)] = 4000,    -- Gnomish Death Ray
        [GetSpellInfo(20577)] = 10000,   -- Cannibalize
        [GetSpellInfo(10797)] = 6000,    -- Starshards
        [GetSpellInfo(16430)] = 12000,   -- Soul Tap
        [GetSpellInfo(24323)] = 8000,    -- Blood Siphon
        [GetSpellInfo(27640)] = 3000,    -- Baron Rivendare's Soul Drain
        [GetSpellInfo(7290)] = 10000,    -- Soul Siphon
        [GetSpellInfo(24322)] = 8000,    -- Blood Siphon
        [GetSpellInfo(27177)] = 10000,   -- Defile
        [GetSpellInfo(27286)] = 1000,    -- Shadow Wrath (see issue #59)
        [GetSpellInfo(433797)] = 7000,   -- Bladestorm
        [GetSpellInfo(404373)] = 10000,  -- Bubble Beam
        [GetSpellInfo(407077)] = 3500,   -- Triple Chomp

        -- DRUID
        [GetSpellInfo(17401)] = 10000,   -- Hurricane
        [GetSpellInfo(740)] = 10000,     -- Tranquility
        [GetSpellInfo(20687)] = 10000,   -- Starfall

        -- HUNTER
        [GetSpellInfo(6197)] = 60000,     -- Eagle Eye
        [GetSpellInfo(1002)] = 60000,     -- Eyes of the Beast
        [GetSpellInfo(1510)] = 6000,      -- Volley
        [GetSpellInfo(136)] = 5000,       -- Mend Pet

        -- MAGE
        [GetSpellInfo(5143)] = 5000,      -- Arcane Missiles
        [GetSpellInfo(7268)] = 3000,      -- Arcane Missile
        [GetSpellInfo(10)] = 8000,        -- Blizzard
        [GetSpellInfo(12051)] = 8000,     -- Evocation
        [GetSpellInfo(401417)] = 3000,    -- Regeneration
        [GetSpellInfo(412510)] = 3000,    -- Mass Regeneration

        -- PRIEST
        [GetSpellInfo(15407)] = 3000,     -- Mind Flay
        [GetSpellInfo(2096)] = 60000,     -- Mind Vision
        [GetSpellInfo(605)] = 3000,       -- Mind Control
        [GetSpellInfo(402174)] = 2000,    -- Penance

        -- WARLOCK
        [GetSpellInfo(126)] = 45000,      -- Eye of Kilrogg
        [GetSpellInfo(689)] = 5000,       -- Drain Life
        [GetSpellInfo(5138)] = 5000,      -- Drain Mana
        [GetSpellInfo(1120)] = 15000,     -- Drain Soul
        [GetSpellInfo(5740)] = 8000,      -- Rain of Fire
        [GetSpellInfo(1949)] = 15000,     -- Hellfire
        [GetSpellInfo(755)] = 10000,      -- Health Funnel
        [GetSpellInfo(17854)] = 10000,    -- Consume Shadows
        [GetSpellInfo(6358)] = 15000,     -- Seduction Channel
    }
end
