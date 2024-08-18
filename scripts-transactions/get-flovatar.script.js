import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function getFlovatarScript(address, flovatarId) {
    if (address == null) return null

    return await fcl
        .query({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

pub fun main(address:Address, flovatarId: UInt64) : Flovatar.FlovatarData? {

    return Flovatar.getFlovatar(address: address, flovatarId: flovatarId)

}
`,
            args: (arg, t) => [
                arg(address, t.Address),
                arg(''+flovatarId, t.UInt64)
            ],
        });

}
