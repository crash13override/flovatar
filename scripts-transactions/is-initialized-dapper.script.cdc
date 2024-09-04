
import "Flovatar" 
import "FlovatarComponent" 
import "FlovatarPack"
import "NFTStorefrontV2"
import "FungibleToken"

access(all) fun main(address: Address): Bool {

  let account = getAccount(address)

  let flovatarCap = account.capabilities.get<&Flovatar.Collection>(Flovatar.CollectionPublicPath)
  let flovatarComponentCap = account.capabilities.get<&FlovatarComponent.Collection>(FlovatarComponent.CollectionPublicPath)
  let storefrontRef = account.capabilities.get<&NFTStorefrontV2.Storefront>(NFTStorefrontV2.StorefrontPublicPath)
  let futRef = account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
  let flovatarPackCap = account.capabilities.get<&FlovatarPack.Collection>(FlovatarPack.CollectionPublicPath)

  return (flovatarCap.check() && flovatarComponentCap.check() && flovatarPackCap.check() && storefrontRef.check() && futRef.check())
}