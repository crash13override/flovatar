import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function checkFlobotAvailabilityScript(body, head, arms, legs, face) {
    return await fcl
        .query({
            cadence: `
import Flobot from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

pub fun main(
    body: UInt64,
    head: UInt64,
    arms: UInt64,
    legs: UInt64,
    face: UInt64) : Bool {

    return Flobot.checkCombinationAvailable(body: body, head: head, arms: arms, legs: legs, face: face)

}
`,
            args: (arg, t) => [
                arg(''+body, t.UInt64),
                arg(''+head, t.UInt64),
                arg(''+arms, t.UInt64),
                arg(''+legs, t.UInt64),
                arg(''+face, t.UInt64)
            ],
        });

}
