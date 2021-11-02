import FungibleToken from "../contracts/FungibleToken.cdc"
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import FlowToken from "../contracts/FlowToken.cdc"
import Flovatar from "../contracts/Flovatar.cdc"
import FlovatarComponent from "../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../contracts/FlovatarPack.cdc"
import FlovatarMarketplace from "../contracts/FlovatarMarketplace.cdc"

//This script checks if an address has been fully initialized

pub fun main(address: Address): Bool {
  let account = getAccount(address)
  let marketplaceCap = account.getCapability<&{FlovatarMarketplace.SalePublic}>(FlovatarMarketplace.CollectionPublicPath)
  let webshotCap = account.getCapability<&{Webshot.CollectionPublic}>(Webshot.CollectionPublicPath)
  let websiteCap = account.getCapability<&{Website.CollectionPublic}>(Website.CollectionPublicPath)


  return (marketplaceCap.check() && webshotCap.check() && Profile.check(address) && websiteCap.check())
}