// FindMyRide - search and category filter for the vehicle summon popup (hold V)
// Requires: redscript, Codeware
module FindMyRide
import Codeware.Localization.*

// Categories: 0 All, 1 Favorites, 2 Cars, 3 Motorcycles, 4 Armed
public class FindMyRideDataView extends VehiclesManagerDataView {
  public let m_search: String;
  public let m_category: Int32;

  public func FilterItem(data: ref<IScriptable>) -> Bool {
    let item: ref<VehicleListItemData> = data as VehicleListItemData;
    if !IsDefined(item) {
      return true;
    };
    if !FmrMatchesCategory(item, this.m_category) {
      return false;
    };
    if StrLen(this.m_search) > 0 {
      return StrContains(FmrNormalize(GetLocalizedTextByKey(item.m_displayName)), FmrNormalize(this.m_search));
    };
    return true;
  }
}

// Normalized compare so "type66" matches "Type-66"
public func FmrNormalize(text: String) -> String {
  let result: String = StrLower(text);
  result = StrReplaceAll(result, " ", "");
  result = StrReplaceAll(result, "-", "");
  return result;
}

public func FmrMatchesCategory(item: ref<VehicleListItemData>, category: Int32) -> Bool {
  if category == 0 {
    return true;
  };
  if category == 1 {
    return item.m_data.uiFavoriteIndex >= 0 || item.m_data.forcedFavorite;
  };
  let isBike: Bool = Equals(item.m_data.vehicleType, gamedataVehicleType.Bike);
  if category == 3 {
    return isBike;
  };
  let record: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(item.m_data.recordID);
  let isArmed: Bool = Equals(record.VehDataPackageHandle().DriverCombat().Type(), gamedataDriverCombatType.MountedWeapons);
  if category == 4 {
    return isArmed;
  };
  return !isBike && !isArmed;
}

public func FmrCategoryLabel(category: Int32, ptBr: Bool) -> String {
  switch category {
    case 1: return ptBr ? "Favoritos" : "Favorites";
    case 2: return ptBr ? "Carros" : "Cars";
    case 3: return ptBr ? "Motos" : "Motorcycles";
    case 4: return ptBr ? "Armados" : "Armed";
    default: return ptBr ? "Todos" : "All";
  };
}

// Physical key to character; US layout, enough for vehicle names
public func FmrKeyToChar(key: EInputKey) -> String {
  switch key {
    case EInputKey.IK_A: return "a";
    case EInputKey.IK_B: return "b";
    case EInputKey.IK_C: return "c";
    case EInputKey.IK_D: return "d";
    case EInputKey.IK_E: return "e";
    case EInputKey.IK_F: return "f";
    case EInputKey.IK_G: return "g";
    case EInputKey.IK_H: return "h";
    case EInputKey.IK_I: return "i";
    case EInputKey.IK_J: return "j";
    case EInputKey.IK_K: return "k";
    case EInputKey.IK_L: return "l";
    case EInputKey.IK_M: return "m";
    case EInputKey.IK_N: return "n";
    case EInputKey.IK_O: return "o";
    case EInputKey.IK_P: return "p";
    case EInputKey.IK_Q: return "q";
    case EInputKey.IK_R: return "r";
    case EInputKey.IK_S: return "s";
    case EInputKey.IK_T: return "t";
    case EInputKey.IK_U: return "u";
    case EInputKey.IK_V: return "v";
    case EInputKey.IK_W: return "w";
    case EInputKey.IK_X: return "x";
    case EInputKey.IK_Y: return "y";
    case EInputKey.IK_Z: return "z";
    case EInputKey.IK_0: return "0";
    case EInputKey.IK_1: return "1";
    case EInputKey.IK_2: return "2";
    case EInputKey.IK_3: return "3";
    case EInputKey.IK_4: return "4";
    case EInputKey.IK_5: return "5";
    case EInputKey.IK_6: return "6";
    case EInputKey.IK_7: return "7";
    case EInputKey.IK_8: return "8";
    case EInputKey.IK_9: return "9";
    case EInputKey.IK_NumPad0: return "0";
    case EInputKey.IK_NumPad1: return "1";
    case EInputKey.IK_NumPad2: return "2";
    case EInputKey.IK_NumPad3: return "3";
    case EInputKey.IK_NumPad4: return "4";
    case EInputKey.IK_NumPad5: return "5";
    case EInputKey.IK_NumPad6: return "6";
    case EInputKey.IK_NumPad7: return "7";
    case EInputKey.IK_NumPad8: return "8";
    case EInputKey.IK_NumPad9: return "9";
    case EInputKey.IK_Space: return " ";
    case EInputKey.IK_Minus: return "-";
    case EInputKey.IK_NumMinus: return "-";
    default: return "";
  };
}

@addField(VehiclesManagerPopupGameController)
let m_fmrSearchActive: Bool;

@addField(VehiclesManagerPopupGameController)
let m_fmrSearch: String;

@addField(VehiclesManagerPopupGameController)
let m_fmrCategory: Int32;

@addField(VehiclesManagerPopupGameController)
let m_fmrEatProceedRelease: Bool;

@addField(VehiclesManagerPopupGameController)
let m_fmrTypedCancelKey: Bool;

@addField(VehiclesManagerPopupGameController)
let m_fmrTypedProceedKey: Bool;

@addField(VehiclesManagerPopupGameController)
let m_fmrPtBr: Bool;

@addField(VehiclesManagerPopupGameController)
let m_fmrBar: wref<inkText>;

@wrapMethod(VehiclesManagerPopupGameController)
protected func SetupVirtualList() -> Void {
  wrappedMethod();
  this.m_dataView = new FindMyRideDataView();
  this.m_dataView.SetSource(this.m_dataSource);
  this.m_listController.SetSource(this.m_dataView);
}

@wrapMethod(VehiclesManagerPopupGameController)
protected cb func OnPlayerAttach(player: ref<GameObject>) -> Bool {
  let result: Bool = wrappedMethod(player);
  this.m_fmrSearchActive = false;
  this.m_fmrSearch = "";
  this.m_fmrCategory = 0;
  this.m_fmrEatProceedRelease = false;
  this.m_fmrTypedCancelKey = false;
  this.m_fmrTypedProceedKey = false;
  this.m_fmrPtBr = Equals(LocalizationSystem.GetInstance(player.GetGame()).GetInterfaceLanguage(), n"pt-br");
  GameInstance.GetCallbackSystem().RegisterCallback(n"Input/Key", this, n"OnFmrKeyInput");
  // Menu hotkeys have their own listeners (inGameMenuGameController + native); the popup
  // only hears actions it registers for, so register them to be able to eat them while typing
  let pco: ref<GameObject> = this.GetPlayerControlledObject();
  pco.RegisterInputListener(this, n"OpenMapMenu");
  pco.RegisterInputListener(this, n"OpenJournalMenu");
  pco.RegisterInputListener(this, n"OpenPerksMenu");
  pco.RegisterInputListener(this, n"OpenInventoryMenu");
  pco.RegisterInputListener(this, n"OpenCraftingMenu");
  pco.RegisterInputListener(this, n"OpenHubMenu");
  pco.RegisterInputListener(this, n"CharacterPanel");
  pco.RegisterInputListener(this, n"Inventory");
  pco.RegisterInputListener(this, n"PhoneInteract");
  this.FmrCreateBar();
  this.FmrUpdateBar();
  return result;
}

@wrapMethod(BaseModalListPopupGameController)
protected cb func OnPlayerDetach(playerPuppet: ref<GameObject>) -> Bool {
  if IsDefined(this as VehiclesManagerPopupGameController) {
    GameInstance.GetCallbackSystem().UnregisterCallback(n"Input/Key", this, n"OnFmrKeyInput");
  };
  return wrappedMethod(playerPuppet);
}

@wrapMethod(VehiclesManagerPopupGameController)
protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool {
  let actionName: CName = ListenerAction.GetName(action);
  // Enter that closed search mode must not also summon: eat the full proceed press+release
  if this.m_fmrEatProceedRelease && Equals(actionName, n"proceed") {
    if ListenerAction.IsButtonJustReleased(action) {
      this.m_fmrEatProceedRelease = false;
    };
    ListenerActionConsumer.Consume(consumer);
    return true;
  };
  if this.m_fmrSearchActive {
    // C is bound to cancel and F to proceed in this popup; when the raw key handler already
    // typed them as characters, swallow the paired action instead of treating it as Esc/Enter
    if this.m_fmrTypedCancelKey && (Equals(actionName, n"cancel") || Equals(actionName, n"OpenPauseMenu")) {
      this.m_fmrTypedCancelKey = false;
      ListenerActionConsumer.DontSendReleaseEvent(consumer);
      ListenerActionConsumer.Consume(consumer);
      return true;
    };
    if this.m_fmrTypedProceedKey && Equals(actionName, n"proceed") {
      this.m_fmrTypedProceedKey = false;
      ListenerActionConsumer.Consume(consumer);
      return true;
    };
    if Equals(actionName, n"cancel") || Equals(actionName, n"OpenPauseMenu") {
      if ListenerAction.IsButtonJustPressed(action) {
        this.m_fmrSearch = "";
        this.m_fmrSearchActive = false;
        this.FmrApplyFilter();
      };
      // pause menu opens on key release; suppress it like vanilla does
      ListenerActionConsumer.DontSendReleaseEvent(consumer);
      ListenerActionConsumer.Consume(consumer);
      return true;
    };
    if Equals(actionName, n"proceed") {
      if ListenerAction.IsButtonJustPressed(action) {
        this.m_fmrSearchActive = false;
        this.m_fmrEatProceedRelease = true;
        this.FmrUpdateBar();
      };
      ListenerActionConsumer.Consume(consumer);
      return true;
    };
    // Typing mode owns the keyboard: eat everything else (menu hotkeys M/J/P/I etc)
    ListenerActionConsumer.DontSendReleaseEvent(consumer);
    ListenerActionConsumer.Consume(consumer);
    return true;
  };
  // Esc outside search mode: clear search, then category, then let popup close
  if (Equals(actionName, n"cancel") || Equals(actionName, n"OpenPauseMenu")) && (StrLen(this.m_fmrSearch) > 0 || this.m_fmrCategory != 0) {
    if ListenerAction.IsButtonJustPressed(action) {
      if StrLen(this.m_fmrSearch) > 0 {
        this.m_fmrSearch = "";
      } else {
        this.m_fmrCategory = 0;
      };
      this.FmrApplyFilter();
    };
    ListenerActionConsumer.DontSendReleaseEvent(consumer);
    ListenerActionConsumer.Consume(consumer);
    return true;
  };
  // Empty filtered list: block summon/favorite on missing selection
  if (Equals(actionName, n"proceed") || Equals(actionName, n"secondaryAction")) && !IsDefined(this.m_listController.GetSelectedItem()) {
    ListenerActionConsumer.Consume(consumer);
    return true;
  };
  return wrappedMethod(action, consumer);
}

@addMethod(VehiclesManagerPopupGameController)
protected cb func OnFmrKeyInput(event: ref<KeyInputEvent>) {
  if !Equals(event.GetAction(), EInputAction.IACT_Press) {
    return;
  };
  let key: EInputKey = event.GetKey();
  if Equals(key, EInputKey.IK_Tab) {
    this.m_fmrSearchActive = !this.m_fmrSearchActive;
    this.FmrUpdateBar();
    return;
  };
  if Equals(key, EInputKey.IK_Left) || Equals(key, EInputKey.IK_Pad_DigitLeft) {
    this.FmrCycleCategory(-1);
    return;
  };
  if Equals(key, EInputKey.IK_Right) || Equals(key, EInputKey.IK_Pad_DigitRight) {
    this.FmrCycleCategory(1);
    return;
  };
  if !this.m_fmrSearchActive {
    return;
  };
  // Raw keys fire before action dispatch: flag C/F so their cancel/proceed get swallowed
  if Equals(key, EInputKey.IK_C) {
    this.m_fmrTypedCancelKey = true;
  };
  if Equals(key, EInputKey.IK_F) {
    this.m_fmrTypedProceedKey = true;
  };
  if Equals(key, EInputKey.IK_Backspace) {
    if StrLen(this.m_fmrSearch) > 0 {
      this.m_fmrSearch = StrLeft(this.m_fmrSearch, StrLen(this.m_fmrSearch) - 1);
      this.FmrApplyFilter();
    };
    return;
  };
  let char: String = FmrKeyToChar(key);
  if StrLen(char) > 0 && StrLen(this.m_fmrSearch) < 24 {
    this.m_fmrSearch += char;
    this.FmrApplyFilter();
  };
}

@addMethod(VehiclesManagerPopupGameController)
private final func FmrCycleCategory(step: Int32) -> Void {
  this.m_fmrCategory = (this.m_fmrCategory + step + 5) % 5;
  this.FmrApplyFilter();
}

@addMethod(VehiclesManagerPopupGameController)
private final func FmrApplyFilter() -> Void {
  let view: ref<FindMyRideDataView> = this.m_dataView as FindMyRideDataView;
  if !IsDefined(view) {
    return;
  };
  view.m_search = this.m_fmrSearch;
  view.m_category = this.m_fmrCategory;
  view.Filter();
  if view.Size() > 0u {
    this.m_listController.SelectItem(0u);
  };
  this.FmrUpdateBar();
}

@addMethod(VehiclesManagerPopupGameController)
private final func FmrCreateBar() -> Void {
  let root: ref<inkCompoundWidget> = this.GetRootCompoundWidget();
  if !IsDefined(root) {
    return;
  };
  let bar: ref<inkText> = new inkText();
  bar.SetName(n"FindMyRideBar");
  bar.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
  bar.SetFontStyle(n"Medium");
  bar.SetFontSize(38);
  bar.SetTintColor(new HDRColor(0.368627, 0.964706, 1.0, 1.0));
  bar.SetAnchor(inkEAnchor.Centered);
  bar.SetAnchorPoint(new Vector2(0.5, 0.5));
  bar.SetHorizontalAlignment(textHorizontalAlignment.Center);
  bar.SetTranslation(new Vector2(0.0, 420.0));
  bar.Reparent(root);
  this.m_fmrBar = bar;
}

@addMethod(VehiclesManagerPopupGameController)
private final func FmrUpdateBar() -> Void {
  if !IsDefined(this.m_fmrBar) {
    return;
  };
  let view: ref<FindMyRideDataView> = this.m_dataView as FindMyRideDataView;
  let count: Int32 = IsDefined(view) ? Cast<Int32>(view.Size()) : 0;
  let text: String;
  if this.m_fmrSearchActive {
    text = (this.m_fmrPtBr ? "Busca: " : "Search: ") + this.m_fmrSearch + "_  (" + IntToString(count) + ")   [Enter] " + (this.m_fmrPtBr ? "confirmar   [Esc] limpar" : "confirm   [Esc] clear");
  } else {
    text = "< " + FmrCategoryLabel(this.m_fmrCategory, this.m_fmrPtBr) + " (" + IntToString(count) + ") >   [Tab] " + (this.m_fmrPtBr ? "buscar" : "search");
    if StrLen(this.m_fmrSearch) > 0 {
      text += "   \"" + this.m_fmrSearch + "\"";
    };
    if StrLen(this.m_fmrSearch) > 0 || this.m_fmrCategory != 0 {
      text += "   [Esc] " + (this.m_fmrPtBr ? "limpar" : "clear");
    };
  };
  this.m_fmrBar.SetText(text);
}
