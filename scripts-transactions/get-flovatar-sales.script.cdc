
import "FlovatarMarketplace"

access(all) fun main(address:Address) : [FlovatarMarketplace.FlovatarSaleData] {

    return FlovatarMarketplace.getFlovatarSales(address: address)

}