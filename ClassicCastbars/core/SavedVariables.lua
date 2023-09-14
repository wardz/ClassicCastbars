local _, namespace = ...

local CLIENT_IS_CLASSIC_ERA = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)

namespace.defaultConfig = {
    version = "35",
    locale = GetLocale(),
    npcCastUninterruptibleCache = {},
    npcCastTimeCache = {},
    usePerCharacterSettings = false,

    nameplate = {
        enabled = true,
        showForFriendly = true,
        showForEnemy = true,
        width = 106,
        height = 11,
        iconSize = 13,
        showBorderShield = true,
        showTimer = false,
        showIcon = true,
        showSpark = true,
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
        statusColorSuccess = { 0, 1, 0, 1 },
        statusColorFailed = { 1, 0, 0 },
        statusColorChannel = { 0, 1, 0, 1 },
        statusColorUninterruptible = { 0.7, 0.7, 0.7, 1 },
        textColor = { 1, 1, 1, 1 },
        textPositionX = 0,
        textPositionY = 0,
        textPoint = "CENTER",
        textOutline = "",
        frameLevel = 10,
        frameStrata = "HIGH",
        statusBackgroundColor = { 0, 0, 0, 0.535 },
        ignoreParentAlpha = false,
        borderPaddingHeight = 1.3,
        borderPaddingWidth = 1.17,
    },

    target = {
        enabled = true,
        width = 150,
        height = 15,
        iconSize = 18,
        showBorderShield = true,
        showTimer = false,
        showIcon = true,
        showSpark = true,
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
        statusColorSuccess = { 0, 1, 0, 1 },
        statusColorFailed = { 1, 0, 0 },
        statusColorChannel = { 0, 1, 0, 1 },
        statusColorUninterruptible = { 0.7, 0.7, 0.7, 1 },
        textColor = { 1, 1, 1, 1 },
        textPositionX = 0,
        textPositionY = 0,
        textPoint = "CENTER",
        textOutline = "",
        frameLevel = 10,
        frameStrata = "HIGH",
        statusBackgroundColor = { 0, 0, 0, 0.535 },
        ignoreParentAlpha = false,
        borderPaddingHeight = 1.3,
        borderPaddingWidth = 1.17,
    },

    focus = {
        enabled = true,
        width = 150,
        height = 15,
        iconSize = 18,
        showBorderShield = true,
        showTimer = false,
        showIcon = true,
        showSpark = true,
        autoPosition = CLIENT_IS_CLASSIC_ERA and false or true,
        castFont = _G.STANDARD_TEXT_FONT,
        castFontSize = 10,
        castStatusBar = "Interface\\TargetingFrame\\UI-StatusBar",
        castBorder = "Interface\\CastingBar\\UI-CastingBar-Border-Small",
        hideIconBorder = false,
        position = (CLIENT_IS_CLASSIC_ERA and { "TOPLEFT", 275, -260 } or { "CENTER", -19, -112 }),
        iconPositionX = -5,
        iconPositionY = 0,
        borderColor = { 1, 1, 1, 1 },
        statusColor = { 1, 0.7, 0, 1 },
        statusColorSuccess = { 0, 1, 0, 1 },
        statusColorFailed = { 1, 0, 0 },
        statusColorChannel = { 0, 1, 0, 1 },
        statusColorUninterruptible = { 0.7, 0.7, 0.7, 1 },
        textColor = { 1, 1, 1, 1 },
        textPositionX = 0,
        textPositionY = 0,
        textPoint = "CENTER",
        textOutline = "",
        frameLevel = 10,
        frameStrata = "HIGH",
        statusBackgroundColor = { 0, 0, 0, 0.535 },
        ignoreParentAlpha = false,
        borderPaddingHeight = 1.3,
        borderPaddingWidth = 1.17,
    },

    party = {
        enabled = false,
        width = 120,
        height = 12,
        iconSize = 18,
        showTimer = false,
        showBorderShield = true,
        showIcon = true,
        showSpark = true,
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
        statusColorSuccess = { 0, 1, 0, 1 },
        statusColorFailed = { 1, 0, 0 },
        statusColorChannel = { 0, 1, 0, 1 },
        statusColorUninterruptible = { 0.7, 0.7, 0.7, 1 },
        textColor = { 1, 1, 1, 1 },
        textPositionX = 0,
        textPositionY = 0,
        textPoint = "CENTER",
        textOutline = "",
        frameLevel = 10,
        frameStrata = "HIGH",
        statusBackgroundColor = { 0, 0, 0, 0.535 },
        ignoreParentAlpha = false,
        borderPaddingHeight = 1.3,
        borderPaddingWidth = 1.17,
    },

    arena = {
        enabled = false,
        width = 150,
        height = 15,
        iconSize = 18,
        showBorderShield = true,
        showTimer = false,
        showIcon = true,
        showSpark = true,
        autoPosition = false,
        castFont = _G.STANDARD_TEXT_FONT,
        castFontSize = 10,
        castStatusBar = "Interface\\TargetingFrame\\UI-StatusBar",
        castBorder = "Interface\\CastingBar\\UI-CastingBar-Border-Small",
        hideIconBorder = false,
        position = { "CENTER", -149, -5 },
        iconPositionX = -5,
        iconPositionY = 0,
        borderColor = { 1, 1, 1, 1 },
        statusColor = { 1, 0.7, 0, 1 },
        statusColorSuccess = { 0, 1, 0, 1 },
        statusColorFailed = { 1, 0, 0 },
        statusColorChannel = { 0, 1, 0, 1 },
        statusColorUninterruptible = { 0.7, 0.7, 0.7, 1 },
        textColor = { 1, 1, 1, 1 },
        textPositionX = 0,
        textPositionY = 0,
        textPoint = "CENTER",
        textOutline = "",
        frameLevel = 10,
        frameStrata = "HIGH",
        statusBackgroundColor = { 0, 0, 0, 0.535 },
        ignoreParentAlpha = false,
        borderPaddingHeight = 1.3,
        borderPaddingWidth = 1.17,
    },

    player = {
        enabled = false,
        width = 190,
        height = 20,
        iconSize = 22,
        showBorderShield = false,
        showTimer = false,
        showTotalTimer = false,
        showIcon = true,
        showSpark = true,
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
        statusColorSuccess = { 1, 0.7, 0, 1 },
        statusColorFailed = { 1, 0, 0 },
        statusColorChannel = { 0, 1, 0, 1 },
        statusColorUninterruptible = { 0.7, 0.7, 0.7, 1 },
        textColor = { 1, 1, 1, 1 },
        textPositionX = 0,
        textPositionY = 1,
        textPoint = "CENTER",
        textOutline = "",
        frameLevel = 10,
        frameStrata = "HIGH",
        statusBackgroundColor = { 0, 0, 0, 0.535 },
        ignoreParentAlpha = false,
        borderPaddingHeight = 1.3,
        borderPaddingWidth = 1.17,
    },
}

if CLIENT_IS_CLASSIC_ERA then
    -- NPC spells that can't be interrupted. (Sensible defaults, doesn't include all)
    -- TODO: if we ever add profiles both npcCastTimeCache and npcCastUninterruptibleCache should be in a separate 'savedvariable'
    namespace.defaultConfig.npcCastUninterruptibleCache = {
        ["11981" .. GetSpellInfo(18500)] = true, -- Flamegor Wing Buffet
        ["12459" .. GetSpellInfo(25417)] = true, -- Blackwing Warlock Shadowbolt
        ["12264" .. GetSpellInfo(1449)] = true, -- Shazzrah Arcane Explosion
        ["13280" .. GetSpellInfo(22421)] = true, -- Hydrospawn Massive Geyser
        ["11583" .. GetSpellInfo(18431)] = true, -- Nefarian Bellowing Roar
        ["11983" .. GetSpellInfo(18500)] = true, -- Firemaw Wing Buffet
        ["11983" .. GetSpellInfo(22539)] = true, -- Firemaw Shadow Flame
        ["12265" .. GetSpellInfo(133)] = true, -- Lava Spawn Fireball
        ["11492" .. GetSpellInfo(22662)] = true, -- Alzzin the Wildshaper Wither
        ["10438" .. GetSpellInfo(116)] = true, -- Maleki the Pallid Frostbolt
        ["12465" .. GetSpellInfo(22425)] = true, -- Death Talon Wyrmkin Fireball Voley
        ["14020" .. GetSpellInfo(23310)] = true, -- Chromaggus Time Lapse
        ["14020" .. GetSpellInfo(23316)] = true, -- Chromaggus Ignite Flesh
        ["14020" .. GetSpellInfo(23309)] = true, -- Chromaggus Incinerate
        ["14020" .. GetSpellInfo(23187)] = true, -- Chromaggus Frost Burn
        ["14020" .. GetSpellInfo(23314)] = true, -- Chromaggus Corrosive Acid
        ["12468" .. GetSpellInfo(2120)] = true, -- Death Talon Hatcher Flamestrike
        ["13020" .. GetSpellInfo(9573)] = true, -- Vaelastrasz the Corrupt Flame Breath
        ["12435" .. GetSpellInfo(22425)] = true, -- Razorgore the Untamed Fireball Volley
        ["14601" .. GetSpellInfo(18500)] = true, -- Ebonroc Wing Buffet
        ["14601" .. GetSpellInfo(22539)] = true, -- Ebonroc Shadow Flame
        ["11981" .. GetSpellInfo(22539)] = true, -- Flamegor Shadow Flame
        ["11583" .. GetSpellInfo(22539)] = true, -- Nefarian Shadow Flame
        ["10184" .. GetSpellInfo(18500)] = true, -- Onyxia Wing Buffet
        ["12118" .. GetSpellInfo(20604)] = true, -- Lucifron Dominate Mind
        ["12201" .. GetSpellInfo(9483)] = true, -- Princess Theradras Boulder
        ["10184" .. GetSpellInfo(9573)] = true, -- Onyxia Flame Breath
        ["10184" .. GetSpellInfo(133)] = true, -- Onyxia Fireball
        ["11492" .. GetSpellInfo(22661)] = true, -- Alzzin the Wildshaper Enervate
        ["11490" .. GetSpellInfo(1050)] = true, -- Zevrim Thornhoof Sacrifice
        ["11490" .. GetSpellInfo(22478)] = true,  -- Zevrim Thornhoof Intense Pain
        ["10436" .. GetSpellInfo(16868)] = true, -- Baroness Anastari Banshee Wail
        ["10184" .. GetSpellInfo(18431)] = true, -- Onyxia Bellowing Roar
        ["11492" .. GetSpellInfo(9616)] = true, -- Alzzin the Wildshaper Wild Regeneration
        ["13996" .. GetSpellInfo(22334)] = true, -- Blackwing Technician Bomb
        ["11359" .. GetSpellInfo(16430)] = true, -- Soulflayer Soul Tap
        ["11372" .. GetSpellInfo(24011)] = true, -- Razzashi Adder Venom Spit
        ["14834" .. GetSpellInfo(24322)] = true, -- Hakkar Blood Siphon
        ["14509" .. GetSpellInfo(24189)] = true, -- High Priest Thekal Force Punch
        ["11382" .. GetSpellInfo(24314)] = true, -- Broodlord Mandokir Threatening Gaze
        ["14750" .. GetSpellInfo(24024)] = true, -- Gurubashi Bat Rider Unstable Concoction
        ["12259" .. GetSpellInfo(686)] = true, -- Gehennas Shadow Bolt
        ["11339" .. GetSpellInfo(22908)] = true, -- Hakkari Shadow Hunter Volley
        ["14507" .. GetSpellInfo(14914)] = true, -- High Priest Venoxis Holy Fire
        ["13161" .. GetSpellInfo(21188)] = true, -- Aerie Gryphon Stun Bomb Attack
        ["14943" .. GetSpellInfo(21188)] = true, -- Guse's War Rider Stun Bomb Attack
        ["14947" .. GetSpellInfo(21188)] = true, -- Ichman's Gryphon Stun Bomb Attack
        ["14944" .. GetSpellInfo(21188)] = true, -- Jeztor's War Rider Stun Bomb Attack
        ["14945" .. GetSpellInfo(21188)] = true, -- Mulverick's War Rider Stun Bomb Attack
        ["12119" .. GetSpellInfo(20604)] = true, -- Flamewaker Protector Dominate Mind
        ["12459" .. GetSpellInfo(22372)] = true, -- Blackwing Warlock Demon Portal
        ["15114" .. GetSpellInfo(22479)] = true, -- Gahz'ranka Frost Breath
        ["15114" .. GetSpellInfo(22421)] = true, -- Gahz'ranka Massive Geyser
        ["12557" .. GetSpellInfo(14515)] = true, -- Grethok the Controller Dominate Mind
        ["15727" .. GetSpellInfo(26134)] = true, -- C'Thun Eye Beam
        ["15589" .. GetSpellInfo(26134)] = true, -- Eye of C'Thun Eye Beam
        ["15517" .. GetSpellInfo(26102)] = true, -- Ouro Sand Blast
        ["15517" .. GetSpellInfo(26103)] = true, -- Ouro Sweep
        ["15517" .. GetSpellInfo(26616)] = true, -- Ouro Boulder
        ["15369" .. GetSpellInfo(25748)] = true, -- Ayamiss the Hunter Poison Stinger
        ["15276" .. GetSpellInfo(26006)] = true, -- Emperor Vek'lor
        ["6109" .. GetSpellInfo(21099)] = true, -- Azuregos Frost Breath
        ["6109" .. GetSpellInfo(21097)] = true, -- Azuregos Manastorm
        ["12397" .. GetSpellInfo(15245)] = true, -- Lord Kazzak Shadow Bolt Volley
        ["12397" .. GetSpellInfo(7588)] = true, -- Lord Kazzak Void Bolt
        ["14887" .. GetSpellInfo(16247)] = true, -- Ysondre Curse of Thorns
        ["14890" .. GetSpellInfo(22686)] = true, -- Taerar Bellowing Roar
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
        ["11881" .. GetSpellInfo(26616)] = true, -- Twilight Geolord Boulder
        ["11729" .. GetSpellInfo(19452)] = true, -- Hive'Zora Hive Sister Toxic Spit
        ["15323" .. GetSpellInfo(26381)] = true, -- Hive'Zara Sandstalker Burrow
        ["15263" .. GetSpellInfo(785)] = true, -- The Prophet Skeram True Fulfillment
        ["15979" .. GetSpellInfo(28615)] = true, -- Tomb Horror Spike Volley
        ["15979" .. GetSpellInfo(28614)] = true, -- Tomb Horror Pointy Spike
        ["15989" .. GetSpellInfo(28524)] = true, -- Sapphiron Frost Breath
        ["16017" .. GetSpellInfo(27794)] = true, -- Patchwork Golem Cleave
        ["15928" .. GetSpellInfo(28089)] = true, -- Thaddius Polarity Shift
        ["16168" .. GetSpellInfo(28995)] = true, -- Stoneskin Gargoyle Stoneskin
        ["16446" .. GetSpellInfo(28995)] = true, -- Plagued Gargoyle Stoneskin
        ["16146" .. GetSpellInfo(17473)] = true, -- Death Knight Raise Dead
        ["16368" .. GetSpellInfo(9081)] = true, -- Necropolis Acolyte Shadow Bolt Volley
        ["15956" .. GetSpellInfo(28783)] = true, -- Anub'Rekhan Impale
        ["15956" .. GetSpellInfo(28786)] = true, -- Anub'Rekhan Locust Swarm
        ["16022" .. GetSpellInfo(16568)] = true, -- Surgical Assistant Mind Flay
        ["16021" .. GetSpellInfo(1397)] = true, -- Living Monstrosity Fear
        ["16021" .. GetSpellInfo(1339)] = true, -- Living Monstrosity Chain Lightning
        ["16021" .. GetSpellInfo(28294)] = true, -- Living Monstrosity Lightning Totem
        ["16215" .. GetSpellInfo(1467)] = true, -- Unholy Staff Arcane Explosion
        ["16452" .. GetSpellInfo(1467)] = true, -- Necro Knight Guardian Arcane Explosion
        ["16452" .. GetSpellInfo(11829)] = true, -- Necro Knight Guardian Flamestrike
        ["16165" .. GetSpellInfo(1467)] = true, -- Necro Knight Arcane Explosion
        ["16165" .. GetSpellInfo(11829)] = true, -- Necro Knight Flamestrike
        ["8607" .. GetSpellInfo(7279)] = true, -- Rotting Sludge Black Sludge
        ["8212" .. GetSpellInfo(7279)] = true, -- The Reak Black Sludge
        ["3295" .. GetSpellInfo(7279)] = true, -- Sludge Beast Black Sludge
        ["6518" .. GetSpellInfo(7279)] = true, -- Tar Lurker Black Sludge
        ["785" .. GetSpellInfo(4979)] = true, -- Skeletal Warder Quick Flame Ward
        ["785" .. GetSpellInfo(4980)] = true, -- Skeletal Warder Quick Frost Ward
    }

    -- Storage for auto-corrected cast times
    namespace.defaultConfig.npcCastTimeCache = {
        ["15990" .. GetSpellInfo(28478)] = 2000, -- Kel Thuzad Frostbolt
        ["15989" .. GetSpellInfo(3131)] = 7000, -- Sapphiron Frost Breath
    }
end
