-- Give Me Everything - in-game panel for the CET overlay (opens with the console)
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
        unlockveh    = "Unlock ALL vehicles",
        vall         = "All vehicles",
        vehwarn      = "Unlock vehicles to call them from your phone. \"Unlock ALL\" grabs every one; the list below unlocks them one by one.",
        unlockbtn    = "Unlock",
        vehdone      = "unlocked",
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
        results      = "results",
        giveallres   = "Give all results",
        showing300   = "(showing first 300)",
        qualcommon   = "Common",
        qualuncommon = "Uncommon",
        qualrare     = "Rare",
        qualepic     = "Epic",
        quallegend   = "Legendary / Iconic",
        uiscale      = "UI scale",
        vcars        = "Cars",
        vbikes       = "Motorcycles",
        varmed       = "Armed",
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
        godmode      = "God mode / toggles",
        tgod         = "Invincibility (HP kept full)",
        tstamina     = "Infinite stamina",
        tinfammo     = "Infinite ammo",
        toneshot     = "Massive damage (one-shot)",
        godhint      = "Toggles stay on across saves. Invincibility holds HP at max each frame - near-immortal, a single huge hit can still register.",
        on           = "ON",
        off          = "OFF",
        tabsearch    = "Search",
        tabquests    = "Quests",
        qcatmain     = "Main story",
        qcatending   = "Affects ending",
        qcatcosmetic = "Cosmetic",
        qnopl        = "Phantom Liberty not detected - showing base game only.",
        qactpro      = "Prologue",
        qact1        = "Act 1",
        qact2        = "Act 2",
        qact3        = "Act 3 / Point of no return",
        qactendings  = "Side jobs that change the ending",
        qactside     = "Side jobs (cosmetic - no ending impact)",
        qactpl       = "Phantom Liberty - Main story",
        qactplside   = "Phantom Liberty - Side jobs",
        qguide       = "Ending guide (reference)",
        qdone        = "Done",
        qactive      = "In progress",
        qtodo        = "Not started",
        qfailed      = "Failed",
        qlocate      = "Locate",
        qrefresh     = "Refresh",
        qtracked     = "Now tracking this quest",
        qreadfail    = "Could not read the journal. Load a save and hit Refresh.",
        favorites    = "Favorites",
        searchall    = "Search all items...",
        searchhint   = "Type to find any weapon, cyberware, clothing, mod or vehicle across every tab.",
        addfav       = "+fav",
        rmfav        = "-fav",
        undo         = "Undo last give",
        undonone     = "Nothing to undo",
        undodone     = "Undone",
        undofail     = "Undo failed",
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
        gcyber       = "Cyberware - other",
        gjohnny      = "Johnny Silverhand set",
        gclothes     = "Clothing",
        tabclothes   = "Clothing",
        clothwarn    = "Warning: taking every clothing item will leave V heavily overweight - barely able to walk until you stash or sell the pile.",
        clothall     = "Give ALL clothing",
        areahead     = "Head",
        areaface     = "Face",
        areaouter    = "Jackets / Coats",
        areainner    = "Shirts / Tops",
        arealegs     = "Pants",
        areafeet     = "Shoes",
        areaoutfit   = "Outfits",
        areaother    = "Other",
        tcaw         = "All cyberware",
        cawall       = "Give ALL cyberware",
        cawwarn      = "Every cyberware in the game. More than V's capacity can hold - extras sit in the inventory until equipped.",
        cfront       = "Frontal Cortex",
        cos          = "Operating System",
        cface        = "Face",
        ccirc        = "Circulatory System",
        cnerv        = "Nervous System",
        cinteg       = "Skin",
        chand        = "Hands",
        carm         = "Arms",
        cskel        = "Skeleton",
        cleg         = "Legs",
        taballweapons = "All weapons",
        weapall      = "Give ALL weapons",
        weapwarn     = "Warning: taking every weapon will also leave V heavily overweight.",
        tabmods      = "Weapon mods",
        modall       = "Give ALL mods",
        modwarn      = "Attachments and mods weigh little, but there are a lot of them.",
        mscopes      = "Scopes",
        mmuzzles     = "Muzzles / Silencers",
        mranged      = "Ranged weapon mods",
        mmelee       = "Melee mods",
        mcloth       = "Clothing mods",
        tabcarry     = "Carry weight",
        carrybonus   = "Extra carry capacity",
        carryhint    = "Adds to V's carry capacity. 0 = off. Reapplies automatically on load - pairs well with the give-everything buttons.",
        recipes      = "Crafting recipes",
        recipesall   = "Unlock all crafting recipes",
        recipesdone  = "recipes learned",
        dupes        = "Duplicates",
        dupesbtn     = "Sell duplicates (keep best of each)",
        dupeshint    = "Scans weapons, clothing and cyberware in your inventory: same name = duplicate. Keeps the highest tier, sells the rest. Equipped and quest items are never touched.",
        dupesdone    = "duplicates sold",
        dupesnone    = "No duplicates found",
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
        unlockveh    = "Desbloquear TODOS os veículos",
        vall         = "Todos os veículos",
        vehwarn      = "Desbloqueie veículos para chamá-los pelo celular. \"Desbloquear TODOS\" pega todos de uma vez; a lista abaixo desbloqueia um por um.",
        unlockbtn    = "Desbloquear",
        vehdone      = "desbloqueado",
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
        results      = "resultados",
        giveallres   = "Dar todos os resultados",
        showing300   = "(mostrando os 300 primeiros)",
        qualcommon   = "Comum",
        qualuncommon = "Incomum",
        qualrare     = "Raro",
        qualepic     = "Épico",
        quallegend   = "Lendário / Icônico",
        uiscale      = "Escala da interface",
        vcars        = "Carros",
        vbikes       = "Motos",
        varmed       = "Armados",
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
        godmode      = "God mode / toggles",
        tgod         = "Invencibilidade (HP sempre cheio)",
        tstamina     = "Stamina infinita",
        tinfammo     = "Munição infinita",
        toneshot     = "Dano massivo (one-shot)",
        godhint      = "Os toggles ficam ligados entre saves. Invencibilidade trava o HP no máximo a cada frame - quase imortal, um dano único enorme ainda pode registrar.",
        on           = "LIGADO",
        off          = "DESLIGADO",
        tabsearch    = "Busca",
        tabquests    = "Missões",
        qcatmain     = "Principal",
        qcatending   = "Afeta o final",
        qcatcosmetic = "Secundária",
        qnopl        = "Phantom Liberty não detectado - mostrando só o jogo base.",
        qactpro      = "Prólogo",
        qact1        = "Ato 1",
        qact2        = "Ato 2",
        qact3        = "Ato 3 / Ponto sem retorno",
        qactendings  = "Secundárias que mudam o final",
        qactside     = "Secundárias (cosméticas - não mudam o final)",
        qactpl       = "Phantom Liberty - Principal",
        qactplside   = "Phantom Liberty - Secundárias",
        qguide       = "Guia por final (referência)",
        qdone        = "Feitas",
        qactive      = "Em andamento",
        qtodo        = "Não iniciadas",
        qfailed      = "Falhadas",
        qlocate      = "Localizar",
        qrefresh     = "Atualizar",
        qtracked     = "Rastreando esta missão agora",
        qreadfail    = "Não deu pra ler o diário. Carregue um save e clique Atualizar.",
        favorites    = "Favoritos",
        searchall    = "Buscar em tudo...",
        searchhint   = "Digite para achar qualquer arma, cyberware, roupa, mod ou veículo em todas as abas.",
        addfav       = "+fav",
        rmfav        = "-fav",
        undo         = "Desfazer último",
        undonone     = "Nada para desfazer",
        undodone     = "Desfeito",
        undofail     = "Falha ao desfazer",
        dmgmult      = "Multiplicador de dano",
        dmgmulthint  = "Multiplica todo dano causado, quickhacks incluídos. 1x = desligado.",
        perkreset    = "Shard de reset de perks",
        ginc         = "Incendiária",
        gsmoke       = "Fumaça",
        gbio         = "Biorisco",
        healhdr      = "Cura",
        gcyber       = "Cyberware - outros",
        gjohnny      = "Set do Johnny Silverhand",
        gclothes     = "Roupas",
        tabclothes   = "Roupas",
        clothwarn    = "Aviso: pegar todas as roupas deixa V com excesso de peso - mal vai conseguir andar até guardar ou vender a pilha.",
        clothall     = "Dar TODAS as roupas",
        areahead     = "Cabeça",
        areaface     = "Rosto",
        areaouter    = "Jaquetas / Casacos",
        areainner    = "Camisas / Tops",
        arealegs     = "Calças",
        areafeet     = "Sapatos",
        areaoutfit   = "Conjuntos",
        areaother    = "Outros",
        tcaw         = "Cyberware (todos)",
        cawall       = "Dar TODOS os cyberware",
        cawwarn      = "Todo cyberware do jogo. Passa da capacidade de V - o excedente fica no inventário até ser equipado.",
        cfront       = "Córtex Frontal",
        cos          = "Sistema Operacional",
        cface        = "Rosto",
        ccirc        = "Sistema Circulatório",
        cnerv        = "Sistema Nervoso",
        cinteg       = "Pele",
        chand        = "Mãos",
        carm         = "Braços",
        cskel        = "Esqueleto",
        cleg         = "Pernas",
        taballweapons = "Armas (todas)",
        weapall      = "Dar TODAS as armas",
        weapwarn     = "Aviso: pegar todas as armas também deixa V com excesso de peso.",
        tabmods      = "Mods de arma",
        modall       = "Dar TODOS os mods",
        modwarn      = "Acessórios e mods pesam pouco, mas são muitos.",
        mscopes      = "Miras",
        mmuzzles     = "Bocais / Silenciadores",
        mranged      = "Mods de arma de fogo",
        mmelee       = "Mods corpo a corpo",
        mcloth       = "Mods de roupa",
        tabcarry     = "Carga",
        carrybonus   = "Capacidade de carga extra",
        carryhint    = "Soma à capacidade de carga de V. 0 = desligado. Reaplica sozinho ao carregar o jogo - combina com os botões de dar tudo.",
        recipes      = "Receitas de craft",
        recipesall   = "Desbloquear todas as receitas",
        recipesdone  = "receitas aprendidas",
        dupes        = "Duplicatas",
        dupesbtn     = "Vender duplicatas (mantém a melhor de cada)",
        dupeshint    = "Varre armas, roupas e cyberware do inventário: mesmo nome = duplicata. Mantém a de maior tier, vende o resto. Itens equipados e de missão nunca são tocados.",
        dupesdone    = "duplicatas vendidas",
        dupesnone    = "Nenhuma duplicata encontrada",
    },
}

-- settings.json holds lang + multipliers; lang.txt kept as read-only fallback (pre-1.2.0)
local settings = { lang = "en", xpmult = 1, dmgmult = 1, carrybonus = 0, uiscale = 1.0,
    god = false, stamina = false, infammo = false, oneshot = false, favorites = {} }

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
            local c = tonumber(saved.carrybonus)
            if c and c >= 0 and c <= 50000 then settings.carrybonus = math.floor(c) end
            local u = tonumber(saved.uiscale)
            if u and u >= 0.8 and u <= 1.6 then settings.uiscale = u end
            settings.god = saved.god == true
            settings.stamina = saved.stamina == true
            settings.infammo = saved.infammo == true
            settings.oneshot = saved.oneshot == true
            if type(saved.favorites) == "table" then
                settings.favorites = {}
                for _, f in ipairs(saved.favorites) do
                    if type(f) == "table" and type(f.src) == "string" and type(f.label) == "string" then
                        settings.favorites[#settings.favorites + 1] = { src = f.src, label = f.label, id = f.id }
                    end
                end
            end
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
-- so mult N = modifier N-1. Modifiers die with the player entity; on OnGameAttached the
-- player isn't queryable yet, so reapply retries via onUpdate until Game.GetPlayer() works.
local dmgMod = nil
local carryMod = nil
local osMod = nil
local statPending = 0
local ONESHOT_VALUE = 100000  -- +100000x damage: kills anything short of a scripted-invuln target
-- forward-declared: the onUpdate toggle loop (below) closes over these before they're assigned
local setPool, refillAmmoSilent
-- undo tracks only the last single item give (points/XP/unlocks/vehicles can't be undone);
-- each item give stores an undo closure, bulk gives clear it
local lastGive = nil

-- shared shape for the damage and carry-capacity modifiers: drop old handle, add if enabled
local function applyStatMod(handle, statType, enabled, value)
    local newHandle = handle
    local ok, err = pcall(function()
        local player = Game.GetPlayer()
        if not player then return end
        local stats = Game.GetStatsSystem()
        if newHandle then
            stats:RemoveModifier(player:GetEntityID(), newHandle)
            newHandle = nil
        end
        if enabled then
            newHandle = RPGManager.CreateStatModifier(statType, gameStatModifierType.Additive, value)
            stats:AddModifier(player:GetEntityID(), newHandle)
        end
    end)
    if not ok then spdlog.info("GiveMeEverything: stat mod failed: " .. tostring(err)) end
    return newHandle
end

local function applyDmgMult()
    dmgMod = applyStatMod(dmgMod, gamedataStatType.AllDamageDonePercentBonus,
        settings.dmgmult > 1, settings.dmgmult - 1)
end

local function applyCarryBonus()
    carryMod = applyStatMod(carryMod, gamedataStatType.CarryCapacity,
        settings.carrybonus > 0, settings.carrybonus)
end

local function applyOneShot()
    osMod = applyStatMod(osMod, gamedataStatType.AllDamageDonePercentBonus,
        settings.oneshot, ONESHOT_VALUE)
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
    loadSettings()  -- file-scope load can run before CET's io is ready; redo here
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
        dmgMod = nil  -- old handles died with the previous player entity
        carryMod = nil
        osMod = nil
        if settings.dmgmult > 1 or settings.carrybonus > 0 or settings.oneshot then statPending = 2.0 end
    end)

    -- CET reloaded mid-session: no OnGameAttached will come, apply on the running player
    if settings.dmgmult > 1 or settings.carrybonus > 0 or settings.oneshot then statPending = 2.0 end
end)

local ammoAcc = 0
registerForEvent("onUpdate", function(dt)
    if statPending > 0 then
        statPending = statPending - dt
        if statPending <= 0 then
            if Game.GetPlayer() then
                applyDmgMult()
                applyCarryBonus()
                applyOneShot()
            else
                statPending = 1.0  -- player not up yet (main menu / still loading), try again
            end
        end
    end
    -- god/stamina/infammo are held by re-setting each frame, so they resume on their own after a reload
    if settings.god or settings.stamina or settings.infammo then
        if Game.GetPlayer() then
            if settings.god then pcall(setPool, "Health") end
            if settings.stamina then pcall(setPool, "Stamina") end
            if settings.infammo then
                ammoAcc = ammoAcc + dt
                if ammoAcc >= 1.0 then ammoAcc = 0; pcall(refillAmmoSilent) end
            end
        end
    end
end)

local function addItem(id, qty, label)
    Game.AddToInventory(id, qty)
    notify("+" .. qty .. " " .. label)
    lastGive = { label = qty .. " " .. label, undo = function()
        Game.GetTransactionSystem():RemoveItem(Game.GetPlayer(), ItemID.FromTDBID(TweakDBID.new(id)), qty)
    end }
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
    lastGive = { label = w.label, undo = function()
        Game.GetTransactionSystem():RemoveItem(Game.GetPlayer(), ItemID.FromTDBID(TweakDBID.new(w.id)), 1)
    end }
end

-- value 100 = percent of max (same call/flags EasyTrainers uses)
setPool = function(pool)
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

local AMMO_QTY = { ammo1 = 9999, ammo2 = 9999, ammo3 = 9999, ammo4 = 9999 }
local AMMO_MIN = 50 -- top up only when nearly empty; reserve caps below a few hundred, so a
-- higher threshold would re-trigger every tick and spam the pickup toast

-- GiveItem (not AddToInventory), and only when the stock is low, so infinite ammo doesn't
-- spam the game's pickup toast every second.
refillAmmoSilent = function()
    local ts = Game.GetTransactionSystem()
    local player = Game.GetPlayer()
    if not ts or not player then return end
    for key, qty in pairs(AMMO_QTY) do
        if items[key] then
            local id = ItemID.FromTDBID(TweakDBID.new(items[key]))
            local have = 0
            pcall(function() have = ts:GetItemQuantity(player, id) end)
            if have < AMMO_MIN then ts:GiveItem(player, id, qty) end
        end
    end
end

local function refillAmmo()
    refillAmmoSilent()
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

local function undoLast()
    if not lastGive then notify(t("undonone")); return end
    local label = lastGive.label
    local ok, err = pcall(lastGive.undo)
    if ok then
        notify(t("undodone") .. ": " .. label)
        lastGive = nil
    else
        notify(t("undofail"))
        spdlog.info("GiveMeEverything: undo failed: " .. tostring(err))
    end
end

-- the mod's namesake: money, all components, consumables, ammo, every weapon and gear piece
local function giveEverything()
    lastGive = nil  -- bulk give: nothing single to undo
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

local function toggle(key, labelKey)
    settings[key] = not settings[key]
    if key == "oneshot" then applyOneShot() end
    saveSettings()
    notify(t(labelKey) .. ": " .. (settings[key] and t("on") or t("off")))
end
registerHotkey("GME_GodMode", "Toggle invincibility", function() toggle("god", "tgod") end)
registerHotkey("GME_InfStamina", "Toggle infinite stamina", function() toggle("stamina", "tstamina") end)
registerHotkey("GME_InfAmmo", "Toggle infinite ammo", function() toggle("infammo", "tinfammo") end)
registerHotkey("GME_OneShot", "Toggle massive damage", function() toggle("oneshot", "toneshot") end)
registerHotkey("GME_Undo", "Undo last item give", function() undoLast() end)

local COL = 170  -- label column width; buttons align after it
local customQty = 0  -- when > 0, every item row gets an extra +custom button
local function bw(px) return px * (settings.uiscale or 1) end

-- zebra-striped list wrapper; plain list fallback if this CET build lacks the tables API.
-- explicit row colors: the default alt-row tint is invisible over the dark theme
local zebraOn = false
local function beginList(uid)
    if ImGui.BeginTable == nil or ImGuiTableFlags == nil or ImGuiCol.TableRowBg == nil then
        zebraOn = false
        return false
    end
    ImGui.PushStyleColor(ImGuiCol.TableRowBg, 0, 0, 0, 0)
    ImGui.PushStyleColor(ImGuiCol.TableRowBgAlt, 1.00, 0.92, 0.40, 0.09)
    -- no SizingFixedFit: fixed columns cache their width, clipping rows after a UI-scale change
    local ok = ImGui.BeginTable("##z" .. uid, 1, ImGuiTableFlags.RowBg)
    if not ok then ImGui.PopStyleColor(2) end
    zebraOn = ok
    return ok
end

-- nil = use the section-level zebra state; row helpers call this with no argument
local function listRow(z)
    if z == nil then z = zebraOn end
    if z then ImGui.TableNextRow(); ImGui.TableNextColumn() end
end

local function endList(z)
    if z == nil then z = zebraOn end
    if z then ImGui.EndTable(); ImGui.PopStyleColor(2) end
    zebraOn = false
end

-- one row per resource: label, then [-qty] [+qty] [+custom]
local function itemRow(label, key, qty)
    if not items[key] then return end
    listRow()
    ImGui.Text(label)
    ImGui.SameLine(COL * (settings.uiscale or 1))
    if ImGui.Button("-" .. qty .. "##" .. key, bw(92), 0) then removeItem(items[key], qty, label) end
    ImGui.SameLine()
    if ImGui.Button("+" .. qty .. "##" .. key, bw(92), 0) then addItem(items[key], qty, label) end
    if customQty > 0 then
        ImGui.SameLine()
        if ImGui.Button("+" .. customQty .. "##c" .. key) then addItem(items[key], customQty, label) end
    end
end

local function pointRow(labelKey, kind)
    listRow()
    ImGui.Text(t(labelKey))
    ImGui.SameLine(COL * (settings.uiscale or 1))
    if ImGui.Button("-10##" .. labelKey, bw(56), 0) then givePoints(kind, -10, t(labelKey)) end
    ImGui.SameLine()
    if ImGui.Button("-1##" .. labelKey, bw(56), 0) then givePoints(kind, -1, t(labelKey)) end
    ImGui.SameLine()
    if ImGui.Button("+1##" .. labelKey, bw(56), 0) then givePoints(kind, 1, t(labelKey)) end
    ImGui.SameLine()
    if ImGui.Button("+10##" .. labelKey, bw(56), 0) then givePoints(kind, 10, t(labelKey)) end
end

-- XP has no safe "remove" in-game, so add-only
local function xpRow(label, kind, q1, q2)
    listRow()
    ImGui.Text(label)
    ImGui.SameLine(COL * (settings.uiscale or 1))
    if ImGui.Button("+" .. q1 .. "##" .. kind, bw(92), 0) then giveXP(kind, q1, label) end
    ImGui.SameLine()
    if ImGui.Button("+" .. q2 .. "##" .. kind, bw(92), 0) then giveXP(kind, q2, label) end
end

local function moneyRow(qty, label)
    listRow()
    ImGui.Text(label)
    ImGui.SameLine(COL * (settings.uiscale or 1))
    if ImGui.Button("-" .. label .. "##m", bw(92), 0) then removeItem("Items.money", qty, "$") end
    ImGui.SameLine()
    if ImGui.Button("+" .. label .. "##m", bw(92), 0) then addItem("Items.money", qty, "$") end
end

local function customQtyRow()
    ImGui.SetNextItemWidth(150 * (settings.uiscale or 1))
    local value, changed = ImGui.InputInt(t("customqty"), customQty, 100)
    if changed then customQty = math.max(0, value) end
    if customQty > 0 then
        ImGui.Text("$")
        ImGui.SameLine(COL * (settings.uiscale or 1))
        if ImGui.Button("-" .. customQty .. "##cm") then removeItem("Items.money", customQty, "$") end
        ImGui.SameLine()
        if ImGui.Button("+" .. customQty .. "##cm") then addItem("Items.money", customQty, "$") end
    end
end

local function romanceRow(name, fact)
    listRow()
    ImGui.Text(name)
    ImGui.SameLine(COL * (settings.uiscale or 1))
    local qs = Game.GetQuestsSystem()
    if qs:GetFactStr(fact) == 1 then
        ImGui.Text(t("unlocked"))
    elseif ImGui.Button(t("unlock") .. "##" .. fact) then
        qs:SetFactStr(fact, 1)
        notify(name .. ": " .. t("romunlocked"))
    end
end

local OPEN = ImGuiTreeNodeFlags.DefaultOpen

local sellDuplicates  -- defined after QUALITY_RANK, used by the Items tab below

local function drawItemsTab()
    if ImGui.Button("GIVE ME EVERYTHING", -1, 32 * (settings.uiscale or 1)) then giveEverything() end
    if ImGui.Button(t("undo")) then undoLast() end
    customQtyRow()
    ImGui.Separator()
    if ImGui.CollapsingHeader(t("money"), OPEN) then
        beginList("money")
        moneyRow(100000, "100K")
        moneyRow(1000000, "1M")
        moneyRow(10000000, "10M")
        endList()
    end
    if ImGui.CollapsingHeader(t("crafting"), OPEN) then
        beginList("craft")
        itemRow("Tier 1", "comp1", 1000)
        itemRow("Tier 2", "comp2", 1000)
        itemRow("Tier 3", "comp3", 1000)
        itemRow("Tier 4", "comp4", 1000)
        itemRow("Tier 5", "comp5", 1000)
        endList()
    end
    if ImGui.CollapsingHeader(t("quickhack"), OPEN) then
        beginList("qh")
        itemRow("Tier 1", "qh1", 500)
        itemRow("Tier 2", "qh2", 500)
        itemRow("Tier 3", "qh3", 500)
        itemRow("Tier 4", "qh4", 500)
        itemRow("Tier 5", "qh5", 500)
        endList()
    end
    if ImGui.CollapsingHeader(t("cyberware"), OPEN) then
        beginList("shard")
        itemRow(t("shard"), "shard", 1)
        itemRow(t("shard"), "shard", 5)
        endList()
    end
    if ImGui.CollapsingHeader(t("dupes"), OPEN) then
        if ImGui.Button(t("dupesbtn"), -1, 28 * (settings.uiscale or 1)) then sellDuplicates() end
        ImGui.TextWrapped(t("dupeshint"))
    end
end

local function drawConsumTab()
    if ImGui.CollapsingHeader(t("godmode"), OPEN) then
        beginList("tgl")
        local v, c
        listRow()
        v, c = ImGui.Checkbox(t("tgod"), settings.god)
        if c then settings.god = v; saveSettings() end
        listRow()
        v, c = ImGui.Checkbox(t("tstamina"), settings.stamina)
        if c then settings.stamina = v; saveSettings() end
        listRow()
        v, c = ImGui.Checkbox(t("tinfammo"), settings.infammo)
        if c then settings.infammo = v; saveSettings() end
        listRow()
        v, c = ImGui.Checkbox(t("toneshot"), settings.oneshot)
        if c then settings.oneshot = v; applyOneShot(); saveSettings() end
        endList()
        ImGui.TextWrapped(t("godhint"))
    end
    if ImGui.CollapsingHeader(t("healhdr"), OPEN) then
        beginList("heal")
        itemRow("MaxDoc", "maxdoc", 20)
        itemRow("Bounce Back", "bounce", 20)
        endList()
        if ImGui.Button(t("heal")) then healPlayer() end
    end
    if ImGui.CollapsingHeader(t("grenades"), OPEN) then
        beginList("gren")
        itemRow("Frag", "grenade", 20)
        itemRow("EMP", "gemp", 20)
        itemRow(t("ginc"), "ginc", 20)
        itemRow("Flash", "gflash", 20)
        itemRow("Recon", "grecon", 20)
        itemRow(t("gsmoke"), "gsmoke", 20)
        itemRow(t("gbio"), "gbio", 20)
        itemRow("Ozob's Nose", "ozob", 10)
        endList()
    end
    if ImGui.CollapsingHeader(t("ammo"), OPEN) then
        beginList("ammo")
        itemRow("Pistol / SMG", "ammo1", 500)
        itemRow("Rifle", "ammo2", 500)
        itemRow("Shotgun", "ammo3", 200)
        itemRow("Sniper", "ammo4", 100)
        endList()
    end
end

-- Game.SetLevel queues SetProficiencyLevel on PlayerDevelopmentSystem (native, patch 2.x)
local levelTargets = {}
local function setLevelRow(label, kind, maxLv)
    listRow()
    ImGui.Text(label)
    ImGui.SameLine(COL * (settings.uiscale or 1))
    ImGui.SetNextItemWidth(120 * (settings.uiscale or 1))
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
        beginList("prog")
        pointRow("perks", "Primary")
        pointRow("attributes", "Attribute")
        pointRow("relic", "Espionage")
        xpRow(t("levelxp"), "Level", 1000, 10000)
        xpRow(t("streetcred"), "StreetCred", 1000, 10000)
        itemRow(t("perkreset"), "perkreset", 1)
        endList()
    end
    if ImGui.CollapsingHeader(t("skills"), OPEN) then
        beginList("skills")
        xpRow("Solo", "StrengthSkill", 1000, 10000)
        xpRow("Shinobi", "ReflexesSkill", 1000, 10000)
        xpRow("Netrunner", "IntelligenceSkill", 1000, 10000)
        xpRow("Engineer", "TechnicalAbilitySkill", 1000, 10000)
        xpRow("Headhunter", "CoolSkill", 1000, 10000)
        endList()
    end
    if ImGui.CollapsingHeader(t("setlevelhdr"), OPEN) then
        beginList("setlv")
        setLevelRow(t("lvl"), "Level", 60)
        setLevelRow(t("streetcred"), "StreetCred", 50)
        setLevelRow("Solo", "StrengthSkill", 60)
        setLevelRow("Shinobi", "ReflexesSkill", 60)
        setLevelRow("Netrunner", "IntelligenceSkill", 60)
        setLevelRow("Engineer", "TechnicalAbilitySkill", 60)
        setLevelRow("Headhunter", "CoolSkill", 60)
        endList()
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

local QUALITY_RANK = {
    Random = 1, Common = 2, CommonPlus = 3, Uncommon = 4, UncommonPlus = 5, Rare = 6,
    RarePlus = 7, Epic = 8, EpicPlus = 9, Legendary = 10, LegendaryPlus = 11, LegendaryPlusPlus = 12,
}

-- in-game rarity colors; rank 0/common stays default white
local function qualityColor(rank)
    if rank >= 10 then return 1.00, 0.60, 0.20 end
    if rank >= 8 then return 0.75, 0.45, 0.95 end
    if rank >= 6 then return 0.35, 0.62, 1.00 end
    if rank >= 4 then return 0.45, 0.85, 0.45 end
    return nil
end

-- iconic presets carry Quality "Random" (rolled at spawn), so the tag decides for those
local function recordRank(rec)
    local rank = 0
    pcall(function() rank = QUALITY_RANK[rec:Quality():Name().value] or 0 end)
    if rank <= 1 then
        pcall(function()
            if rec:TagsContains(CName.new("IconicWeapon")) then rank = 10 end
        end)
    end
    return rank
end

-- static lists carry only id+label; quality is looked up once per id on first draw
local staticRankCache = {}
local function staticRank(id)
    local r = staticRankCache[id]
    if r == nil then
        r = 0
        pcall(function() r = recordRank(TweakDB:GetRecord(id)) end)
        staticRankCache[id] = r
    end
    return r
end

local function rankName(rank)
    if rank >= 10 then return t("quallegend") end
    if rank >= 8 then return t("qualepic") end
    if rank >= 6 then return t("qualrare") end
    if rank >= 4 then return t("qualuncommon") end
    return t("qualcommon")
end

-- extra: optional second tooltip line (static tabs pass the TweakDB id)
local function itemLabel(label, rank, extra)
    rank = rank or 0
    local r, g, b = qualityColor(rank)
    if r then ImGui.TextColored(r, g, b, 1.0, label) else ImGui.Text(label) end
    if ImGui.IsItemHovered() then
        local tip = label .. "\n" .. rankName(rank)
        if extra then tip = tip .. "\n" .. tostring(extra) end
        ImGui.SetTooltip(tip)
    end
end

-- button first, then label (see dynRow): keeps long names from sliding under the button
local function weaponRow(w)
    if ownedCache[w.id] then
        ImGui.Text(t("owned"))
    elseif ImGui.Button(t("give") .. "##" .. w.id) then
        giveWeapon(w)
    end
    ImGui.SameLine(120 * (settings.uiscale or 1))
    itemLabel(w.label, staticRank(w.id), w.id)
end

local filters = {}

-- tokenized search: every space-separated word must appear in the label, any order
local function searchTokens(text)
    local toks = {}
    for w in text:lower():gmatch("%S+") do toks[#toks + 1] = w end
    return toks
end

local function matchesAll(label, toks)
    label = label:lower()
    for _, tk in ipairs(toks) do
        if not label:find(tk, 1, true) then return false end
    end
    return true
end

-- shared by Weapons and Gear tabs: search field + grouped list with give-all
local function drawGearList(id, groups)
    ImGui.SetNextItemWidth(220 * (settings.uiscale or 1))
    local text, changed = ImGui.InputTextWithHint("##filter" .. id, t("search"), filters[id] or "", 64)
    if changed then filters[id] = text end
    ImGui.Separator()

    -- filter active: flat list across all groups, headers skipped
    local needle = (filters[id] or ""):lower()
    if needle ~= "" then
        local toks = searchTokens(needle)
        local matches = {}
        for _, group in ipairs(groups) do
            for _, w in ipairs(group.weapons) do
                if w.id and matchesAll(w.label, toks) then matches[#matches + 1] = w end
            end
        end
        if #matches == 0 then ImGui.Text(t("noresults")); return end
        ImGui.Text(#matches .. " " .. t("results"))
        ImGui.SameLine()
        if ImGui.Button(t("giveallres") .. "##" .. id) then
            local n = 0
            for _, w in ipairs(matches) do
                if not ownedCache[w.id] then
                    Game.AddToInventory(w.id, 1)
                    ownedCache[w.id] = true
                    n = n + 1
                end
            end
            notify("+" .. n .. " " .. t("itemsgiven"))
        end
        local z = beginList(id .. "f")
        for _, w in ipairs(matches) do listRow(z); weaponRow(w) end
        endList(z)
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
            local z = beginList(id .. group.key)
            for _, w in ipairs(group.weapons) do
                if w.id then listRow(z); weaponRow(w) end
            end
            endList(z)
        end
    end
end

-- dynamic item lists pulled from TweakDB; built on first open of each tab.
-- Clothing keeps every record (color variants share a display name); weapons dedupe
-- by name keeping the highest-quality preset, so "give all" hands out the orange ones.
local CLOTH_GROUPS = {
    order = { "areahead", "areaface", "areaouter", "areainner", "arealegs", "areafeet", "areaoutfit", "areaother" },
    map = { Head = "areahead", Face = "areaface", OuterChest = "areaouter", InnerChest = "areainner",
            Legs = "arealegs", Feet = "areafeet", Outfit = "areaoutfit" },
    typeOf = function(rec) return rec:EquipArea():Type().value end,
}
-- all cyberware from gamedataItem_Record, grouped by cyberware EquipArea slot.
-- arm cyberware (Mantis/Gorilla/etc.) are weapon records, so they stay in the weapons tab, not here.
-- inclusion keys off the "*CW" EquipArea suffix, not exact enum names: a mis-mapped slot lands
-- in Other instead of vanishing, so no cyberware is ever silently dropped.
local CYBER_GROUPS = {
    order = { "cfront", "cos", "carm", "cface", "cskel", "chand", "cnerv", "ccirc", "cinteg", "cleg", "areaother" },
    map = {
        FrontalCortexCW = "cfront", SystemReplacementCW = "cos", ArmsCW = "carm",
        EyesCW = "cface", SkeletonCW = "cskel", HandsCW = "chand",
        NervousSystemCW = "cnerv", CardiovascularSystemCW = "ccirc",
        IntegumentarySystemCW = "cinteg", LegsCW = "cleg",
    },
    typeOf = function(rec) return rec:EquipArea():Type().value end,
    skip = function(tv) return tv == nil or tv:find("CW$") == nil end,
    dedupe = true,
    -- arm cyberware (Mantis/Gorilla/etc.) are weapon records: merge both classes here
    merge = true,
}
-- vehicles aren't inventory items: unlock via VehicleSystem so they appear in the phone call list.
-- ~500 vehicle records include every traffic/NPC variant; dedupe by display name collapses them to
-- the unique models. Per-record unlock passes the record TweakDBID; "all" uses the native bulk call.
local function unlockVehicle(c)
    pcall(function() Game.GetVehicleSystem():EnablePlayerVehicle(c.id, true, false) end)
end
-- armed first (mounted weapons), then bike; everything else is a car (same split as FindMyRide)
local VEH_GROUPS = {
    order = { "vcars", "vbikes", "varmed" },
    map = { car = "vcars", bike = "vbikes", armed = "varmed" },
    typeOf = function(rec)
        local armed = false
        pcall(function() armed = rec:VehDataPackageHandle():DriverCombat():Type().value == "MountedWeapons" end)
        if armed then return "armed" end
        local ty = ""
        pcall(function() ty = rec:Type():Type().value end)
        if ty == "Bike" then return "bike" end
        return "car"
    end,
    dedupe = true,
    give = unlockVehicle,
    btnKey = "unlockbtn",
    doneKey = "vehdone",
    allAction = function() pcall(function() Game.GetVehicleSystem():EnableAllPlayerVehicles() end) end,
}
local WEAPON_GROUPS = {
    order = { "wpistols", "wsmgs", "wrifles", "wshotguns", "wlmg", "wsnipers", "wmelee", "areaother" },
    map = {
        Wea_Handgun = "wpistols", Wea_Revolver = "wpistols",
        Wea_SubmachineGun = "wsmgs",
        Wea_AssaultRifle = "wrifles", Wea_Rifle = "wrifles",
        Wea_Shotgun = "wshotguns", Wea_ShotgunDual = "wshotguns",
        Wea_LightMachineGun = "wlmg", Wea_HeavyMachineGun = "wlmg", Wea_GrenadeLauncher = "wlmg",
        Wea_SniperRifle = "wsnipers", Wea_PrecisionRifle = "wsnipers",
        Wea_Katana = "wmelee", Wea_Knife = "wmelee", Wea_Sword = "wmelee", Wea_Machete = "wmelee",
        Wea_Axe = "wmelee", Wea_Chainsword = "wmelee", Wea_Hammer = "wmelee", Wea_OneHandedClub = "wmelee",
        Wea_TwoHandedClub = "wmelee", Wea_LongBlade = "wmelee", Wea_ShortBlade = "wmelee",
        Wea_Melee = "wmelee", Wea_Fists = "wmelee",
    },
    typeOf = function(rec) return rec:ItemType():Type().value end,
    -- Cyb_ arm weapons live in the All cyberware tab (merged there), not here
    skip = function(tv) return tv ~= nil and (tv:find("^Wea_Vehicle") ~= nil or tv:find("^Cyb_") ~= nil) end,
    dedupe = true,
}
local MODS_GROUPS = {
    order = { "mscopes", "mmuzzles", "mranged", "mmelee", "mcloth" },
    map = {
        Prt_Scope = "mscopes", Prt_ShortScope = "mscopes", Prt_LongScope = "mscopes",
        Prt_PowerSniperScope = "mscopes", Prt_TechSniperScope = "mscopes", Prt_ScopeRail = "mscopes",
        Prt_Muzzle = "mmuzzles", Prt_HandgunMuzzle = "mmuzzles", Prt_RifleMuzzle = "mmuzzles",
        Prt_Mod = "mranged", Prt_RangedMod = "mranged", Prt_PowerMod = "mranged", Prt_TechMod = "mranged",
        Prt_SmartMod = "mranged", Prt_HandgunMod = "mranged", Prt_ShotgunMod = "mranged",
        Prt_Magazine = "mranged", Prt_Stock = "mranged", Prt_TargetingSystem = "mranged", Prt_Capacitor = "mranged",
        Prt_BladeMod = "mmelee", Prt_BluntMod = "mmelee", Prt_MeleeMod = "mmelee", Prt_ThrowableMod = "mmelee",
        Prt_FabricEnhancer = "mcloth", Prt_HeadFabricEnhancer = "mcloth", Prt_FaceFabricEnhancer = "mcloth",
        Prt_TorsoFabricEnhancer = "mcloth", Prt_OuterTorsoFabricEnhancer = "mcloth",
        Prt_PantsFabricEnhancer = "mcloth", Prt_BootsFabricEnhancer = "mcloth",
    },
    typeOf = function(rec) return rec:ItemType():Type().value end,
    strict = true,  -- everything that isn't a mapped part type is skipped, not bucketed into Other
    dedupe = true,
}

local dynLists = {}

-- recordTypes: string or list of candidate record classes; first one yielding entries wins
local function buildDynList(key, recordTypes, def)
    if dynLists[key] then return dynLists[key] end
    if type(recordTypes) == "string" then recordTypes = { recordTypes } end
    local groups, best, total = {}, {}, 0
    for _, recordType in ipairs(recordTypes) do
        local records = {}
        pcall(function() records = TweakDB:GetRecords(recordType) or {} end)
        local count = 0
        for _, rec in ipairs(records) do
            pcall(function()
                local name = Game.GetLocalizedTextByKey(rec:DisplayName())
                if name == nil or name == "" then return end
                local tv = nil
                pcall(function() tv = def.typeOf(rec) end)
                if def.skip and def.skip(tv) then return end
                local g = def.map[tv]
                if g == nil then
                    if def.strict then return end
                    g = "areaother"
                end
                local entry = { label = name, id = rec:GetID(), give = def.give, btnKey = def.btnKey, doneKey = def.doneKey }
                local rank = recordRank(rec)
                entry.rank = rank
                if def.dedupe then
                    local dk = g .. "|" .. name
                    if best[dk] == nil then
                        groups[g] = groups[g] or {}
                        groups[g][#groups[g] + 1] = entry
                        best[dk] = { entry = entry, rank = rank }
                        count = count + 1
                    elseif rank > best[dk].rank then
                        best[dk].entry.id = entry.id
                        best[dk].entry.rank = rank
                        best[dk].rank = rank
                    end
                else
                    groups[g] = groups[g] or {}
                    groups[g][#groups[g] + 1] = entry
                    count = count + 1
                end
            end)
        end
        if count > 0 and not def.merge then break end
    end
    for _, list in pairs(groups) do
        total = total + #list
        table.sort(list, function(a, b) return a.label < b.label end)
    end
    dynLists[key] = { groups = groups, total = total, order = def.order, allAction = def.allAction }
    return dynLists[key]
end

-- default action gives the item; lists can override with def.give (e.g. vehicles unlock instead)
local function giveDynItem(c)
    if c.give then c.give(c)
    else
        Game.GetTransactionSystem():GiveItem(Game.GetPlayer(), ItemID.FromTDBID(c.id), 1)
        lastGive = { label = c.label, undo = function()
            Game.GetTransactionSystem():RemoveItem(Game.GetPlayer(), ItemID.FromTDBID(c.id), 1)
        end }
    end
end

-- button first, then label: long pt-BR names were sliding under a right-aligned button
local function dynRow(c, uid)
    if ImGui.Button(t(c.btnKey or "give") .. "##d" .. uid) then
        giveDynItem(c)
        notify(c.doneKey and (c.label .. " " .. t(c.doneKey)) or ("+1 " .. c.label))
    end
    ImGui.SameLine()
    itemLabel(c.label, c.rank)
end

local function drawDynTab(id, data, allLabel, warnText)
    ImGui.TextWrapped(warnText)
    if ImGui.Button(allLabel .. " (" .. data.total .. ")", -1, 28 * (settings.uiscale or 1)) then
        if data.allAction then
            data.allAction()
            notify(allLabel)
        else
            local n = 0
            for _, list in pairs(data.groups) do
                for _, c in ipairs(list) do
                    giveDynItem(c)
                    n = n + 1
                end
            end
            lastGive = nil
            notify("+" .. n .. " " .. t("itemsgiven"))
        end
    end
    ImGui.Separator()
    ImGui.SetNextItemWidth(220 * (settings.uiscale or 1))
    local text, changed = ImGui.InputTextWithHint("##filter" .. id, t("search"), filters[id] or "", 64)
    if changed then filters[id] = text end
    local needle = (filters[id] or ""):lower()
    if needle ~= "" then
        -- flat result list, display capped so ImGui doesn't choke on huge matches
        local toks = searchTokens(needle)
        local matches = {}
        for _, g in ipairs(data.order) do
            for i, c in ipairs(data.groups[g] or {}) do
                if matchesAll(c.label, toks) then matches[#matches + 1] = { c = c, g = g, i = i } end
            end
        end
        if #matches == 0 then ImGui.Text(t("noresults")); return end
        ImGui.Text(#matches .. " " .. t("results") .. (#matches > 300 and " " .. t("showing300") or ""))
        ImGui.SameLine()
        if ImGui.Button(t("giveallres") .. "##" .. id) then
            for _, m in ipairs(matches) do giveDynItem(m.c) end
            lastGive = nil
            notify("+" .. #matches .. " " .. t("itemsgiven"))
        end
        local z = beginList(id .. "f")
        for n, m in ipairs(matches) do
            if n > 300 then break end
            listRow(z)
            dynRow(m.c, id .. m.g .. m.i)
            ImGui.SameLine()
            ImGui.TextColored(0.62, 0.62, 0.64, 1.0, t(m.g))
        end
        endList(z)
        return
    end
    -- single-group tabs (vehicles): flat list, the top button already covers "all"
    local nGroups = 0
    for _, g in ipairs(data.order) do
        if data.groups[g] and #data.groups[g] > 0 then nGroups = nGroups + 1 end
    end
    for _, g in ipairs(data.order) do
        local list = data.groups[g]
        if list and #list > 0 then
            if nGroups == 1 then
                local z = beginList(id .. g)
                for i, c in ipairs(list) do listRow(z); dynRow(c, id .. g .. i) end
                endList(z)
            elseif ImGui.CollapsingHeader(t(g) .. " (" .. #list .. ")##" .. id .. g) then
                if ImGui.Button(t("giveall") .. "##" .. id .. g) then
                    for _, c in ipairs(list) do giveDynItem(c) end
                    lastGive = nil
                    notify("+" .. #list .. " " .. t("itemsgiven"))
                end
                local z = beginList(id .. g)
                for i, c in ipairs(list) do listRow(z); dynRow(c, id .. g .. i) end
                endList(z)
            end
        end
    end
end

local function drawCarryTab()
    if ImGui.CollapsingHeader(t("carrybonus"), OPEN) then
        local value, changed = ImGui.SliderInt("##carry", settings.carrybonus, 0, 50000, "+%d")
        if changed then
            settings.carrybonus = value
            saveSettings()
            applyCarryBonus()
        end
        ImGui.TextWrapped(t("carryhint"))
    end
end

-- learn every craftable recipe: any item record carrying CraftingData, straight into the
-- player CraftBook (same API the addAllRecipes mod uses); ammo recipes are junk, skipped
local function unlockAllRecipes()
    local n = 0
    local ok, err = pcall(function()
        local craftBook = Game.GetScriptableSystemsContainer():Get("CraftingSystem"):GetPlayerCraftBook()
        local seen = {}
        local classes = {
            "gamedataClothing_Record", "gamedataWeaponItem_Record", "gamedataRecipeItem_Record",
            "gamedataConsumableItem_Record", "gamedataItem_Record", "gamedataGrenade_Record",
        }
        for _, className in ipairs(classes) do
            for _, rec in ipairs(TweakDB:GetRecords(className) or {}) do
                pcall(function()
                    local idStr = tostring(rec:GetID().value)
                    if seen[idStr] or idStr:find("Ammo") then return end
                    if rec:CraftingData() or rec:CraftingDataHandle() then
                        seen[idStr] = true
                        craftBook:AddRecipe(rec:GetID())
                        n = n + 1
                    end
                end)
            end
        end
    end)
    if ok then
        notify("+" .. n .. " " .. t("recipesdone"))
    else
        notify(t("recipes") .. " " .. t("failed"))
        spdlog.info("GiveMeEverything: recipes failed: " .. tostring(err))
    end
end

-- same display name = duplicate (covers repeated give-alls and same-name tier variants);
-- keeps the highest-tier copy, sells the rest; equipped and quest items untouched
sellDuplicates = function()
    local player = Game.GetPlayer()
    if not player then return end
    local ts = Game.GetTransactionSystem()
    local epd
    pcall(function()
        epd = Game.GetScriptableSystemsContainer():Get("EquipmentSystem"):GetPlayerData(player)
    end)
    local items
    pcall(function()
        local _, list = ts:GetItemList(player)
        items = list
    end)
    if epd == nil or items == nil then
        notify(t("dupes") .. " " .. t("failed"))
        spdlog.info("GiveMeEverything: sellDuplicates aborted (no equipment data or item list)")
        return
    end
    local groups = {}
    for _, it in ipairs(items) do
        pcall(function()
            local ty = it:GetItemType().value
            if not (ty:find("Wea_", 1, true) == 1 or ty:find("Clo_", 1, true) == 1
                    or ty:find("Cyb", 1, true) == 1) then return end
            if it:HasTag(CName.new("Quest")) then return end
            local id = it:GetID()
            local name = Game.GetLocalizedTextByKey(TweakDB:GetRecord(id.id):DisplayName())
            if name == nil or name == "" then return end
            local equipped = true  -- if the check errors, treat as equipped and never touch it
            pcall(function() equipped = epd:IsEquipped(id) end)
            local g = groups[name]
            if g == nil then
                g = { copies = {}, hasEquipped = false }
                groups[name] = g
            end
            if equipped then
                g.hasEquipped = true
                return
            end
            local rank, price, qty = 0, 0, 1
            pcall(function() rank = (QUALITY_RANK[RPGManager.GetItemDataQuality(it).value] or 0) * 10 end)
            pcall(function() rank = rank + RPGManager.GetItemPlus(it) end)
            pcall(function() price = it:GetStatValueByType(gamedataStatType.Price) end)
            pcall(function() qty = it:GetQuantity() end)
            g.copies[#g.copies + 1] = { id = id, rank = rank, price = price, qty = qty }
        end)
    end
    local sold, cash = 0, 0
    for _, g in pairs(groups) do
        local keep = nil
        if not g.hasEquipped then  -- an equipped copy already counts as the one kept
            for _, c in ipairs(g.copies) do
                if keep == nil or c.rank > keep.rank then keep = c end
            end
        end
        for _, c in ipairs(g.copies) do
            local removeQty = (c == keep) and (c.qty - 1) or c.qty
            if removeQty > 0 then
                local ok = pcall(function() ts:RemoveItem(player, c.id, removeQty) end)
                if ok then
                    sold = sold + removeQty
                    -- ponytail: flat 10% of the Price stat, close enough to vendor rates
                    cash = cash + math.floor(c.price * 0.1) * removeQty
                end
            end
        end
    end
    if sold == 0 then
        notify(t("dupesnone"))
        return
    end
    if cash > 0 then Game.AddToInventory("Items.money", cash) end
    notify(sold .. " " .. t("dupesdone") .. " (+$" .. cash .. ")")
    refreshOwned()
end

registerHotkey("GME_SellDupes", "Sell duplicate gear", function() sellDuplicates() end)

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
        beginList("rom")
        romanceRow("Judy", "judy_romanceable")
        romanceRow("Panam", "panam_romanceable")
        romanceRow("River", "river_romanceable")
        romanceRow("Kerry", "kerry_romanceable")
        endList()
    end
    if ImGui.CollapsingHeader(t("recipes"), OPEN) then
        if ImGui.Button(t("recipesall")) then unlockAllRecipes() end
    end
    if ImGui.CollapsingHeader(t("ncpd"), OPEN) then
        drawNcpdSection()
    end
end

-- global search + favorites: dynamic sources are rebuilt on demand and matched by name.
-- favorites store only {src, label} (+ id for static string-id sources) so they survive a
-- restart despite record TweakDBIDs not being serializable; the give is resolved at click time.
local SRC_DEF = {
    aw  = { "gamedataWeaponItem_Record", WEAPON_GROUPS },
    c   = { "gamedataClothing_Record", CLOTH_GROUPS },
    cyb = { { "gamedataItem_Record", "gamedataWeaponItem_Record" }, CYBER_GROUPS },
    m   = { { "gamedataAttachment_Record", "gamedataItem_Record" }, MODS_GROUPS },
    veh = { "gamedataVehicle_Record", VEH_GROUPS },
}

-- origin tab shown as a gray tag on each global search result
local SRC_TAB = { aw = "taballweapons", c = "tabclothes", cyb = "tcaw", m = "tabmods", veh = "vehicles" }
local STATIC_TAB = { "tabweapons", "tabgear" }

local function searchAll(needle)
    local toks = searchTokens(needle)
    local results = {}
    for src, d in pairs(SRC_DEF) do
        local data = buildDynList(src, d[1], d[2])
        for _, list in pairs(data.groups) do
            for _, c in ipairs(list) do
                if matchesAll(c.label, toks) then
                    results[#results + 1] = { label = c.label, entry = c, src = src, tag = SRC_TAB[src] }
                end
            end
        end
    end
    for li, list in ipairs({ WEAPONS, GEAR }) do
        for _, group in ipairs(list) do
            for _, w in ipairs(group.weapons) do
                if w.id and matchesAll(w.label, toks) then
                    results[#results + 1] = { label = w.label, id = w.id, src = "static", tag = STATIC_TAB[li] }
                end
            end
        end
    end
    table.sort(results, function(a, b) return a.label < b.label end)
    return results
end

local function isFav(src, label)
    for _, f in ipairs(settings.favorites) do
        if f.src == src and f.label == label then return true end
    end
    return false
end

local function toggleFav(src, label, id)
    for i, f in ipairs(settings.favorites) do
        if f.src == src and f.label == label then
            table.remove(settings.favorites, i); saveSettings(); return
        end
    end
    settings.favorites[#settings.favorites + 1] = { src = src, label = label, id = id }
    saveSettings()
end

local function giveStatic(id, label)
    Game.AddToInventory(id, 1)
    lastGive = { label = label, undo = function()
        Game.GetTransactionSystem():RemoveItem(Game.GetPlayer(), ItemID.FromTDBID(TweakDBID.new(id)), 1)
    end }
    notify("+1 " .. label)
end

local function giveResult(r)
    if r.src == "static" then
        giveStatic(r.id, r.label)
    else
        giveDynItem(r.entry)
        notify(r.entry.give and (r.label .. " " .. t("vehdone")) or ("+1 " .. r.label))
    end
end

local function giveFav(f)
    if f.src == "static" then
        giveStatic(f.id, f.label)
        return
    end
    local d = SRC_DEF[f.src]
    if not d then return end
    local data = buildDynList(f.src, d[1], d[2])
    for _, list in pairs(data.groups) do
        for _, c in ipairs(list) do
            if c.label == f.label then
                giveDynItem(c)
                notify(c.give and (c.label .. " " .. t("vehdone")) or ("+1 " .. c.label))
                return
            end
        end
    end
    notify(f.label .. " " .. t("failed"))
end

local function drawSearchTab()
    if #settings.favorites > 0 and ImGui.CollapsingHeader(t("favorites") .. " (" .. #settings.favorites .. ")", OPEN) then
        local z = beginList("fav")
        for i = #settings.favorites, 1, -1 do
            local f = settings.favorites[i]
            listRow(z)
            if ImGui.Button(t("give") .. "##fg" .. i) then giveFav(f) end
            ImGui.SameLine()
            if ImGui.Button(t("rmfav") .. "##fx" .. i) then toggleFav(f.src, f.label) end
            ImGui.SameLine()
            ImGui.Text(f.label)
        end
        endList(z)
        ImGui.Separator()
    end
    ImGui.SetNextItemWidth(260 * (settings.uiscale or 1))
    local text, changed = ImGui.InputTextWithHint("##gsearch", t("searchall"), filters.g or "", 64)
    if changed then filters.g = text end
    local needle = (filters.g or ""):lower()
    if needle == "" then ImGui.TextWrapped(t("searchhint")); return end
    local results = searchAll(needle)
    if #results == 0 then ImGui.Text(t("noresults")); return end
    ImGui.Text(#results .. " " .. t("results") .. (#results > 300 and " " .. t("showing300") or ""))
    ImGui.SameLine()
    if ImGui.Button(t("giveallres") .. "##gall") then
        for _, r in ipairs(results) do
            -- silent path: giveResult would toast once per item
            if r.src == "static" then Game.AddToInventory(r.id, 1)
            else giveDynItem(r.entry) end
        end
        lastGive = nil
        notify("+" .. #results .. " " .. t("itemsgiven"))
    end
    local z = beginList("gsr")
    for i, r in ipairs(results) do
        if i > 300 then break end
        listRow(z)
        if ImGui.Button(t("give") .. "##g" .. i) then giveResult(r) end
        ImGui.SameLine()
        local fav = isFav(r.src, r.label)
        if ImGui.Button((fav and t("rmfav") or t("addfav")) .. "##gs" .. i) then
            toggleFav(r.src, r.label, r.id)
        end
        ImGui.SameLine()
        itemLabel(r.label, r.entry and r.entry.rank or staticRank(r.id))
        if r.tag then
            ImGui.SameLine()
            ImGui.TextColored(0.62, 0.62, 0.64, 1.0, t(r.tag))
        end
    end
    endList(z)
end

-- Quest guide: static curated list separating real main story from side jobs that
-- change the ending vs purely cosmetic ones. Read-only, no game-state query.
local QCAT = {
    main     = { key = "qcatmain",     r = 1.00, g = 0.82, b = 0.00 },
    ending   = { key = "qcatending",   r = 0.00, g = 0.85, b = 0.85 },
    cosmetic = { key = "qcatcosmetic", r = 0.62, g = 0.62, b = 0.64 },
}

-- live journal category tag: derived from each quest's journal path (folder = category).
-- main_quest -> Principal; side_quest -> Cosmetica, except the ids below that gate/affect an
-- ending or romance payoff -> Afeta o final; everything else (gigs, NCPD, minor) -> Cosmetica.
local ENDING_SIDE_IDS = {
    sq004_riders_on_the_storm = true, -- Panam -> The Star
    sq031_rogue = true,               -- Chippin' In -> The Sun + secret ending
    sq031_smack_my_bitch_up = true,   -- A Cool Metal Fire
    sq031_cinema = true,              -- Blistering Love -> call Rogue
    sq030_judy_romance = true,        -- Judy romance payoff
    sq028_kerry_romance = true,       -- Kerry romance payoff
    sq029_sobchak_romance = true,     -- River romance payoff
    sq021_sick_dreams = true,         -- The Hunt (River)
    sq011_kerry = true, sq017_kerry = true, sq011_concert = true, sq011_johnny = true,
    sq017_02_lounge = true,           -- Kerry chain
}
-- base main story surfaces under quests/meta/ (Nocturne = meta/02_sickness), all main except
-- these; PL and base sub-quests carry a real main_quest path.
local META_COSMETIC = { ["07_nc_underground"] = true, ["08_headhunter"] = true }
local function catFromPath(path)
    if not path or path == "" then return nil end
    if path:find("main_quest", 1, true) then return "main" end
    local mid = path:match("/meta/([^/]+)")
    if mid then return META_COSMETIC[mid] and "cosmetic" or "main" end
    local sid = path:match("side_quest/([^/]+)")
    if sid then return ENDING_SIDE_IDS[sid] and "ending" or "cosmetic" end
    return "cosmetic"
end

-- Phantom Liberty detection: PL-only content (ep1-scoped) resolves only when the expansion
-- is installed. Two independent signals; either hit => PL present (ep1 naming rules out a
-- base-game false positive). If both miss on a PL install, it's a wrong id, not a wrong method.
local PL_DETECT_RECORD = "Vehicle.v_standard2_archer_hella_ep1_kurtz"
local PL_DETECT_RESOURCE = "ep1\\vehicles\\special\\av_militech_manticore_fake_trama.ent"
local plCache
local function hasPL()
    if plCache == nil then
        local ok, hit = pcall(function()
            if TweakDB:GetRecord(PL_DETECT_RECORD) ~= nil then return true end
            local depot = Game.GetResourceDepot()
            return depot ~= nil and depot:ResourceExists(PL_DETECT_RESOURCE)
        end)
        plCache = ok and hit == true
    end
    return plCache
end

local function qnote(q)
    if type(q.note) == "table" then return q.note[settings.lang] or q.note.en or "" end
    return q.note or ""
end

-- live journal: real quests read from the game (pt-BR names, completion state, locate).
local QSTATE = {
    { key = "qdone",   val = 3, r = 0.30, g = 0.85, b = 0.35 },
    { key = "qactive", val = 2, r = 1.00, g = 0.82, b = 0.00 },
    { key = "qtodo",   val = 1, r = 0.62, g = 0.62, b = 0.64 },
    { key = "qfailed", val = 4, r = 0.90, g = 0.35, b = 0.30 },
}
local qsShow = { [3] = true, [2] = true, [1] = true, [4] = false }
local questCache

local function fetchQuests()
    local jm = Game.GetJournalManager()
    if not jm then return nil end
    local ok, quests = pcall(function()
        local ctx = JournalRequestContext.new({
            stateFilter = JournalRequestStateFilter.new({
                inactive = true, active = true, succeeded = true, failed = true,
            }),
        })
        return jm:GetQuests(ctx)
    end)
    if not ok or not quests then return nil end
    return jm, quests
end

-- GetEntryState returns a gameJournalEntryState enum; compare against the global enum
-- values (the proven pattern from real mods) since .value isn't reliable across builds.
local function stateNum(es)
    if es == nil then return 0 end
    if es == gameJournalEntryState.Succeeded then return 3 end
    if es == gameJournalEntryState.Active then return 2 end
    if es == gameJournalEntryState.Inactive then return 1 end
    if es == gameJournalEntryState.Failed then return 4 end
    if type(es) == "number" then return es end
    local ok, v = pcall(function() return es.value end)
    return (ok and type(v) == "number") and v or 0
end

local function entryId(e)
    local id = ""
    pcall(function()
        local v = e.id
        if type(v) == "string" then id = v elseif v ~= nil then id = tostring(v.value or v) end
    end)
    return id
end

-- reconstruct a quest's journal path by walking parents, for the category tag
local function questPath(jm, entry)
    local parts, e, guard = {}, entry, 0
    while e ~= nil and guard < 20 do
        local id = entryId(e)
        if id == "" then break end
        table.insert(parts, 1, id)
        local parent
        pcall(function() parent = jm:GetParentEntry(e) end)
        e = parent
        guard = guard + 1
    end
    return table.concat(parts, "/")
end

local function buildQuestList()
    local out = {}
    local jm, quests = fetchQuests()
    if not jm then return out end
    for _, q in ipairs(quests) do
        local name, st = "?", 0
        pcall(function() name = GetLocalizedText(q:GetTitle(jm)) end)
        if name == nil or name == "" then name = "?" end
        pcall(function() st = stateNum(jm:GetEntryState(q)) end)
        local cat
        pcall(function() cat = catFromPath(questPath(jm, q)) end)
        out[#out + 1] = { name = name, entry = q, state = st, cat = cat }
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

local function locateQuest(entry)
    local ok = pcall(function() Game.GetJournalManager():TrackEntry(entry) end)
    notify(ok and t("qtracked") or t("failed"))
end

local qcatShow = { main = true, ending = true, cosmetic = true }
local CAT_ORDER = { "main", "ending", "cosmetic" }
local function stateMeta(val)
    for _, s in ipairs(QSTATE) do if s.val == val then return s end end
    return QSTATE[3]
end

-- one unified list: grouped by category (Principal/Afeta o final/Cosmetica); each row is
-- colored by its live state and shows the state word; Localizar on anything not done.
local function drawQuestsTab()
    ImGui.SetNextItemWidth(260 * (settings.uiscale or 1))
    local text, changed = ImGui.InputTextWithHint("##qsearch", t("search"), filters.q or "", 64)
    if changed then filters.q = text end
    local qtoks = searchTokens(filters.q or "")
    ImGui.SameLine()
    if ImGui.Button(t("qrefresh")) then questCache = nil end
    for i, c in ipairs(CAT_ORDER) do
        if i > 1 then ImGui.SameLine() end
        local q = QCAT[c]
        local v, ch = ImGui.Checkbox("##qc" .. c, qcatShow[c])
        if ch then qcatShow[c] = v end
        ImGui.SameLine()
        ImGui.TextColored(q.r, q.g, q.b, 1.0, t(q.key))
    end
    for i, s in ipairs(QSTATE) do
        if i > 1 then ImGui.SameLine() end
        local v, ch = ImGui.Checkbox("##qs" .. s.val, qsShow[s.val])
        if ch then qsShow[s.val] = v end
        ImGui.SameLine()
        ImGui.TextColored(s.r, s.g, s.b, 1.0, t(s.key))
    end
    if not hasPL() then ImGui.TextWrapped(t("qnopl")) end
    ImGui.Separator()

    if questCache == nil or #questCache == 0 then questCache = buildQuestList() end
    if #questCache == 0 then ImGui.TextWrapped(t("qreadfail")); return end

    if #qtoks > 0 then
        local n = 0
        for _, q in ipairs(questCache) do
            if qcatShow[q.cat] and qsShow[q.state] and matchesAll(q.name, qtoks) then n = n + 1 end
        end
        ImGui.Text(n .. " " .. t("results"))
    end

    for _, c in ipairs(CAT_ORDER) do
        if qcatShow[c] then
            local rows = {}
            for i, q in ipairs(questCache) do
                if q.cat == c and qsShow[q.state]
                    and (#qtoks == 0 or matchesAll(q.name, qtoks)) then
                    rows[#rows + 1] = { q = q, i = i }
                end
            end
            if #rows > 0 then
                local cc = QCAT[c]
                if ImGui.CollapsingHeader(t(cc.key) .. " (" .. #rows .. ")", OPEN) then
                    local z = beginList("q" .. c)
                    for _, e in ipairs(rows) do
                        listRow(z)
                        local sm = stateMeta(e.q.state)
                        if e.q.state ~= 3 then
                            if ImGui.Button(t("qlocate") .. "##ql" .. e.i) then locateQuest(e.q.entry) end
                            ImGui.SameLine()
                        end
                        ImGui.TextColored(sm.r, sm.g, sm.b, 1.0, e.q.name)
                        ImGui.SameLine()
                        ImGui.TextDisabled(t(sm.key))
                    end
                    endList(z)
                end
            end
        end
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
    local s = settings.uiscale or 1
    ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, 8 * s, 5 * s)
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 8 * s, 6 * s)
    return 21, 5
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
    ImGui.SetWindowFontScale(settings.uiscale or 1.0)

    if ImGui.BeginTabBar("##gmetabs") then
        if ImGui.BeginTabItem(t("tabsearch")) then
            drawSearchTab()
            ImGui.EndTabItem()
        end
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
        if ImGui.BeginTabItem(t("taballweapons")) then
            drawDynTab("aw", buildDynList("aw", "gamedataWeaponItem_Record", WEAPON_GROUPS), t("weapall"), t("weapwarn"))
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem(t("tabmods")) then
            drawDynTab("m", buildDynList("m", { "gamedataAttachment_Record", "gamedataItem_Record" }, MODS_GROUPS), t("modall"), t("modwarn"))
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem(t("tabclothes")) then
            drawDynTab("c", buildDynList("c", "gamedataClothing_Record", CLOTH_GROUPS), t("clothall"), t("clothwarn"))
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem(t("tcaw")) then
            drawDynTab("cyb", buildDynList("cyb", { "gamedataItem_Record", "gamedataWeaponItem_Record" }, CYBER_GROUPS), t("cawall"), t("cawwarn"))
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem(t("vehicles")) then
            drawDynTab("veh", buildDynList("veh", "gamedataVehicle_Record", VEH_GROUPS), t("unlockveh"), t("vehwarn"))
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem(t("tabcarry")) then
            drawCarryTab()
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem(t("tabunlocks")) then
            drawUnlocksTab()
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem(t("tabquests")) then
            drawQuestsTab()
            ImGui.EndTabItem()
        end
        ImGui.EndTabBar()
    end

    ImGui.Separator()
    ImGui.SetNextItemWidth(140 * (settings.uiscale or 1))
    local sc, scch = ImGui.SliderFloat("##uiscale", settings.uiscale or 1.0, 0.8, 1.6, "%.1fx")
    if scch then settings.uiscale = sc; saveSettings() end
    ImGui.SameLine()
    ImGui.TextColored(0.62, 0.62, 0.64, 1.0, t("uiscale"))

    ImGui.End()
    ImGui.PopStyleColor(nCol)
    ImGui.PopStyleVar(nVar)
end)
