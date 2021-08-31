import FungibleToken from "../contracts/FungibleToken.cdc"
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import FUSD from "../contracts/FUSD.cdc"
import Flovatar from "../contracts/Flovatar.cdc"
import FlovatarComponent from "../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../contracts/FlovatarPack.cdc"
import NFTStorefront from "../contracts/NFTStorefront.cdc"

pub fun main(address: Address): Bool {

  let account = getAccount(address)

  let flovatarCap = account.getCapability<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath)
  let flovatarComponentCap = account.getCapability<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath)
  let nftStorefrontCap = account.getCapability<&{NFTStorefront.StorefrontPublic}>(NFTStorefront.StorefrontPublicPath)

  var hasFusd = false
  if let fusdVault = account.getCapability(/public/fusdBalance).borrow<&FUSD.Vault{FungibleToken.Balance}>(){
    hasFusd = true
  }

  return (flovatarCap.check() && flovatarComponentCap.check() && nftStorefrontCap.check() && hasFusd)
}