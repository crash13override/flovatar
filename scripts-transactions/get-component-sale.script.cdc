
import "FlovatarMarketplace"

access(all) fun main(address: Address, componentId: UInt64) : FlovatarMarketplace.FlovatarComponentSaleData? {

    return FlovatarMarketplace.getFlovatarComponentSale(address: address, id: componentId)

}