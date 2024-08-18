import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function getComponentSaleScript(address, componentId) {
    if (address == null) return null

    return await fcl
        .query({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

pub fun main(address: Address, componentId: UInt64) : FlovatarMarketplace.FlovatarComponentSaleData? {

    return FlovatarMarketplace.getFlovatarComponentSale(address: address, id: componentId)

}
`,
            args: (arg, t) => [
                arg(address, t.Address),
                arg(''+componentId, t.UInt64)
            ],
        });

}
