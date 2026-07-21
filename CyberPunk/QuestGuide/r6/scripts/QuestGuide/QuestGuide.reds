// QuestGuide - guia de missões com UI nativa: principal real vs. afeta o final vs. cosmética,
// com estado vivo do journal
// Requires: redscript, Codeware
module QuestGuide
import Codeware.UI.*
import Codeware.Localization.*

enum QGCategory {
  Main = 0,
  Ending = 1,
  Cosmetic = 2
}

public struct QGQuest {
  public let entry: wref<JournalQuest>;
  public let title: String;
  public let path: String;
  public let category: QGCategory;
  public let state: gameJournalEntryState;
  public let tracked: Bool;
}

// side jobs que gateiam final ou payoff de romance -> Ending; demais side -> Cosmetic
public func QGEndingSideIds() -> array<String> {
  return [
    "sq004_riders_on_the_storm", // Panam -> The Star
    "sq031_rogue",               // Chippin' In -> The Sun + final secreto
    "sq031_smack_my_bitch_up",   // A Cool Metal Fire
    "sq031_cinema",              // Blistering Love -> ligar pra Rogue
    "sq030_judy_romance",
    "sq028_kerry_romance",
    "sq029_sobchak_romance",
    "sq021_sick_dreams",         // The Hunt (River)
    "sq011_kerry", "sq017_kerry", "sq011_concert", "sq011_johnny",
    "sq017_02_lounge"            // cadeia do Kerry
  ];
}

// história principal base aparece sob quests/meta/ (Nocturne = meta/02_sickness);
// tudo main exceto estes
public func QGMetaCosmeticIds() -> array<String> {
  return ["07_nc_underground", "08_headhunter"];
}

func QGHas(ids: array<String>, id: String) -> Bool {
  let i: Int32 = 0;
  while i < ArraySize(ids) {
    if Equals(ids[i], id) {
      return true;
    };
    i += 1;
  };
  return false;
}

// categoria pela pasta do journal: main_quest -> Main; /meta/<id> -> Main salvo lista
// cosmética; side_quest/<id> -> Ending se na lista, senão Cosmetic; resto -> Cosmetic
public func QGCategoryFromPath(path: String) -> QGCategory {
  if StrContains(path, "main_quest") {
    return QGCategory.Main;
  };
  let segs: array<String> = StrSplit(path, "/");
  let i: Int32 = 0;
  while i < ArraySize(segs) - 1 {
    if i > 0 && Equals(segs[i], "meta") {
      return QGHas(QGMetaCosmeticIds(), segs[i + 1]) ? QGCategory.Cosmetic : QGCategory.Main;
    };
    if Equals(segs[i], "side_quest") {
      return QGHas(QGEndingSideIds(), segs[i + 1]) ? QGCategory.Ending : QGCategory.Cosmetic;
    };
    i += 1;
  };
  return QGCategory.Cosmetic;
}

// caminho do journal reconstruído subindo os pais (pasta = categoria)
public func QGEntryPath(jm: ref<JournalManager>, entry: wref<JournalEntry>) -> String {
  let path: String = entry.GetId();
  let parent: wref<JournalEntry> = jm.GetParentEntry(entry);
  let guard: Int32 = 0;
  while IsDefined(parent) && guard < 20 {
    path = parent.GetId() + "/" + path;
    parent = jm.GetParentEntry(parent);
    guard += 1;
  };
  return path;
}

public func QGBuildQuestList(game: GameInstance) -> array<QGQuest> {
  let result: array<QGQuest>;
  let jm: ref<JournalManager> = GameInstance.GetJournalManager(game);
  if !IsDefined(jm) {
    return result;
  };
  let context: JournalRequestContext;
  context.stateFilter.active = true;
  context.stateFilter.inactive = true;
  context.stateFilter.succeeded = true;
  context.stateFilter.failed = true;
  let entries: array<wref<JournalEntry>>;
  jm.GetQuests(context, entries);
  let tracked: wref<JournalEntry> = jm.GetTrackedEntry();
  let i: Int32 = 0;
  while i < ArraySize(entries) {
    let quest: wref<JournalQuest> = entries[i] as JournalQuest;
    if IsDefined(quest) {
      let item: QGQuest;
      item.entry = quest;
      item.title = GetLocalizedText(quest.GetTitle(jm));
      if Equals(item.title, "") {
        item.title = "?";
      };
      item.path = QGEntryPath(jm, quest);
      item.category = QGCategoryFromPath(item.path);
      item.state = jm.GetEntryState(quest);
      item.tracked = IsDefined(tracked) && tracked == quest;
      QGInsertSorted(result, item);
    };
    i += 1;
  };
  return result;
}

// inserção ordenada por título (lista de quests é pequena, sem sort nativo em redscript)
func QGInsertSorted(out list: array<QGQuest>, item: QGQuest) {
  let i: Int32 = 0;
  while i < ArraySize(list) && UnicodeStringCompare(list[i].title, item.title) <= 0 {
    i += 1;
  };
  ArrayInsert(list, i, item);
}

public func QGTrackQuest(game: GameInstance, entry: wref<JournalQuest>) {
  GameInstance.GetJournalManager(game).TrackEntry(entry);
}

// ---------------------------------------------------------------------------
// UI: popup nativo (infra CustomPopup do Codeware), 3 colunas por categoria,
// linha colorida pelo estado vivo do journal. Toggle com U no gameplay.
// ---------------------------------------------------------------------------

func QGIsPtBr(game: GameInstance) -> Bool {
  return Equals(LocalizationSystem.GetInstance(game).GetInterfaceLanguage(), n"pt-br");
}

func QGStateColor(state: gameJournalEntryState) -> HDRColor {
  if Equals(state, gameJournalEntryState.Succeeded) {
    return new HDRColor(0.30, 0.85, 0.35, 1.0);
  };
  if Equals(state, gameJournalEntryState.Active) {
    return new HDRColor(1.00, 0.82, 0.00, 1.0);
  };
  if Equals(state, gameJournalEntryState.Failed) {
    return new HDRColor(0.90, 0.35, 0.30, 1.0);
  };
  return new HDRColor(0.62, 0.62, 0.64, 1.0);
}

// fonte raj nao tem varios glifos unicode ("—" vira "?"), prefixos so em ASCII
func QGStatePrefix(state: gameJournalEntryState) -> String {
  if Equals(state, gameJournalEntryState.Succeeded) {
    return "+ ";
  };
  if Equals(state, gameJournalEntryState.Active) {
    return "> ";
  };
  if Equals(state, gameJournalEntryState.Failed) {
    return "x ";
  };
  return "- ";
}

public class QuestGuidePopup extends InGamePopup {
  protected let m_header: ref<InGamePopupHeader>;
  protected let m_footer: ref<InGamePopupFooter>;
  protected let m_content: ref<InGamePopupContent>;
  protected let m_scrollContents: array<wref<inkVerticalPanel>>;
  protected let m_contentHeights: array<Float>;
  protected let m_scrollOffset: Float;
  protected let m_search: ref<HubTextInput>;
  protected let m_columnsPanel: wref<inkHorizontalPanel>;
  protected let m_quests: array<QGQuest>;
  protected let m_rowWidgets: array<wref<inkText>>;
  protected let m_rowEntries: array<wref<JournalQuest>>;

  public func GetName() -> CName {
    return n"QuestGuidePopup";
  }

  public func UseCursor() -> Bool {
    return true;
  }

  public func QGIsOpen() -> Bool {
    return this.IsInitialized();
  }

  protected cb func OnCreate() {
    super.OnCreate();
    this.m_container.SetSize(Vector2(2600.0, 1340.0));
    let ptBr: Bool = QGIsPtBr(this.GetGame());

    this.m_header = InGamePopupHeader.Create();
    this.m_header.SetTitle(ptBr ? "Guia de Missões" : "Quest Guide");
    this.m_header.SetFluffLeft("v1.0.0"); // default do Codeware mostra chave de loc crua
    this.m_header.SetFluffRight("QUESTGUIDE");
    this.m_header.Reparent(this);

    this.m_footer = InGamePopupFooter.Create();
    this.m_footer.SetFluffIcon(n"fluff_triangle2");
    this.m_footer.SetFluffText(ptBr
      ? "+ concluída   > ativa   - pendente   x falhou   clique: rastrear   [U] fechar"
      : "+ done   > active   - pending   x failed   click: track   [U] close");
    this.m_footer.Reparent(this);

    this.m_content = InGamePopupContent.Create();
    this.m_content.Reparent(this);

    let outer: ref<inkVerticalPanel> = new inkVerticalPanel();
    outer.SetName(n"outer");
    outer.Reparent(this.m_content.GetRootCompoundWidget());

    this.m_search = HubTextInput.Create();
    this.m_search.SetName(n"search");
    this.m_search.SetDefaultText(ptBr ? "Buscar missão..." : "Search quest...");
    this.m_search.SetMaxLength(64);
    this.m_search.SetWidth(700.0);
    this.m_search.Reparent(outer);
    this.m_search.GetRootWidget().SetMargin(inkMargin(0.0, 0.0, 0.0, 24.0));
    this.m_search.RegisterToCallback(n"OnInput", this, n"OnSearchInput");

    let columns: ref<inkHorizontalPanel> = new inkHorizontalPanel();
    columns.SetName(n"columns");
    columns.Reparent(outer);
    this.m_columnsPanel = columns;

    this.m_quests = QGBuildQuestList(this.GetGame());
    this.Rebuild();
  }

  public func QGSearchFocused() -> Bool {
    return IsDefined(this.m_search) && this.m_search.IsFocused();
  }

  protected cb func OnSearchInput(widget: wref<inkWidget>) {
    this.Rebuild();
  }

  protected func Rebuild() {
    let ptBr: Bool = QGIsPtBr(this.GetGame());
    this.m_columnsPanel.RemoveAllChildren();
    ArrayClear(this.m_scrollContents);
    ArrayClear(this.m_contentHeights);
    ArrayClear(this.m_rowWidgets);
    ArrayClear(this.m_rowEntries);
    this.m_scrollOffset = 0.0;
    let needle: String = UTF8StrLower(this.m_search.GetText());
    this.AddColumn(this.m_columnsPanel, this.m_quests, QGCategory.Main,
      ptBr ? "PRINCIPAL" : "MAIN STORY", new HDRColor(1.00, 0.82, 0.00, 1.0), needle);
    this.AddColumn(this.m_columnsPanel, this.m_quests, QGCategory.Ending,
      ptBr ? "AFETA O FINAL" : "AFFECTS ENDING", new HDRColor(0.00, 0.85, 0.85, 1.0), needle);
    this.AddColumn(this.m_columnsPanel, this.m_quests, QGCategory.Cosmetic,
      ptBr ? "COSMÉTICA" : "COSMETIC", new HDRColor(0.62, 0.62, 0.64, 1.0), needle);
  }

  protected func AddColumn(parent: ref<inkCompoundWidget>, quests: array<QGQuest>,
      category: QGCategory, title: String, color: HDRColor, needle: String) {
    let column: ref<inkVerticalPanel> = new inkVerticalPanel();
    column.SetMargin(inkMargin(0.0, 0.0, 70.0, 0.0));
    column.Reparent(parent);

    let total: Int32 = 0;
    let done: Int32 = 0;
    let i: Int32 = 0;
    while i < ArraySize(quests) {
      if Equals(quests[i].category, category)
          && (Equals(needle, "") || StrContains(UTF8StrLower(quests[i].title), needle)) {
        total += 1;
        if Equals(quests[i].state, gameJournalEntryState.Succeeded) {
          done += 1;
        };
      };
      i += 1;
    };

    let head: ref<inkText> = new inkText();
    head.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    head.SetFontStyle(n"Medium");
    head.SetFontSize(34);
    head.SetFitToContent(true);
    head.SetMargin(inkMargin(0.0, 0.0, 0.0, 14.0));
    head.SetTintColor(color);
    head.SetText(title + "  " + IntToString(done) + "/" + IntToString(total));
    head.Reparent(column);

    // viewport com mascara: corta o excesso e a roda do mouse rola (clamp por coluna)
    let viewport: ref<inkScrollArea> = new inkScrollArea();
    viewport.SetSize(Vector2(780.0, 940.0));
    viewport.SetUseInternalMask(true);
    viewport.SetConstrainContentPosition(true);
    viewport.Reparent(column);

    let rows: ref<inkVerticalPanel> = new inkVerticalPanel();
    rows.SetName(n"rows");
    rows.Reparent(viewport);

    let shown: Int32 = 0;
    i = 0;
    while i < ArraySize(quests) {
      if Equals(quests[i].category, category)
          && (Equals(needle, "") || StrContains(UTF8StrLower(quests[i].title), needle)) {
        let row: ref<inkText> = new inkText();
        row.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
        row.SetFontStyle(n"Medium");
        row.SetFontSize(27);
        row.SetFitToContent(true);
        row.SetTintColor(QGStateColor(quests[i].state));
        row.SetText(QGStatePrefix(quests[i].state) + quests[i].title
          + (quests[i].tracked ? (QGIsPtBr(this.GetGame()) ? "  [rastreada]" : "  [tracked]") : ""));
        row.Reparent(rows);
        // clique rastreia; concluida nao tem o que localizar
        if NotEquals(quests[i].state, gameJournalEntryState.Succeeded) {
          row.SetInteractive(true);
          ArrayPush(this.m_rowWidgets, row);
          ArrayPush(this.m_rowEntries, quests[i].entry);
        };
        shown += 1;
      };
      i += 1;
    };

    ArrayPush(this.m_scrollContents, rows);
    // altura estimada por linha (raj 27 fitToContent ~35px); folga no clamp e inofensiva
    ArrayPush(this.m_contentHeights, Cast<Float>(shown) * 35.0);
  }

  protected cb func OnAttach() {
    super.OnAttach();
    this.RegisterToGlobalInputCallback(n"OnPostOnRelative", this, n"OnQGRelativeInput");
  }

  protected cb func OnDetach() {
    this.UnregisterFromGlobalInputCallback(n"OnPostOnRelative", this, n"OnQGRelativeInput");
    super.OnDetach();
  }

  protected cb func OnQGRelativeInput(evt: ref<inkPointerEvent>) -> Bool {
    if evt.IsAction(n"mouse_wheel") && NotEquals(evt.GetAxisData(), 0.0) {
      this.m_scrollOffset += evt.GetAxisData() * 105.0;
      this.ApplyScroll();
    };
    return false;
  }

  protected cb func OnGlobalReleaseInput(evt: ref<inkPointerEvent>) -> Bool {
    if evt.IsAction(n"mouse_left") && !evt.IsHandled() {
      let target: wref<inkWidget> = evt.GetTarget();
      let i: Int32 = 0;
      while IsDefined(target) && i < ArraySize(this.m_rowWidgets) {
        if Equals(target, this.m_rowWidgets[i]) {
          QGTrackQuest(this.GetGame(), this.m_rowEntries[i]);
          this.RefreshTracked();
          let keep: Float = this.m_scrollOffset;
          this.Rebuild();
          this.m_scrollOffset = keep;
          this.ApplyScroll();
          break;
        };
        i += 1;
      };
    };
    return super.OnGlobalReleaseInput(evt);
  }

  // estado tracked vem do fetch; depois de TrackEntry so a flag muda, sem refetch
  protected func RefreshTracked() {
    let jm: ref<JournalManager> = GameInstance.GetJournalManager(this.GetGame());
    let tracked: wref<JournalEntry> = jm.GetTrackedEntry();
    let i: Int32 = 0;
    while i < ArraySize(this.m_quests) {
      this.m_quests[i].tracked = IsDefined(tracked) && tracked == this.m_quests[i].entry;
      i += 1;
    };
  }

  protected func ApplyScroll() {
    let viewportHeight: Float = 940.0;
    if this.m_scrollOffset > 0.0 {
      this.m_scrollOffset = 0.0;
    };
    let i: Int32 = 0;
    while i < ArraySize(this.m_scrollContents) {
      let maxScroll: Float = MaxF(0.0, this.m_contentHeights[i] - viewportHeight);
      this.m_scrollContents[i].SetTranslation(new Vector2(0.0, MaxF(-maxScroll, this.m_scrollOffset)));
      i += 1;
    };
  }

  public static func Show(player: ref<PlayerPuppet>) -> ref<QuestGuidePopup> {
    let popup: ref<QuestGuidePopup> = new QuestGuidePopup();
    GameInstance.GetUISystem(player.GetGame()).QueueEvent(ShowCustomPopupEvent.Create(popup));
    return popup;
  }
}

// ---------------------------------------------------------------------------
// Hotkey: U (livre no layout padrao) abre/fecha o painel no gameplay
// ---------------------------------------------------------------------------

@addField(PlayerPuppet)
let m_qgPopup: ref<QuestGuidePopup>;

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  let result: Bool = wrappedMethod();
  GameInstance.GetCallbackSystem().RegisterCallback(n"Input/Key", this, n"OnQGKeyInput");
  return result;
}

@wrapMethod(PlayerPuppet)
protected cb func OnDetach() -> Bool {
  GameInstance.GetCallbackSystem().UnregisterCallback(n"Input/Key", this, n"OnQGKeyInput");
  return wrappedMethod();
}

@addMethod(PlayerPuppet)
protected cb func OnQGKeyInput(event: ref<KeyInputEvent>) {
  if !Equals(event.GetAction(), EInputAction.IACT_Press) || !Equals(event.GetKey(), EInputKey.IK_U) {
    return;
  };
  if IsDefined(this.m_qgPopup) && this.m_qgPopup.QGIsOpen() {
    if this.m_qgPopup.QGSearchFocused() {
      return; // digitando na busca, "u" e texto
    };
    this.m_qgPopup.Close();
    this.m_qgPopup = null;
    return;
  };
  this.m_qgPopup = null;
  let bb: ref<IBlackboard> = GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_System);
  if bb.GetBool(GetAllBlackboardDefs().UI_System.IsInMenu) {
    return;
  };
  this.m_qgPopup = QuestGuidePopup.Show(this);
}

// TODO UI: scroll nas colunas, busca por texto (HubTextInput), botao de track por
// linha e opcao de injecao no Journal — próximos itens do TODO.md
