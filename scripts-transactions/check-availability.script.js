import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function checkAvailabilityScript(body, hair, facialHair, eyes, nose, mouth, clothing) {
    return await fcl
        .query({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

pub fun main(
    body: UInt64,
    hair: UInt64,
    facialHair: UInt64?,
    eyes: UInt64,
    nose: UInt64,
    mouth: UInt64,
    clothing: UInt64) : Bool {

    return Flovatar.checkCombinationAvailable(body: body, hair: hair, facialHair: facialHair, eyes: eyes, nose: nose, mouth: mouth, clothing: clothing)

}
`,
            args: (arg, t) => [
                arg(''+body, t.UInt64),
                arg(''+hair, t.UInt64),
                arg(facialHair ? ''+facialHair : facialHair, t.Optional(t.UInt64)),
                arg(''+eyes, t.UInt64),
                arg(''+nose, t.UInt64),
                arg(''+mouth, t.UInt64),
                arg(''+clothing, t.UInt64)
            ],
        });

}
