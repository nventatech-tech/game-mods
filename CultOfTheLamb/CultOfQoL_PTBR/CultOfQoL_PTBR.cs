using BepInEx;
using BepInEx.Bootstrap;
using BepInEx.Configuration;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using UnityEngine;

namespace CultOfQoL_PTBR
{
    [BepInPlugin(PluginGuid, PluginName, PluginVersion)]
    [BepInDependency(TargetGuid, BepInDependency.DependencyFlags.HardDependency)]
    [BepInDependency(ConfigurationManagerGuid, BepInDependency.DependencyFlags.SoftDependency)]
    public sealed class Plugin : BaseUnityPlugin
    {
        private const string PluginGuid = "opaaaaaaaaaaaa.cotl.cultofqol.ptbr";
        private const string PluginName = "CultOfQoL PT-BR - Configuration Manager";
        private const string PluginVersion = "1.0.1";

        private const string TargetGuid = "p1xel8ted.cotl.CultOfQoLCollection";
        private const string ConfigurationManagerGuid = "com.bepis.bepinex.configurationmanager";

        private static Type _configurationManagerAttributesType;
        private static bool _loggedSuccess;

        private void Awake()
        {
            ApplyTranslations();
            StartCoroutine(DelayedApply());
        }

        private IEnumerator DelayedApply()
        {
            // Alguns mods registram ConfigEntry no Awake/Start. Reaplicar em alguns frames evita corrida de carregamento.
            for (var i = 0; i < 8; i++)
            {
                yield return null;
                ApplyTranslations();
            }
        }

        private void ApplyTranslations()
        {
            try
            {
                if (!Chainloader.PluginInfos.TryGetValue(TargetGuid, out var pluginInfo) || pluginInfo?.Instance == null)
                {
                    return;
                }

                var config = pluginInfo.Instance.Config;
                if (config == null)
                {
                    return;
                }

                var changed = 0;
                foreach (var entry in GetEntries(config))
                {
                    if (entry?.Definition == null)
                    {
                        continue;
                    }

                    var section = Clean(entry.Definition.Section);
                    var key = Clean(entry.Definition.Key);
                    var translation = FindTranslation(section, key);
                    if (translation == null)
                    {
                        continue;
                    }

                    var category = translation.Category ?? FindCategory(section);
                    if (PatchEntry(entry, category, translation.DisplayName, translation.Description))
                    {
                        changed++;
                    }
                }

                if (changed > 0 && !_loggedSuccess)
                {
                    _loggedSuccess = true;
                    Logger.LogInfo($"Tradução PT-BR aplicada ao Configuration Manager do CultOfQoL: {changed} opções.");
                }
            }
            catch (Exception ex)
            {
                Logger.LogWarning("Falha ao aplicar tradução PT-BR do CultOfQoL: " + ex.Message);
            }
        }

        private static IEnumerable<ConfigEntryBase> GetEntries(ConfigFile config)
        {
            var type = config.GetType();

            var valuesProperty = type.GetProperty("Values", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
            if (valuesProperty?.GetValue(config) is IEnumerable values)
            {
                foreach (var value in values)
                {
                    if (value is ConfigEntryBase entry)
                    {
                        yield return entry;
                    }
                }
                yield break;
            }

            var entriesProperty = type.GetProperty("Entries", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
            if (entriesProperty?.GetValue(config) is IDictionary entriesFromProperty)
            {
                foreach (DictionaryEntry item in entriesFromProperty)
                {
                    if (item.Value is ConfigEntryBase entry)
                    {
                        yield return entry;
                    }
                }
                yield break;
            }

            var entriesField = type.GetField("_entries", BindingFlags.Instance | BindingFlags.NonPublic)
                ?? type.GetField("entries", BindingFlags.Instance | BindingFlags.NonPublic);

            if (entriesField?.GetValue(config) is IDictionary entriesFromField)
            {
                foreach (DictionaryEntry item in entriesFromField)
                {
                    if (item.Value is ConfigEntryBase entry)
                    {
                        yield return entry;
                    }
                }
                yield break;
            }

            if (config is IEnumerable enumerable)
            {
                foreach (var item in enumerable)
                {
                    if (item is ConfigEntryBase direct)
                    {
                        yield return direct;
                        continue;
                    }

                    var valueProperty = item?.GetType().GetProperty("Value", BindingFlags.Instance | BindingFlags.Public);
                    if (valueProperty?.GetValue(item) is ConfigEntryBase entry)
                    {
                        yield return entry;
                    }
                }
            }
        }

        private static bool PatchEntry(ConfigEntryBase entry, string category, string displayName, string description)
        {
            var oldDescription = entry.Description ?? new ConfigDescription(string.Empty);
            var tags = oldDescription.Tags != null
                ? oldDescription.Tags.Where(t => t == null || !IsConfigurationManagerAttributes(t.GetType())).ToList()
                : new List<object>();

            var cmAttributes = CreateConfigurationManagerAttributes(category, displayName, description);
            if (cmAttributes != null)
            {
                tags.Add(cmAttributes);
            }

            var newDescription = new ConfigDescription(description ?? oldDescription.Description, oldDescription.AcceptableValues, tags.ToArray());
            return SetEntryDescription(entry, newDescription);
        }

        private static object CreateConfigurationManagerAttributes(string category, string displayName, string description)
        {
            var type = FindConfigurationManagerAttributesType();
            if (type == null)
            {
                return null;
            }

            var instance = Activator.CreateInstance(type);
            SetPropertyOrField(instance, "Category", category);
            SetPropertyOrField(instance, "DispName", displayName);
            SetPropertyOrField(instance, "Description", description);
            return instance;
        }

        private static Type FindConfigurationManagerAttributesType()
        {
            if (_configurationManagerAttributesType != null)
            {
                return _configurationManagerAttributesType;
            }

            foreach (var assembly in AppDomain.CurrentDomain.GetAssemblies())
            {
                Type[] types;
                try
                {
                    types = assembly.GetTypes();
                }
                catch (ReflectionTypeLoadException ex)
                {
                    types = ex.Types.Where(t => t != null).ToArray();
                }
                catch
                {
                    continue;
                }

                foreach (var type in types)
                {
                    if (IsConfigurationManagerAttributes(type))
                    {
                        _configurationManagerAttributesType = type;
                        return type;
                    }
                }
            }

            return null;
        }

        private static bool IsConfigurationManagerAttributes(Type type)
        {
            return type != null &&
                   (type.FullName == "ConfigurationManager.ConfigurationManagerAttributes" ||
                    type.Name == "ConfigurationManagerAttributes");
        }

        private static void SetPropertyOrField(object instance, string name, object value)
        {
            if (instance == null || string.IsNullOrEmpty(name))
            {
                return;
            }

            var type = instance.GetType();
            var property = type.GetProperty(name, BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
            var setter = property?.GetSetMethod(true);
            if (setter != null)
            {
                setter.Invoke(instance, new[] { value });
                return;
            }

            var field = type.GetField(name, BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic)
                ?? type.GetField("<" + name + ">k__BackingField", BindingFlags.Instance | BindingFlags.NonPublic);
            field?.SetValue(instance, value);
        }

        private static bool SetEntryDescription(ConfigEntryBase entry, ConfigDescription description)
        {
            var type = entry.GetType();
            while (type != null)
            {
                var property = type.GetProperty("Description", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
                var setter = property?.GetSetMethod(true);
                if (setter != null)
                {
                    setter.Invoke(entry, new object[] { description });
                    return true;
                }

                var field = type.GetField("<Description>k__BackingField", BindingFlags.Instance | BindingFlags.NonPublic)
                    ?? type.GetField("_description", BindingFlags.Instance | BindingFlags.NonPublic)
                    ?? type.GetField("description", BindingFlags.Instance | BindingFlags.NonPublic);

                if (field != null)
                {
                    field.SetValue(entry, description);
                    return true;
                }

                type = type.BaseType;
            }

            return false;
        }

        private static Translation FindTranslation(string section, string key)
        {
            var sectionKey = Normalize(section) + "|" + Normalize(RemoveRestartMarker(key));
            if (Entries.TryGetValue(sectionKey, out var exact))
            {
                return exact;
            }

            if (Entries.TryGetValue(Normalize(RemoveRestartMarker(key)), out var byKey))
            {
                return byKey;
            }

            return null;
        }

        private static string FindCategory(string section)
        {
            return Categories.TryGetValue(Normalize(section), out var category) ? category : section;
        }

        private static string Clean(string value)
        {
            return (value ?? string.Empty).Trim();
        }

        private static string RemoveRestartMarker(string value)
        {
            return Clean(value).Replace("**", string.Empty).Trim();
        }

        private static string Normalize(string value)
        {
            return RemoveRestartMarker(value).ToLowerInvariant();
        }

        private sealed class Translation
        {
            public readonly string Category;
            public readonly string DisplayName;
            public readonly string Description;

            public Translation(string displayName, string description, string category = null)
            {
                Category = category;
                DisplayName = displayName;
                Description = description;
            }
        }

        private static Translation T(string displayName, string description, string category = null)
        {
            return new Translation(displayName, description, category);
        }

        private static readonly Dictionary<string, string> Categories = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            ["general"] = "Geral",
            ["animals"] = "Animais",
            ["auto-interact (chests)"] = "Interação automática (baús)",
            ["capacities"] = "Capacidades",
            ["collection"] = "Coleta",
            ["farm"] = "Fazenda",
            ["followers"] = "Seguidores",
            ["game mechanics"] = "Mecânicas do jogo",
            ["game speed"] = "Velocidade do jogo",
            ["golden fleece"] = "Velo Dourado",
            ["knucklebones"] = "Jogo dos dados",
            ["loot"] = "Saque",
            ["mass action costs"] = "Custos de ações em massa",
            ["mass animal"] = "Animais em massa",
            ["mass collect"] = "Coleta em massa",
            ["mass farm"] = "Fazenda em massa",
            ["mass follower"] = "Seguidores em massa",
            ["menu cleanup"] = "Limpeza dos menus",
            ["mines"] = "Minas",
            ["notifications"] = "Notificações",
            ["player"] = "Jogador",
            ["post processing"] = "Pós-processamento",
            ["rituals"] = "Rituais",
            ["saves"] = "Salvamentos",
            ["sound"] = "Som",
            ["structures"] = "Estruturas",
            ["tarot"] = "Tarô",
            ["weather"] = "Clima",
            ["fixes"] = "Correções",
            ["reset all settings"] = "Redefinir todas as configurações"
        };

        private static readonly Dictionary<string, Translation> Entries = new Dictionary<string, Translation>(StringComparer.OrdinalIgnoreCase)
        {
            ["enable logging"] = T("Ativar logs", "Ativa ou desativa os logs do mod."),
            ["dump translations key"] = T("Tecla para exportar traduções", "Com os logs ativados, pressione esta tecla para exportar as traduções em inglês para um arquivo em BepInEx/plugins/CultOfQoL/."),
            ["unlock twitch items"] = T("Desbloquear itens da Twitch", "Desbloqueia DLC de pré-venda, plush da Twitch e drops da Twitch. DLCs pagas são excluídas de propósito."),

            ["immortal farm animals"] = T("Animais da fazenda imortais", "Impede que os animais da fazenda morram de velhice."),
            ["animal old age death threshold"] = T("Idade mínima para morte por velhice", "Idade mínima, em dias, antes de os animais poderem morrer de velhice. O padrão do jogo é 15."),
            ["animal guaranteed death age"] = T("Idade de morte garantida", "Idade em que a morte por velhice se torna certa. A chance diária escala linearmente; na metade dessa idade, há 50% de chance por dia. O padrão do jogo é 100."),

            ["enable auto collect"] = T("Ativar coleta automática", "Faz os baús enviarem recursos automaticamente quando você estiver por perto."),
            ["auto collect from farm station chests"] = T("Coletar baús da estação de fazenda", "Coleta automaticamente os recursos dos baús da estação de fazenda."),
            ["trigger amount"] = T("Quantidade para ativar", "Quantidade de recursos necessária para acionar a interação automática."),
            ["auto-interact (chests)|loot magnet range multiplier"] = T("Multiplicador do alcance do ímã", "Multiplicador usado para o alcance da coleta automática quando o alcance personalizado estiver ativo."),

            ["use multiples of 32"] = T("Usar múltiplos de 32", "Usa múltiplos de 32 para a capacidade dos silos."),
            ["silo capacity multiplier"] = T("Multiplicador da capacidade dos silos", "Multiplicador usado para a capacidade dos silos quando a capacidade personalizada estiver ativa."),
            ["soul capacity multiplier"] = T("Multiplicador da capacidade de almas", "Multiplicador usado para a capacidade de almas quando a capacidade personalizada estiver ativa."),

            ["speed up collection"] = T("Acelerar coleta", "Acelera a drenagem de almas dos santuários, instantânea, e das camas, 2x mais rápida. Também remove atrasos ao coletar de baús de recursos."),
            ["collect shrine devotion instantly"] = T("Coletar devoção do santuário instantaneamente", "Ao coletar devoção do santuário, coleta tudo de uma vez em vez de precisar segurar o botão."),
            ["disable soul camera shake"] = T("Desativar tremor de câmera das almas", "Desativa o tremor de câmera causado por orbes de devoção e almas atingindo o santuário. Não afeta o tremor de câmera em combate."),

            ["prioritize requested followers"] = T("Priorizar seguidores solicitados", "Seguidores com pedidos ativos, rituais, missões, acasalamento etc., aparecem no topo das listas de seleção."),
            ["give followers new necklaces"] = T("Dar novos colares aos seguidores", "Permite dar novos colares aos seguidores, devolvendo o colar antigo para você."),
            ["cleanse illness and exhaustion"] = T("Curar doença e exaustão", "Quando um seguidor sobe de nível, se estiver doente ou exausto, esse status é removido."),
            ["collect tithe from old followers"] = T("Coletar dízimo de seguidores idosos", "Permite coletar dízimo de seguidores idosos."),
            ["intimidate old followers"] = T("Intimidar seguidores idosos", "Permite intimidar seguidores idosos."),
            ["uncap level benefits"] = T("Remover limite dos benefícios de nível", "Remove o limite de nível 10 nos benefícios dos seguidores. Produtividade, devoção por oração e recompensas de sacrifício escalam além do nível 10."),
            ["elder work mode"] = T("Modo de trabalho dos idosos", "Desativado: idosos não trabalham, como no jogo padrão. Todos trabalham: idosos fazem todas as tarefas. Trabalho leve: idosos só fazem tarefas leves como adorar, cozinhar, preparar bebidas e pesquisar."),
            ["minimum range life expectancy"] = T("Expectativa de vida mínima", "Menor expectativa de vida possível para um seguidor. O jogo escolherá um valor entre este mínimo e o máximo abaixo. Deve ser menor que o máximo."),
            ["maximum range life expectancy"] = T("Expectativa de vida máxima", "Maior expectativa de vida possível para um seguidor. O jogo escolherá um valor entre o mínimo acima e este máximo."),

            ["easy fishing"] = T("Pesca fácil", "Recolhe o peixe automaticamente sem apertar botões repetidamente. Basta lançar a linha e esperar."),
            ["no more game-over"] = T("Sem game over", "Desativa a função de game over quando você fica com 0 seguidores por dias consecutivos."),
            ["sin boss limit"] = T("Limite de chefes para Pecado", "Quantidade de bispos mortos necessária para desbloquear o Pecado. O padrão é 3."),

            ["enable game speed manipulation"] = T("Ativar controle da velocidade do jogo", "Use as setas esquerda/direita para diminuir/aumentar a velocidade em incrementos de 0,25. Use seta para cima para voltar ao normal."),
            ["shorten game speed increments"] = T("Usar incrementos curtos de velocidade", "Quando ativado, as mudanças usam passos grandes: 0,25x, 1x, 2x, 3x, 4x e 5x. Quando desativado, usam passos finos de 0,25x até 5x."),
            ["reset time scale key"] = T("Tecla para resetar velocidade", "Atalho de teclado para restaurar a velocidade do jogo para 1x."),
            ["increase game speed key"] = T("Tecla para aumentar velocidade", "Atalho de teclado para aumentar a velocidade do jogo."),
            ["decrease game speed key"] = T("Tecla para diminuir velocidade", "Atalho de teclado para diminuir a velocidade do jogo."),
            ["slow down time multiplier"] = T("Multiplicador para desacelerar o tempo", "Multiplicador usado para desacelerar o tempo. Por exemplo, o valor 2 faz o dia durar o dobro."),

            ["reverse golden fleece change"] = T("Reverter alteração do Velo Dourado", "Restaura o aumento de dano padrão para 10% em vez de 5%."),
            ["fleece damage multiplier"] = T("Multiplicador de dano do velo", "Multiplicador de dano personalizado. Baseado no padrão atual do jogo, que é 5%."),

            ["animation speed multiplier"] = T("Multiplicador de velocidade das animações", "Acelera as animações do Jogo dos Dados. 1,0 = velocidade normal, 2,0 = duas vezes mais rápido etc."),

            ["all loot magnets"] = T("Ímã para todo saque", "Todo saque é atraído para você."),
            ["loot|magnet range multiplier"] = T("Multiplicador do alcance do ímã", "Aplica um multiplicador ao alcance do ímã de saque."),

            ["mass pet animals"] = T("Acariciar animais em massa", "Ao acariciar um animal da fazenda, todos os animais da fazenda são acariciados de uma vez."),
            ["mass clean animals"] = T("Limpar animais em massa", "Ao limpar um animal fedido, todos os animais fedidos são limpos de uma vez."),
            ["mass feed animals"] = T("Alimentar animais em massa", "Ao alimentar um animal, todos os animais famintos recebem a mesma comida de uma vez, consumindo um item por animal."),
            ["mass milk animals"] = T("Ordenhar animais em massa", "Ao ordenhar um animal, todos os animais prontos para ordenha são ordenhados de uma vez."),
            ["mass shear animals"] = T("Tosquiar animais em massa", "Ao tosquiar um animal, todos os animais prontos para tosquia são tosquiados de uma vez."),
            ["fill trough to capacity"] = T("Encher cocho até a capacidade", "Ao adicionar comida a um cocho, enche até a capacidade em uma ação em vez de adicionar um item por vez."),
            ["mass fill troughs"] = T("Encher cochos em massa", "Ao encher um cocho, todos os cochos que não estão cheios recebem a mesma comida."),

            ["cost mode"] = T("Modo de custo", "Como os custos são calculados. Por ação em massa = taxa fixa. Por objeto = custo multiplicado pela quantidade de objetos afetados."),
            ["show cost preview"] = T("Mostrar prévia de custo", "Mostra o custo estimado no rótulo de interação ao destacar uma ação em massa. Só aparece quando o modo de custo está em Por Objeto."),
            ["gold cost"] = T("Custo em ouro", "Ouro descontado por uma ação em massa. Use 0 para deixar grátis. Se você não tiver ouro suficiente, a ação em massa é ignorada, mas a interação única original ainda funciona."),
            ["time cost (game minutes)"] = T("Custo de tempo (minutos do jogo)", "Minutos do jogo que passam em uma ação em massa. Use 0 para não gastar tempo. 240 minutos = 1 fase do jogo."),
            ["faith reduction (%)"] = T("Redução de fé (%)", "Reduz a fé recebida por seguidor em Bênção e Inspirar em massa. 0 = fé cheia, 50 = metade, 100 = nenhuma fé. A interação única original sempre dá fé completa."),

            ["collect all god tears at once"] = T("Coletar todas as Lágrimas Divinas de uma vez", "Ao coletar Lágrimas Divinas do santuário, coleta todas as disponíveis de uma vez em vez de uma por interação."),
            ["mass collect from beds"] = T("Coletar camas em massa", "Ao coletar almas de uma cama, todas as camas são coletadas de uma vez. Também acelera a drenagem de almas para 2x."),
            ["mass collect from outhouses"] = T("Coletar latrinas em massa", "Ao coletar recursos de uma latrina, todas as latrinas são coletadas de uma vez."),
            ["mass collect from offering shrines"] = T("Coletar altares de oferenda em massa", "Ao coletar recursos de um altar de oferenda, todos os altares de oferenda são coletados de uma vez."),
            ["mass collect from passive shrines"] = T("Coletar santuários passivos em massa", "Ao coletar recursos de um santuário passivo, todos os santuários passivos são coletados de uma vez."),
            ["mass collect from compost"] = T("Coletar composteiras em massa", "Ao coletar recursos de uma composteira, todas as composteiras são coletadas de uma vez."),
            ["mass collect from harvest totems"] = T("Coletar totens de colheita em massa", "Ao coletar recursos de um totem de colheita, todos os totens de colheita são coletados de uma vez."),
            ["mass clean poop"] = T("Limpar cocô em massa", "Ao limpar uma pilha de cocô, todas as pilhas de cocô são limpas de uma vez."),
            ["mass clean vomit"] = T("Limpar vômito em massa", "Ao limpar uma poça de vômito, todas as poças de vômito são limpas de uma vez."),

            ["mass plant seeds"] = T("Plantar sementes em massa", "Ao plantar uma semente em um canteiro, todos os outros canteiros vazios recebem a mesma semente."),
            ["mass fertilize"] = T("Fertilizar em massa", "Ao fertilizar um canteiro, todos os canteiros são fertilizados de uma vez."),
            ["mass water"] = T("Regar em massa", "Ao regar um canteiro, todos os canteiros são regados de uma vez."),
            ["fill carpentry station to capacity"] = T("Encher estação de carpintaria até a capacidade", "Ao depositar materiais na estação de carpintaria, preenche até a capacidade em uma ação em vez de adicionar um item por vez."),
            ["mass fill carpentry stations"] = T("Encher estações de carpintaria em massa", "Ao encher uma estação de carpintaria, todas as estações que não estão cheias recebem o mesmo material."),
            ["fill medic station to capacity"] = T("Encher estação médica até a capacidade", "Ao depositar suprimentos na estação médica, preenche até a capacidade em uma ação em vez de adicionar um item por vez."),
            ["mass fill medic stations"] = T("Encher estações médicas em massa", "Ao encher uma estação médica, todas as estações que não estão cheias recebem o mesmo suprimento."),
            ["fill seed silo to capacity"] = T("Encher silo de sementes até a capacidade", "Ao depositar sementes no silo de sementes, preenche até a capacidade em uma ação em vez de adicionar uma por vez."),
            ["mass fill seed silos"] = T("Encher silos de sementes em massa", "Ao encher um silo de sementes, todos os silos que não estão cheios recebem a mesma semente."),
            ["fill fertiliser silo to capacity"] = T("Encher silo de fertilizante até a capacidade", "Ao depositar fertilizante no silo, preenche até a capacidade em uma ação em vez de adicionar um por vez."),
            ["mass fill fertiliser silos"] = T("Encher silos de fertilizante em massa", "Ao encher um silo de fertilizante, todos os silos que não estão cheios recebem o mesmo fertilizante."),
            ["mass open scarecrows"] = T("Abrir espantalhos em massa", "Ao abrir uma armadilha de espantalho, todas as armadilhas com pássaros capturados são abertas de uma vez."),
            ["mass wolf traps"] = T("Armadilhas de lobo em massa", "Somente preencher: enche todas as armadilhas vazias com a mesma isca. Somente coletar: coleta de todas as armadilhas com lobos capturados. Ambos: faz as duas ações."),

            ["rot fertilizer decay"] = T("Decaimento do fertilizante de podridão", "Quando ativado, o aquecimento do fertilizante de podridão nos canteiros expira após um número definido de dias, em vez de durar para sempre."),
            ["rot fertilizer duration (days)"] = T("Duração do fertilizante de podridão (dias)", "Número de dias antes do aquecimento do fertilizante de podridão expirar. Plantações em canteiros expirados congelam no inverno, salvo se estiverem perto de um Totem de Colheita Descongelante."),

            ["mass notification threshold"] = T("Limite para notificação em massa", "Quando uma ação em massa afeta mais seguidores que este valor, mostra uma única notificação de resumo em vez de uma por seguidor. Use 0 para sempre mostrar resumo."),
            ["mass bribe"] = T("Subornar em massa", "Ao subornar um seguidor, todos os seguidores são subornados de uma vez."),
            ["mass bless"] = T("Abençoar em massa", "Ao abençoar um seguidor, todos os seguidores são abençoados de uma vez."),
            ["mass extort"] = T("Extorquir em massa", "Ao extorquir um seguidor, todos os seguidores são extorquidos de uma vez."),
            ["mass intimidate"] = T("Intimidar em massa", "Ao intimidar um seguidor, todos os seguidores são intimidados de uma vez."),
            ["mass intimidate scare all"] = T("Intimidação em massa assusta todos", "Quando Intimidar em massa estiver ativo, aplica a rolagem de 5% do traço Assustado a todos os seguidores intimidados, não só ao original."),
            ["mass inspire"] = T("Inspirar em massa", "Ao inspirar um seguidor, todos os seguidores são inspirados de uma vez."),
            ["mass romance"] = T("Romance em massa", "Ao fazer romance com um seguidor, todos os seguidores recebem romance de uma vez."),
            ["mass bully"] = T("Amedrontar em massa", "Ao intimidar/oprimir um seguidor, todos os seguidores recebem essa ação de uma vez."),
            ["mass reassure"] = T("Tranquilizar em massa", "Ao tranquilizar um seguidor, todos os seguidores são tranquilizados de uma vez."),
            ["mass reeducate"] = T("Reeducar em massa", "Ao reeducar um seguidor, todos os seguidores são reeducados de uma vez."),
            ["mass level up"] = T("Subir nível em massa", "Ao subir o nível de um seguidor, todos os seguidores elegíveis sobem de nível de uma vez."),
            ["mass level up instant souls"] = T("Almas instantâneas ao subir nível em massa", "Coleta almas instantaneamente durante o nivelamento em massa em vez de fazê-las voar até você."),
            ["mass pet follower"] = T("Acariciar seguidores em massa", "Ao acariciar um seguidor, todos os seguidores elegíveis são acariciados de uma vez. A elegibilidade depende da opção Acariciar todos os seguidores."),
            ["mass pet all followers"] = T("Acariciar todos os seguidores", "Quando ativado, acariciar em massa se aplica a todos os seguidores, independentemente do traço Acariciável. Quando desativado, só seguidores com o traço Acariciável ou pele de Cão/Poppy são acariciados."),
            ["mass sin extract"] = T("Extrair pecado em massa", "Ao extrair pecado de um seguidor, todos os seguidores elegíveis têm o pecado extraído de uma vez."),

            ["remove extra menu buttons"] = T("Remover botões extras do menu", "Remove botões de créditos, roadmap e Discord dos menus."),
            ["remove twitch buttons"] = T("Remover botões da Twitch", "Remove os botões da Twitch dos menus."),
            ["hide ads"] = T("Ocultar anúncios", "Oculta anúncios promocionais do menu principal."),
            ["remove help button in pause menu"] = T("Remover botão de ajuda no menu de pausa", "Remove o botão de ajuda do menu de pausa."),
            ["remove twitch button in pause menu"] = T("Remover botão da Twitch no menu de pausa", "Remove o botão da Twitch do menu de pausa."),
            ["remove photo mode button in pause menu"] = T("Remover botão do modo foto no menu de pausa", "Remove o botão do modo foto do menu de pausa."),
            ["main menu glitch"] = T("Efeito glitch do menu principal", "Controla o efeito repentino de alternância para modo escuro."),

            ["infinite lumber & mining stations"] = T("Estações de madeira e mineração infinitas", "Estações de madeira e mineração nunca acabam nem desmoronam. Tem prioridade máxima."),
            ["lumber & mining stations age multiplier"] = T("Multiplicador de envelhecimento das estações", "Controla quão mais devagar ou mais rápido as estações de madeira e mineração envelhecem. O padrão é 1,0."),

            ["hide all notifications"] = T("Ocultar todas as notificações", "Oculta todas as notificações do jogo. Também impede que as notificações personalizadas abaixo apareçam."),
            ["allow critical notifications"] = T("Permitir notificações críticas", "Quando Ocultar todas as notificações estiver ativo, ainda mostra notificações críticas, como mortes, destruição de armas e dissidentes."),
            ["suppress notifications on load"] = T("Suprimir notificações ao carregar", "Suprime notificações individuais por alguns segundos após carregar um save, evitando uma enxurrada de atualizações de status. Indicadores dinâmicos, como fome e doença, não são afetados."),
            ["notify of scarecrow traps"] = T("Notificar armadilhas do espantalho", "Mostra uma notificação quando os espantalhos da fazenda capturam algo."),
            ["notify of no fuel"] = T("Notificar falta de combustível", "Mostra uma notificação quando uma estrutura fica sem combustível."),
            ["notify of bed collapse"] = T("Notificar cama quebrada", "Mostra uma notificação quando uma cama desmorona."),
            ["phase notifications"] = T("Notificações de fase", "Mostra uma notificação quando o período do dia muda."),
            ["weather change notifications"] = T("Notificações de mudança climática", "Mostra uma notificação quando o clima muda."),

            ["run speed multiplier"] = T("Multiplicador de velocidade de corrida", "Controla quão mais rápido o jogador corre."),
            ["exclude dungeons"] = T("Excluir masmorras", "Quando ativado, o multiplicador de corrida não se aplica em masmorras."),
            ["exclude combat"] = T("Excluir combate", "Quando ativado, o multiplicador de corrida não se aplica durante o combate."),
            ["base damage multiplier"] = T("Multiplicador de dano base", "Multiplicador de dano base a ser usado."),
            ["dodge speed multiplier"] = T("Multiplicador de velocidade da esquiva", "Controla quão mais rápido o jogador esquiva."),
            ["lunge speed multiplier"] = T("Multiplicador de velocidade do avanço", "Controla quão mais rápido o jogador avança/investe."),

            ["vignette ui overlay"] = T("Sobreposição de vinheta da interface", "Ativa ou desativa as imagens de vinheta da interface, separadas do efeito de vinheta de pós-processamento."),

            ["fast rituals & sermons"] = T("Rituais e sermões rápidos", "Acelera rituais e sermões."),
            ["ritual & sermon speed multiplier"] = T("Multiplicador de velocidade de rituais e sermões", "Velocidade dos rituais e sermões quando a opção Rituais e sermões rápidos está ativa. 2,0 = duas vezes mais rápido; 5,0 = cinco vezes; 10,0 = dez vezes, podendo causar falhas visuais."),
            ["speed multiplier"] = T("Multiplicador de velocidade", "Multiplicador de velocidade usado por esta opção."),
            ["reverse enrichment nerf"] = T("Reverter nerf do Ritual de Enriquecimento", "Reverte o nerf do Ritual de Enriquecimento. As moedas escalam com o nível do seguidor: nível x 20 por seguidor."),
            ["ritual cooldown time multiplier"] = T("Multiplicador do tempo de recarga dos rituais", "Escala a duração da recarga dos rituais. 2,0 = recarga dobrada; 1,0 = normal; 0,5 = metade; 0,25 = muito mais rápido. Aplica-se apenas a rituais feitos depois da alteração."),
            ["ritual cost multiplier"] = T("Multiplicador do custo dos rituais", "Multiplica os custos de materiais dos rituais. Valores acima de 1 aumentam custos; abaixo de 1 reduzem. Acumula com descontos do jogo. Não afeta requisitos de seguidores nem desbloqueios de doutrina."),

            ["save on quit to desktop"] = T("Salvar ao sair para a área de trabalho", "Modifica a confirmação para salvar o jogo quando você sair para a área de trabalho."),
            ["save on quit to menu"] = T("Salvar ao sair para o menu", "Modifica a confirmação para salvar o jogo quando você sair para o menu."),
            ["hide new game button (s)"] = T("Ocultar botão Novo Jogo", "Oculta o botão Novo Jogo se você tiver pelo menos um save."),
            ["enable quick save shortcut"] = T("Ativar atalho de salvamento rápido", "Ativa ou desativa o atalho de teclado para salvar rapidamente."),
            ["save keyboard shortcut"] = T("Atalho para salvar", "Atalho de teclado para salvar o jogo."),
            ["direct load save"] = T("Carregar save diretamente", "Carrega diretamente o save especificado em vez de mostrar o menu de saves."),
            ["direct load skip key"] = T("Tecla para ignorar carregamento automático", "Atalho de teclado para ignorar o carregamento automático ao abrir o jogo."),
            ["save slot to load"] = T("Slot de save para carregar", "Slot de save que será carregado."),

            ["resource chest deposit sounds"] = T("Sons ao depositar em baús de recursos", "Toca sons quando seguidores depositam recursos em baús."),
            ["resource chest collect sounds"] = T("Sons ao coletar baús de recursos", "Toca sons ao coletar recursos dos baús."),

            ["rotburn as shrine fuel"] = T("Usar Rotburn como combustível do santuário", "Permite usar Rotburn, MAGMA_STONE, como combustível para o braseiro do santuário."),
            ["rotburn fuel weight"] = T("Valor de combustível do Rotburn", "Valor de combustível ao adicionar Rotburn ao santuário. O padrão corresponde a LOG, 13. MAGMA_STONE no jogo padrão é 14700."),
            ["shrine provides warmth"] = T("Santuário fornece calor", "Quando o braseiro do santuário está totalmente abastecido, ele fornece calor durante o inverno, com contribuição de 20%."),
            ["furnace heater scaling"] = T("Escala de aquecedores da fornalha", "Cada aquecedor de proximidade aumenta o consumo de combustível da fornalha durante o inverno. Mais aquecedores = consumo mais rápido."),
            ["furnace heater fuel cost"] = T("Custo de combustível do aquecedor", "Unidades de combustível drenadas por aquecedor por fase do jogo durante o inverno. 1 Rotburn = 14.700 de combustível."),
            ["heater fuel cost"] = T("Custo de combustível do aquecedor", "Custo de combustível usado pelo aquecedor."),
            ["refinery: poop to rot fertilizer"] = T("Refinaria: cocô para fertilizante de podridão", "Adiciona uma receita na refinaria para converter Cocô + Rotgrit em Fertilizante de Podridão."),
            ["adjust refinery requirements"] = T("Ajustar requisitos da refinaria", "Quando possível, reduz pela metade os materiais necessários para converter itens na refinaria. Arredonda para cima."),
            ["refinery mass fill"] = T("Preencher refinaria em massa", "Ao adicionar um item à fila da refinaria, preenche automaticamente todos os espaços disponíveis com esse item."),
            ["cooking fire mass fill"] = T("Preencher fogueira de cozinha em massa", "Ao adicionar uma refeição à fila da fogueira de cozinha, preenche automaticamente todos os espaços disponíveis com essa refeição."),
            ["kitchen mass fill"] = T("Preencher cozinha em massa", "Ao adicionar uma refeição à fila da cozinha dos seguidores, preenche automaticamente todos os espaços disponíveis com essa refeição."),
            ["pub mass fill"] = T("Preencher bar em massa", "Ao adicionar uma bebida à fila do bar, preenche automaticamente todos os espaços disponíveis com essa bebida."),
            ["auto-select best mating pair"] = T("Selecionar melhor par automaticamente", "Seleciona automaticamente os dois seguidores com maior chance de acasalamento quando a Tenda de Acasalamento é aberta."),
            ["add exhausted to healing bay"] = T("Adicionar exaustos à enfermaria", "Permite selecionar seguidores exaustos para descanso e relaxamento nas enfermarias."),
            ["hide healthy from healing bay"] = T("Ocultar saudáveis da enfermaria", "Oculta seguidores que não precisam de cura no menu de seleção da enfermaria."),
            ["only show dissenters in prison menu"] = T("Mostrar só dissidentes no menu da prisão", "Mostra apenas seguidores dissidentes ao interagir com a prisão."),
            ["exclude grass from seed deposit"] = T("Excluir grama do depósito de sementes", "Ao usar Depositar todas as sementes no silo de sementes, a grama não será depositada."),
            ["turn off speakers at night"] = T("Desligar alto-falantes à noite", "Desliga os alto-falantes e interrompe o consumo de combustível durante a noite."),
            ["mute propaganda speakers"] = T("Silenciar alto-falantes de propaganda", "Silencia o áudio dos alto-falantes de propaganda."),
            ["propaganda speaker range"] = T("Alcance do alto-falante de propaganda", "Alcance do alto-falante de propaganda. Padrão: {0}."),
            ["harvest totem range"] = T("Alcance do totem de colheita", "Alcance do totem de colheita. Padrão: {0}."),
            ["farm station range"] = T("Alcance da estação de fazenda", "Alcance da estação de fazenda. Padrão: 6."),
            ["farm plot sign range"] = T("Alcance da placa de canteiro", "Alcance da placa de canteiro. Padrão: 5."),
            ["lightning rod range (basic)"] = T("Alcance do para-raios básico", "Alcance do para-raios básico. Padrão: {0}."),
            ["lightning rod range (upgraded)"] = T("Alcance do para-raios aprimorado", "Alcance do para-raios aprimorado. Padrão: {0}."),
            ["cooked meat meals contain bone"] = T("Refeições de carne cozida contêm ossos", "Refeições de carne + peixe geram de 1 a 3 ossos quando cozidas."),
            ["add spider webs to offerings"] = T("Adicionar teias às oferendas", "Adiciona Teias de Aranha às oferendas padrão dos Altares de Oferenda."),
            ["add crystals to offerings"] = T("Adicionar cristais às oferendas", "Adiciona Fragmentos de Cristal às oferendas raras dos Altares de Oferenda."),
            ["lumber stations produce spider webs"] = T("Estações de madeira produzem teias", "Estações de madeira produzem teias de aranha a partir dos troncos coletados."),
            ["spider webs per logs"] = T("Teias por troncos", "Número de troncos necessários para produzir 1 teia de aranha."),
            ["mining stations produce crystal shards"] = T("Estações de mineração produzem cristais", "Estações de mineração produzem fragmentos de cristal a partir das pedras coletadas."),
            ["crystal shards per stone"] = T("Cristais por pedra", "Número de pedras necessárias para produzir 1 fragmento de cristal."),

            ["increase tarot luck"] = T("Aumentar sorte do tarô", "Multiplica sua sorte para comprar cartas de tarô raras pelo valor abaixo."),
            ["tarot luck multiplier"] = T("Multiplicador de sorte do tarô", "Multiplicador de sorte para sorteio de cartas raras. Quanto maior, mais cartas raras aparecem."),
            ["rare tarot cards only"] = T("Somente cartas de tarô raras", "Compra apenas cartas de tarô raras."),

            ["weather change trigger"] = T("Gatilho de mudança climática", "Quando o clima deve mudar aleatoriamente? Desativado = padrão do jogo, uma vez por dia. Mudança de local = masmorras/viagem rápida. Mudança de fase = toda fase. Ambos = local e fase."),
            ["unlock all weather types"] = T("Desbloquear todos os tipos de clima", "Permite que todos os tipos de clima, incluindo neve, apareçam independentemente da estação ou progresso do jogo."),
            ["light snow color"] = T("Cor de neve fraca", "Controla a cor da tela quando há neve fraca."),
            ["light wind color"] = T("Cor de vento fraco", "Controla a cor da tela quando há vento fraco."),
            ["light rain color"] = T("Cor de chuva fraca", "Controla a cor da tela quando há chuva fraca."),
            ["medium rain color"] = T("Cor de chuva média", "Controla a cor da tela quando há chuva média."),
            ["heavy rain color"] = T("Cor de chuva forte", "Controla a cor da tela quando há chuva forte."),
            ["weather dropdown"] = T("Selecionar clima", "Selecione o tipo de clima que deseja testar para ver o efeito da cor escolhida."),
            ["test weather"] = T("Testar clima", "Clique para aplicar o tipo de clima selecionado e pré-visualizar suas cores personalizadas no jogo."),

            ["auto repair missing lore"] = T("Reparar conhecimento ausente automaticamente", "Repara automaticamente tabuletas de conhecimento ausentes que não foram desbloqueadas por causa de um bug anterior."),

            ["reset all settings"] = T("Redefinir todas as configurações", "Defina como verdadeiro e salve o arquivo de configuração para redefinir todas as opções para o padrão.")
        };
    }
}
