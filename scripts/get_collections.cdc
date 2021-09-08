import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FUSD from "../../contracts/FUSD.cdc"
import Flovatar from "../../contracts/Flovatar.cdc"
import FlovatarComponent from "../../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../../contracts/FlovatarPack.cdc"
import Marketplace from "../../contracts/Marketplace.cdc"

pub struct Collections {

  pub(set) var address: Address
  pub(set) var flovatars: [Flovatar.FlovatarData]
  pub(set) var components: [FlovatarComponent.ComponentData]
  pub(set) var packs: [UInt64]
  init (_ address:Address) {
    self.address = address
    self.flovatars = []
    self.components = []
    self.packs = []
  }
}

pub fun main(address:Address) : Collections {
    // get the accounts' public address objects
    let account = getAccount(address)
    let status = Collections(address)

    status.flovatars = Flovatar.getFlovatars(address: address)
    status.components = FlovatarComponent.getComponents(address: address)
    status.packs = FlovatarPack.getPacks(address: address)!

    return status
}