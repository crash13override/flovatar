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
  pub(set) var components: [UInt64]
  pub(set) var dust: UFix64
  init (_ address:Address) {
    self.address = address
    self.components = []
    self.dust = 0.0
  }
}

pub fun main(address:Address) : Claimables {
    // get the accounts' public address objects
    let status = Claimables(address)
    let account = getAccount(address)

    status.components = FlovatarInbox.getWalletComponentIDs(address: address)
    status.dust = FlovatarInbox.getWalletDustBalance(address: address)

    return status
}