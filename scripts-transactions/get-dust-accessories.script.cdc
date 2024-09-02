
import "FlovatarDustCollectibleAccessory"

access(all) fun main(address:Address) : [FlovatarDustCollectibleAccessory.CollectibleAccessoryData] {
    return FlovatarDustCollectibleAccessory.getAccessories(address: address)
}