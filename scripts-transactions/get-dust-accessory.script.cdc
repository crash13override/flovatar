
import "FlovatarDustCollectibleAccessory"

access(all) fun main(address:Address, accessoryId:UInt64) : FlovatarDustCollectibleAccessory.CollectibleAccessoryData? {
    return FlovatarDustCollectibleAccessory.getAccessory(address: address, componentId: accessoryId)
}
