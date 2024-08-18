import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function getDustAccessoryScript(address, accessoryId) {
    if (address == null) return null

    return await fcl
        .query({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace, FlovatarDustCollectible, FlovatarDustCollectibleAccessory, FlovatarDustCollectibleTemplate from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

pub fun main(address:Address, accessoryId:UInt64) : FlovatarDustCollectibleAccessory.CollectibleAccessoryData? {
    // get the accounts' public address objects
    return FlovatarDustCollectibleAccessory.getAccessory(address: address, componentId: accessoryId)
}
`,
            args: (arg, t) => [
                arg(address, t.Address),
                arg(''+accessoryId, t.UInt64)
            ],
        });

}
