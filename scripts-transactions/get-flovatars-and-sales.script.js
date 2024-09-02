import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function getFlovatarsAndSalesScript(address) {
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
  access(all) var flovatarSales: [FlovatarMarketplace.FlovatarSaleData]
  init (_ address:Address, _ flovatars: [Flovatar.FlovatarData], _ flovatarSales: [FlovatarMarketplace.FlovatarSaleData]) {
    self.address = address
    self.flovatars = []
    self.flovatarSales = []
  }
}

access(all) fun main(address:Address) : Collections {
    let flovatars = Flovatar.getFlovatars(address: address)
    let flovatarSales = FlovatarMarketplace.getFlovatarSales(address: address)
    let status = Collections(address, flovatars, flovatarSales)

    return status
}
`,
            args: (arg, t) => [
                arg(address, t.Address)
            ],
        });

}
