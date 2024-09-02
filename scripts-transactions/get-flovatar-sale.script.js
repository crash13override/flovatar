import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function getFlovatarSaleScript(address, flovatarId) {
    if (address == null) return null

    return await fcl
        .query({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

access(all) fun main(address:Address, flovatarId: UInt64) : FlovatarMarketplace.FlovatarSaleData? {

    return FlovatarMarketplace.getFlovatarSale(address: address, id: flovatarId)

}
`,
            args: (arg, t) => [
                arg(address, t.Address),
                arg(''+flovatarId, t.UInt64)
            ],
    });

}

