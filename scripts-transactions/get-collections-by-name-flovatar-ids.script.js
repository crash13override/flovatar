import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function getCollectionsByNameFlovatarIdsScript(name) {
    if (name == null) return null

    return await fcl
        .query({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken
import FIND from 0xFind

access(all) struct Collections {

  access(all) var address: Address
  access(all) var flovatars: [Flovatar.FlovatarData]
  access(all) var flovatarIds: [UInt64]
  access(all) var components: [FlovatarComponent.ComponentData]
  access(all) var flovatarSales: [FlovatarMarketplace.FlovatarSaleData]
  access(all) var componentSales: [FlovatarMarketplace.FlovatarComponentSaleData]
  access(all) var packs: [UInt64]
  init (_ address:Address, _ flovatarIds: [UInt64]) {
    self.address = address
    self.flovatars = []
    self.flovatarIds = []
    self.components = []
    self.flovatarSales = []
    self.componentSales = []
    self.packs = []
  }
}

access(all) fun main(name: String) :Collections? {

    let address = FIND.lookupAddress(name)

    if (address != nil) {
      let account = getAccount(address!)
      var flovatarIds: [UInt64] = []

      if let flovatarCollection = account.capabilities.borrow<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath)  {
          flovatarIds = flovatarCollection.getIDs()
      }

        return Collections(address!, flovatarIds)
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
