import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function getDustAccessoriesScript(address) {
    if (address == null) return null

    return await fcl
        .query({
            cadence: `
import FlovatarDustCollectibleAccessory from 0xFlovatar

access(all) fun main(address:Address) : [FlovatarDustCollectibleAccessory.CollectibleAccessoryData] {
    // get the accounts' public address objects
    return FlovatarDustCollectibleAccessory.getAccessories(address: address)
}
`,
            args: (arg, t) => [
                arg(address, t.Address)
            ],
        });

}
