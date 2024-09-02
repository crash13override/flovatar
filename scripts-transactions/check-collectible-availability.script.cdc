import "FlovatarDustCollectible"

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
