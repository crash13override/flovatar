
import "FlovatarComponent"

access(all) fun main(address:Address) : [FlovatarComponent.ComponentData] {
    return FlovatarComponent.getComponents(address: address)
}