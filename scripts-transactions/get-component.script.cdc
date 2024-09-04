
import "FlovatarComponent"

access(all) fun main(address:Address, componentId: UInt64) : FlovatarComponent.ComponentData? {
    return FlovatarComponent.getComponent(address: address, componentId: componentId)
}