-- Give Me Everything — in-game panel for the CET overlay (opens with the console)
-- + a bindable hotkey (set it in CET > Bindings).

local AMOUNT = 1000000  -- how much the hotkey adds

-- UI language follows the game's on-screen language: pt-* = Português (Brasil), else English.
local L = {
    en = {
        money        = "Money",
        crafting     = "Crafting components",
        quickhack    = "Quickhack components",
        progression  = "Progression",
        perks        = "Perk points",
        attributes   = "Attribute points",
        relic        = "Relic points (PL)",
        levelxp      = "Level XP",
        streetcred   = "Street Cred",
        skills       = "Skills",
        cyberware    = "Cyberware",
        shard        = "Capacity shards",
        consumables  = "Consumables",
        grenades     = "Grenades",
        romances     = "Romances",
        unlock       = "Unlock",
        unlocked     = "Unlocked",
        romunlocked  = "romance unlocked",
        vehicles     = "Vehicles",
        unlockveh    = "Unlock all purchasable vehicles",
        vehunlocked  = "All vehicles unlocked",
        failed       = "failed (check the log)",
        tabitems     = "Items",
        tabprog      = "Progression",
        tabweapons   = "Weapons",
        tabunlocks   = "Unlocks",
        xpmult       = "XP multiplier",
        xpmulthint   = "Multiplies all XP gained (level, street cred, skills). 1x = off.",
        give         = "Give",
        giveall      = "Give all",
        owned        = "Owned",
        wpistols     = "Pistols / Revolvers",
        wsmgs        = "SMGs",
        wrifles      = "Assault Rifles",
        wshotguns    = "Shotguns",
        wlmg         = "LMG / HMG",
        wsnipers     = "Snipers / Precision",
        wmelee       = "Melee",
        wcyber       = "Cyberware",
        search       = "Search",
        customqty    = "Custom amount (0 = off)",
        noresults    = "Nothing found",
        ammo         = "Ammo",
        setlevel     = "Set",
        setlevelhdr  = "Set level directly",
        lvl          = "Level",
        levelset     = "level set",
        ncpd         = "NCPD",
        clearwanted  = "Clear wanted level",
        wantedcleared = "Wanted level cleared",
        ncpdoff      = "Disable NCPD (until game restart)",
        tabgear      = "Gear",
        itemsgiven   = "items given",
        healed       = "Healed",
        ammofull     = "Ammo refilled",
        heal         = "Full heal",
        dmgmult      = "Damage multiplier",
        dmgmulthint  = "Multiplies all damage you deal, quickhacks included. 1x = off.",
        perkreset    = "Perk reset shard",
        ginc         = "Incendiary",
        gsmoke       = "Smoke",
        gbio         = "Biohazard",
        healhdr      = "Healing",
        gqh          = "Quickhacks",
        gsande       = "Sandevistan",
        gberserk     = "Berserk",
        gdeck        = "Cyberdecks",
        gcyber       = "Cyberware — other",
        gjohnny      = "Johnny Silverhand set",
        gclothes     = "Clothing",
    },
    pt = {
        money        = "Dinheiro",
        crafting     = "Componentes (crafting)",
        quickhack    = "Componentes (quickhack)",
        progression  = "Progressão",
        perks        = "Pontos de perk",
        attributes   = "Pontos de atributo",
        relic        = "Pontos de Relic (PL)",
        levelxp      = "XP de nível",
        streetcred   = "Street Cred",
        skills       = "Skills",
        cyberware    = "Cyberware",
        shard        = "Shards de capacidade",
        consumables  = "Consumíveis",
        grenades     = "Granadas",
        romances     = "Romances",
        unlock       = "Desbloquear",
        unlocked     = "Desbloqueado",
        romunlocked  = "romance desbloqueado",
        vehicles     = "Veículos",
        unlockveh    = "Desbloquear todos os veículos compráveis",
        vehunlocked  = "Todos os veículos desbloqueados",
        failed       = "falhou (veja o log)",
        tabitems     = "Itens",
        tabprog      = "Progressão",
        tabweapons   = "Armas",
        tabunlocks   = "Desbloqueios",
        xpmult       = "Multiplicador de XP",
        xpmulthint   = "Multiplica todo XP ganho (nível, street cred, skills). 1x = desligado.",
        give         = "Dar",
        giveall      = "Dar todas",
        owned        = "Na mochila",
        wpistols     = "Pistolas / Revólveres",
        wsmgs        = "SMGs",
        wrifles      = "Fuzis de assalto",
        wshotguns    = "Escopetas",
        wlmg         = "LMG / HMG",
        wsnipers     = "Snipers / Precisão",
        wmelee       = "Corpo a corpo",
        wcyber       = "Cyberware",
        search       = "Buscar",
        customqty    = "Quantidade custom (0 = desliga)",
        noresults    = "Nada encontrado",
        ammo         = "Munição",
        setlevel     = "Definir",
        setlevelhdr  = "Setar nível direto",
        lvl          = "Nível",
        levelset     = "nível definido",
        ncpd         = "NCPD",
        clearwanted  = "Limpar procurado",
        wantedcleared = "Procurado zerado",
        ncpdoff      = "Desativar NCPD (até reiniciar o jogo)",
        tabgear      = "Equipamentos",
        itemsgiven   = "itens dados",
        healed       = "Curado",
        ammofull     = "Munição cheia",
        heal         = "Curar 100%",
        dmgmult      = "Multiplicador de dano",
        dmgmulthint  = "Multiplica todo dano causado, quickhacks incluídos. 1x = desligado.",
        perkreset    = "Shard de reset de perks",
        ginc         = "Incendiária",
        gsmoke       = "Fumaça",
        gbio         = "Biorisco",
        healhdr      = "Cura",
        gcyber       = "Cyberware — outros",
        gjohnny      = "Set do Johnny Silverhand",
        gclothes     = "Roupas",
    },
}

-- settings.json holds lang + multipliers; lang.txt kept as read-only fallback (pre-1.2.0)
local settings = { lang = "en", xpmult = 1, dmgmult = 1 }

local function t(key) return L[settings.lang][key] or L.en[key] or key end

local function saveSettings()
    local ok, contents = pcall(function() return json.encode(settings) end)
    if ok and contents then
        local f = io.open("settings.json", "w")
        if f then f:write(contents); f:close() end
    end
end

local function loadSettings()
    local f = io.open("settings.json", "r")
    if f then
        local contents = f:read("*a")
        f:close()
        local ok, saved = pcall(function() return json.decode(contents) end)
        if ok and type(saved) == "table" then
            if L[saved.lang] then settings.lang = saved.lang end
            local m = tonumber(saved.xpmult)
            if m and m >= 1 and m <= 10 then settings.xpmult = math.floor(m) end
            local d = tonumber(saved.dmgmult)
            if d and d >= 1 and d <= 10 then settings.dmgmult = math.floor(d) end
        end
        return
    end
    f = io.open("lang.txt", "r")
    if f then
        local v = f:read("*l")
        f:close()
        if v and L[v] then settings.lang = v end
    end
end
loadSettings()

-- on-screen toast using the game's own message widget (auto-fades, works with the overlay closed)
local function notify(text)
    local ok, err = pcall(function()
        local msg = SimpleScreenMessage.new()
        msg.duration = 3.0
        msg.message = text
        msg.isShown = true
        local defs = Game.GetAllBlackboardDefs()
        Game.GetBlackboardSystem():Get(defs.UI_Notifications)
            :SetVariant(defs.UI_Notifications.OnscreenMessage, ToVariant(msg), true)
    end)
    if not ok then spdlog.info("GiveMeEverything: notify failed: " .. tostring(err)) end
end

local refreshOwned  -- defined below, after the weapons table

local overlayOpen = false
registerForEvent("onOverlayOpen", function()
    overlayOpen = true
    refreshOwned()
end)
registerForEvent("onOverlayClose", function() overlayOpen = false end)

registerHotkey("GiveMeEverything", "Add $" .. AMOUNT, function()
    Game.AddToInventory("Items.money", AMOUNT)
    notify("+$" .. AMOUNT)
end)

-- item ids vary between game versions: on load, use the first one that exists
local function resolve(candidates)
    for _, id in ipairs(candidates) do
        if TweakDB:GetRecord(id) then return id end
    end
    spdlog.info("GiveMeEverything: no valid id among: " .. table.concat(candidates, ", "))
    return nil
end

-- iconic weapons by class; ids resolved on init, invalid ones hidden (e.g. PL items without the DLC)
local WEAPONS = {
    { key = "wpistols", weapons = {
        { label = "Dying Night",            ids = { "Items.Preset_Lexington_Wilson" } },
        { label = "Rook",                   ids = { "Items.Preset_Lexington_Rook" } },
        { label = "Lexington x-MOD2",       ids = { "Items.Preset_Lexington_Shooting_Competition" } },
        { label = "Kongou",                 ids = { "Items.Preset_Liberty_Yorinobu" } },
        { label = "Plan B",                 ids = { "Items.Preset_Liberty_Dex" } },
        { label = "Pride",                  ids = { "Items.Preset_Liberty_Rogue" } },
        { label = "Seraph",                 ids = { "Items.Preset_Liberty_Padre" } },
        { label = "La Chingona Dorada",     ids = { "Items.Preset_Nue_Jackie" } },
        { label = "Death and Taxes",        ids = { "Items.Preset_Nue_Maiko" } },
        { label = "Riskit (PL)",            ids = { "Items.Preset_Nue_Bree" } },
        { label = "Apparition",             ids = { "Items.Preset_Kenshin_Frank" } },
        { label = "Chaos",                  ids = { "Items.Preset_Kenshin_Royce" } },
        { label = "Ambition (PL)",          ids = { "Items.Preset_Kenshin_Spy" } },
        { label = "Lizzie",                 ids = { "Items.Preset_Omaha_Suzie" } },
        { label = "Skippy",                 ids = { "Items.Preset_Yukimura_Skippy" } },
        { label = "Genjiroh",               ids = { "Items.Preset_Yukimura_Kiji" } },
        { label = "Her Majesty (PL)",       ids = { "Items.Preset_Unity_Agent" } },
        { label = "Cheetah (PL)",           ids = { "Items.Preset_Unity_Angelica" } },
        { label = "Pariah (PL)",            ids = { "Items.Preset_Ticon_Reed" } },
        { label = "Scorch (PL)",            ids = { "Items.Preset_Ticon_Gwent" } },
        { label = "Catahoula",              ids = { "Items.Preset_Grit_Amazon" } },
        { label = "Kappa x-MOD2 (PL)",      ids = { "Items.Preset_Kappa_Legendary" } },
        { label = "Crimestopper (PL)",      ids = { "Items.Preset_Kappa_George" } },
        { label = "Ogou (PL)",              ids = { "Items.Preset_Chao_VooDoo" } },
        { label = "Malorian Arms 3516",     ids = { "Items.Preset_Silverhand_3516" } },
        { label = "Amnesty",                ids = { "Items.Preset_Overture_Cassidy" } },
        { label = "Archangel",              ids = { "Items.Preset_Overture_Kerry" } },
        { label = "Crash",                  ids = { "Items.Preset_Overture_River" } },
        { label = "Rosco (PL)",             ids = { "Items.Preset_Overture_Dodger" } },
        { label = "Ol' Reliable (PL)",      ids = { "Items.Preset_Overture_Dante" } },
        { label = "Doom Doom",              ids = { "Items.Preset_Nova_Doom_Doom" } },
        { label = "Mancinella (PL)",        ids = { "Items.Preset_Nova_Hitman" } },
        { label = "Comrade's Hammer",       ids = { "Items.Preset_Burya_Comrade" } },
        { label = "Laika (PL)",             ids = { "Items.Preset_Burya_AirDrop" } },
        { label = "Bald Eagle (PL)",        ids = { "Items.Preset_Metel_Kurt" } },
        { label = "Taigan (PL)",            ids = { "Items.Preset_Metel_AirDrop" } },
        { label = "Gris-Gris (PL)",         ids = { "Items.Preset_Quasar_Baron" } },
        { label = "Amstaff",                ids = { "Items.Preset_Crusher_Amazon" } },
    } },
    { key = "wsmgs", weapons = {
        { label = "Problem Solver",         ids = { "Items.Preset_Saratoga_Raffen" } },
        { label = "Fenrir",                 ids = { "Items.Preset_Saratoga_Maelstrom" } },
        { label = "Buzzsaw",                ids = { "Items.Preset_Pulsar_Buzzsaw" } },
        { label = "Yinglong",               ids = { "Items.Preset_Dian_Yinglong" } },
        { label = "Guillotine x-MOD2",      ids = { "Items.Preset_Guillotine_Collectible" } },
        { label = "Erebus (PL)",            ids = { "Items.Preset_Borg4a_HauntedGun" } },
        { label = "Pizdets (PL)",           ids = { "Items.Preset_Warden_Boris" } },
        { label = "Chesapeake",             ids = { "Items.Preset_Warden_Amazon" } },
        { label = "Shingen Mark V",         ids = { "Items.Preset_Shingen_Prototype" } },
        { label = "Raiju (PL)",             ids = { "Items.Preset_Senkoh_Prototype" } },
    } },
    { key = "wrifles", weapons = {
        { label = "Moron Labe",             ids = { "Items.Preset_Ajax_Moron" } },
        { label = "Pit Bull",               ids = { "Items.Preset_Ajax_Amazon" } },
        { label = "Psalm 11:6",             ids = { "Items.Preset_Copperhead_Genesis" } },
        { label = "Divided We Stand",       ids = { "Items.Preset_Sidewinder_Divided" } },
        { label = "Prejudice",              ids = { "Items.Preset_Masamune_Rogue" } },
        { label = "Hercules 3AX (PL)",      ids = { "Items.Preset_Hercules_Prototype" } },
        { label = "Hawk (PL)",              ids = { "Items.Preset_Kyubi_Myers" } },
        { label = "Chinook",                ids = { "Items.Preset_Kyubi_Amazon" } },
        { label = "Kyubi x-MOD2",           ids = { "Items.Preset_Kyubi_Legendary" } },
        { label = "Carmen (PL)",            ids = { "Items.Preset_Umbra_Bebe" } },
        { label = "Umbra x-MOD2",           ids = { "Items.Preset_Umbra_Collectible" } },
    } },
    { key = "wshotguns", weapons = {
        { label = "Ba Xing Chong",          ids = { "Items.Preset_Zhuo_Eight_Star" } },
        { label = "Guts",                   ids = { "Items.Preset_Carnage_Edgerunners" } },
        { label = "Mox",                    ids = { "Items.Preset_Carnage_Mox" } },
        { label = "Sovereign",              ids = { "Items.Preset_Igla_Sovereign" } },
        { label = "The Headsman",           ids = { "Items.Preset_Tactician_Headsman" } },
        { label = "Order (PL)",             ids = { "Items.Preset_Satara_Brick" } },
        { label = "Dezerter (PL)",          ids = { "Items.Preset_Testera_Nicolas" } },
        { label = "Alabai (PL)",            ids = { "Items.Preset_Pozhar_AirDrop" } },
        { label = "Pozhar x-MOD2",          ids = { "Items.Preset_Pozhar_Legendary" } },
    } },
    { key = "wlmg", weapons = {
        { label = "Wild Dog (PL)",          ids = { "Items.Preset_Defender_Kurt" } },
        { label = "MA70 HB x-MOD2",         ids = { "Items.Preset_MA70_Collectible" } },
    } },
    { key = "wsnipers", weapons = {
        { label = "Widow Maker",            ids = { "Items.Preset_Achilles_Nash" } },
        { label = "Achilles x-MOD2",        ids = { "Items.Preset_Achilles_Collectible" } },
        { label = "Breakthrough",           ids = { "Items.Preset_Nekomata_Breakthrough" } },
        { label = "Foxhound",               ids = { "Items.Preset_Nekomata_Amazon" } },
        { label = "O'Five",                 ids = { "Items.Preset_Grad_Buck" } },
        { label = "Overwatch",              ids = { "Items.Preset_Grad_Panam" } },
        { label = "Borzaya (PL)",           ids = { "Items.Preset_Grad_AirDrop" } },
        { label = "Sparky",                 ids = { "Items.Preset_Grad_Scav" } },
        { label = "Yasha",                  ids = { "Items.Preset_Ashura_Twitch" } },
        { label = "Rasetsu (PL)",           ids = { "Items.Preset_Rasetsu_Prototype" } },
        { label = "Osprey (PL)",            ids = { "Items.Preset_Osprey_Prototype" } },
        { label = "Hypercritical",          ids = { "Items.Preset_Kolac_Tiny_Mike" } },
    } },
    { key = "wmelee", weapons = {
        { label = "Jinchu-Maru",            ids = { "Items.Preset_Katana_Takemura" } },
        { label = "Satori",                 ids = { "Items.Preset_Katana_Saburo" } },
        { label = "Cocktail Stick",         ids = { "Items.Preset_Katana_Cocktail" } },
        { label = "Scalpel",                ids = { "Items.Preset_Katana_Surgeon" } },
        { label = "Byakko",                 ids = { "Items.Preset_Katana_Wakako" } },
        { label = "Errata",                 ids = { "Items.Preset_Katana_E3" } },
        { label = "Tsumetogi",              ids = { "Items.Preset_Katana_Hiromi" } },
        { label = "Black Unicorn",          ids = { "Items.Preset_Katana_GoG" } },
        { label = "Nehan",                  ids = { "Items.Preset_Tanto_Saburo" } },
        { label = "Headhunter",             ids = { "Items.Preset_Punk_Knife_Iconic" } },
        { label = "Blue Fang",              ids = { "Items.Preset_Neurotoxin_Knife_Iconic" } },
        { label = "Fang (PL)",              ids = { "Items.Preset_Knife_Kurtz_1" } },
        { label = "Stinger",                ids = { "Items.Preset_Knife_Stinger" } },
        { label = "Tinker Bell",            ids = { "Items.Preset_Baton_Tinker_Bell" } },
        { label = "Cottonmouth",            ids = { "Items.Preset_Cane_Fingers" } },
        { label = "Caretaker's Spade",      ids = { "Items.Preset_Shovel_Caretaker" } },
        { label = "Gold-Plated Bat",        ids = { "Items.Preset_Baseball_Bat_Denny" } },
        { label = "Baby Boomer (PL)",       ids = { "Items.Preset_Baseball_Bat_Malina" } },
        { label = "Baseball Bat x-MOD2",    ids = { "Items.Preset_Baseball_Bat_Legendary" } },
        { label = "Sir John Phallustiff",   ids = { "Items.Preset_Dildo_Stout" } },
        { label = "BFC 9000 (PL)",          ids = { "Items.Preset_Dildo_SexShop" } },
        { label = "Murphy's Law (PL)",      ids = { "Items.Preset_Baton_Murphy" } },
        { label = "Agaou (PL)",             ids = { "Items.Preset_VB_Axe" } },
        { label = "Butcher's Cleaver",      ids = { "Items.Preset_Butchers_Knife_Iconic" } },
        { label = "Bunker Crowbar (PL)",    ids = { "Items.Preset_Crowbar_Bunker" } },
        { label = "Volkodav (PL)",          ids = { "Items.Preset_Machete_Borg_AirDrop" } },
        { label = "Gwynbleidd",             ids = { "Items.Preset_Sword_Witcher" } },
        { label = "Cut-O-Matic x-MOD2",     ids = { "Items.Preset_Chainsword_Legendary" } },
        { label = "Claw x-MOD2",            ids = { "Items.Preset_Fanged_Axe_Collectible" } },
        { label = "Sasquatch's Hammer",     ids = { "Items.Preset_Hammer_Sasquatch" } },
    } },
    { key = "wcyber", weapons = {
        { label = "Militech Canto MK.6 (PL)", ids = { "Items.HauntedCyberdeck_Legendary" } },
    } },
}

-- iconic/top-tier cyberware, quickhacks and iconic clothing; same shape as WEAPONS (resolve + owned cache)
local GEAR = {
    -- internal TweakDB names differ from 2.0 display names (EMPOverload = Short Circuit, etc.)
    { key = "gqh", weapons = {
        { label = "Ping",                 ids = { "Items.PingLvl4PlusPlusProgram", "Items.PingLvl4Program" } },
        { label = "Contagion",            ids = { "Items.ContagionLvl4PlusPlusProgram", "Items.ContagionLvl4Program" } },
        { label = "Overheat",             ids = { "Items.OverheatLvl4PlusPlusProgram", "Items.OverheatLvl4Program" } },
        { label = "Short Circuit",        ids = { "Items.EMPOverloadLvl4PlusPlusProgram", "Items.EMPOverloadLvl4Program" } },
        { label = "Synapse Burnout",      ids = { "Items.BrainMeltLvl4PlusPlusProgram", "Items.BrainMeltLvl4Program" } },
        { label = "Cyberware Malfunction", ids = { "Items.DisableCyberwareLvl4PlusPlusProgram", "Items.DisableCyberwareLvl4Program" } },
        { label = "Weapon Glitch",        ids = { "Items.WeaponMalfunctionLvl4PlusPlusProgram", "Items.WeaponMalfunctionLvl4Program" } },
        { label = "Cripple Movement",     ids = { "Items.LocomotionMalfunctionLvl4PlusPlusProgram", "Items.LocomotionMalfunctionLvl4Program" } },
        { label = "Reboot Optics",        ids = { "Items.BlindLvl4PlusPlusProgram", "Items.BlindLvl4Program" } },
        { label = "Memory Wipe",          ids = { "Items.MemoryWipeLvl4PlusPlusProgram", "Items.MemoryWipeLvl4Program" } },
        { label = "Sonic Shock",          ids = { "Items.CommsNoiseLvl4PlusPlusProgram", "Items.CommsNoiseLvl4Program" } },
        { label = "Request Backup",       ids = { "Items.CommsCallInLvl4PlusPlusProgram", "Items.CommsCallInLvl4Program" } },
        { label = "Bait",                 ids = { "Items.WhistleLvl4PlusPlusProgram", "Items.WhistleLvl4Program" } },
        { label = "Suicide",              ids = { "Items.SuicideLvl4PlusPlusProgram", "Items.SuicideLvl4Program" } },
        { label = "System Reset",         ids = { "Items.SystemCollapseLvl4PlusPlusProgram", "Items.SystemCollapseLvl4Program" } },
        { label = "Detonate Grenade",     ids = { "Items.GrenadeExplodeLvl4PlusPlusProgram", "Items.GrenadeExplodeLvl4Program" } },
        { label = "Cyberpsychosis",       ids = { "Items.MadnessLvl4PlusPlusProgram", "Items.MadnessLvl4Program" } },
    } },
    { key = "gsande", weapons = {
        { label = "Militech \"Apogee\" (PL)",        ids = { "Items.AdvancedSandevistanApogee", "Items.AdvancedSandevistanApogeePlusPlus" } },
        { label = "Militech \"Falcon\" Mk.5",        ids = { "Items.AdvancedSandevistanC4MK5", "Items.AdvancedSandevistanC4MK5PlusPlus" } },
        { label = "QianT \"Warp Dancer\" Mk.5",      ids = { "Items.AdvancedSandevistanC3MK5", "Items.AdvancedSandevistanC3MK5PlusPlus" } },
        { label = "Dynalar Mk.4",                    ids = { "Items.AdvancedSandevistanC2MK4", "Items.AdvancedSandevistanC2MK4PlusPlus" } },
        { label = "Zetatech Mk.4",                   ids = { "Items.AdvancedSandevistanC1MK4", "Items.AdvancedSandevistanC1MK4PlusPlus" } },
    } },
    { key = "gberserk", weapons = {
        { label = "Militech Berserk Mk.5",           ids = { "Items.AdvancedBerserkC4MK5", "Items.AdvancedBerserkC4MK5PlusPlus" } },
        { label = "Zetatech Berserk Mk.5",           ids = { "Items.AdvancedBerserkC3MK5", "Items.AdvancedBerserkC3MK5PlusPlus" } },
        { label = "Biodyne Berserk Mk.4",            ids = { "Items.AdvancedBerserkC2MK4", "Items.AdvancedBerserkC2MK4PlusPlus" } },
        { label = "MooreTech Berserk Mk.4",          ids = { "Items.AdvancedBerserkC1MK4", "Items.AdvancedBerserkC1MK4PlusPlus" } },
    } },
    { key = "gdeck", weapons = {
        { label = "Tetratronic Rippler Mk.5",        ids = { "Items.AdvancedTetratronicRipplerMKVLegendary", "Items.AdvancedTetratronicRipplerMKVLegendaryPlusPlus" } },
        { label = "NetWatch Netdriver Mk.5",         ids = { "Items.AdvancedNetwatchNetdriverMKLegendary", "Items.AdvancedNetwatchNetdriverMKLegendaryPlusPlus" } },
        { label = "Arasaka Shadow Mk.5",             ids = { "Items.AdvancedArasakaShadowMKVLegendary", "Items.AdvancedArasakaShadowMKVLegendaryPlusPlus" } },
        { label = "Raven Microcyber Mk.3",           ids = { "Items.AdvancedRavenMicrocyberMKIIILegendary", "Items.AdvancedRavenMicrocyberMKIIILegendaryPlusPlus" } },
        { label = "Biotech Sigma Mk.4",              ids = { "Items.AdvancedBiotechSigmaMKIVLegendary", "Items.AdvancedBiotechSigmaMKIVLegendaryPlusPlus" } },
    } },
    { key = "gcyber", weapons = {
        { label = "MaxTac Mantis Blades (PL)",       ids = { "Items.AdvancedMaxTacMantisBladesLegendary", "Items.AdvancedMaxTacMantisBladesLegendaryPlusPlus" } },
        { label = "Immovable Force (PL)",            ids = { "Items.IconicGunStabilizerLegendary", "Items.IconicGunStabilizerLegendaryPlusPlus" } },
        { label = "Chrome Compressor (PL)",          ids = { "Items.CapacityBoosterLegendary", "Items.CapacityBoosterLegendaryPlusPlus" } },
        { label = "Quantum Tuner (PL)",              ids = { "Items.AdvancedTimeBankLegendary", "Items.AdvancedTimeBankLegendaryPlusPlus" } },
        { label = "Axolotl (PL)",                    ids = { "Items.IconicAdvancedSubdermalCoProcessorLegendary", "Items.IconicAdvancedSubdermalCoProcessorLegendaryPlusPlus" } },
        { label = "COX-2 Optimizer (PL)",            ids = { "Items.IconicBioConductorsLegendary", "Items.IconicBioConductorsLegendaryPlusPlus" } },
        { label = "RAM Reallocator (PL)",            ids = { "Items.IconicCamilloRamManagerLegendary", "Items.IconicCamilloRamManagerLegendaryPlusPlus" } },
    } },
    { key = "gjohnny", weapons = {
        { label = "Samurai Jacket (Replica)",        ids = { "Items.SQ031_Samurai_Jacket" } },
        { label = "Johnny's Aviators",               ids = { "Items.Q005_Johnny_Glasses" } },
        { label = "Johnny's Tank Top",               ids = { "Items.Q005_Johnny_Shirt" } },
        { label = "Johnny's Pants",                  ids = { "Items.Q005_Johnny_Pants" } },
        { label = "Johnny's Boots",                  ids = { "Items.Q005_Johnny_Shoes" } },
    } },
    { key = "gclothes", weapons = {
        { label = "Aldecaldos Jacket",               ids = { "Items.Q114_Aldecaldo_Jacket" } },
        { label = "David's Jacket (Edgerunners)",    ids = { "Items.MQ049_martinez_jacket" } },
        { label = "Amikiri Sound Cutter (PL)",       ids = { "Items.Q303_mask_h1" } },
    } },
}

-- AllDamageDonePercentBonus: DamageSystem does attack *= 1 + value, quickhacks included,
-- so mult N = modifier N-1. Modifier dies with the player entity: reapplied on OnGameAttached.
local dmgMod = nil
local function applyDmgMult()
    local ok, err = pcall(function()
        local player = Game.GetPlayer()
        if not player then return end
        local stats = Game.GetStatsSystem()
        if dmgMod then
            stats:RemoveModifier(player:GetEntityID(), dmgMod)
            dmgMod = nil
        end
        if settings.dmgmult > 1 then
            dmgMod = RPGManager.CreateStatModifier(
                gamedataStatType.AllDamageDonePercentBonus,
                gameStatModifierType.Additive,
                settings.dmgmult - 1)
            stats:AddModifier(player:GetEntityID(), dmgMod)
        end
    end)
    if not ok then spdlog.info("GiveMeEverything: dmg mult failed: " .. tostring(err)) end
end

-- follow the game's on-screen language: pt-* = Portuguese, anything else = English
local function detectLang()
    local ok, value = pcall(function()
        return Game.GetSettingsSystem():GetVar("/language", "OnScreen"):GetValue()
    end)
    if ok and value then
        local v = type(value) == "string" and value or NameToString(value)
        settings.lang = v:lower():find("pt") and "pt" or "en"
    end
end

local items = {}
registerForEvent("onInit", function()
    detectLang()
    local map = {
        comp1 = { "Items.LowQualityMaterial1", "Items.CommonMaterial1" },
        comp2 = { "Items.MediumQualityMaterial1", "Items.UncommonMaterial1" },
        comp3 = { "Items.HighQualityMaterial1", "Items.RareMaterial1" },
        comp4 = { "Items.TopQualityMaterial1", "Items.EpicMaterial1" },
        comp5 = { "Items.LegendaryMaterial1" },
        qh1   = { "Items.QuickHackCommonMaterial1" },
        qh2   = { "Items.QuickHackUncommonMaterial1" },
        qh3   = { "Items.QuickHackRareMaterial1" },
        qh4   = { "Items.QuickHackEpicMaterial1" },
        qh5   = { "Items.QuickHackLegendaryMaterial1" },
        shard = { "Items.CWCapacityPermaReward_Legendary", "Items.CWCapacityPermaReward_Rare", "Items.CyberwareCapacityAllocationItem" },
        maxdoc  = { "Items.FirstAidWhiffV0" },
        bounce  = { "Items.BonesMcCoy70V0" },
        grenade = { "Items.GrenadeFragRegular", "Items.FragGrenade" },
        ammo1   = { "Ammo.HandgunAmmo" },
        ammo2   = { "Ammo.RifleAmmo" },
        ammo3   = { "Ammo.ShotgunAmmo" },
        ammo4   = { "Ammo.SniperRifleAmmo" },
        gemp    = { "Items.GrenadeEMPRegular" },
        ginc    = { "Items.GrenadeIncendiaryRegular" },
        gflash  = { "Items.GrenadeFlashRegular" },
        grecon  = { "Items.GrenadeReconRegular" },
        gsmoke  = { "Items.GrenadeSmokeRegular" },
        gbio    = { "Items.GrenadeBiohazardRegular" },
        ozob    = { "Items.GrenadeOzobsNose" },
        perkreset = { "Items.PerkPointsResetter" },
    }
    for key, candidates in pairs(map) do
        items[key] = resolve(candidates)
    end

    for _, list in ipairs({ WEAPONS, GEAR }) do
        for _, group in ipairs(list) do
            for _, w in ipairs(group.weapons) do
                w.id = resolve(w.ids)
            end
        end
    end

    -- same hooks SimpleXPMultiplier uses; request-based, so the panel's own +XP buttons bypass it
    local function scaledRequest(request)
        if settings.xpmult > 1 then
            request.amount = math.floor(request.amount * settings.xpmult)
        end
        return request
    end
    Override("PlayerDevelopmentSystem", "OnExperienceAdded", function(_, request, wrapped)
        wrapped(scaledRequest(request))
    end)
    Override("PlayerDevelopmentSystem", "OnExperienceQueued", function(_, request, wrapped)
        wrapped(scaledRequest(request))
    end)

    Observe("PlayerPuppet", "OnGameAttached", function()
        dmgMod = nil  -- old handle died with the previous player entity
        if settings.dmgmult > 1 then applyDmgMult() end
    end)
end)

local function addItem(id, qty, label)
    Game.AddToInventory(id, qty)
    notify("+" .. qty .. " " .. label)
end

local function removeItem(id, qty, label)
    local ok, err = pcall(function()
        Game.GetTransactionSystem():RemoveItem(Game.GetPlayer(), ItemID.FromTDBID(TweakDBID.new(id)), qty)
    end)
    if ok then
        notify("-" .. qty .. " " .. label)
    else
        notify(label .. " " .. t("failed"))
        spdlog.info("GiveMeEverything: RemoveItem " .. id .. " failed: " .. tostring(err))
    end
end

local function devData()
    local player = Game.GetPlayer()
    return PlayerDevelopmentSystem.GetInstance(player):GetDevelopmentData(player)
end

-- kind: "Primary" (perks) | "Attribute" | "Espionage" (relic)
local function givePoints(kind, qty, label)
    local ok, err = pcall(function()
        devData():AddDevelopmentPoints(qty, gamedataDevelopmentPointType[kind])
    end)
    if ok then
        notify((qty > 0 and "+" or "") .. qty .. " " .. label)
    else
        notify(label .. " " .. t("failed"))
        spdlog.info("GiveMeEverything: AddDevelopmentPoints " .. kind .. " failed: " .. tostring(err))
    end
end

-- kind: gamedataProficiencyType name ("Level", "StreetCred", "CoolSkill", ...)
local function giveXP(kind, qty, label)
    local ok, err = pcall(function()
        devData():AddExperience(qty, gamedataProficiencyType[kind], telemetryLevelGainReason.Ignore)
    end)
    if ok then
        notify("+" .. qty .. " " .. label)
    else
        notify(label .. " " .. t("failed"))
        spdlog.info("GiveMeEverything: AddExperience " .. kind .. " failed: " .. tostring(err))
    end
end

local function hasItem(id)
    local ok, found = pcall(function()
        return Game.GetTransactionSystem():HasItem(Game.GetPlayer(), ItemID.FromTDBID(TweakDBID.new(id)))
    end)
    return ok and found
end

-- checking ~110 items per frame stutters; cache and refresh on overlay open / after giving
local ownedCache = {}
function refreshOwned()
    for _, list in ipairs({ WEAPONS, GEAR }) do
        for _, group in ipairs(list) do
            for _, w in ipairs(group.weapons) do
                if w.id then ownedCache[w.id] = hasItem(w.id) end
            end
        end
    end
end

local function giveWeapon(w)
    Game.AddToInventory(w.id, 1)
    ownedCache[w.id] = true
    notify("+1 " .. w.label)
end

-- value 100 = percent of max (same call/flags EasyTrainers uses)
local function setPool(pool)
    Game.GetStatPoolsSystem():RequestSettingStatPoolValue(
        Game.GetPlayer():GetEntityID(), gamedataStatPoolType[pool], 100, Game.GetPlayer(), true, true)
end

local function healPlayer()
    local ok, err = pcall(function()
        setPool("Health")
        setPool("Stamina")
        setPool("Memory")
    end)
    if ok then
        notify(t("healed"))
    else
        notify(t("heal") .. " " .. t("failed"))
        spdlog.info("GiveMeEverything: heal failed: " .. tostring(err))
    end
end

local AMMO_QTY = { ammo1 = 500, ammo2 = 500, ammo3 = 200, ammo4 = 100 }

local function refillAmmo()
    for key, qty in pairs(AMMO_QTY) do
        if items[key] then Game.AddToInventory(items[key], qty) end
    end
    notify(t("ammofull"))
end

local function clearWanted()
    local ok, err = pcall(function()
        Game.GetScriptableSystemsContainer():Get("PreventionSystem")
            :ChangeHeatStage(EPreventionHeatStage.Heat_0, "")
    end)
    if ok then
        notify(t("wantedcleared"))
    else
        notify(t("ncpd") .. " " .. t("failed"))
        spdlog.info("GiveMeEverything: ChangeHeatStage failed: " .. tostring(err))
    end
end

-- the mod's namesake: money, all components, consumables, ammo, every weapon and gear piece
local function giveEverything()
    Game.AddToInventory("Items.money", 10000000)
    local qtys = {
        comp1 = 1000, comp2 = 1000, comp3 = 1000, comp4 = 1000, comp5 = 1000,
        qh1 = 500, qh2 = 500, qh3 = 500, qh4 = 500, qh5 = 500,
        shard = 5, maxdoc = 20, bounce = 20,
        grenade = 20, gemp = 20, ginc = 20, gflash = 20, grecon = 20, gsmoke = 20, gbio = 20, ozob = 10,
        ammo1 = 500, ammo2 = 500, ammo3 = 200, ammo4 = 100,
        perkreset = 3,
    }
    for key, qty in pairs(qtys) do
        if items[key] then Game.AddToInventory(items[key], qty) end
    end
    local n = 0
    for _, list in ipairs({ WEAPONS, GEAR }) do
        for _, group in ipairs(list) do
            for _, w in ipairs(group.weapons) do
                if w.id and not ownedCache[w.id] then
                    Game.AddToInventory(w.id, 1)
                    ownedCache[w.id] = true
                    n = n + 1
                end
            end
        end
    end
    notify("GIVE ME EVERYTHING: +" .. n .. " " .. t("itemsgiven"))
end

registerHotkey("GME_Heal", "Full heal (HP/stamina/RAM)", healPlayer)
registerHotkey("GME_Ammo", "Refill ammo", refillAmmo)
registerHotkey("GME_ClearWanted", "Clear NCPD wanted level", clearWanted)

local COL = 170  -- label column width; buttons align after it
local customQty = 0  -- when > 0, every item row gets an extra +custom button

-- one row per resource: label, then [-qty] [+qty] [+custom]
local function itemRow(label, key, qty)
    if not items[key] then return end
    ImGui.Text(label)
    ImGui.SameLine(COL)
    if ImGui.Button("-" .. qty .. "##" .. key) then removeItem(items[key], qty, label) end
    ImGui.SameLine()
    if ImGui.Button("+" .. qty .. "##" .. key) then addItem(items[key], qty, label) end
    if customQty > 0 then
        ImGui.SameLine()
        if ImGui.Button("+" .. customQty .. "##c" .. key) then addItem(items[key], customQty, label) end
    end
end

local function pointRow(labelKey, kind)
    ImGui.Text(t(labelKey))
    ImGui.SameLine(COL)
    if ImGui.Button("-10##" .. labelKey) then givePoints(kind, -10, t(labelKey)) end
    ImGui.SameLine()
    if ImGui.Button("-1##" .. labelKey) then givePoints(kind, -1, t(labelKey)) end
    ImGui.SameLine()
    if ImGui.Button("+1##" .. labelKey) then givePoints(kind, 1, t(labelKey)) end
    ImGui.SameLine()
    if ImGui.Button("+10##" .. labelKey) then givePoints(kind, 10, t(labelKey)) end
end

-- XP has no safe "remove" in-game, so add-only
local function xpRow(label, kind, q1, q2)
    ImGui.Text(label)
    ImGui.SameLine(COL)
    if ImGui.Button("+" .. q1 .. "##" .. kind) then giveXP(kind, q1, label) end
    ImGui.SameLine()
    if ImGui.Button("+" .. q2 .. "##" .. kind) then giveXP(kind, q2, label) end
end

local function moneyRow(qty, label)
    ImGui.Text(label)
    ImGui.SameLine(COL)
    if ImGui.Button("-" .. label .. "##m") then removeItem("Items.money", qty, "$") end
    ImGui.SameLine()
    if ImGui.Button("+" .. label .. "##m") then addItem("Items.money", qty, "$") end
end

local function customQtyRow()
    ImGui.SetNextItemWidth(150)
    local value, changed = ImGui.InputInt(t("customqty"), customQty, 100)
    if changed then customQty = math.max(0, value) end
    if customQty > 0 then
        ImGui.Text("$")
        ImGui.SameLine(COL)
        if ImGui.Button("-" .. customQty .. "##cm") then removeItem("Items.money", customQty, "$") end
        ImGui.SameLine()
        if ImGui.Button("+" .. customQty .. "##cm") then addItem("Items.money", customQty, "$") end
    end
end

local function romanceRow(name, fact)
    ImGui.Text(name)
    ImGui.SameLine(COL)
    local qs = Game.GetQuestsSystem()
    if qs:GetFactStr(fact) == 1 then
        ImGui.Text(t("unlocked"))
    elseif ImGui.Button(t("unlock") .. "##" .. fact) then
        qs:SetFactStr(fact, 1)
        notify(name .. ": " .. t("romunlocked"))
    end
end

local OPEN = ImGuiTreeNodeFlags.DefaultOpen
local WCOL = 220  -- weapons need a wider label column

local function drawItemsTab()
    if ImGui.Button("GIVE ME EVERYTHING", -1, 32) then giveEverything() end
    customQtyRow()
    ImGui.Separator()
    if ImGui.CollapsingHeader(t("money"), OPEN) then
        moneyRow(100000, "100K")
        moneyRow(1000000, "1M")
        moneyRow(10000000, "10M")
    end
    if ImGui.CollapsingHeader(t("crafting"), OPEN) then
        itemRow("Tier 1", "comp1", 1000)
        itemRow("Tier 2", "comp2", 1000)
        itemRow("Tier 3", "comp3", 1000)
        itemRow("Tier 4", "comp4", 1000)
        itemRow("Tier 5", "comp5", 1000)
    end
    if ImGui.CollapsingHeader(t("quickhack"), OPEN) then
        itemRow("Tier 1", "qh1", 500)
        itemRow("Tier 2", "qh2", 500)
        itemRow("Tier 3", "qh3", 500)
        itemRow("Tier 4", "qh4", 500)
        itemRow("Tier 5", "qh5", 500)
    end
    if ImGui.CollapsingHeader(t("cyberware"), OPEN) then
        itemRow(t("shard"), "shard", 1)
        itemRow(t("shard"), "shard", 5)
    end
end

local function drawConsumTab()
    if ImGui.CollapsingHeader(t("healhdr"), OPEN) then
        itemRow("MaxDoc", "maxdoc", 20)
        itemRow("Bounce Back", "bounce", 20)
        if ImGui.Button(t("heal")) then healPlayer() end
    end
    if ImGui.CollapsingHeader(t("grenades"), OPEN) then
        itemRow("Frag", "grenade", 20)
        itemRow("EMP", "gemp", 20)
        itemRow(t("ginc"), "ginc", 20)
        itemRow("Flash", "gflash", 20)
        itemRow("Recon", "grecon", 20)
        itemRow(t("gsmoke"), "gsmoke", 20)
        itemRow(t("gbio"), "gbio", 20)
        itemRow("Ozob's Nose", "ozob", 10)
    end
    if ImGui.CollapsingHeader(t("ammo"), OPEN) then
        itemRow("Pistol / SMG", "ammo1", 500)
        itemRow("Rifle", "ammo2", 500)
        itemRow("Shotgun", "ammo3", 200)
        itemRow("Sniper", "ammo4", 100)
    end
end

-- Game.SetLevel queues SetProficiencyLevel on PlayerDevelopmentSystem (native, patch 2.x)
local levelTargets = {}
local function setLevelRow(label, kind, maxLv)
    ImGui.Text(label)
    ImGui.SameLine(COL)
    ImGui.SetNextItemWidth(100)
    local v, changed = ImGui.InputInt("##lv" .. kind, levelTargets[kind] or maxLv, 1)
    if changed then levelTargets[kind] = math.min(math.max(v, 1), maxLv) end
    ImGui.SameLine()
    if ImGui.Button(t("setlevel") .. "##" .. kind) then
        local target = levelTargets[kind] or maxLv
        local ok, err = pcall(function() Game.SetLevel(kind, target, 1) end)
        if ok then
            notify(label .. " " .. target .. ": " .. t("levelset"))
        else
            notify(label .. " " .. t("failed"))
            spdlog.info("GiveMeEverything: SetLevel " .. kind .. " failed: " .. tostring(err))
        end
    end
end

local function drawProgressionTab()
    if ImGui.CollapsingHeader(t("progression"), OPEN) then
        pointRow("perks", "Primary")
        pointRow("attributes", "Attribute")
        pointRow("relic", "Espionage")
        xpRow(t("levelxp"), "Level", 1000, 10000)
        xpRow(t("streetcred"), "StreetCred", 1000, 10000)
        itemRow(t("perkreset"), "perkreset", 1)
    end
    if ImGui.CollapsingHeader(t("skills"), OPEN) then
        xpRow("Solo", "StrengthSkill", 1000, 10000)
        xpRow("Shinobi", "ReflexesSkill", 1000, 10000)
        xpRow("Netrunner", "IntelligenceSkill", 1000, 10000)
        xpRow("Engineer", "TechnicalAbilitySkill", 1000, 10000)
        xpRow("Headhunter", "CoolSkill", 1000, 10000)
    end
    if ImGui.CollapsingHeader(t("setlevelhdr"), OPEN) then
        setLevelRow(t("lvl"), "Level", 60)
        setLevelRow(t("streetcred"), "StreetCred", 50)
        setLevelRow("Solo", "StrengthSkill", 60)
        setLevelRow("Shinobi", "ReflexesSkill", 60)
        setLevelRow("Netrunner", "IntelligenceSkill", 60)
        setLevelRow("Engineer", "TechnicalAbilitySkill", 60)
        setLevelRow("Headhunter", "CoolSkill", 60)
    end
    if ImGui.CollapsingHeader(t("xpmult"), OPEN) then
        local value, changed = ImGui.SliderInt("##xpmult", settings.xpmult, 1, 10, "%dx")
        if changed then
            settings.xpmult = value
            saveSettings()
        end
        ImGui.TextWrapped(t("xpmulthint"))
    end
    if ImGui.CollapsingHeader(t("dmgmult"), OPEN) then
        local value, changed = ImGui.SliderInt("##dmgmult", settings.dmgmult, 1, 10, "%dx")
        if changed then
            settings.dmgmult = value
            saveSettings()
            applyDmgMult()
        end
        ImGui.TextWrapped(t("dmgmulthint"))
    end
end

local function weaponRow(w)
    ImGui.Text(w.label)
    ImGui.SameLine(WCOL)
    if ownedCache[w.id] then
        ImGui.Text(t("owned"))
    elseif ImGui.Button(t("give") .. "##" .. w.id) then
        giveWeapon(w)
    end
end

local filters = {}

-- shared by Weapons and Gear tabs: search field + grouped list with give-all
local function drawGearList(id, groups)
    ImGui.SetNextItemWidth(220)
    local text, changed = ImGui.InputTextWithHint("##filter" .. id, t("search"), filters[id] or "", 64)
    if changed then filters[id] = text end
    ImGui.Separator()

    -- filter active: flat list across all groups, headers skipped
    local needle = (filters[id] or ""):lower()
    if needle ~= "" then
        local found = 0
        for _, group in ipairs(groups) do
            for _, w in ipairs(group.weapons) do
                if w.id and w.label:lower():find(needle, 1, true) then
                    weaponRow(w)
                    found = found + 1
                end
            end
        end
        if found == 0 then ImGui.Text(t("noresults")) end
        return
    end

    for _, group in ipairs(groups) do
        if ImGui.CollapsingHeader(t(group.key)) then
            if ImGui.Button(t("giveall") .. "##" .. group.key) then
                local n = 0
                for _, w in ipairs(group.weapons) do
                    if w.id and not ownedCache[w.id] then
                        Game.AddToInventory(w.id, 1)
                        ownedCache[w.id] = true
                        n = n + 1
                    end
                end
                notify("+" .. n .. " " .. t("itemsgiven"))
            end
            for _, w in ipairs(group.weapons) do
                if w.id then weaponRow(w) end
            end
        end
    end
end

local ncpdDisabled = false
local function drawNcpdSection()
    if ImGui.Button(t("clearwanted")) then clearWanted() end
    local value, changed = ImGui.Checkbox(t("ncpdoff"), ncpdDisabled)
    if changed then
        local ok, err = pcall(function()
            Game.GetScriptableSystemsContainer():Get("PreventionSystem")
                :TogglePreventionSystem(not value)
        end)
        if ok then
            ncpdDisabled = value
        else
            notify(t("ncpd") .. " " .. t("failed"))
            spdlog.info("GiveMeEverything: TogglePreventionSystem failed: " .. tostring(err))
        end
    end
end

local function drawUnlocksTab()
    if ImGui.CollapsingHeader(t("romances"), OPEN) then
        romanceRow("Judy", "judy_romanceable")
        romanceRow("Panam", "panam_romanceable")
        romanceRow("River", "river_romanceable")
        romanceRow("Kerry", "kerry_romanceable")
    end
    if ImGui.CollapsingHeader(t("vehicles"), OPEN) then
        if ImGui.Button(t("unlockveh")) then
            local ok, err = pcall(function() Game.GetVehicleSystem():EnableAllPlayerVehicles() end)
            if ok then
                notify(t("vehunlocked"))
            else
                notify(t("vehicles") .. " " .. t("failed"))
                spdlog.info("GiveMeEverything: EnableAllPlayerVehicles failed: " .. tostring(err))
            end
        end
    end
    if ImGui.CollapsingHeader(t("ncpd"), OPEN) then
        drawNcpdSection()
    end
end

-- cyberpunk-ish look: yellow accents, teal headers, angular corners; only this window
local function pushTheme()
    ImGui.PushStyleColor(ImGuiCol.WindowBg,        0.07, 0.07, 0.05, 0.97)
    ImGui.PushStyleColor(ImGuiCol.Border,          0.96, 0.88, 0.05, 0.45)
    ImGui.PushStyleColor(ImGuiCol.TitleBg,         0.10, 0.10, 0.06, 1.00)
    ImGui.PushStyleColor(ImGuiCol.TitleBgActive,   0.35, 0.32, 0.02, 1.00)
    ImGui.PushStyleColor(ImGuiCol.TitleBgCollapsed,0.10, 0.10, 0.06, 0.80)
    ImGui.PushStyleColor(ImGuiCol.Tab,             0.15, 0.15, 0.10, 1.00)
    ImGui.PushStyleColor(ImGuiCol.TabHovered,      0.55, 0.50, 0.03, 1.00)
    ImGui.PushStyleColor(ImGuiCol.TabActive,       0.42, 0.38, 0.02, 1.00)
    ImGui.PushStyleColor(ImGuiCol.Header,          0.10, 0.28, 0.31, 0.85)
    ImGui.PushStyleColor(ImGuiCol.HeaderHovered,   0.08, 0.42, 0.47, 0.90)
    ImGui.PushStyleColor(ImGuiCol.HeaderActive,    0.05, 0.52, 0.58, 1.00)
    ImGui.PushStyleColor(ImGuiCol.Button,          0.16, 0.16, 0.12, 1.00)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered,   0.50, 0.46, 0.03, 1.00)
    ImGui.PushStyleColor(ImGuiCol.ButtonActive,    0.70, 0.64, 0.04, 1.00)
    ImGui.PushStyleColor(ImGuiCol.FrameBg,         0.13, 0.13, 0.09, 1.00)
    ImGui.PushStyleColor(ImGuiCol.FrameBgHovered,  0.20, 0.20, 0.13, 1.00)
    ImGui.PushStyleColor(ImGuiCol.FrameBgActive,   0.28, 0.26, 0.10, 1.00)
    ImGui.PushStyleColor(ImGuiCol.SliderGrab,      0.96, 0.88, 0.05, 1.00)
    ImGui.PushStyleColor(ImGuiCol.SliderGrabActive,1.00, 0.95, 0.30, 1.00)
    ImGui.PushStyleColor(ImGuiCol.CheckMark,       0.96, 0.88, 0.05, 1.00)
    ImGui.PushStyleColor(ImGuiCol.Separator,       0.96, 0.88, 0.05, 0.35)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 0)
    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 0)
    ImGui.PushStyleVar(ImGuiStyleVar.TabRounding, 0)
    return 21, 3
end

registerForEvent("onDraw", function()
    if not overlayOpen then return end
    local nCol, nVar = pushTheme()
    if not ImGui.Begin("Give Me Everything", ImGuiWindowFlags.AlwaysAutoResize) then
        ImGui.End()
        ImGui.PopStyleColor(nCol)
        ImGui.PopStyleVar(nVar)
        return
    end

    if ImGui.BeginTabBar("##gmetabs") then
        if ImGui.BeginTabItem(t("tabitems")) then
            drawItemsTab()
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem(t("consumables")) then
            drawConsumTab()
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem(t("tabprog")) then
            drawProgressionTab()
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem(t("tabweapons")) then
            drawGearList("w", WEAPONS)
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem(t("tabgear")) then
            drawGearList("g", GEAR)
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem(t("tabunlocks")) then
            drawUnlocksTab()
            ImGui.EndTabItem()
        end
        ImGui.EndTabBar()
    end

    ImGui.End()
    ImGui.PopStyleColor(nCol)
    ImGui.PopStyleVar(nVar)
end)
