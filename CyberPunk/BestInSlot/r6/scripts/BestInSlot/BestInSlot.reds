// BestInSlot - marks the best item of each type in the inventory and equips the best loadout with B
// Requires: redscript, Codeware
module BestInSlot
import Codeware.Localization.*

// Weapon score: EffectiveDPS as base (already aggregates damage, fire rate and crit),
// weighted by what DPS alone misses - +6% per tier, +10% iconic, +3% per plus upgrade
public func BisWeaponScore(item: ref<UIInventoryItem>) -> Float {
  let stat: ref<UIInventoryItemStat> = item.GetPrimaryStat();
  let dps: Float = IsDefined(stat) ? stat.Value : 0.0;
  let quality: Float = Cast<Float>(item.GetQualityInt());
  let iconic: Float = item.IsIconic() ? 1.0 : 0.0;
  let weight: Float = 1.0 + 0.06 * quality + 0.10 * iconic + 0.03 * item.GetItemPlus();
  return dps * weight + item.GetComparisonQualityF();
}

// Non-weapons: tier decides (iconic and plus included), primary stat (e.g. cyberware armor)
// breaks ties inside the same tier
public func BisGenericScore(item: ref<UIInventoryItem>) -> Float {
  let stat: ref<UIInventoryItemStat> = item.GetPrimaryStat();
  let statValue: Float = IsDefined(stat) ? stat.Value : 0.0;
  return item.GetComparisonQualityF() * 1000.0 + statValue;
}

public func BisScore(item: ref<UIInventoryItem>) -> Float {
  return item.IsWeapon() ? BisWeaponScore(item) : BisGenericScore(item);
}

public func BisIsRankable(item: ref<UIInventoryItem>) -> Bool {
  if !IsDefined(item) || ItemID.HasFlag(item.GetID(), gameEItemIDFlag.Preview) {
    return false;
  };
  if item.IsWeapon() || item.IsAnyCyberware() || item.IsHealingItem() || item.IsProgram() {
    return true;
  };
  if Equals(item.GetItemType(), gamedataItemType.Gad_Grenade) {
    return true;
  };
  return item.IsClothing() && NotEquals(item.GetEquipmentArea(), gamedataEquipmentArea.Invalid);
}

// Grouping: weapons by type, clothes by equipment slot, consumables/programs by type,
// cyberware by slot + item type (mantis vs gorilla vs monowire etc. don't compete)
public func BisGroupKey(item: ref<UIInventoryItem>) -> Int32 {
  let key: Int32;
  if item.IsWeapon() {
    return EnumInt(item.GetItemType());
  };
  if item.IsClothing() {
    return 10000 + EnumInt(item.GetEquipmentArea());
  };
  if item.IsAnyCyberware() {
    key = 100000 + EnumInt(item.GetEquipmentArea()) * 1000 + EnumInt(item.GetItemType());
    // OS slot: deck/sande/berserk are build choices, rank each on its own
    if Equals(item.GetEquipmentArea(), gamedataEquipmentArea.SystemReplacementCW) {
      if item.IsCyberdeck() {
        key += 1000000;
      } else {
        if Equals(TweakDBInterface.GetCName(ItemID.GetTDBID(item.GetID()) + t".cyberwareType", n"None"), n"Sandevistan") {
          key += 2000000;
        } else {
          key += 3000000;
        };
      };
    };
    return key;
  };
  return 30000 + EnumInt(item.GetItemType());
}

// Ranking lives on the player entity: session-scoped, no ScriptableSystem registration involved
@addField(PlayerPuppet)
let m_bisBestHashes: [Uint64];

@addField(PlayerPuppet)
let m_bisBestWeapons: [ItemID];

@addField(PlayerPuppet)
let m_bisBestClothes: [ItemID];

@addField(PlayerPuppet)
let m_bisBestConsumables: [ItemID];

@addField(PlayerPuppet)
let m_bisScanned: Int32;

@addMethod(PlayerPuppet)
public final func BisIsBest(itemID: ItemID) -> Bool {
  let hash: Uint64 = ItemID.GetCombinedHash(itemID);
  let i: Int32 = 0;
  while i < ArraySize(this.m_bisBestHashes) {
    if this.m_bisBestHashes[i] == hash {
      return true;
    };
    i += 1;
  };
  return false;
}

@addMethod(PlayerPuppet)
public final func BisRecompute() -> Void {
  let uiSystem: ref<UIInventoryScriptableSystem> = UIInventoryScriptableSystem.GetInstance(this.GetGame());
  let values: [wref<IScriptable>];
  let bestPerGroup: [wref<UIInventoryItem>];
  let groupKeys: [Int32];
  let item: wref<UIInventoryItem>;
  let key: Int32;
  let idx: Int32;
  let j: Int32;
  let i: Int32;
  if !IsDefined(uiSystem) {
    return;
  };
  uiSystem.GetPlayerItemsMap().GetValues(values);
  this.m_bisScanned = ArraySize(values);
  while i < ArraySize(values) {
    item = values[i] as UIInventoryItem;
    if BisIsRankable(item) {
      key = BisGroupKey(item);
      idx = -1;
      j = 0;
      while j < ArraySize(groupKeys) {
        if groupKeys[j] == key {
          idx = j;
        };
        j += 1;
      };
      if idx < 0 {
        ArrayPush(groupKeys, key);
        ArrayPush(bestPerGroup, item);
      } else {
        if BisScore(item) > BisScore(bestPerGroup[idx]) {
          bestPerGroup[idx] = item;
        };
      };
    };
    i += 1;
  };
  ArrayClear(this.m_bisBestHashes);
  ArrayClear(this.m_bisBestWeapons);
  ArrayClear(this.m_bisBestClothes);
  ArrayClear(this.m_bisBestConsumables);
  i = 0;
  while i < ArraySize(bestPerGroup) {
    ArrayPush(this.m_bisBestHashes, ItemID.GetCombinedHash(bestPerGroup[i].GetID()));
    if bestPerGroup[i].IsWeapon() {
      ArrayPush(this.m_bisBestWeapons, bestPerGroup[i].GetID());
    } else {
      if bestPerGroup[i].IsClothing() {
        ArrayPush(this.m_bisBestClothes, bestPerGroup[i].GetID());
      } else {
        // granada e cura entram no equipar-melhor; cyberware/quickhack so recebem o selo
        if bestPerGroup[i].IsHealingItem() || Equals(bestPerGroup[i].GetItemType(), gamedataItemType.Gad_Grenade) {
          ArrayPush(this.m_bisBestConsumables, bestPerGroup[i].GetID());
        };
      };
    };
    i += 1;
  };
}

// Best 3 weapons across distinct types into slots 0-2, best clothing piece per area
@addMethod(PlayerPuppet)
public final func BisEquipBest() -> Int32 {
  let game: GameInstance = this.GetGame();
  let uiSystem: ref<UIInventoryScriptableSystem> = UIInventoryScriptableSystem.GetInstance(game);
  let equipment: ref<EquipmentSystem> = GameInstance.GetScriptableSystemsContainer(game).Get(n"EquipmentSystem") as EquipmentSystem;
  let sortedIds: [ItemID];
  let sortedScores: [Float];
  let item: wref<UIInventoryItem>;
  let score: Float;
  let count: Int32;
  let slot: Int32;
  let j: Int32;
  let i: Int32;
  this.BisRecompute();
  if !IsDefined(uiSystem) || !IsDefined(equipment) {
    return 0;
  };
  while i < ArraySize(this.m_bisBestWeapons) {
    item = uiSystem.GetPlayerItem(this.m_bisBestWeapons[i]);
    if IsDefined(item) {
      score = BisWeaponScore(item);
      j = 0;
      while j < ArraySize(sortedScores) && sortedScores[j] >= score {
        j += 1;
      };
      ArrayInsert(sortedIds, j, this.m_bisBestWeapons[i]);
      ArrayInsert(sortedScores, j, score);
    };
    i += 1;
  };
  i = 0;
  while i < ArraySize(sortedIds) && slot < 3 {
    BisQueueEquip(equipment, this, sortedIds[i], slot);
    slot += 1;
    count += 1;
    i += 1;
  };
  i = 0;
  while i < ArraySize(this.m_bisBestClothes) {
    item = uiSystem.GetPlayerItem(this.m_bisBestClothes[i]);
    if IsDefined(item) && !item.IsEquipped() {
      BisQueueEquip(equipment, this, this.m_bisBestClothes[i], 0);
      count += 1;
    };
    i += 1;
  };
  i = 0;
  while i < ArraySize(this.m_bisBestConsumables) {
    item = uiSystem.GetPlayerItem(this.m_bisBestConsumables[i]);
    if IsDefined(item) && !item.IsEquipped() {
      BisQueueEquip(equipment, this, this.m_bisBestConsumables[i], 0);
      count += 1;
    };
    i += 1;
  };
  return count;
}

public func BisQueueEquip(equipment: ref<EquipmentSystem>, player: ref<PlayerPuppet>, itemID: ItemID, slotIndex: Int32) -> Void {
  let request: ref<EquipRequest> = new EquipRequest();
  request.owner = player;
  request.itemID = itemID;
  request.slotIndex = slotIndex;
  request.addToInventory = false;
  request.equipToCurrentActiveSlot = false;
  equipment.QueueRequest(request);
}

// --- badge: gold star on the best item of each group, backpack and inventory grids ---

@addField(InventoryItemDisplayController)
let m_bisBadge: wref<inkWidget>;

@wrapMethod(InventoryItemDisplayController)
protected func NewUpdateIndicators(itemData: ref<UIInventoryItem>) -> Void {
  wrappedMethod(itemData);
  this.BisUpdateBadge(itemData);
}

// reforco: nem toda tela passa por NewUpdateIndicators
@wrapMethod(InventoryItemDisplayController)
protected func NewRefreshUI(itemData: ref<UIInventoryItem>) -> Void {
  wrappedMethod(itemData);
  this.BisUpdateBadge(itemData);
}

// caminho legado (vendor, estoque, gear panel): usa InventoryItemData em vez de UIInventoryItem
@wrapMethod(InventoryItemDisplayController)
protected func RefreshUI() -> Void {
  wrappedMethod();
  this.BisUpdateBadgeLegacy();
}

// HUD hotkey slot and the radial wheel reuse this controller; badge there covers the icon
@addMethod(InventoryItemDisplayController)
private final func BisIsHudContext() -> Bool {
  return Equals(this.m_itemDisplayContext, ItemDisplayContext.DPAD_RADIAL);
}

@addMethod(InventoryItemDisplayController)
private final func BisUpdateBadgeLegacy() -> Void {
  let player: ref<PlayerPuppet>;
  let isBest: Bool;
  this.BisEnsureBadge();
  if !IsDefined(this.m_bisBadge) {
    return;
  };
  if this.BisIsHudContext() {
    this.m_bisBadge.SetVisible(false);
    return;
  };
  if !InventoryItemData.IsEmpty(this.m_itemData) {
    player = GetPlayer(GetGameInstance());
    isBest = IsDefined(player) && player.BisIsBest(InventoryItemData.GetID(this.m_itemData));
  };
  this.m_bisBadge.SetVisible(isBest);
}

@addMethod(InventoryItemDisplayController)
private final func BisUpdateBadge(itemData: ref<UIInventoryItem>) -> Void {
  let player: ref<PlayerPuppet>;
  let isBest: Bool;
  this.BisEnsureBadge();
  if !IsDefined(this.m_bisBadge) {
    return;
  };
  if this.BisIsHudContext() {
    this.m_bisBadge.SetVisible(false);
    return;
  };
  if IsDefined(itemData) {
    player = GetPlayer(GetGameInstance());
    isBest = IsDefined(player) && player.BisIsBest(itemData.GetID());
  };
  this.m_bisBadge.SetVisible(isBest);
}

// chip dourado com texto preto, estilo etiqueta, canto superior direito da celula
@addMethod(InventoryItemDisplayController)
private final func BisEnsureBadge() -> Void {
  let root: ref<inkCompoundWidget>;
  let chip: ref<inkCanvas>;
  let bg: ref<inkRectangle>;
  let label: ref<inkText>;
  if !IsDefined(this.m_bisBadge) {
    root = this.GetRootCompoundWidget();
    if !IsDefined(root) {
      return;
    };
    chip = new inkCanvas();
    chip.SetName(n"BisBadge");
    chip.SetSize(new Vector2(96.0, 42.0));
    chip.SetAnchor(inkEAnchor.TopRight);
    chip.SetAnchorPoint(new Vector2(1.0, 0.0));
    chip.SetTranslation(new Vector2(-6.0, 6.0));
    chip.SetHAlign(inkEHorizontalAlign.Right);
    chip.SetVAlign(inkEVerticalAlign.Top);
    chip.SetAffectsLayoutWhenHidden(false);
    bg = new inkRectangle();
    bg.SetName(n"BisBadgeBg");
    bg.SetAnchor(inkEAnchor.Fill);
    bg.SetTintColor(new HDRColor(1.4, 1.0, 0.25, 1.0));
    bg.SetOpacity(0.95);
    bg.Reparent(chip);
    label = new inkText();
    label.SetName(n"BisBadgeText");
    label.SetText("TOP");
    label.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    label.SetFontStyle(n"Semi-Bold");
    label.SetFontSize(32);
    label.SetTintColor(new HDRColor(0.05, 0.05, 0.05, 1.0));
    label.SetAnchor(inkEAnchor.Fill);
    label.SetHorizontalAlignment(textHorizontalAlignment.Center);
    label.SetVerticalAlignment(textVerticalAlignment.Center);
    label.Reparent(chip);
    chip.Reparent(root);
    this.m_bisBadge = chip;
  };
}

// --- recompute when the inventory screens open, hotkey B in the backpack ---

@addField(BackpackMainGameController)
let m_bisBar: wref<inkText>;

// m_player so existe a partir do OnPlayerAttach; OnInitialize roda antes com player nulo
@wrapMethod(BackpackMainGameController)
protected cb func OnPlayerAttach(playerPuppet: ref<GameObject>) -> Bool {
  let result: Bool = wrappedMethod(playerPuppet);
  if IsDefined(this.m_player) {
    this.m_player.BisRecompute();
    let ptBr: Bool = Equals(LocalizationSystem.GetInstance(this.m_player.GetGame()).GetInterfaceLanguage(), n"pt-br");
    this.BisUpdateBar(ptBr
      ? IntToString(ArraySize(this.m_player.m_bisBestHashes)) + " itens TOP marcados   [B] equipar os melhores"
      : IntToString(ArraySize(this.m_player.m_bisBestHashes)) + " TOP items marked   [B] equip best loadout");
  };
  GameInstance.GetCallbackSystem().RegisterCallback(n"Input/Key", this, n"OnBisKeyInput");
  return result;
}

// barra de status dentro da tela da mochila; HUD fica escondido em menu, inkText no root nao
@addMethod(BackpackMainGameController)
private final func BisUpdateBar(text: String) -> Void {
  let root: ref<inkCompoundWidget>;
  let bar: ref<inkText>;
  if !IsDefined(this.m_bisBar) {
    root = this.GetRootCompoundWidget();
    if !IsDefined(root) {
      return;
    };
    bar = new inkText();
    bar.SetName(n"BisBar");
    bar.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    bar.SetFontStyle(n"Medium");
    bar.SetFontSize(36);
    bar.SetFitToContent(true);
    bar.SetTintColor(new HDRColor(0.368627, 0.964706, 1.0, 1.0));
    // ao lado do rotulo FILTROS, topo da area do grid (coords virtuais 3840x2160)
    bar.SetAnchor(inkEAnchor.TopLeft);
    bar.SetAnchorPoint(new Vector2(0.0, 0.0));
    bar.SetTranslation(new Vector2(1000.0, 262.0));
    bar.Reparent(root);
    this.m_bisBar = bar;
  };
  this.m_bisBar.SetText(text);
}

@wrapMethod(BackpackMainGameController)
protected cb func OnUninitialize() -> Bool {
  GameInstance.GetCallbackSystem().UnregisterCallback(n"Input/Key", this, n"OnBisKeyInput");
  return wrappedMethod();
}

@addMethod(BackpackMainGameController)
protected cb func OnBisKeyInput(event: ref<KeyInputEvent>) {
  let count: Int32;
  if !Equals(event.GetAction(), EInputAction.IACT_Press) || !Equals(event.GetKey(), EInputKey.IK_B) {
    return;
  };
  if !IsDefined(this.m_player) {
    return;
  };
  count = this.m_player.BisEquipBest();
  let onScreenLanguage: CName = LocalizationSystem.GetInstance(this.m_player.GetGame()).GetInterfaceLanguage();
  this.BisUpdateBar(Equals(onScreenLanguage, n"pt-br")
    ? "Melhor equipamento aplicado (" + IntToString(count) + " itens)"
    : "Best loadout equipped (" + IntToString(count) + " items)");
}

@wrapMethod(gameuiInventoryGameController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  if IsDefined(this.m_player) {
    this.m_player.BisRecompute();
  };
  return result;
}

// tela CIBERNETICA do menu e ripperdoc compartilham este controller; as celulas
// (InventoryCyberwareDisplayController) ja passam pelos wraps de badge acima
@wrapMethod(RipperDocGameController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  let player: ref<PlayerPuppet> = GetPlayer(GetGameInstance());
  if IsDefined(player) {
    player.BisRecompute();
  };
  return result;
}

// vendor e estoque compartilham este controller
@wrapMethod(FullscreenVendorGameController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  let player: ref<PlayerPuppet> = GetPlayer(GetGameInstance());
  if IsDefined(player) {
    player.BisRecompute();
  };
  GameInstance.GetCallbackSystem().RegisterCallback(n"Input/Key", this, n"OnBisVendorKeyInput");
  return result;
}

@wrapMethod(FullscreenVendorGameController)
protected cb func OnUninitialize() -> Bool {
  GameInstance.GetCallbackSystem().UnregisterCallback(n"Input/Key", this, n"OnBisVendorKeyInput");
  return wrappedMethod();
}

// N no vendedor: vende todas as armas sem selo TOP, com o popup nativo de venda em massa.
// Fora da venda: equipadas, TOP, iconicas e itens de quest.
@addField(FullscreenVendorGameController)
let m_bisSellPopupToken: ref<inkGameNotificationToken>;

@addMethod(FullscreenVendorGameController)
protected cb func OnBisVendorKeyInput(event: ref<KeyInputEvent>) {
  if !Equals(event.GetAction(), EInputAction.IACT_Press) || !Equals(event.GetKey(), EInputKey.IK_N) {
    return;
  };
  this.BisOpenSellNonTopConfirmation();
}

@addMethod(FullscreenVendorGameController)
private final func BisGetSellableNonTopWeapons() -> [wref<gameItemData>] {
  let result: [wref<gameItemData>];
  let values: [wref<IScriptable>];
  let item: wref<UIInventoryItem>;
  let i: Int32;
  let player: ref<PlayerPuppet> = GetPlayer(GetGameInstance());
  let uiSystem: ref<UIInventoryScriptableSystem> = UIInventoryScriptableSystem.GetInstance(GetGameInstance());
  if !IsDefined(player) || !IsDefined(uiSystem) {
    return result;
  };
  player.BisRecompute();
  uiSystem.GetPlayerItemsMap().GetValues(values);
  while i < ArraySize(values) {
    item = values[i] as UIInventoryItem;
    if IsDefined(item)
      && item.IsWeapon()
      && !item.IsEquipped()
      && !item.IsQuestItem()
      && !item.IsIconic()
      && !player.BisIsBest(item.GetID())
      && this.m_VendorDataManager.CanPlayerSellItem(item.GetID()) {
      ArrayPush(result, item.GetRealItemData());
    };
    i += 1;
  };
  return result;
}

@addMethod(FullscreenVendorGameController)
private final func BisOpenSellNonTopConfirmation() -> Void {
  let data: ref<VendorSellJunkPopupData>;
  let vendorMoney: Int32;
  let limitedItems: [ref<VendorJunkSellItem>];
  let sellableItems: [wref<gameItemData>] = this.BisGetSellableNonTopWeapons();
  if ArraySize(sellableItems) == 0 || this.m_isPopupPending {
    return;
  };
  this.m_isPopupPending = true;
  vendorMoney = MarketSystem.GetVendorMoney(this.m_VendorDataManager.GetVendorInstance());
  limitedItems = this.GetLimitedSellableItems(sellableItems, vendorMoney);
  data = new VendorSellJunkPopupData();
  data.notificationName = n"base\\gameplay\\gui\\widgets\\notifications\\vendor_sell_junk_confirmation.inkwidget";
  data.isBlocking = true;
  data.useCursor = true;
  data.queueName = n"modal_popup";
  data.items = sellableItems;
  data.itemsQuantity = ArraySize(sellableItems);
  data.totalPrice = this.GetBulkSellPrice(sellableItems);
  data.limitedTotalPrice = Cast<Int32>(this.GetBulkSellPrice(limitedItems));
  data.limitedItems = limitedItems;
  data.limitedItemsQuantity = ArraySize(limitedItems);
  this.m_bisSellPopupToken = this.ShowGameNotification(data);
  this.m_bisSellPopupToken.RegisterListener(this, n"OnBisSellPopupClosed");
  this.m_buttonHintsController.Hide();
}

@addMethod(FullscreenVendorGameController)
protected cb func OnBisSellPopupClosed(data: ref<inkGameNotificationData>) -> Bool {
  let itemsData: [wref<gameItemData>];
  let amounts: [Int32];
  let i: Int32;
  this.m_isPopupPending = false;
  this.m_bisSellPopupToken = null;
  let closeData: ref<VendorSellJunkPopupCloseData> = data as VendorSellJunkPopupCloseData;
  if IsDefined(closeData) && closeData.confirm {
    while i < ArraySize(closeData.limitedItems) {
      ArrayPush(itemsData, closeData.limitedItems[i].item);
      ArrayPush(amounts, closeData.limitedItems[i].quantity);
      i += 1;
    };
    this.m_VendorDataManager.SellItemsToVendor(itemsData, amounts);
    this.PlaySound(n"Item", n"OnSell");
    this.m_TooltipsManager.HideTooltips();
  } else {
    this.PlaySound(n"Button", n"OnPress");
  };
  this.m_buttonHintsController.Show();
}
