import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"
import {getCollectionsByNameComponentScript} from "./get-collections-by-name-component.script";

export async function getCollectionsComponentSaleScript(address) {
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
  access(all) var components: [FlovatarComponent.ComponentData]
  access(all) var flovatarSales: [FlovatarMarketplace.FlovatarSaleData]
  access(all) var componentSales: [FlovatarMarketplace.FlovatarComponentSaleData]
  access(all) var packs: [UInt64]
  init (_ address:Address, _ componentSales: [FlovatarMarketplace.FlovatarComponentSaleData]) {
    self.address = address
    self.flovatars = []
    self.components = []
    self.flovatarSales = []
    self.componentSales = componentSales
    self.packs = []
  }
}

access(all) fun main(address:Address) : Collections {
    // get the accounts' public address objects
    let componentSales = FlovatarMarketplace.getFlovatarComponentSales(address: address)

    return Collections(address, componentSales)
}
`,
            args: (arg, t) => [
                arg(address, t.Address)
            ],
        });

}
