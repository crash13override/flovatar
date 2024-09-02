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

access(all) struct Collections {

  access(all) var address: Address
  access(all) var flovatars: [Flovatar.FlovatarData]
  access(all) var flovatarIds: [UInt64]
  access(all) var components: [FlovatarComponent.ComponentData]
  access(all) var flovatarSales: [FlovatarMarketplace.FlovatarSaleData]
  access(all) var componentSales: [FlovatarMarketplace.FlovatarComponentSaleData]
  access(all) var packs: [UInt64]
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

access(all) fun main(address:Address) : Collections {
    // get the accounts' public address objects
    let account = getAccount(address)
    let status = Collections(address)

    status.flovatars = Flovatar.getFlovatars(address: address)
    status.components = FlovatarComponent.getComponents(address: address)
    status.packs = FlovatarPack.getPacks(address: address) ?? []
    status.flovatarSales = FlovatarMarketplace.getFlovatarSales(address: address)
    status.componentSales = FlovatarMarketplace.getFlovatarComponentSales(address: address)

    if let flovatarCollection = account.capabilities.get(Flovatar.CollectionPublicPath).borrow<&{Flovatar.CollectionPublic}>()  {
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
