
import "Flovatar" 
import "Flobot"
import "FlovatarDustCollectible"
import "FlovatarDustCollectibleAccessory"
import "FlovatarComponent" 
import "FlovatarPack"
import "NFTStorefrontV2"
import "FungibleToken"

access(all) fun main(address: Address): Bool {

  let account = getAccount(address)

  let flovatarCap = account.capabilities.get<&Flovatar.Collection>(Flovatar.CollectionPublicPath)
  let flobotCap = account.capabilities.get<&Flobot.Collection>(Flobot.CollectionPublicPath)
  let flovatarComponentCap = account.capabilities.get<&FlovatarComponent.Collection>(FlovatarComponent.CollectionPublicPath)
  let storefrontRef = account.capabilities.get<&NFTStorefrontV2.Storefront>(NFTStorefrontV2.StorefrontPublicPath)
  let futRef = account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
  let flovatarPackCap = account.capabilities.get<&FlovatarPack.Collection>(FlovatarPack.CollectionPublicPath)
  let flovatarCollectibleCap = account.capabilities.get<&FlovatarDustCollectible.Collection>(FlovatarDustCollectible.CollectionPublicPath)
  let flovatarAccessoryCap = account.capabilities.get<&FlovatarDustCollectibleAccessory.Collection>(FlovatarDustCollectibleAccessory.CollectionPublicPath)

  return (flovatarCap.check() && flobotCap.check() && flovatarComponentCap.check() && flovatarPackCap.check() && storefrontRef.check() && futRef.check() && flovatarCollectibleCap.check() && flovatarAccessoryCap.check())
}