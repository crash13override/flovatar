import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FUSD from "../../contracts/FUSD.cdc"
import Flovatar from "../../contracts/Flovatar.cdc"
import FlovatarComponent from "../../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../../contracts/FlovatarPack.cdc"
import Marketplace from "../../contracts/Marketplace.cdc"

//This script checks if an address has been fully initialized

pub fun main(address: Address): Bool {
  let account = getAccount(address)
  let marketplaceCap = account.getCapability<&{Marketplace.SalePublic}>(Marketplace.CollectionPublicPath)
  let webshotCap = account.getCapability<&{Webshot.CollectionPublic}>(Webshot.CollectionPublicPath)
  let websiteCap = account.getCapability<&{Website.CollectionPublic}>(Website.CollectionPublicPath)
  var hasFusd = false
  if let fusdVault = account.getCapability(/public/fusdBalance).borrow<&FUSD.Vault{FungibleToken.Balance}>(){
    hasFusd = true
  }


  return (marketplaceCap.check() && webshotCap.check() && Profile.check(address) && websiteCap.check() && hasFusd)
}