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

  pub(set) var id: UInt64
  pub(set) var components: [UInt64]
  pub(set) var dust: UFix64
  pub(set) var communityDust: FlovatarInbox.ClaimableDust?
  init (_ id: UInt64) {
    self.id = id
    self.components = []
    self.dust = 0.0
    self.communityDust = nil
  }
}

pub fun main(id: UInt64, address: Address) : Claimables {
    let status = Claimables(id)
    let account = getAccount(address)

    status.dust = status.flovatarDust + FlovatarInbox.getFlovatarDustBalance(id: id)
    status.communityDust = FlovatarInbox.getClaimableFlovatarCommunityDust(id: id, address: address)
    status.flovatarComponents = FlovatarInbox.getFlovatarComponentIDs(id: id)

    return status
}