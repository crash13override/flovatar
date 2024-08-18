import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function getDustAccessoriesScript(address) {
    if (address == null) return null

    return await fcl
        .query({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace, FlovatarDustCollectible, FlovatarDustCollectibleAccessory, FlovatarDustCollectibleTemplate from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

pub fun main(address:Address) : [FlovatarDustCollectibleAccessory.CollectibleAccessoryData] {
    // get the accounts' public address objects
    return FlovatarDustCollectibleAccessory.getAccessories(address: address)
}
`,
            args: (arg, t) => [
                arg(address, t.Address)
            ],
        });

}
