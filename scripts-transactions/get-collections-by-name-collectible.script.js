import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function getCollectionsByNameCollectibleScript(name) {
    if (name == null) return null

    return await fcl
        .query({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace, FlovatarDustToken, FlovatarDustCollectible, FlovatarDustCollectibleAccessory, FlovatarDustCollectibleTemplate from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken
import FIND from 0xFind

access(all) struct Collections {

  access(all) var address: Address
  access(all) var flovatars: [Flovatar.FlovatarData]
  access(all) var components: [FlovatarComponent.ComponentData]
  access(all) var flovatarSales: [FlovatarMarketplace.FlovatarSaleData]
  access(all) var componentSales: [FlovatarMarketplace.FlovatarComponentSaleData]
  access(all) var collectibles: [FlovatarDustCollectible.FlovatarDustCollectibleData]
  access(all) var packs: [UInt64]
  init (_ address:Address, _ collectibles: [FlovatarDustCollectible.FlovatarDustCollectibleData]) {
    self.address = address
    self.flovatars = []
    self.components = []
    self.flovatarSales = []
    self.componentSales = []
    self.collectibles = collectibles
    self.packs = []
  }
}

access(all) fun main(name: String) :Collections? {

    let address = FIND.lookupAddress(name)

    if (address != nil) {

        let collectibles = FlovatarDustCollectible.getCollectibles(address: address!)

        return Collections(address!, collectibles)
    } else {
        return nil
    }

}
`,
            args: (arg, t) => [
                arg(name, t.String)
            ],
        });
}