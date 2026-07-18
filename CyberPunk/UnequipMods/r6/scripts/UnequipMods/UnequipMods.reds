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
