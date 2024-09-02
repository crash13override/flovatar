import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function getCollectionsFlobotScript(address) {
    if (address == null) return null

    return await fcl
        .query({
            cadence: `
import Flobot, Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

access(all) struct Collections {

  access(all) var address: Address
  access(all) var flobots: [Flobot.FlobotData]
  init (_ address:Address, _ flobots: [Flobot.FlobotData]) {
    self.address = address
    self.flobots = []
  }
}

access(all) fun main(address:Address) : Collections {
    // get the accounts' public address objects
    let flobots = Flobot.getFlobots(address: address)

    return Collections(address, flobots)
}
`,
            args: (arg, t) => [
                arg(address, t.Address)
            ],
        });

}
