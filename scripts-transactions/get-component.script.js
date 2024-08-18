import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function getComponentScript(address, componentId) {
    if (address == null) return null

    return await fcl
        .query({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

pub fun main(address:Address, componentId: UInt64) : FlovatarComponent.ComponentData? {
    // get the accounts' public address objects
    return FlovatarComponent.getComponent(address: address, componentId: componentId)
}
`,
            args: (arg, t) => [
                arg(address, t.Address),
                arg(''+componentId, t.UInt64)
            ],
        });

}
