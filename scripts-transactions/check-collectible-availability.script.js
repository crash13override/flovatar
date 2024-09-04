import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function checkCollectibleAvailabilityScript(series, layersId, layersValue) {
    return await fcl
        .query({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace, FlovatarDustCollectible, FlovatarDustCollectibleAccessory, FlovatarDustCollectibleTemplate from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

access(all) fun main(
    series: UInt64,
    layersId: [UInt32],
    layersValue: [UInt64]) : Bool {

    let layers: {UInt32: UInt64} = {}
    var i: UInt32 = UInt32(0)
    while(i <  UInt32(layersId.length)){
        layers.insert(key: layersId[i]!, layersValue[i]!)
        i = i + UInt32(1)
    }

    return FlovatarDustCollectible.checkCombinationAvailable(series: series, layers: layers)

}
`,
            args: (arg, t) => [
                arg(''+series, t.UInt64),
                arg(layersId, t.Array(t.UInt32)),
                arg(layersValue, t.Array(t.UInt64))
            ],
        });

}
