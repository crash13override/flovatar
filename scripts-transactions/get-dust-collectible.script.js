import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function getDustCollectibleScript(address, collectibleId) {
    if (address == null) return null

    return await fcl
        .query({
            cadence: `

import FlovatarDustCollectible from 0xFlovatar

access(all) fun main(address:Address, collectibleId:UInt64) : FlovatarDustCollectible.FlovatarDustCollectibleData? {
    // get the accounts' public address objects
    return FlovatarDustCollectible.getCollectible(address: address, collectibleId: collectibleId)
}
`,
            args: (arg, t) => [
                arg(address, t.Address),
                arg(''+collectibleId, t.UInt64)
            ],
        });

}
