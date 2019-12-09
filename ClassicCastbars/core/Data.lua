local _, namespace = ...
local GetSpellInfo = _G.GetSpellInfo

local castSpellIDs = {
    25262, -- Abomination Spit
    24334, -- Acid Spit
    6306, -- Acid Splash
    26419, -- Acid Spray
    12280, -- Acid of Hakkar
    8352, -- Adjust Attitude
    20904, -- Aimed Shot
    12248, -- Amplify Damage
    9482, -- Amplify Flames
    20777, -- Ancestral Spirit
    24168, -- Animist's Caress
    16991, -- Annihilator
    19645, -- Anti-Magic Shield
    13901, -- Arcane Bolt
    19821, -- Arcane Bomb
    11975, -- Arcane Explosion
    1450, -- Arcane Spirit II
    1451, -- Arcane Spirit III
    1452, -- Arcane Spirit IV
    1453, -- Arcane Spirit V
    25181, -- Arcane Weakness
    8000, -- Area Burn
    10418, -- Arugal spawn-in spell
    7124, -- Arugal's Gift
    25149, -- Arygos's Vengeance
    6422, -- Ashcrombe's Teleport
    6421, -- Ashcrombe's Unlock
    21332, -- Aspect of Neptulon
    556, -- Astral Recall
    10436, -- Attack
    8386, -- Attacking
    16629, -- Attuned Dampener
    17536, -- Awaken Kerlonian
    10258, -- Awaken Vault Warder
    12346, -- Awaken the Soulflayer
    18375, -- Aynasha's Arrow
    6753, -- Backhand
    13982, -- Bael'Gar's Fiery Essence
    23151, -- Balance of Light and Shadow
    5414, -- Balance of Nature
    5412, -- Balance of Nature Failure
    28299, -- Ball Lightning
    18647, -- Banish
    4130, -- Banish Burning Exile
    4131, -- Banish Cresting Exile
    4132, -- Banish Thundering Exile
    5884, -- Banshee Curse
    16868, -- Banshee Wail
    16051, -- Barrier of Light
    11759, -- Basilisk Sample
    1179, -- Beast Claws
    1849, -- Beast Claws II
    3133, -- Beast Claws III
    23677, -- Beasts Deck
    22686, -- Bellowing Roar
    8856, -- Bending Shinbone
    4067, -- Big Bronze Bomb
    7398, -- Birth
    23638, -- Black Amnesty
    20733, -- Black Arrow
    22719, -- Black Battlestrider
    27589, -- Black Grasp of the Destroyer
    7279, -- Black Sludge
    23639, -- Blackfury
    23652, -- Blackguard
    16978, -- Blazing Rapier
    16965, -- Bleakwood Hew
    16599, -- Blessing of Shahram
    6510, -- Blinding Powder
    15783, -- Blizzard
    3264, -- Blood Howl
    16986, -- Blood Talon
    11365, -- Bly's Band's Escape
    9143, -- Bomb
    1980, -- Bombard
    3015, -- Bombard II
    28280, -- Bombard Slime
    17014, -- Bone Shards
    23392, -- Boulder
    24006, -- Bounty of the Harvest
    7962, -- Break Big Stuff
    7437, -- Break Stuff
    4954, -- Break Tool
    18571, -- Breath
    28352, -- Breath of Sargeras
    8090, -- Bright Baubles
    7359, -- Bright Campfire
    17293, -- Burning Winds
    26381, -- Burrow
    20364, -- Bury Samuel's Remains
    27720, -- Buttermilk Delight
    23123, -- Cairne's Hoofprint
    23041, -- Call Anathema
    25167, -- Call Ancients
    23042, -- Call Benediction
    7487, -- Call Bleak Worg
    25166, -- Call Glyphs of Warding
    7489, -- Call Lupine Horror
    25159, -- Call Prismatic Barrier
    7488, -- Call Slavering Worg
    11654, -- Call of Sul'thraze
    11024, -- Call of Thund
    5137, -- Call of the Grave
    21249, -- Call of the Nether
    271, -- Call of the Void
    21648, -- Call to Ivus
    17501, -- Cannon Fire
    9095, -- Cantation of Manifestation
    27571, -- Cascade of Roses
    15120, -- Cenarion Beacon
    11085, -- Chain Bolt
    8211, -- Chain Burn
    10623, -- Chain Heal
    10605, -- Chain Lightning
    15549, -- Chained Bolt
    512, -- Chains of Ice
    11537, -- Charge Stave of Equinex
    16570, -- Charged Arcane Bolt
    22434, -- Charged Scale of Onyxia
    1538, -- Charging
    6648, -- Chestnut Mare
    3132, -- Chilling Breath
    22599, -- Chromatic Mantle of the Dawn
    24576, -- Chromatic Mount
    24973, -- Clean Up Stink Bomb
    27794, -- Cleave
    27890, -- Clone
    9002, -- Coarse Dynamite
    26167, -- Colossal Smash
    19720, -- Combine Pendants
    16781, -- Combining Charms
    21267, -- Conjure Altar of Summoning
    21646, -- Conjure Circle of Calling
    25813, -- Conjure Dream Rift
    21100, -- Conjure Elegant Letter
    28612, -- Conjure Food
    18831, -- Conjure Lily Root
    759, -- Conjure Mana Agate
    10053, -- Conjure Mana Citrine
    3552, -- Conjure Mana Jade
    10054, -- Conjure Mana Ruby
    19797, -- Conjure Torch of Retribution
    10140, -- Conjure Water
    28891, -- Consecrated Weapon
    5174, -- Cookie's Cooking
    23313, -- Corrosive Acid
    21047, -- Corrosive Acid Spit
    3396, -- Corrosive Poison
    20629, -- Corrosive Venom Spit
    18666, -- Corrupt Redpath
    25311, -- Corruption
    6619, -- Cowardly Flight Potion
    5403, -- Crash of Waves
    17951, -- Create Firestone
    17952, -- Create Firestone (Greater)
    6366, -- Create Firestone (Lesser)
    17953, -- Create Firestone (Major)
    28023, -- Create Healthstone
    11729, -- Create Healthstone (Greater)
    6202, -- Create Healthstone (Lesser)
    11730, -- Create Healthstone (Major)
    6201, -- Create Healthstone (Minor)
    20755, -- Create Soulstone
    20756, -- Create Soulstone (Greater)
    20752, -- Create Soulstone (Lesser)
    20757, -- Create Soulstone (Major)
    693, -- Create Soulstone (Minor)
    2362, -- Create Spellstone
    17727, -- Create Spellstone (Greater)
    17728, -- Create Spellstone (Major)
    14532, -- Creeper Venom
    2840, -- Creeping Anguish
    6278, -- Creeping Mold
    2838, -- Creeping Pain
    2841, -- Creeping Torment
    17496, -- Crest of Retribution
    11443, -- Cripple
    11202, -- Crippling Poison
    3421, -- Crippling Poison II
    3974, -- Crude Scope
    16594, -- Crypt Scarabs
    5106, -- Crystal Flash
    3635, -- Crystal Gaze
    30021, -- Crystal Infused Bandage
    30047, -- Crystal Throat Lozenge
    3636, -- Crystalline Slumber
    13399, -- Cultivate Packet of Seeds
    27552, -- Cupid's Arrow
    28133, -- Cure Disease
    8282, -- Curse of Blood
    18502, -- Curse of Hakkar
    7098, -- Curse of Mending
    16597, -- Curse of Shahram
    13524, -- Curse of Stalvan
    16247, -- Curse of Thorns
    3237, -- Curse of Thule
    17505, -- Curse of Timmy
    8552, -- Curse of Weakness
    18702, -- Curse of the Darkmaster
    13583, -- Curse of the Deadwood
    18159, -- Curse of the Fallen Magram
    16071, -- Curse of the Firebrand
    17738, -- Curse of the Plague Rat
    21048, -- Curse of the Tribes
    5267, -- Dalaran Wizard Disguise
    27723, -- Dark Desire
    19784, -- Dark Iron Bomb
    5268, -- Dark Iron Dwarf Disguise
    19775, -- Dark Mending
    7106, -- Dark Restore
    3335, -- Dark Sludge
    16587, -- Dark Whispers
    5514, -- Darken Vision
    23765, -- Darkmoon Faire Fortune
    16987, -- Darkspear
    3146, -- Daunting Growl
    16970, -- Dawn's Edge
    17045, -- Dawn's Gambit
    2835, -- Deadly Poison
    2837, -- Deadly Poison II
    11355, -- Deadly Poison III
    11356, -- Deadly Poison IV
    25347, -- Deadly Poison V
    12459, -- Deadly Scope
    7395, -- Deadmines Dynamite
    11433, -- Death & Decay
    6894, -- Death Bed
    5395, -- Death Capsule
    24161, -- Death's Embrace
    17481, -- Deathcharger
    7901, -- Decayed Agility
    13528, -- Decayed Strength
    12890, -- Deep Slumber
    5169, -- Defias Disguise
    22999, -- Defibrillate
    18559, -- Demon Pick
    22372, -- Demon Portal
    25793, -- Demon Summoning Torch
    23063, -- Dense Dynamite
    5140, -- Detonate
    9435, -- Detonation
    6700, -- Dimensional Portal
    13692, -- Dire Growl
    1842, -- Disarm Trap
    27891, -- Disease Buffet
    11397, -- Diseased Shot
    6907, -- Diseased Slime
    17745, -- Diseased Spit
    2641, -- Dismiss Pet
    25808, -- Dispel
    21954, -- Dispel Poison
    16613, -- Displacing Temporal Rift
    5099, -- Disruption
    15746, -- Disturb Rookery Egg
    6310, -- Divining Scroll Spell
    5017, -- Divining Trance
    20604, -- Dominate Mind
    17405, -- Domination
    16053, -- Dominion of Soul
    6805, -- Dousing
    12253, -- Dowse Eternal Flame
    11758, -- Dowsing
    16007, -- Draco-Incarcinatrix 900
    24815, -- Draw Ancient Glyphs
    19564, -- Draw Water Sample
    5219, -- Draw of Thistlenettle
    12304, -- Drawing Kit
    3368, -- Drink Minor Potion
    3359, -- Drink Potion
    8040, -- Druid's Slumber
    20436, -- Drunken Pit Crew
    26072, -- Dust Cloud
    8800, -- Dynamite
    513, -- Earth Elemental
    8376, -- Earthgrab Totem
    23650, -- Ebon Hand
    29335, -- Elderberry Pie
    11820, -- Electrified Net
    849, -- Elemental Armor
    19773, -- Elemental Fire
    877, -- Elemental Fury
    23679, -- Elementals Deck
    26636, -- Elune's Candle
    16533, -- Emberseer Start
    22647, -- Empower Pet
    7081, -- Encage
    4962, -- Encasing Webs
    6296, -- Enchant: Fiery Blaze
    16973, -- Enchanted Battlehammer
    20269, -- Enchanted Gaea Seed
    3443, -- Enchanted Quickness
    20513, -- Enchanted Resonite Crystal
    16798, -- Enchanting Lullaby
    27287, -- Energy Siphon
    22661, -- Enervate
    11963, -- Enfeeble
    27860, -- Engulfing Shadows
    3112, -- Enhance Blunt Weapon
    3113, -- Enhance Blunt Weapon II
    3114, -- Enhance Blunt Weapon III
    9903, -- Enhance Blunt Weapon IV
    16622, -- Enhance Blunt Weapon V
    8365, -- Enlarge
    12655, -- Enlightenment
    11726, -- Enslave Demon
    9853, -- Entangling Roots
    6728, -- Enveloping Winds
    20589, -- Escape Artist
    24302, -- Eternium Fishing Line
    23442, -- Everlook Transporter
    3233, -- Evil Eye
    12458, -- Evil God Counterspell
    28354, -- Exorcise Atiesh
    23208, -- Exorcise Spirits
    7896, -- Exploding Shot
    12719, -- Explosive Arrow
    6441, -- Explosive Shells
    15495, -- Explosive Shot
    24264, -- Extinguish
    26134, -- Eye Beam
    22909, -- Eye of Immol'thar
    126, -- Eye of Kilrogg
    21160, -- Eye of Sulfuras
    1002, -- Eyes of the Beast
    23000, -- Ez-Thro Dynamite
    6950, -- Faerie Fire
    8682, -- Fake Shot
    24162, -- Falcon's Call
    5262, -- Fanatic Blade
    6196, -- Far Sight
    6215, -- Fear
    457, -- Feeblemind
    509, -- Feeblemind II
    855, -- Feeblemind III
    12938, -- Fel Curse
    26086, -- Felcloth Bag
    3488, -- Felstrom Resurrection
    555, -- Feral Spirit
    968, -- Feral Spirit II
    8139, -- Fevered Fatigue
    8600, -- Fevered Plague
    22704, -- Field Repair Bot 74A
    6297, -- Fiery Blaze
    13900, -- Fiery Burst
    6250, -- Fire Cannon
    895, -- Fire Elemental
    134, -- Fire Shield
    184, -- Fire Shield II
    2601, -- Fire Shield III
    2602, -- Fire Shield IV
    13899, -- Fire Storm
    25177, -- Fire Weakness
    29332, -- Fire-toasted Bun
    10149, -- Fireball
    17203, -- Fireball Volley
    11763, -- Firebolt
    690, -- Firebolt II
    1084, -- Firebolt III
    1096, -- Firebolt IV
    25465, -- Firework
    26443, -- Firework Cluster Launcher
    7162, -- First Aid
    16601, -- Fist of Shahram
    23061, -- Fix Ritual Node
    7101, -- Flame Blast
    16396, -- Flame Breath
    16168, -- Flame Buffet
    6305, -- Flame Burst
    15575, -- Flame Cannon
    3356, -- Flame Lash
    22593, -- Flame Mantle of the Dawn
    6725, -- Flame Spike
    10733, -- Flame Spray
    15743, -- Flamecrack
    10854, -- Flames of Chaos
    12534, -- Flames of Retribution
    16596, -- Flames of Shahram
    11021, -- Flamespit
    10216, -- Flamestrike
    27608, -- Flash Heal
    19943, -- Flash of Light
    9092, -- Flesh Eating Worm
    14292, -- Fling Torch
    3678, -- Focusing
    24189, -- Force Punch
    22797, -- Force Reactive Disk
    8912, -- Forge Verigan's Fist
    18711, -- Forging
    28697, -- Forgiveness
    8435, -- Forked Lightning
    10849, -- Form of the Moonstalker (no invis)
    28324, -- Forming Frame of Atiesh
    23193, -- Forming Lok'delar
    23192, -- Forming Rhok'delar
    7054, -- Forsaken Skills
    29480, -- Fortitude of the Scourge
    18763, -- Freeze
    15748, -- Freeze Rookery Egg
    16028, -- Freeze Rookery Egg - Prototype
    11836, -- Freeze Solid
    19755, -- Frightalon
    3131, -- Frost Breath
    23187, -- Frost Burn
    22594, -- Frost Mantle of the Dawn
    3595, -- Frost Oil
    17460, -- Frost Ram
    25178, -- Frost Weakness
    8398, -- Frostbolt Volley
    16992, -- Frostguard
    6957, -- Frostmane Strength
    25840, -- Full Heal
    474, -- Fumble
    507, -- Fumble II
    867, -- Fumble III
    6405, -- Furbolg Form
    16997, -- Gargoyle Strike
    8901, -- Gas Bomb
    19470, -- Gem of the Serpent
    2645, -- Ghost Wolf
    6925, -- Gift of the Xavian
    23632, -- Girdle of the Dawn
    3143, -- Glacial Roar
    26105, -- Glare
    6974, -- Gnome Camera Connection
    12904, -- Gnomish Ham Radio
    23453, -- Gnomish Transporter
    12720, -- Goblin "Boom" Box
    7023, -- Goblin Camera Connection
    10837, -- Goblin Land Mine
    12722, -- Goblin Radio
    24967, -- Gong
    11434, -- Gong Zul'Farrak Gong
    22789, -- Gordok Green Grog
    22924, -- Grasping Vines
    25807, -- Great Heal
    15441, -- Greater Arcane Amalgamation
    24997, -- Greater Dispel
    25314, -- Greater Heal
    10228, -- Greater Invisibility
    24195, -- Grom's Tribute
    4153, -- Guile of the Raptor
    24266, -- Gurubashi Mojo Madness
    6982, -- Gust of Wind
    24239, -- Hammer of Wrath
    16988, -- Hammer of the Titans
    18762, -- Hand of Iruxos
    5166, -- Harvest Silithid Egg
    7277, -- Harvest Swarm
    16336, -- Haunting Phantoms
    7057, -- Haunting Spirits
    8812, -- Heal
    21885, -- Heal Vylestem Vine
    22458, -- Healing Circle
    4209, -- Healing Tongue
    4221, -- Healing Tongue II
    9888, -- Healing Touch
    4971, -- Healing Ward
    10396, -- Healing Wave
    11895, -- Healing Wave of Antu'sul
    8690, -- Hearthstone
    16995, -- Heartseeker
    4062, -- Heavy Dynamite
    30297, -- Heightened Senses
    711, -- Hellfire
    1124, -- Hellfire II
    2951, -- Hellfire III
    22566, -- Hex
    7655, -- Hex of Ravenclaw
    12543, -- Hi-Explosive Bomb
    18658, -- Hibernate
    15261, -- Holy Fire
    25292, -- Holy Light
    9481, -- Holy Smite
    10318, -- Holy Wrath
    24165, -- Hoodoo Hex
    14030, -- Hooked Net
    17928, -- Howl of Terror
    7481, -- Howling Rage
    23124, -- Human Orphan Whistle
    11760, -- Hyena Sample
    28163, -- Ice Guard
    16869, -- Ice Tomb
    28526, -- Icebolt
    11131, -- Icicle
    6741, -- Identify Brood
    23316, -- Ignite Flesh
    23054, -- Igniting Kroshius
    6487, -- Ilkrud's Guardians
    25309, -- Immolate
    10451, -- Implosion
    16996, -- Incendia Powder
    23308, -- Incinerate
    6234, -- Incineration
    27290, -- Increase Reputation
    4981, -- Inducing Vision
    1122, -- Inferno
    7739, -- Inferno Shell
    9612, -- Ink Spray
    16967, -- Inlaid Thorium Hammer
    8681, -- Instant Poison
    8686, -- Instant Poison II
    8688, -- Instant Poison III
    11338, -- Instant Poison IV
    11339, -- Instant Poison V
    11343, -- Instant Poison VI
    6651, -- Instant Toxin
    22478, -- Intense Pain
    6576, -- Intimidating Growl
    9478, -- Invis Placing Bear Trap
    885, -- Invisibility
    16746, -- Invulnerable Mail
    4068, -- Iron Grenade
    23140, -- J'eevee summons object
    23122, -- Jaina's Autograph
    9744, -- Jarkal's Translation
    11438, -- Join Map Fragments
    8348, -- Julie's Blessing
    9654, -- Jumping Lightning
    12684, -- Kadrak's Flag
    12512, -- Kalaran Conjures Torch
    3121, -- Kev
    10166, -- Khadgar's Unlocking
    22799, -- King of the Gordok
    18153, -- Kodo Kombobulator
    22790, -- Kreeg's Stout Beatdown
    4065, -- Large Copper Bomb
    4075, -- Large Seaforium Charge
    27146, -- Left Piece of Lord Valthalak's Amulet
    15463, -- Legendary Arcane Amalgamation
    10788, -- Leopard
    11534, -- Leper Cure!
    15402, -- Lesser Arcane Amalgamation
    2053, -- Lesser Heal
    27624, -- Lesser Healing Wave
    66, -- Lesser Invisibility
    8256, -- Lethal Toxin
    3243, -- Life Harvest
    9172, -- Lift Seal
    7364, -- Light Torch
    8598, -- Lightning Blast
    15207, -- Lightning Bolt
    20627, -- Lightning Breath
    6535, -- Lightning Cloud
    28297, -- Lightning Totem
    27871, -- Lightwell
    15712, -- Linken's Boomerang
    16729, -- Lionheart Helm
    5401, -- Lizard Bolt
    28785, -- Locust Swarm
    1536, -- Longshot II
    3007, -- Longshot III
    25247, -- Longsight
    26373, -- Lunar Invititation
    13808, -- M73 Frag Grenade
    10346, -- Machine Gun
    17117, -- Magatha Incendia Powder
    3659, -- Mage Sight
    20565, -- Magma Blast
    19484, -- Majordomo Teleport Visual
    10876, -- Mana Burn
    21097, -- Manastorm
    21960, -- Manifest Spirit
    18113, -- Manifestation Cleansing
    23304, -- Manna-Enriched Horse Feed
    15128, -- Mark of Flames
    12198, -- Marksman Hit
    4526, -- Mass Dispell
    25839, -- Mass Healing
    22421, -- Massive Geyser
    16993, -- Masterwork Stormhammer
    19814, -- Masterwork Target Dummy
    29134, -- Maypole
    7920, -- Mebok Smart Drink
    15057, -- Mechanical Patch Kit
    4055, -- Mechanical Squirrel
    11082, -- Megavolt
    21050, -- Melodious Rapture
    5159, -- Melt Ore
    16032, -- Merging Oozes
    25145, -- Merithra's Wake
    29333, -- Midsummer Sausage
    21154, -- Might of Ragnaros
    16600, -- Might of Shahram
    29483, -- Might of the Scourge
    10947, -- Mind Blast
    10912, -- Mind Control
    606, -- Mind Rot
    8272, -- Mind Tremor
    5761, -- Mind-numbing Poison
    8693, -- Mind-numbing Poison II
    11399, -- Mind-numbing Poison III
    23675, -- Minigun
    3611, -- Minion of Morganth
    3537, -- Minions of Malathrom
    5567, -- Miring Mud
    8138, -- Mirkfallon Fungus
    26218, -- Mistletoe
    12421, -- Mithril Frag Bomb
    12900, -- Mobile Alarm
    15095, -- Molten Blast
    5213, -- Molten Metal
    25150, -- Molten Rain
    20528, -- Mor'rogal Enchant
    14928, -- Nagmara's Love Potion
    25688, -- Narain!
    7967, -- Naralex's Nightmare
    25180, -- Nature Weakness
    16069, -- Nefarius Attack 001
    7673, -- Nether Gem
    8088, -- Nightcrawlers
    23653, -- Nightfall
    6199, -- Nostalgia
    7994, -- Nullify Mana
    16528, -- Numbing Pain
    11437, -- Opening Chest
    23125, -- Orcish Orphan Whistle
    26063, -- Ouro Submerge Visual
    8153, -- Owl Form
    16379, -- Ozzie Explodes
    471, -- Palamino Stallion
    16082, -- Palomino Stallion
    17176, -- Panther Cage Key
    8363, -- Parasite
    6758, -- Party Fever
    5668, -- Peasant Disguise
    5669, -- Peon Disguise
    11048, -- Perm. Illusion Bishop Tyriona
    11067, -- Perm. Illusion Tyrion
    27830, -- Persuader
    6461, -- Pick Lock
    16429, -- Piercing Shadow
    4982, -- Pillar Delving
    15728, -- Plague Cloud
    3429, -- Plague Mind
    28614, -- Pointy Spike
    21067, -- Poison Bolt
    11790, -- Poison Cloud
    25748, -- Poison Stinger
    5208, -- Poisoned Harpoon
    8275, -- Poisoned Shot
    4286, -- Poisonous Spit
    28089, -- Polarity Shift
    28271, -- Polymorph
    28270, -- Polymorph: Cow
    11419, -- Portal: Darnassus
    11416, -- Portal: Ironforge
    28148, -- Portal: Karazhan
    11417, -- Portal: Orgrimmar
    10059, -- Portal: Stormwind
    11420, -- Portal: Thunder Bluff
    11418, -- Portal: Undercity
    23680, -- Portals Deck
    7638, -- Potion Toss
    29467, -- Power of the Scourge
    23008, -- Powerful Seaforium Charge
    10850, -- Powerful Smelling Salts
    25841, -- Prayer of Elune
    25316, -- Prayer of Healing
    3109, -- Presence of Death
    24149, -- Presence of Might
    24164, -- Presence of Sight
    16058, -- Primal Leopard
    13912, -- Princess Summons Portal
    24167, -- Prophetic Aura
    7120, -- Proudmoore's Defense
    15050, -- Psychometry
    16072, -- Purify and Place Food
    22313, -- Purple Hands
    18809, -- Pyroblast
    3229, -- Quick Bloodlust
    4979, -- Quick Flame Ward
    4980, -- Quick Frost Ward
    9771, -- Radiation Bolt
    3387, -- Rage of Thule
    20568, -- Ragnaros Emerge
    4629, -- Rain of Fire
    28353, -- Raise Dead
    17235, -- Raise Undead Scarab
    5316, -- Raptor Feather
    5280, -- Razor Mane
    20748, -- Rebirth
    22563, -- Recall
    21950, -- Recite Words of Celebras
    4093, -- Reconstruction
    23254, -- Redeeming the Soul
    20773, -- Redemption
    22430, -- Refined Scale of Onyxia
    9858, -- Regrowth
    25952, -- Reindeer Dust Effect
    23180, -- Release Imp
    23136, -- Release J'eevee
    10617, -- Release Rageclaw
    17166, -- Release Umi's Yeti
    16502, -- Release Winna's Kitten
    12851, -- Release the Hounds
    16031, -- Releasing Corrupt Ooze
    6656, -- Remote Detonate
    22027, -- Remove Insignia
    8362, -- Renew
    11923, -- Repair the Blade of Heroes
    455, -- Replenish Spirit
    932, -- Replenish Spirit II
    29475, -- Resilience of the Scourge
    4961, -- Resupply
    20770, -- Resurrection
    30081, -- Retching Plague
    5161, -- Revive Dig Rat
    982, -- Revive Pet
    15591, -- Revive Ringo
    9614, -- Rift Beacon
    27738, -- Right Piece of Lord Valthalak's Amulet
    461, -- Righteous Flame On
    18540, -- Ritual of Doom
    18541, -- Ritual of Doom Effect
    698, -- Ritual of Summoning
    7720, -- Ritual of Summoning Effect
    1940, -- Rocket Blast
    15750, -- Rookery Whelp Spawn-in Spell
    26137, -- Rotate Trigger
    4064, -- Rough Copper Bomb
    20875, -- Rumsey Rum
    25804, -- Rumsey Rum Black Label
    25722, -- Rumsey Rum Dark
    25037, -- Rumsey Rum Light
    16980, -- Rune Edge
    3407, -- Rune of Opening
    20051, -- Runed Arcanite Rod
    21403, -- Ryson's All Seeing Eye
    21425, -- Ryson's Eye in the Sky
    10459, -- Sacrifice Spinneret
    27832, -- Sageblade
    19566, -- Salt Shaker
    26102, -- Sand Blast
    20716, -- Sand Breath
    3204, -- Sapper Explode
    6490, -- Sarilus's Elementals
    28161, -- Savage Guard
    14327, -- Scare Beast
    9232, -- Scarlet Resurrection
    15125, -- Scarshield Portal
    10207, -- Scorch
    11761, -- Scorpid Sample
    13630, -- Scraping
    7960, -- Scry on Azrethoc
    22949, -- Seal Felvine Shard
    9552, -- Searing Flames
    17923, -- Searing Pain
    6358, -- Seduction
    17196, -- Seeping Willow
    5407, -- Segra Darkthorn Effect
    9879, -- Self Destruct
    9575, -- Self Detonation
    18976, -- Self Resurrection
    16983, -- Serenity
    6270, -- Serpentine Cleansing
    6626, -- Set NG-5 Charge (Blue)
    6630, -- Set NG-5 Charge (Red)
    10955, -- Shackle Undead
    11661, -- Shadow Bolt
    14871, -- Shadow Bolt Misfire
    14887, -- Shadow Bolt Volley
    22979, -- Shadow Flame
    28165, -- Shadow Guard
    22596, -- Shadow Mantle of the Dawn
    1112, -- Shadow Nova II
    7136, -- Shadow Port
    17950, -- Shadow Portal
    9657, -- Shadow Shell
    25183, -- Shadow Weakness
    22681, -- Shadowblink
    7761, -- Shared Bonds
    2828, -- Sharpen Blade
    2829, -- Sharpen Blade II
    2830, -- Sharpen Blade III
    9900, -- Sharpen Blade IV
    16138, -- Sharpen Blade V
    22756, -- Sharpen Weapon - Critical
    11402, -- Shay's Bell
    3651, -- Shield of Reflection
    8087, -- Shiny Bauble
    28099, -- Shock
    1698, -- Shockwave
    2480, -- Shoot Bow
    7919, -- Shoot Crossbow
    7918, -- Shoot Gun
    25031, -- Shoot Missile
    25030, -- Shoot Rocket
    21559, -- Shredder Armor Melt
    10096, -- Shrink
    14227, -- Signing
    26069, -- Silence
    8137, -- Silithid Pox
    7077, -- Simple Teleport
    7078, -- Simple Teleport Group
    7079, -- Simple Teleport Other
    6469, -- Skeletal Miner Explode
    11605, -- Slam
    8809, -- Slave Drain
    1090, -- Sleep
    28311, -- Slime Bolt
    6530, -- Sling Dirt
    3650, -- Sling Mud
    3332, -- Slow Poison
    1056, -- Slow Poison II
    7992, -- Slowing Poison
    6814, -- Sludge Toxin
    4066, -- Small Bronze Bomb
    22967, -- Smelt Elementium
    10934, -- Smite
    27572, -- Smitten
    12460, -- Sniper Scope
    21935, -- SnowMaster 9000
    21848, -- Snowman
    8283, -- Snufflenose Command
    3206, -- Sol H
    3120, -- Sol L
    3205, -- Sol M
    3207, -- Sol U
    9901, -- Soothe Animal
    11016, -- Soul Bite
    17506, -- Soul Breaker
    17048, -- Soul Claim
    12667, -- Soul Consumption
    7295, -- Soul Drain
    17924, -- Soul Fire
    10771, -- Soul Shatter
    20762, -- Soulstone Resurrection
    5264, -- South Seas Pirate Disguise
    6252, -- Southsea Cannon Fire
    21027, -- Spark
    16447, -- Spawn Challenge to Urok
    3644, -- Speak with Heads
    31364, -- Spice Mortar
    28615, -- Spike Volley
    8016, -- Spirit Decay
    17680, -- Spirit Spawn-out
    3477, -- Spirit Steal
    17155, -- Sprinkling Purified Water
    3975, -- Standard Scope
    25298, -- Starfire
    10254, -- Stone Dwarf Awaken Visual
    28995, -- Stoneskin
    5265, -- Stonesplinter Trogg Disguise
    20685, -- Storm Bolt
    23510, -- Stormpike Battle Charger
    18163, -- Strength of Arko'narin
    4539, -- Strength of the Ages
    26181, -- Strike
    24245, -- String Together Heads
    16741, -- Stronghold Gauntlets
    7355, -- Stuck
    16497, -- Stun Bomb
    21188, -- Stun Bomb Attack
    26234, -- Submerge Visual
    15734, -- Summon
    23004, -- Summon Alarm-o-Bot
    10713, -- Summon Albino Snake
    23428, -- Summon Albino Snapjaw
    15033, -- Summon Ancient Spirits
    10685, -- Summon Ancona
    13978, -- Summon Aquementas
    22567, -- Summon Ar'lia
    12151, -- Summon Atal'ai Skeleton
    10696, -- Summon Azure Whelpling
    25849, -- Summon Baby Shark
    10714, -- Summon Black Kingsnake
    15794, -- Summon Blackhand Dreadweaver
    15792, -- Summon Blackhand Veteran
    17567, -- Summon Blood Parrot
    13463, -- Summon Bloodpetal Mini Pests
    10715, -- Summon Blue Racer
    8286, -- Summon Boar Spirit
    15048, -- Summon Bomb
    10673, -- Summon Bombay
    10699, -- Summon Bronze Whelpling
    10716, -- Summon Brown Snake
    17169, -- Summon Carrion Scarab
    23214, -- Summon Charger
    10680, -- Summon Cockatiel
    10681, -- Summon Cockatoo
    10688, -- Summon Cockroach
    15647, -- Summon Common Kitten
    10674, -- Summon Cornish Rex
    15648, -- Summon Corrupted Kitten
    10710, -- Summon Cottontail Rabbit
    10717, -- Summon Crimson Snake
    10697, -- Summon Crimson Whelpling
    8606, -- Summon Cyclonian
    4945, -- Summon Dagun
    10695, -- Summon Dark Whelpling
    10701, -- Summon Dart Frog
    9097, -- Summon Demon of the Orb
    17708, -- Summon Diablo
    25162, -- Summon Disgusting Oozeling
    23161, -- Summon Dreadsteed
    10705, -- Summon Eagle Owl
    12189, -- Summon Echeyakee
    11840, -- Summon Edana Hatetalon
    8677, -- Summon Effect
    10721, -- Summon Elven Wisp
    10869, -- Summon Embers
    10698, -- Summon Emerald Whelpling
    10700, -- Summon Faeling
    13548, -- Summon Farm Chicken
    691, -- Summon Felhunter
    5784, -- Summon Felsteed
    16531, -- Summon Frail Skeleton
    19561, -- Summon Gnashjaw
    13258, -- Summon Goblin Bomb
    10707, -- Summon Great Horned Owl
    10718, -- Summon Green Water Snake
    10683, -- Summon Green Wing Macaw
    7762, -- Summon Gunther's Visage
    27241, -- Summon Gurky
    10706, -- Summon Hawk Owl
    23432, -- Summon Hawksbill Snapjaw
    4950, -- Summon Helcular's Puppets
    30156, -- Summon Hippogryph Hatchling
    10682, -- Summon Hyacinth Macaw
    15114, -- Summon Illusionary Dreamwatchers
    6905, -- Summon Illusionary Nightmare
    8986, -- Summon Illusionary Phantasm
    17231, -- Summon Illusory Wraith
    688, -- Summon Imp
    12740, -- Summon Infernal Servant
    12199, -- Summon Ishamuhale
    10702, -- Summon Island Frog
    23811, -- Summon Jubling
    20737, -- Summon Karang's Banner
    23431, -- Summon Leatherback Snapjaw
    19772, -- Summon Lifelike Toad
    5110, -- Summon Living Flame
    23429, -- Summon Loggerhead Snapjaw
    20693, -- Summon Lost Amulet
    18974, -- Summon Lunaclaw
    7132, -- Summon Lupine Delusions
    27291, -- Summon Magic Staff
    18166, -- Summon Magram Ravager
    10675, -- Summon Maine Coon
    12243, -- Summon Mechanical Chicken
    18476, -- Summon Minion
    28739, -- Summon Mr. Wiggles
    25018, -- Summon Murki
    24696, -- Summon Murky
    4141, -- Summon Myzrael
    22876, -- Summon Netherwalker
    23430, -- Summon Olive Snapjaw
    17646, -- Summon Onyxia Whelp
    10676, -- Summon Orange Tabby
    23012, -- Summon Orphan
    17707, -- Summon Panda
    28505, -- Summon Poley
    10686, -- Summon Prairie Chicken
    10709, -- Summon Prairie Dog
    19774, -- Summon Ragnaros
    13143, -- Summon Razelikh
    3605, -- Summon Remote-Controlled Golem
    10719, -- Summon Ribbon Snake
    3363, -- Summon Riding Gryphon
    17618, -- Summon Risen Lackey
    15049, -- Summon Robot
    16381, -- Summon Rockwing Gargoyles
    15745, -- Summon Rookery Whelp
    10720, -- Summon Scarlet Snake
    12699, -- Summon Screecher Spirit
    10684, -- Summon Senegal
    12258, -- Summon Shadowcaster
    21181, -- Summon Shadowstrike
    3655, -- Summon Shield Guard
    16796, -- Summon Shy-Rotam
    10677, -- Summon Siamese
    10678, -- Summon Silver Tabby
    17204, -- Summon Skeleton
    11209, -- Summon Smithing Hammer
    16450, -- Summon Smolderweb
    10711, -- Summon Snowshoe Rabbit
    10708, -- Summon Snowy Owl
    6918, -- Summon Snufflenose
    13895, -- Summon Spawn of Bael'Gar
    28738, -- Summon Speedy
    3657, -- Summon Spell Guard
    11548, -- Summon Spider God
    3652, -- Summon Spirit of Old
    10712, -- Summon Spotted Rabbit
    15067, -- Summon Sprite Darter Hatchling
    712, -- Summon Succubus
    9461, -- Summon Swamp Ooze
    9636, -- Summon Swamp Spirit
    3722, -- Summon Syndicate Spectre
    28487, -- Summon Terky
    7076, -- Summon Tervosh's Minion
    3658, -- Summon Theurgist
    21180, -- Summon Thunderstrike
    5666, -- Summon Timberling
    23531, -- Summon Tiny Green Dragon
    23530, -- Summon Tiny Red Dragon
    26010, -- Summon Tranquil Mechanical Yeti
    20702, -- Summon Treant Allies
    12554, -- Summon Treasure Horde
    12564, -- Summon Treasure Horde Visual
    10704, -- Summon Tree Frog
    7949, -- Summon Viper
    697, -- Summon Voidwalker
    13819, -- Summon Warhorse
    17162, -- Summon Water Elemental
    28740, -- Summon Whiskers
    10679, -- Summon White Kitten
    10687, -- Summon White Plymouth Rock
    30152, -- Summon White Tiger Cub
    11017, -- Summon Witherbark Felhunter
    10703, -- Summon Wood Frog
    15999, -- Summon Worg Pup
    23152, -- Summon Xorothian Dreadsteed
    17709, -- Summon Zergling
    16590, -- Summon Zombie
    16473, -- Summoned Urok
    25186, -- Super Crystal
    15869, -- Superior Healing Ward
    26103, -- Sweep
    27722, -- Sweet Surprise
    8593, -- Symbol of Life
    24160, -- Syncretist's Sigil
    3718, -- Syndicate Bomb
    5266, -- Syndicate Disguise
    18969, -- Taelan Death
    17161, -- Taking Moon Well Sample
    9795, -- Talvash's Necklace Repair
    20041, -- Tammra Sapling
    2817, -- Teach Bark of Doom
    12521, -- Teleport from Azshara Tower
    12509, -- Teleport to Azshara Tower
    3565, -- Teleport: Darnassus
    3562, -- Teleport: Ironforge
    18960, -- Teleport: Moonglade
    3567, -- Teleport: Orgrimmar
    3561, -- Teleport: Stormwind
    3566, -- Teleport: Thunder Bluff
    3563, -- Teleport: Undercity
    6755, -- Tell Joke
    16378, -- Temperature Reading
    9456, -- Tharnariun Cure 1
    9457, -- Tharnariun's Heal
    12562, -- The Big One
    22989, -- The Breaking
    21953, -- The Feast of Winter Veil
    22990, -- The Forming
    19769, -- Thorium Grenade
    24649, -- Thousand Blades
    24314, -- Threatening Gaze
    5781, -- Threatening Growl
    16075, -- Throw Axe
    27662, -- Throw Cupid's Dart
    14814, -- Throw Dark Iron Ale
    7978, -- Throw Dynamite
    25004, -- Throw Nightmare Object
    4164, -- Throw Rock
    4165, -- Throw Rock II
    23312, -- Time Lapse
    25158, -- Time Stop
    6470, -- Tiny Bronze Key
    6471, -- Tiny Iron Key
    27829, -- Titanic Leggings
    29116, -- Toast Smorc
    29334, -- Toasted Smorc
    27739, -- Top Piece of Lord Valthalak's Amulet
    12511, -- Torch Combine
    6257, -- Torch Toss
    28806, -- Toss Fuel on Bonfire
    24706, -- Toss Stink Bomb
    3108, -- Touch of Death
    3263, -- Touch of Ravenclaw
    16554, -- Toxic Bolt
    7125, -- Toxic Saliva
    7951, -- Toxic Spit
    19877, -- Tranquilizing Shot
    7821, -- Transform Victim
    25146, -- Transmute: Elemental Fire
    4320, -- Trelane's Freezing Touch
    20804, -- Triage
    785, -- True Fulfillment
    10348, -- Tune Up
    10326, -- Turn Undead
    10340, -- Uldaman Boss Agro
    9577, -- Uldaman Key Staff
    11568, -- Uldaman Sub-Boss Agro
    20006, -- Unholy Curse
    3670, -- Unlock Maury's Foot
    10738, -- Unlocking
    24024, -- Unstable Concoction
    16562, -- Urok Minions Vanish
    19719, -- Use Bauble
    24194, -- Uther's Tribute
    7068, -- Veil of Shadow
    15664, -- Venom Spit
    6354, -- Venom's Bane
    27721, -- Very Berry Cream
    18115, -- Viewing Room Student Transform - Effect
    17529, -- Vitreous Focuser
    24163, -- Vodouisant's Vigilant Embrace
    21066, -- Void Bolt
    5252, -- Voidwalker Guardian
    18149, -- Volatile Infection
    16984, -- Volcanic Hammer
    1540, -- Volley
    3013, -- Volley II
    17009, -- Voodoo
    8277, -- Voodoo Hex
    17639, -- Wail of the Banshee
    3436, -- Wandering Plague
    20549, -- War Stomp
    23678, -- Warlord Deck
    16801, -- Warosh's Transform
    7383, -- Water Bubble
    9583, -- Water Sample
    6949, -- Weak Frostbolt
    7220, -- Weapon Chain
    7218, -- Weapon Counterweight
    11410, -- Whirling Barrage
    16724, -- Whitesoul Helm
    4520, -- Wide Sweep
    28732, -- Widow's Embrace
    9616, -- Wild Regeneration
    16598, -- Will of Shahram
    23339, -- Wing Buffet
    21736, -- Winterax Wisdom
    22662, -- Wither
    4974, -- Wither Touch
    25121, -- Wizard Oil
    28800, -- Word of Thawing
    30732, -- Worm Sweep
    13227, -- Wound Poison
    13228, -- Wound Poison II
    13229, -- Wound Poison III
    13230, -- Wound Poison IV
    9912, -- Wrath
    3607, -- Yenniku's Release
    24422, -- Zandalar Signet of Might
    24421, -- Zandalar Signet of Mojo
    24420, -- Zandalar Signet of Serenity
    1050, -- Sacrific
    22651, -- Sacrifice 2 (On German client this is named Opfern but other Sacrifice is named Opferung)
    10181, -- Frostbolt (needs to be last for chinese clients, see issue #16)

    -- Channeled casts in random order. These are used to retrieve spell icon later on (namespace.channeledSpells only stores spell name)
    -- Commented out IDs are duplicates that also has a normal cast already listed above.
    746, -- First Aid
    13278, -- Gnomish Death Ray
    20577, -- Cannibalize
    10797, -- Starshards
    16430, -- Soul Tap
    27640, -- Baron Rivendare's Soul Drain
    7290, -- Soul Siphon
    24322, -- Blood Siphon
    27177, -- Defile
    17401, -- Hurricane
    740, -- Tranquility
    20687, -- Starfall
    6197, -- Eagle Eye
    --1002, -- Eyes of the Beast
    --1510, -- Volley
    136, -- Mend Pet
    5143, -- Arcane Missiles
    --10, -- Blizzard
    12051, -- Evocation
    15407, -- Mind Flay
    2096, -- Mind Vision
    --605, -- Mind Control
    --126, -- Eye of Kilrogg
    689, -- Drain Life
    5138, -- Drain Mana
    1120, -- Drain Soul
    --5740, -- Rain of Fire
    1949, -- Hellfire
    755, -- Health Funnel
    17854, -- Consume Shadows
    --6358, -- Seduction Channel
}

local counter, cursor = 0, 1
local castedSpells = {}
namespace.castedSpells = castedSpells

-- TODO: cleanup
local function BuildSpellNameToSpellIDTable()
    counter = 0

    for i = cursor, #castSpellIDs do
        local spellName = GetSpellInfo(castSpellIDs[i])
        if spellName then
            castedSpells[spellName] = castSpellIDs[i]
        end

        cursor = i + 1
        counter = counter + 1
        if counter > 200 then
            break
        end
    end

    if cursor < #castSpellIDs then
        C_Timer.After(2, BuildSpellNameToSpellIDTable)
    else
        castSpellIDs = nil
    end
end

C_Timer.After(0.1, BuildSpellNameToSpellIDTable) -- run asap once the current call stack has executed

-- GetSpellInfo doesn't return any cast time for channeled casts
-- so we need to store the cast time ourself
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
    [GetSpellInfo(10)] = 8000,        -- Blizzard
    [GetSpellInfo(12051)] = 8000,     -- Evocation

    -- PRIEST
    [GetSpellInfo(15407)] = 3000,     -- Mind Flay
    [GetSpellInfo(2096)] = 60000,     -- Mind Vision
    [GetSpellInfo(605)] = 3000,       -- Mind Control

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

-- List of abilities that increases cast time (reduces speed)
-- Value here is the slow percentage.
namespace.castTimeIncreases = {
    -- ITEMS
    [17331] = 10,   -- Fang of the Crystal Spider

    -- NPCS
    [7127] = 20,    -- Wavering Will
    [7102] = 25,    -- Contagion of Rot
    [7103] = 25,    -- Contagion of Rot 2
    [3603] = 35,    -- Distracting Pain
    [8140] = 50,    -- Befuddlement
    [8272] = 20,    -- Mind Tremor
    [12255] = 15,   -- Curse of Tuten'kash
    [10651] = 20,   -- Curse of the Eye
    [14538] = 35,   -- Aural Shock
    [22247] = 80,   -- Suppression Aura
    [22642] = 50,   -- Brood Power: Bronze
    [23153] = 50,   -- Brood Power: Blue
    [24415] = 50,   -- Slow
    [19365] = 50,   -- Ancient Dread
    [28732] = 25,   -- Widow's Embrace
    [22909] = 50,   -- Eye of Immol'thar
    [13338] = 50,   -- Curse of Tongues
    [12889] = 50,   -- Curse of Tongues
    [15470] = 50,   -- Curse of Tongues
    [25195] = 75,   -- Curse of Tongues
    [10653] = 20,   -- Curse of the Eye

    -- WARLOCK
    [1714] = 50,    -- Curse of Tongues Rank 1
    [11719] = 60,   -- Curse of Tongues Rank 2
    [1098] = 30,    -- Enslave Demon Rank 1
    [11725] = 30,   -- Enslave Demon Rank 2
    [11726] = 30,   -- Enslave Demon Rank 3
    [20882] = 30,   -- Enslave Demon (NPC?)

    -- ROGUE
    [5760] = 40,    -- Mind-Numbing Poison Rank 1
    [8692] = 50,    -- Mind-Numbing Poison Rank 2
    [25810] = 50,   -- Mind-Numbing Poison Rank 2 incorrect?
    [11398] = 60,   -- Mind-Numbing Poison Rank 3
}

-- Store both spellID and spell name in this table since UnitAura returns spellIDs but combat log doesn't.
C_Timer.After(10, function()
    for spellID, slowPercentage in pairs(namespace.castTimeIncreases) do
        if GetSpellInfo(spellID) then
            namespace.castTimeIncreases[GetSpellInfo(spellID)] = slowPercentage
        end
    end
end)

-- Spells that often have cast time reduced by talents.
namespace.castTimeTalentDecreases = {
    [GetSpellInfo(403)] = 2000,      -- Lightning Bolt
    [GetSpellInfo(421)] = 1500,      -- Chain Lightning
    [GetSpellInfo(6353)] = 4000,     -- Soul Fire
    [GetSpellInfo(116)] = 2500,      -- Frostbolt
    [GetSpellInfo(133)] = 3000,      -- Fireball
    [GetSpellInfo(686)] = 2500,      -- Shadow Bolt
    [GetSpellInfo(348)] = 1500,      -- Immolate
    [GetSpellInfo(331)] = 2500,      -- Healing Wave
    [GetSpellInfo(585)] = 2000,      -- Smite
    [GetSpellInfo(14914)] = 3000,    -- Holy Fire
    [GetSpellInfo(2054)] = 2500,     -- Heal
    [GetSpellInfo(25314)] = 2500,    -- Greater Heal
    [GetSpellInfo(8129)] = 2500,     -- Mana Burn
    [GetSpellInfo(5176)] = 1500,     -- Wrath
    [GetSpellInfo(2912)] = 3000,     -- Starfire
    [GetSpellInfo(5185)] = 3000,     -- Healing Touch
    [GetSpellInfo(2645)] = 1000,     -- Ghost Wolf
    [GetSpellInfo(691)] = 6000,      -- Summon Felhunter
    [GetSpellInfo(688)] = 6000,      -- Summon Imp
    [GetSpellInfo(697)] = 6000,      -- Summon Voidwalker
    [GetSpellInfo(712)] = 6000,      -- Summon Succubus
    [GetSpellInfo(982)] = 4000,      -- Revive Pet
}

-- List of crowd controls.
-- We want to stop the castbar when these auras are detected
-- as SPELL_CAST_FAILED is not triggered when an unit gets CC'ed.
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
    [GetSpellInfo(2878)] = 1,       -- Turn Undead
    [GetSpellInfo(710)] = 1,        -- Banish

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
    [GetSpellInfo(8345)] = 1,       -- Control Machine (Gnomish Universal Remote trinket)
    [GetSpellInfo(13235)] = 1,      -- Forcefield Collapse (Gnomish Harm Prevention Belt)
    [GetSpellInfo(15753)] = 1,      -- Linken's Boomerang (trinket)
    [GetSpellInfo(15535)] = 1,      -- Enveloping Winds (Six Demon Bag trinket)
    [GetSpellInfo(28406)] = 1,      -- Polymorph Backfire
    [GetSpellInfo(16600)] = 1,      -- Might of Shahram (Blackblade of Shahram sword)
    [GetSpellInfo(13907)] = 1,      -- Smite Demon (Enchant Weapon - Demonslaying)
    [GetSpellInfo(15822)] = 1,      -- Dreamless Sleep Potion
    [GetSpellInfo(16053)] = 1,      -- Dominion of Soul (Orb of Draconic Energy)
    [GetSpellInfo(21330)] = 1,      -- Corrupted Fear (Deathmist Raiment set)

    -- NPCS
    [GetSpellInfo(3242)] = 1,       -- Ravage
    [GetSpellInfo(3271)] = 1,       -- Fatigued
    [GetSpellInfo(5708)] = 1,       -- Swoop
    [GetSpellInfo(11430)] = 1,      -- Slam
    [GetSpellInfo(17276)] = 1,      -- Scald
    [GetSpellInfo(18812)] = 1,      -- Knockdown
    [GetSpellInfo(3442)] = 1,       -- Enslave
    [GetSpellInfo(20683)] = 1,      -- Highlord's Justice
    [GetSpellInfo(17286)] = 1,      -- Crusader's Hammer
    [GetSpellInfo(3109)] = 1,       -- Presence of Death
    [GetSpellInfo(3143)] = 1,       -- Glacial Roar
    [GetSpellInfo(3263)] = 1,       -- Touch of Ravenclaw
    [GetSpellInfo(5106)] = 1,       -- Crystal Flash
    [GetSpellInfo(6266)] = 1,       -- Kodo Stomp
    [GetSpellInfo(6730)] = 1,       -- Head Butt
    [GetSpellInfo(6982)] = 1,       -- Gust of Wind
    [GetSpellInfo(7961)] = 1,       -- Azrethoc's Stomp
    [GetSpellInfo(8151)] = 1,       -- Surprise Attack
    [GetSpellInfo(3635)] = 1,       -- Crystal Gaze
    [GetSpellInfo(21188)] = 1,      -- Stun Bomb Attack
    [GetSpellInfo(16451)] = 1,      -- Judge's Gavel
    [GetSpellInfo(3589)] = 1,       -- Deafening Screech
    [GetSpellInfo(4320)] = 1,       -- Trelane's Freezing Touch
    [GetSpellInfo(6942)] = 1,       -- Overwhelming Stench
    [GetSpellInfo(8715)] = 1,       -- Terrifying Howl
    [GetSpellInfo(8817)] = 1,       -- Smoke Bomb
    [GetSpellInfo(25772)] = 1,      -- Mental Domination
    [GetSpellInfo(15859)] = 1,      -- Dominate Mind
    [GetSpellInfo(24753)] = 1,      -- Trick
    [GetSpellInfo(19408)] = 1,      -- Panic
    [GetSpellInfo(23364)] = 1,      -- Tail Lash
    [GetSpellInfo(19364)] = 1,      -- Ground Stomp
    [GetSpellInfo(19369)] = 1,      -- Ancient Despair
    [GetSpellInfo(19641)] = 1,      -- Pyroclast Barrage
    [GetSpellInfo(19393)] = 1,      -- Soul Burn
    [GetSpellInfo(20277)] = 1,      -- Fist of Ragnaros
    [GetSpellInfo(19780)] = 1,      -- Hand of Ragnaros
    [GetSpellInfo(18431)] = 1,      -- Bellowing Roar
    [GetSpellInfo(22289)] = 1,      -- Brood Power: Green
    [GetSpellInfo(22291)] = 1,      -- Brood Power: Bronze
    [GetSpellInfo(22561)] = 1,      -- Brood Power: Green
    [GetSpellInfo(19872)] = 1,      -- Calm Dragonkin
    [GetSpellInfo(22274)] = 1,      -- Greater Polymorph
    [GetSpellInfo(23310)] = 1,      -- Time Lapse
    [GetSpellInfo(23174)] = 1,      -- Chromatic Mutation
    [GetSpellInfo(23171)] = 1,      -- Time Stop (Brood Affliction: Bronze)
    [GetSpellInfo(22667)] = 1,      -- Shadow Command
    [GetSpellInfo(23603)] = 1,      -- Wild Polymorph
    [GetSpellInfo(23182)] = 1,      -- Mark of Frost
    [GetSpellInfo(25043)] = 1,      -- Aura of Nature
    [GetSpellInfo(24811)] = 1,      -- Draw Spirit
    [GetSpellInfo(25806)] = 1,      -- Creature of Nightmare
    [GetSpellInfo(6253)] = 1,       -- Backhand
    [GetSpellInfo(6466)] = 1,       -- Axe Toss
    [GetSpellInfo(8242)] = 1,       -- Shield Slam
    [GetSpellInfo(8285)] = 1,       -- Rampage
    [GetSpellInfo(6524)] = 1,       -- Ground Tremor
    [GetSpellInfo(6607)] = 1,       -- Lash
    [GetSpellInfo(7399)] = 1,       -- Terrify
    [GetSpellInfo(8150)] = 1,       -- Thundercrack
    [GetSpellInfo(11020)] = 1,      -- Petrify
    [GetSpellInfo(11641)] = 1,      -- Hex
    [GetSpellInfo(17307)] = 1,      -- Knockout
    [GetSpellInfo(16075)] = 1,      -- Throw Axe
    [GetSpellInfo(16104)] = 1,      -- Crystallize
    [GetSpellInfo(11836)] = 1,      -- Freeze Solid
    [GetSpellInfo(29419)] = 1,      -- Flash Bomb
    [GetSpellInfo(6304)] = 1,       -- Rhahk'Zor Slam
    [GetSpellInfo(6435)] = 1,       -- Smite Slam
    [GetSpellInfo(6432)] = 1,       -- Smite Stomp
    [GetSpellInfo(228)] = 1,        -- Polymorph: Chicken
    [GetSpellInfo(8040)] = 1,       -- Druid's Slumber
    [GetSpellInfo(7967)] = 1,       -- Naralex's Nightmare
    [GetSpellInfo(7139)] = 1,       -- Fel Stomp
    [GetSpellInfo(7621)] = 1,       -- Arugal's Curse
    [GetSpellInfo(7803)] = 1,       -- Thundershock
    [GetSpellInfo(7074)] = 1,       -- Screams of the Past
    [GetSpellInfo(8281)] = 1,       -- Sonic Burst
    [GetSpellInfo(8359)] = 1,       -- Left for Dead
    [GetSpellInfo(9256)] = 1,       -- Deep Sleep
    [GetSpellInfo(12946)] = 1,      -- Putrid Stench
    [GetSpellInfo(3636)] = 1,       -- Crystalline Slumber
    [GetSpellInfo(10093)] = 1,      -- Harsh Winds
    [GetSpellInfo(21808)] = 1,      -- Summon Shardlings
    [GetSpellInfo(21869)] = 1,      -- Repulsive Gaze
    [GetSpellInfo(12888)] = 1,      -- Cause Insanity
    [GetSpellInfo(12480)] = 1,      -- Hex of Jammal'an
    [GetSpellInfo(12890)] = 1,      -- Deep Slumber
    [GetSpellInfo(25774)] = 1,      -- Mind Shatter
    [GetSpellInfo(15471)] = 1,      -- Enveloping Web
    [GetSpellInfo(3609)] = 1,       -- Paralyzing Poison
    [GetSpellInfo(17492)] = 1,      -- Hand of Thaurissan
    [GetSpellInfo(14870)] = 1,      -- Drunken Stupor
    [GetSpellInfo(13902)] = 1,      -- Fist of Ragnaros
    [GetSpellInfo(6945)] = 1,       -- Chest Pains
    [GetSpellInfo(3551)] = 1,       -- Skull Crack
    [GetSpellInfo(15618)] = 1,      -- Snap Kick
    [GetSpellInfo(16508)] = 1,      -- Intimidating Roar
    [GetSpellInfo(16497)] = 1,      -- Stun Bomb
    [GetSpellInfo(17405)] = 1,      -- Domination
    [GetSpellInfo(16798)] = 1,      -- Enchanting Lullaby
    [GetSpellInfo(12734)] = 1,      -- Ground Smash
    [GetSpellInfo(17293)] = 1,      -- Burning Winds
    [GetSpellInfo(16869)] = 1,      -- Ice Tomb
    [GetSpellInfo(22856)] = 1,      -- Ice Lock
    [GetSpellInfo(16838)] = 1,      -- Banshee Shriek
}

-- Skip pushback calculation for these spells since they
-- have chance to ignore pushback when talented, or is always immune.
namespace.pushbackBlacklist = {
    [GetSpellInfo(1064)] = 1,       -- Chain Heal
    [GetSpellInfo(25357)] = 1,      -- Healing Wave
    [GetSpellInfo(8004)] = 1,       -- Lesser Healing Wave
    [GetSpellInfo(2061)] = 1,       -- Flash Heal
    [GetSpellInfo(2054)] = 1,       -- Heal
    [GetSpellInfo(2050)] = 1,       -- Lesser Heal
    [GetSpellInfo(596)] = 1,        -- Prayer of Healing
    [GetSpellInfo(2060)] = 1,       -- Greater Heal
    [GetSpellInfo(19750)] = 1,      -- Flash of Light
    [GetSpellInfo(635)] = 1,        -- Holy Light
    -- Druid heals are afaik many times not talented so ignoring them for now

    [GetSpellInfo(4068)] = 1,       -- Iron Grenade
    [GetSpellInfo(19769)] = 1,      -- Thorium Grenade
    [GetSpellInfo(13278)] = 1,      -- Gnomish Death Ray
    [GetSpellInfo(20589)] = 1,      -- Escape Artist
    [GetSpellInfo(20549)] = 1,      -- War Stomp
}

-- Casts that should be stopped on damage received
namespace.stopCastOnDamageList = {
    [GetSpellInfo(8690)] = 1, -- Hearthstone
    [GetSpellInfo(5784)] = 1, -- Summon Felsteed
    [GetSpellInfo(23161)] = 1, -- Summon Dreadsteed
    [GetSpellInfo(13819)] = 1, -- Summon Warhorse
    [GetSpellInfo(23214)] = 1, -- Summon Charger
    [GetSpellInfo(2006)] = 1, -- Resurrection
    [GetSpellInfo(2008)] = 1, -- Ancestral Spirit
    [GetSpellInfo(7328)] = 1, -- Redemption
    [GetSpellInfo(22999)] = 1, -- Defibrillate
    -- First Aid not included here since we track aura removed
}

namespace.unaffectedCastModsSpells = {
    -- Player Spells
    [11605] = 1, -- Slam
    [6651] = 1, -- Instant Toxin
    [1842] = 1, -- Disarm Trap
    [6461] = 1, -- Pick Lock
    [20904] = 1, -- Aimed Shot
    [2641] = 1, -- Dismiss Pet
    [2480] = 1, -- Shoot Bow
    [7918] = 1, -- Shoot Gun
    [20549] = 1, -- War Stomp
    [20589] = 1, -- Escape Artist
    [22027] = 1, -- Remove Insignia
    [6510] = 1, -- Blinding Powder
    [7355] = 1, -- Stuck

    -- NPCs and Others
    [2835] = 1, -- Deadly Poison
    [3131] = 1, -- Frost Breath
    [15664] = 1, -- Venom Spit
    [7068] = 1, -- Veil of Shadow
    [16247] = 1, -- Curse of Thorns
    [14030] = 1, -- Hooked Net
    [20716] = 1, -- Sand Breath
    [8275] = 1, -- Poisoned Shot
    [1980] = 1, -- Bombard
    [3015] = 1, -- Bombard II
    [1536] = 1, -- Longshot II
    [3007] = 1, -- Longshot III
    [1540] = 1, -- Volley
    [3013] = 1, -- Volley II
    [4164] = 1, -- Throw Rock
    [4165] = 1, -- Throw Rock II
    [3537] = 1, -- Minions of Malathrom
    [5567] = 1, -- Miring Mud
    [28352] = 1, -- Breath of Sargeras
    [7106] = 1, -- Dark Restore
    [4075] = 1, -- Large Seaforium Charge
    [5106] = 1, -- Crystal Flash
    [22979] = 1, -- Shadow Flame
    [3611] = 1, -- Minion of Morganth
    [27794] = 1, -- Cleave
    [25247] = 1, -- Longsight
    [5208] = 1, -- Poisoned Harpoon
    [14532] = 1, -- Creeper Venom
    [3132] = 1, -- Chilling Breath
    [3650] = 1, -- Sling Mud
    [3651] = 1, -- Shield of Reflection
    [3143] = 1, -- Glacial Roar
    [6296] = 1, -- Enchant: Fiery Blaze
    [24194] = 1, -- Uther's Tribute
    [7364] = 1, -- Light Torch
    [12684] = 1, -- Kadrak's Flag
    [7919] = 1, -- Shoot Crossbow
    [6907] = 1, -- Diseased Slime
    [3204] = 1, -- Sapper Explode
    [26234] = 1, -- Submerge Visual
    [26063] = 1, -- Ouro Submerge Visual
    [6925] = 1, -- Gift of the Xavian
    [7951] = 1, -- Toxic Spit
    [24195] = 1, -- Grom's Tribute
    [16554] = 1, -- Toxic Bolt
    [15495] = 1, -- Explosive Shot
    [6530] = 1, -- Sling Dirt
    [26072] = 1, -- Dust Cloud
    [5514] = 1, -- Darken Vision
    [11016] = 1, -- Soul Bite
    [21050] = 1, -- Melodious Rapture
    [4520] = 1, -- Wide Sweep
    [4526] = 1, -- Mass Dispell
    [6576] = 1, -- Intimidating Growl
    [20627] = 1, -- Lightning Breath
    [25793] = 1, -- Demon Summoning Torch
    [23254] = 1, -- Redeeming the Soul
    [18711] = 1, -- Forging
    [12198] = 1, -- Marksman Hit
    [8153] = 1, -- Owl Form
    [6626] = 1, -- Set NG-5 Charge (Blue)
    [6630] = 1, -- Set NG-5 Charge (Red)
    [30081] = 1, -- Retching Plague
    [6656] = 1, -- Remote Detonate
    [10254] = 1, -- Stone Dwarf Awaken Visual
    [3359] = 1, -- Drink Potion
    [17618] = 1, -- Summon Risen Lackey
    [8286] = 1, -- Summon Boar Spirit
    [17235] = 1, -- Raise Undead Scarab
    [8386] = 1, -- Attacking
    [28311] = 1, -- Slime Bolt
    [1698] = 1, -- Shockwave
    [23008] = 1, -- Powerful Seaforium Charge
    [6951] = 1, -- Decayed Strength
    [28732] = 1, -- Widow's Embrace
    [28995] = 1, -- Stoneskin
    [24706] = 1, -- Toss Stink Bomb
    [6257] = 1, -- Torch Toss
    [7359] = 1, -- Bright Campfire
    [16590] = 1, -- Summon Zombie
    [9612] = 1, -- Ink Spray
    [3436] = 1, -- Wandering Plague
    [9636] = 1, -- Summon Swamp Spirit
    [17204] = 1, -- Summon Skeleton
    [7896] = 1, -- Exploding Shot
    [23392] = 1, -- Boulder
    [7920] = 1, -- Mebok Smart Drink
    [8682] = 1, -- Fake Shot
    [28614] = 1, -- Pointy Spike
    [8016] = 1, -- Spirit Decay
    [26102] = 1, -- Sand Blast
    [3477] = 1, -- Spirit Steal
    [5395] = 1, -- Death Capsule
    [5159] = 1, -- Melt Ore
    [5403] = 1, -- Crash of Waves
    [8256] = 1, -- Lethal Toxin
    [6441] = 1, -- Explosive Shells
    [10850] = 1, -- Powerful Smelling Salts
    [3488] = 1, -- Felstrom Resurrection
    [10346] = 1, -- Machine Gun
    [12740] = 1, -- Summon Infernal Servant
    [6469] = 1, -- Skeletal Miner Explode
    [11397] = 1, -- Diseased Shot
    [4950] = 1, -- Summon Helcular's Puppets
    [8363] = 1, -- Parasite
    [16531] = 1, -- Summon Frail Skeleton
    [16072] = 1, -- Purify and Place Food
    [20629] = 1, -- Corrosive Venom Spit
    [28615] = 1, -- Spike Volley
    [19566] = 1, -- Salt Shaker
    [7901] = 1, -- Decayed Agility
    [7054] = 1, -- Forsaken Skills
    [24189] = 1, -- Force Punch
}

-- Addon Savedvariables
namespace.defaultConfig = {
    version = "14", -- settings version
    pushbackDetect = true,
    movementDetect = true,
    locale = GetLocale(),

    nameplate = {
        enabled = true,
        width = 106,
        height = 11,
        iconSize = 13,
        showCastInfoOnly = false,
        showTimer = false,
        showIcon = true,
        autoPosition = true,
        castFont = _G.STANDARD_TEXT_FONT,
        castFontSize = 8,
        castStatusBar = "Interface\\TargetingFrame\\UI-StatusBar",
        castBorder = "Interface\\CastingBar\\UI-CastingBar-Border-Small",
        hideIconBorder = false,
        position = { "CENTER", 7.3, -23.1 },
        iconPositionX = -3,
        iconPositionY = 0,
        borderColor = { 1, 0.796078431372549, 0, 1 },
        statusColor = { 1, 0.7, 0, 1 },
        statusColorChannel = { 0, 1, 0, 1 },
        textColor = { 1, 1, 1, 1 },
        textPositionX = 0,
        textPositionY = 0,
        frameLevel = 10,
        statusBackgroundColor = { 0, 0, 0, 0.535 },
    },

    target = {
        enabled = true,
        width = 150,
        height = 15,
        iconSize = 16,
        showCastInfoOnly = false,
        showTimer = false,
        showIcon = true,
        autoPosition = true,
        castFont = _G.STANDARD_TEXT_FONT,
        castFontSize = 10,
        castStatusBar = "Interface\\TargetingFrame\\UI-StatusBar",
        castBorder = "Interface\\CastingBar\\UI-CastingBar-Border-Small",
        hideIconBorder = false,
        position = { "CENTER", -18, -87 },
        iconPositionX = -5,
        iconPositionY = 0,
        borderColor = { 1, 1, 1, 1 },
        statusColor = { 1, 0.7, 0, 1 },
        statusColorChannel = { 0, 1, 0, 1 },
        textColor = { 1, 1, 1, 1 },
        textPositionX = 0,
        textPositionY = 0,
        frameLevel = 10,
        statusBackgroundColor = { 0, 0, 0, 0.535 },
    },

    party = {
        enabled = false,
        width = 120,
        height = 12,
        iconSize = 16,
        showCastInfoOnly = false,
        showTimer = false,
        showIcon = true,
        autoPosition = false,
        castFont = _G.STANDARD_TEXT_FONT,
        castFontSize = 9,
        castStatusBar = "Interface\\TargetingFrame\\UI-StatusBar",
        castBorder = "Interface\\CastingBar\\UI-CastingBar-Border",
        hideIconBorder = false,
        position = { "CENTER", 141, 6 },
        iconPositionX = -5,
        iconPositionY = 0,
        borderColor = { 1, 1, 1, 1 },
        statusColor = { 1, 0.7, 0, 1 },
        statusColorChannel = { 0, 1, 0, 1 },
        textColor = { 1, 1, 1, 1 },
        textPositionX = 0,
        textPositionY = 0,
        frameLevel = 10,
        statusBackgroundColor = { 0, 0, 0, 0.535 },
    },

    player = {
        enabled = false,
        width = 195,
        height = 20,
        iconSize = 22,
        showCastInfoOnly = false,
        showTimer = false,
        showIcon = true,
        autoPosition = true,
        castFont = _G.STANDARD_TEXT_FONT,
        castFontSize = 12,
        castStatusBar = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",
        castBorder = "Interface\\CastingBar\\UI-CastingBar-Border",
        hideIconBorder = false,
        position = { "CENTER", -18, -87 },
        iconPositionX = -10,
        iconPositionY = 0,
        borderColor = { 1, 1, 1, 1 },
        statusColor = { 1, 0.7, 0, 1 },
        statusColorChannel = { 0, 1, 0, 1 },
        textColor = { 1, 1, 1, 1 },
        textPositionX = 0,
        textPositionY = 0,
        frameLevel = 10,
        statusBackgroundColor = { 0, 0, 0, 0.535 },
    },
}
