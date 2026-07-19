// UnequipMods - weapon and clothing mods can be unequipped back to the inventory
// Requires: redscript
module UnequipMods

// Vanilla only allows unequipping iconic mods; scopes, muzzles and programs were already free.
// Integral cyberware parts (knuckles, mantis edge, wires, launcher rounds) stay blocked.
@wrapMethod(RPGManager)
public final static func CanPartBeUnequipped(data: InventoryItemData, slotId: TweakDBID) -> Bool {
  let type: gamedataItemType = RPGManager.GetItemType(data.ID);
  if RPGManager.IsWeaponMod(type) || RPGManager.IsClothingMod(type) {
    return true;
  };
  return wrappedMethod(data, slotId);
}

// Parts worth saving: mods plus the attachments vanilla already lets you detach.
func UnequipModsIsRemovablePart(type: gamedataItemType) -> Bool {
  if RPGManager.IsWeaponMod(type) || RPGManager.IsClothingMod(type) {
    return true;
  };
  return Equals(type, gamedataItemType.Prt_ShortScope)
    || Equals(type, gamedataItemType.Prt_LongScope)
    || Equals(type, gamedataItemType.Prt_Muzzle)
    || Equals(type, gamedataItemType.Prt_HandgunMuzzle)
    || Equals(type, gamedataItemType.Prt_RifleMuzzle);
}

// Detaches every removable part of a weapon/clothing item back to the owner's inventory.
func UnequipModsStripParts(game: GameInstance, owner: wref<GameObject>, itemID: ItemID) -> Int32 {
  if !RPGManager.IsItemWeapon(itemID) && !RPGManager.IsItemClothing(itemID) {
    return 0;
  };
  let ts = GameInstance.GetTransactionSystem(game);
  let itemData = ts.GetItemData(owner, itemID);
  if !IsDefined(itemData) {
    return 0;
  };
  let usedSlots: array<TweakDBID>;
  ts.GetUsedSlotsOnItem(owner, itemID, usedSlots);
  let count = 0;
  for slot in usedSlots {
    let partData: InnerItemData;
    itemData.GetItemPart(partData, slot);
    let partType = RPGManager.GetItemType(InnerItemData.GetItemID(partData));
    if UnequipModsIsRemovablePart(partType) {
      ts.RemovePart(owner, itemID, slot);
      count += 1;
    };
  };
  return count;
}

// Toast follows the game's on-screen language: pt-* = Portuguese, else English.
func UnequipModsNotify(game: GameInstance, count: Int32) {
  if count <= 0 {
    return;
  };
  let lang: CName = (GameInstance.GetSettingsSystem(game).GetVar(n"/language", n"OnScreen") as ConfigVarListName).GetValue();
  let msg: SimpleScreenMessage;
  msg.isShown = true;
  msg.duration = 5.0;
  if StrBeginsWith(NameToString(lang), "pt") {
    msg.message = s"Mods devolvidos ao inventário: \(count)";
  } else {
    msg.message = s"Mods returned to inventory: \(count)";
  };
  GameInstance.GetBlackboardSystem(game).Get(GetAllBlackboardDefs().UI_Notifications)
    .SetVariant(GetAllBlackboardDefs().UI_Notifications.OnscreenMessage, ToVariant(msg), true);
}

// Single-item sales route through this too, so one wrap covers unit sell,
// junk bulk sell and drop points.
@wrapMethod(VendorDataManager)
public final func SellItemsToVendor(const itemsData: script_ref<array<wref<gameItemData>>>, const amounts: script_ref<array<Int32>>, opt requestId: Int32) {
  let game = GetGameInstance();
  let player = GameInstance.GetPlayerSystem(game).GetLocalPlayerMainGameObject();
  let total = 0;
  let i = 0;
  while i < ArraySize(Deref(itemsData)) {
    total += UnequipModsStripParts(game, player, Deref(itemsData)[i].GetID());
    i += 1;
  };
  UnequipModsNotify(game, total);
  wrappedMethod(itemsData, amounts, requestId);
}

// Vanilla disassemble only restores a few attachments; strip everything first.
@wrapMethod(CraftingSystem)
private final const func DisassembleItem(target: wref<GameObject>, itemID: ItemID, amount: Int32) -> Void {
  let count = UnequipModsStripParts(GetGameInstance(), target, itemID);
  UnequipModsNotify(GetGameInstance(), count);
  wrappedMethod(target, itemID, amount);
}
