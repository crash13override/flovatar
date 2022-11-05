import FungibleToken from "../contracts/FungibleToken.cdc"
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import FlowToken from "../contracts/FlowToken.cdc"
import Flovatar from "../contracts/Flovatar.cdc"
import FlovatarComponent from "../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../contracts/FlovatarPack.cdc"
import FlovatarMarketplace from "../contracts/FlovatarMarketplace.cdc"
import FlovatarInbox from "../../contracts/FlovatarInbox.cdc"

pub struct Claimables {

  pub(set) var address: Address
  pub(set) var flovatarComponents: [UInt64]
  pub(set) var walletComponents: [UInt64]
  pub(set) var flovatarDust: UFix64
  pub(set) var walletDust: UFix64
  pub(set) var flovatarCommunityDust: UFix64
  init (_ address:Address) {
    self.address = address
    self.flovatarComponents = []
    self.walletComponents = []
    self.flovatarDust = 0.0
    self.walletDust = 0.0
    self.flovatarCommunityDust = 0.0
  }
}

pub fun main(address:Address) : Claimables {
    // get the accounts' public address objects
    let status = Claimables(address)
    let account = getAccount(address)

    if let flovatarCollection = account.getCapability(self.CollectionPublicPath).borrow<&Flovatar.Collection{Flovatar.CollectionPublic}>()  {
        for id in flovatarCollection.getIDs() {
            status.flovatarDust = status.flovatarDust + FlovatarInbox.getFlovatarDustBalance(id: id)
            if let claimableCommunityDust = FlovatarInbox.getClaimableFlovatarCommunityDust(id: id, address: address) {
                status.flovatarCommunityDust = status.flovatarCommunityDust + claimableCommunityDust.amount
            }
            status.flovatarComponents = status.flovatarComponents.concat(FlovatarInbox.getFlovatarComponentIDs(id: id))
        }
    }

    status.walletComponents = FlovatarInbox.getWalletComponentIDs(address: address)
    status.walletDust = FlovatarInbox.getWalletDustBalance(address: address)

    return status
}