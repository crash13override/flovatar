
import "Flovatar"
import "FlovatarComponent"
import "FlovatarComponentTemplate"
import "FlovatarPack"
import "FlovatarMarketplace"
import "Flobot"
import "FlovatarDustToken"
import "FlovatarDustCollectible"
import "FlovatarDustCollectibleAccessory"

access(all) fun main(address: Address): Bool {

  let account = getAccount(address)

  let flovatarCap = account.capabilities.get<&Flovatar.Collection>(Flovatar.CollectionPublicPath)
  let flobotCap = account.capabilities.get<&Flobot.Collection>(Flobot.CollectionPublicPath)
  let flovatarComponentCap = account.capabilities.get<&FlovatarComponent.Collection>(FlovatarComponent.CollectionPublicPath)
  let marketplaceCap = account.capabilities.get<&FlovatarMarketplace.SaleCollection>(FlovatarMarketplace.CollectionPublicPath)
  let flovatarPackCap = account.capabilities.get<&FlovatarPack.Collection>(FlovatarPack.CollectionPublicPath)
  let flovatarCollectibleCap = account.capabilities.get<&FlovatarDustCollectible.Collection>(FlovatarDustCollectible.CollectionPublicPath)
  let flovatarAccessoryCap = account.capabilities.get<&FlovatarDustCollectibleAccessory.Collection>(FlovatarDustCollectibleAccessory.CollectionPublicPath)
  let dustTokenCap = account.capabilities.get<&FlovatarDustToken.Vault>(FlovatarDustToken.VaultReceiverPath)
  let dustTokenCapBalance = account.capabilities.get<&FlovatarDustToken.Vault>(FlovatarDustToken.VaultBalancePath)

  return (flovatarCap.check() && flobotCap.check() && flovatarComponentCap.check() && marketplaceCap.check() && flovatarPackCap.check() && flovatarCollectibleCap.check() && flovatarAccessoryCap.check() && dustTokenCap.check() && dustTokenCapBalance.check())
}