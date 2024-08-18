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

pub struct Collections {

  pub(set) var address: Address
  pub(set) var flovatars: [Flovatar.FlovatarData]
  pub(set) var components: [FlovatarComponent.ComponentData]
  pub(set) var flovatarSales: [FlovatarMarketplace.FlovatarSaleData]
  pub(set) var componentSales: [FlovatarMarketplace.FlovatarComponentSaleData]
  pub(set) var packs: [UInt64]
  init (_ address:Address) {
    self.address = address
    self.flovatars = []
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

    status.componentSales = FlovatarMarketplace.getFlovatarComponentSales(address: address)

    return status
}
`,
            args: (arg, t) => [
                arg(address, t.Address)
            ],
        });

}
