
import "FlovatarMarketplace"

access(all) fun main(address:Address, flovatarId: UInt64) : FlovatarMarketplace.FlovatarSaleData? {

    return FlovatarMarketplace.getFlovatarSale(address: address, id: flovatarId)

}