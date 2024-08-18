import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function getCollectionsScript(address) {
    if (address == null) return null

    return await fcl
        .query({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

pub struct Collections {

  pub(set) var address: Address
  pub(set) var flovatars: [Flovatar.FlovatarData]
  pub(set) var flovatarIds: [UInt64]
  pub(set) var components: [FlovatarComponent.ComponentData]
  pub(set) var flovatarSales: [FlovatarMarketplace.FlovatarSaleData]
  pub(set) var componentSales: [FlovatarMarketplace.FlovatarComponentSaleData]
  pub(set) var packs: [UInt64]
  init (_ address:Address) {
    self.address = address
    self.flovatars = []
    self.flovatarIds = []
    self.components = []
    self.flovatarSales = []
    self.componentSales = []
    self.packs = []
  }
}

pub fun main(address:Address) : Collections {
    // get the accounts' public address objects
    let account = getAccount(address)
    let status = Collections(address)

    status.flovatars = Flovatar.getFlovatars(address: address)
    status.components = FlovatarComponent.getComponents(address: address)
    status.packs = FlovatarPack.getPacks(address: address) ?? []
    status.flovatarSales = FlovatarMarketplace.getFlovatarSales(address: address)
    status.componentSales = FlovatarMarketplace.getFlovatarComponentSales(address: address)

    if let flovatarCollection = account.getCapability(Flovatar.CollectionPublicPath).borrow<&{Flovatar.CollectionPublic}>()  {
        status.flovatarIds = flovatarCollection.getIDs()
    }

    return status
}
`,
            args: (arg, t) => [
                arg(address, t.Address)
            ],
        });

}
