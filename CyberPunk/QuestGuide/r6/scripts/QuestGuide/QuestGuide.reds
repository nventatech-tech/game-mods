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
// UI: popup nativo (infra CustomPopup do Codeware), lista única com seções por
// categoria (nome colorido pelo estado + palavra de estado em cinza) e painel de
// detalhe à direita preenchido no hover. Toggle com a tecla configurada.
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

// toggles de filtro por estado: 0=ativa 1=pendente 2=concluída 3=falhou
func QGStateToggleIdx(state: gameJournalEntryState) -> Int32 {
  if Equals(state, gameJournalEntryState.Active) {
    return 0;
  };
  if Equals(state, gameJournalEntryState.Succeeded) {
    return 2;
  };
  if Equals(state, gameJournalEntryState.Failed) {
    return 3;
  };
  return 1;
}

func QGStateShowLabel(idx: Int32, ptBr: Bool) -> String {
  if idx == 0 {
    return ptBr ? "ativa" : "active";
  };
  if idx == 1 {
    return ptBr ? "pendente" : "pending";
  };
  if idx == 2 {
    return ptBr ? "concluída" : "done";
  };
  return ptBr ? "falhou" : "failed";
}

func QGStateShowColor(idx: Int32) -> HDRColor {
  if idx == 0 {
    return new HDRColor(1.00, 0.82, 0.00, 1.0);
  };
  if idx == 1 {
    return new HDRColor(0.62, 0.62, 0.64, 1.0);
  };
  if idx == 2 {
    return new HDRColor(0.30, 0.85, 0.35, 1.0);
  };
  return new HDRColor(0.90, 0.35, 0.30, 1.0);
}

// estimativa de linhas pro clamp do scroll (StrLen em bytes superestima com acento; folga inofensiva)
func QGEstLines(text: String, charsPerLine: Int32) -> Int32 {
  return StrLen(text) / charsPerLine + 1;
}

func QGStateWord(state: gameJournalEntryState, ptBr: Bool) -> String {
  if Equals(state, gameJournalEntryState.Succeeded) {
    return ptBr ? "concluída" : "done";
  };
  if Equals(state, gameJournalEntryState.Active) {
    return ptBr ? "ativa" : "active";
  };
  if Equals(state, gameJournalEntryState.Failed) {
    return ptBr ? "falhou" : "failed";
  };
  return ptBr ? "pendente" : "pending";
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

// GetDescription do journal pode vir "LocKey#..." cru; resolve quando for o caso
func QGLocText(raw: String) -> String {
  let loc: String = GetLocalizedText(raw);
  return Equals(loc, "") ? raw : loc;
}

public class QuestGuidePopup extends InGamePopup {
  protected let m_header: ref<InGamePopupHeader>;
  protected let m_footer: ref<InGamePopupFooter>;
  protected let m_content: ref<InGamePopupContent>;
  protected let m_scrollContent: wref<inkVerticalPanel>;
  protected let m_contentHeight: Float;
  protected let m_scrollOffset: Float;
  protected let m_search: ref<HubTextInput>;
  protected let m_stateToggles: array<wref<inkText>>;
  protected let m_stateShow: array<Bool>;
  protected let m_listPanel: wref<inkVerticalPanel>;
  protected let m_quests: array<QGQuest>;
  protected let m_hoverRows: array<wref<inkWidget>>;
  protected let m_hoverNames: array<wref<inkText>>;
  protected let m_hoverQuests: array<Int32>;
  protected let m_selected: Int32;
  protected let m_overDetail: Bool;
  protected let m_detailTitle: wref<inkText>;
  protected let m_trackBtn: wref<inkText>;
  protected let m_detailContent: wref<inkVerticalPanel>;
  protected let m_detailScroll: Float;
  protected let m_detailHeight: Float;
  protected let m_detailDesc: wref<inkText>;
  protected let m_detailObjectives: wref<inkVerticalPanel>;

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
    this.m_header.SetFluffLeft("v1.1.0"); // default do Codeware mostra chave de loc crua
    this.m_header.SetFluffRight("QUESTGUIDE");
    this.m_header.Reparent(this);

    this.m_footer = InGamePopupFooter.Create();
    this.m_footer.SetFluffIcon(n"fluff_triangle2");
    let keyName: String = StrReplace(
      EnumValueToString("EInputKey", Cast<Int64>(EnumInt(QuestGuideConfig.Key()))), "IK_", "");
    this.m_footer.SetFluffText(ptBr
      ? "clique: detalhes   [" + keyName + "] fechar"
      : "click: details   [" + keyName + "] close");
    this.m_footer.Reparent(this);

    this.m_content = InGamePopupContent.Create();
    this.m_content.Reparent(this);

    let outer: ref<inkVerticalPanel> = new inkVerticalPanel();
    outer.SetName(n"outer");
    outer.Reparent(this.m_content.GetRootCompoundWidget());

    let topRow: ref<inkHorizontalPanel> = new inkHorizontalPanel();
    topRow.SetName(n"topRow");
    topRow.SetMargin(inkMargin(0.0, 0.0, 0.0, 24.0));
    topRow.Reparent(outer);

    this.m_search = HubTextInput.Create();
    this.m_search.SetName(n"search");
    this.m_search.SetDefaultText(ptBr ? "Buscar missão..." : "Search quest...");
    this.m_search.SetMaxLength(64);
    this.m_search.SetWidth(700.0);
    this.m_search.Reparent(topRow);
    this.m_search.RegisterToCallback(n"OnInput", this, n"OnSearchInput");

    let body: ref<inkHorizontalPanel> = new inkHorizontalPanel();
    body.SetName(n"body");
    body.Reparent(outer);

    // lista única rolável com seções por categoria (estilo GME)
    let viewport: ref<inkScrollArea> = new inkScrollArea();
    viewport.SetSize(Vector2(1100.0, 980.0));
    viewport.SetUseInternalMask(true);
    viewport.SetConstrainContentPosition(true);
    viewport.Reparent(body);

    let list: ref<inkVerticalPanel> = new inkVerticalPanel();
    list.SetName(n"list");
    list.Reparent(viewport);
    this.m_listPanel = list;
    this.m_scrollContent = list;

    // filtros de estado em coluna, entre a lista e o detalhe
    let filters: ref<inkVerticalPanel> = new inkVerticalPanel();
    filters.SetName(n"filters");
    filters.SetMargin(inkMargin(40.0, 0.0, 0.0, 0.0));
    filters.Reparent(body);

    let ti: Int32 = 0;
    while ti < 4 {
      ArrayPush(this.m_stateShow, true);
      let toggle: ref<inkText> = new inkText();
      toggle.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
      toggle.SetFontStyle(n"Medium");
      toggle.SetFontSize(27);
      toggle.SetFitToContent(true);
      toggle.SetMargin(inkMargin(0.0, ti == 0 ? 0.0 : 14.0, 0.0, 0.0));
      toggle.SetInteractive(true);
      toggle.Reparent(filters);
      ArrayPush(this.m_stateToggles, toggle);
      ti += 1;
    };
    this.UpdateStateToggles();

    // painel de detalhe fixo à direita; clique numa linha preenche
    let detail: ref<inkVerticalPanel> = new inkVerticalPanel();
    detail.SetName(n"detail");
    detail.SetMargin(inkMargin(40.0, 0.0, 0.0, 0.0));
    detail.SetInteractive(true);
    detail.RegisterToCallback(n"OnHoverOver", this, n"OnDetailHoverOver");
    detail.RegisterToCallback(n"OnHoverOut", this, n"OnDetailHoverOut");
    detail.Reparent(body);

    let dTitle: ref<inkText> = new inkText();
    dTitle.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    dTitle.SetFontStyle(n"Medium");
    dTitle.SetFontSize(34);
    dTitle.SetFitToContent(true);
    dTitle.SetWrapping(true, 1100.0);
    dTitle.SetMargin(inkMargin(0.0, 0.0, 0.0, 14.0));
    dTitle.SetTintColor(new HDRColor(0.62, 0.62, 0.64, 1.0));
    dTitle.SetText(ptBr ? "DETALHE" : "DETAILS");
    dTitle.Reparent(detail);
    this.m_detailTitle = dTitle;

    // botão de rastrear a missão selecionada
    let track: ref<inkText> = new inkText();
    track.SetName(n"trackBtn");
    track.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    track.SetFontStyle(n"Medium");
    track.SetFontSize(30);
    track.SetFitToContent(true);
    track.SetMargin(inkMargin(0.0, 0.0, 0.0, 20.0));
    track.SetTintColor(new HDRColor(1.00, 0.82, 0.00, 1.0));
    track.SetInteractive(true);
    track.RegisterToCallback(n"OnHoverOver", this, n"OnDetailHoverOver");
    track.SetVisible(false);
    track.Reparent(detail);
    this.m_trackBtn = track;

    // conteúdo do detalhe rolável (descrições longas não estouram o painel)
    let dView: ref<inkScrollArea> = new inkScrollArea();
    dView.SetSize(Vector2(1150.0, 830.0));
    dView.SetUseInternalMask(true);
    dView.SetConstrainContentPosition(true);
    dView.Reparent(detail);

    let dContent: ref<inkVerticalPanel> = new inkVerticalPanel();
    dContent.SetName(n"detailContent");
    dContent.Reparent(dView);
    this.m_detailContent = dContent;

    let dDesc: ref<inkText> = new inkText();
    dDesc.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    dDesc.SetFontStyle(n"Medium");
    dDesc.SetFontSize(24);
    dDesc.SetFitToContent(true);
    dDesc.SetWrapping(true, 1100.0);
    dDesc.SetMargin(inkMargin(0.0, 0.0, 0.0, 20.0));
    dDesc.SetTintColor(new HDRColor(0.62, 0.62, 0.64, 1.0));
    dDesc.SetText(ptBr ? "Clique numa missão." : "Click a quest.");
    dDesc.Reparent(dContent);
    this.m_detailDesc = dDesc;

    let dObjectives: ref<inkVerticalPanel> = new inkVerticalPanel();
    dObjectives.SetName(n"objectives");
    dObjectives.Reparent(dContent);
    this.m_detailObjectives = dObjectives;

    this.m_selected = -1;
    this.m_quests = QGBuildQuestList(this.GetGame());
    this.Rebuild();
  }

  public func QGSearchFocused() -> Bool {
    return IsDefined(this.m_search) && this.m_search.IsFocused();
  }

  protected func UpdateStateToggles() {
    let ptBr: Bool = QGIsPtBr(this.GetGame());
    let i: Int32 = 0;
    while i < ArraySize(this.m_stateToggles) {
      this.m_stateToggles[i].SetText((this.m_stateShow[i] ? "[x] " : "[ ] ")
        + QGStateShowLabel(i, ptBr));
      this.m_stateToggles[i].SetTintColor(this.m_stateShow[i]
        ? QGStateShowColor(i) : new HDRColor(0.35, 0.35, 0.36, 1.0));
      i += 1;
    };
  }

  // filtro de linha: busca + toggles de estado
  protected func RowVisible(item: QGQuest, needle: String) -> Bool {
    if !Equals(needle, "") && !StrContains(UTF8StrLower(item.title), needle) {
      return false;
    };
    return this.m_stateShow[QGStateToggleIdx(item.state)];
  }

  protected cb func OnSearchInput(widget: wref<inkWidget>) {
    this.Rebuild();
  }

  protected func Rebuild() {
    let ptBr: Bool = QGIsPtBr(this.GetGame());
    this.m_listPanel.RemoveAllChildren();
    ArrayClear(this.m_hoverRows);
    ArrayClear(this.m_hoverNames);
    ArrayClear(this.m_hoverQuests);
    this.m_scrollOffset = 0.0;
    this.m_contentHeight = 0.0;
    let needle: String = UTF8StrLower(this.m_search.GetText());
    this.AddSection(this.m_quests, QGCategory.Main,
      ptBr ? "PRINCIPAL" : "MAIN STORY", new HDRColor(1.00, 0.82, 0.00, 1.0), needle);
    this.AddSection(this.m_quests, QGCategory.Ending,
      ptBr ? "AFETA O FINAL" : "AFFECTS ENDING", new HDRColor(0.00, 0.85, 0.85, 1.0), needle);
    this.AddSection(this.m_quests, QGCategory.Cosmetic,
      ptBr ? "COSMÉTICA" : "COSMETIC", new HDRColor(0.62, 0.62, 0.64, 1.0), needle);
    this.ApplyScroll();
  }

  protected func AddSection(quests: array<QGQuest>, category: QGCategory,
      title: String, color: HDRColor, needle: String) {
    let ptBr: Bool = QGIsPtBr(this.GetGame());

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
    head.SetFontSize(38);
    head.SetFitToContent(true);
    // primeira seção cola no topo; demais respiram
    head.SetMargin(inkMargin(0.0, this.m_contentHeight > 0.0 ? 36.0 : 0.0, 0.0, 16.0));
    head.SetTintColor(color);
    head.SetText(title + "  " + IntToString(done) + "/" + IntToString(total));
    head.Reparent(this.m_listPanel);
    this.m_contentHeight += this.m_contentHeight > 0.0 ? 102.0 : 66.0;

    i = 0;
    while i < ArraySize(quests) {
      if Equals(quests[i].category, category) && this.RowVisible(quests[i], needle) {
        let row: ref<inkHorizontalPanel> = new inkHorizontalPanel();
        row.SetMargin(inkMargin(24.0, 0.0, 0.0, 10.0));
        row.SetInteractive(true);
        row.Reparent(this.m_listPanel);

        let name: ref<inkText> = new inkText();
        name.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
        name.SetFontStyle(n"Medium");
        name.SetFontSize(32);
        name.SetFitToContent(true);
        name.SetTintColor(i == this.m_selected
          ? new HDRColor(1.0, 1.0, 1.0, 1.0) : QGStateColor(quests[i].state));
        name.SetText(quests[i].title
          + (quests[i].tracked ? (ptBr ? "  [rastreada]" : "  [tracked]") : ""));
        name.Reparent(row);

        // palavra de estado em cinza ao lado do nome (estilo GME)
        let stateText: ref<inkText> = new inkText();
        stateText.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
        stateText.SetFontStyle(n"Medium");
        stateText.SetFontSize(26);
        stateText.SetFitToContent(true);
        stateText.SetMargin(inkMargin(28.0, 6.0, 0.0, 0.0));
        stateText.SetTintColor(new HDRColor(0.62, 0.62, 0.64, 1.0));
        stateText.SetText(QGStateWord(quests[i].state, ptBr));
        stateText.Reparent(row);

        // hover em qualquer linha alimenta o painel de detalhe
        row.RegisterToCallback(n"OnHoverOver", this, n"OnRowHoverOver");
        row.RegisterToCallback(n"OnHoverOut", this, n"OnRowHoverOut");
        ArrayPush(this.m_hoverRows, row);
        ArrayPush(this.m_hoverNames, name);
        ArrayPush(this.m_hoverQuests, i);
        // raj 32 fitToContent ~42px + margem inferior
        this.m_contentHeight += 52.0;
      };
      i += 1;
    };
  }

  protected cb func OnAttach() {
    super.OnAttach();
    this.RegisterToGlobalInputCallback(n"OnPostOnRelative", this, n"OnQGRelativeInput");
  }

  protected cb func OnDetach() {
    this.UnregisterFromGlobalInputCallback(n"OnPostOnRelative", this, n"OnQGRelativeInput");
    super.OnDetach();
  }

  // roda do mouse rola a área sob o cursor: lista à esquerda, detalhe à direita
  protected cb func OnQGRelativeInput(evt: ref<inkPointerEvent>) -> Bool {
    if evt.IsAction(n"mouse_wheel") && NotEquals(evt.GetAxisData(), 0.0) {
      if this.m_overDetail {
        this.m_detailScroll += evt.GetAxisData() * 105.0;
        this.ApplyDetailScroll();
      } else {
        this.m_scrollOffset += evt.GetAxisData() * 105.0;
        this.ApplyScroll();
      };
    };
    return false;
  }

  protected cb func OnDetailHoverOver(evt: ref<inkPointerEvent>) -> Bool {
    this.m_overDetail = true;
    return false;
  }

  protected cb func OnDetailHoverOut(evt: ref<inkPointerEvent>) -> Bool {
    this.m_overDetail = false;
    return false;
  }

  protected cb func OnGlobalReleaseInput(evt: ref<inkPointerEvent>) -> Bool {
    if evt.IsAction(n"mouse_left") && !evt.IsHandled() {
      let target: wref<inkWidget> = evt.GetTarget();
      if IsDefined(target) && Equals(target, this.m_trackBtn) {
        this.TrackSelected();
        return super.OnGlobalReleaseInput(evt);
      };
      let t: Int32 = 0;
      while IsDefined(target) && t < ArraySize(this.m_stateToggles) {
        if Equals(target, this.m_stateToggles[t]) {
          this.m_stateShow[t] = !this.m_stateShow[t];
          this.UpdateStateToggles();
          this.Rebuild();
          return super.OnGlobalReleaseInput(evt);
        };
        t += 1;
      };
      let i: Int32 = 0;
      while IsDefined(target) && i < ArraySize(this.m_hoverRows) {
        if Equals(target, this.m_hoverRows[i]) {
          this.SelectQuest(this.m_hoverQuests[i]);
          break;
        };
        i += 1;
      };
    };
    return super.OnGlobalReleaseInput(evt);
  }

  // clique seleciona: nome fica branco e o painel da direita mostra as informações
  protected func SelectQuest(idx: Int32) {
    let j: Int32 = 0;
    while j < ArraySize(this.m_hoverQuests) {
      if this.m_hoverQuests[j] == this.m_selected {
        this.m_hoverNames[j].SetTintColor(QGStateColor(this.m_quests[this.m_selected].state));
      };
      j += 1;
    };
    this.m_selected = idx;
    j = 0;
    while j < ArraySize(this.m_hoverQuests) {
      if this.m_hoverQuests[j] == idx {
        this.m_hoverNames[j].SetTintColor(new HDRColor(1.0, 1.0, 1.0, 1.0));
      };
      j += 1;
    };
    this.ShowDetail(idx);
  }

  protected func TrackSelected() {
    if this.m_selected < 0 || Equals(this.m_quests[this.m_selected].state, gameJournalEntryState.Succeeded) {
      return;
    };
    QGTrackQuest(this.GetGame(), this.m_quests[this.m_selected].entry);
    this.RefreshTracked();
    let keep: Float = this.m_scrollOffset;
    this.Rebuild();
    this.m_scrollOffset = keep;
    this.ApplyScroll();
    this.ShowDetail(this.m_selected);
  }

  protected cb func OnRowHoverOver(evt: ref<inkPointerEvent>) -> Bool {
    let target: wref<inkWidget> = evt.GetCurrentTarget();
    let i: Int32 = 0;
    while i < ArraySize(this.m_hoverRows) {
      if Equals(target, this.m_hoverRows[i]) {
        this.m_hoverNames[i].SetTintColor(new HDRColor(1.0, 1.0, 1.0, 1.0));
        break;
      };
      i += 1;
    };
    return false;
  }

  protected cb func OnRowHoverOut(evt: ref<inkPointerEvent>) -> Bool {
    let target: wref<inkWidget> = evt.GetCurrentTarget();
    let i: Int32 = 0;
    while i < ArraySize(this.m_hoverRows) {
      if Equals(target, this.m_hoverRows[i]) {
        // selecionada continua branca
        if this.m_hoverQuests[i] != this.m_selected {
          this.m_hoverNames[i].SetTintColor(QGStateColor(this.m_quests[this.m_hoverQuests[i]].state));
        };
        break;
      };
      i += 1;
    };
    return false;
  }

  // detalhe: descrição (JournalQuestDescription) + objetivos (quest -> fases -> objetivos);
  // inactive fica de fora pra não dar spoiler de objetivo futuro
  protected func ShowDetail(idx: Int32) {
    let ptBr: Bool = QGIsPtBr(this.GetGame());
    let jm: ref<JournalManager> = GameInstance.GetJournalManager(this.GetGame());
    let item: QGQuest = this.m_quests[idx];
    this.m_detailTitle.SetTintColor(QGStateColor(item.state));
    this.m_detailTitle.SetText(item.title);
    this.m_detailObjectives.RemoveAllChildren();
    this.m_detailScroll = 0.0;
    this.m_detailHeight = 0.0;

    if Equals(item.state, gameJournalEntryState.Succeeded) {
      this.m_trackBtn.SetVisible(false);
    } else {
      this.m_trackBtn.SetVisible(true);
      if item.tracked {
        this.m_trackBtn.SetText(ptBr ? "[ rastreada ]" : "[ tracked ]");
        this.m_trackBtn.SetTintColor(new HDRColor(0.30, 0.85, 0.35, 1.0));
      } else {
        this.m_trackBtn.SetText(ptBr ? "[ RASTREAR ]" : "[ TRACK ]");
        this.m_trackBtn.SetTintColor(new HDRColor(1.00, 0.82, 0.00, 1.0));
      };
    };

    let filter: JournalRequestStateFilter;
    filter.active = true;
    filter.succeeded = true;
    filter.failed = true;
    let children: array<wref<JournalEntry>>;
    jm.GetChildren(item.entry, filter, children);

    let desc: String = "";
    let i: Int32 = 0;
    while i < ArraySize(children) {
      let d: wref<JournalQuestDescription> = children[i] as JournalQuestDescription;
      if IsDefined(d) && Equals(desc, "") {
        desc = QGLocText(d.GetDescription());
      };
      let phase: wref<JournalQuestPhase> = children[i] as JournalQuestPhase;
      if IsDefined(phase) {
        let objs: array<wref<JournalEntry>>;
        jm.GetChildren(phase, filter, objs);
        let j: Int32 = 0;
        while j < ArraySize(objs) {
          this.AddObjectiveRow(jm, objs[j] as JournalQuestObjective);
          j += 1;
        };
      };
      this.AddObjectiveRow(jm, children[i] as JournalQuestObjective);
      i += 1;
    };
    let descText: String = Equals(desc, "")
      ? (ptBr ? "Sem descrição." : "No description.") : desc;
    this.m_detailDesc.SetText(descText);
    this.m_detailHeight += Cast<Float>(QGEstLines(descText, 80)) * 32.0 + 20.0;
    this.ApplyDetailScroll();
  }

  protected func AddObjectiveRow(jm: ref<JournalManager>, obj: wref<JournalQuestObjective>) {
    if !IsDefined(obj) {
      return;
    };
    let state: gameJournalEntryState = jm.GetEntryState(obj);
    let text: String = QGStatePrefix(state) + QGLocText(obj.GetDescription());
    if obj.HasCounter() {
      text += " (" + IntToString(jm.GetObjectiveCurrentCounter(obj))
        + "/" + IntToString(jm.GetObjectiveTotalCounter(obj)) + ")";
    };
    if jm.GetIsObjectiveOptional(obj) {
      text += QGIsPtBr(this.GetGame()) ? " (opcional)" : " (optional)";
    };
    let row: ref<inkText> = new inkText();
    row.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    row.SetFontStyle(n"Medium");
    row.SetFontSize(24);
    row.SetFitToContent(true);
    row.SetWrapping(true, 1100.0);
    row.SetMargin(inkMargin(0.0, 0.0, 0.0, 8.0));
    row.SetTintColor(QGStateColor(state));
    row.SetText(text);
    row.Reparent(this.m_detailObjectives);
    this.m_detailHeight += Cast<Float>(QGEstLines(text, 80)) * 32.0 + 8.0;
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
    let viewportHeight: Float = 980.0;
    if this.m_scrollOffset > 0.0 {
      this.m_scrollOffset = 0.0;
    };
    let maxScroll: Float = MaxF(0.0, this.m_contentHeight - viewportHeight);
    this.m_scrollOffset = MaxF(-maxScroll, this.m_scrollOffset);
    this.m_scrollContent.SetTranslation(new Vector2(0.0, this.m_scrollOffset));
  }

  protected func ApplyDetailScroll() {
    if this.m_detailScroll > 0.0 {
      this.m_detailScroll = 0.0;
    };
    let maxScroll: Float = MaxF(0.0, this.m_detailHeight - 830.0);
    this.m_detailScroll = MaxF(-maxScroll, this.m_detailScroll);
    this.m_detailContent.SetTranslation(new Vector2(0.0, this.m_detailScroll));
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
  if !Equals(event.GetAction(), EInputAction.IACT_Press) || !Equals(event.GetKey(), QuestGuideConfig.Key()) {
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
  this.m_qgPopup = QuestGuidePopup.Show(this);
}
