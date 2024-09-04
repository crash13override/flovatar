
import "FlovatarMarketplace"

access(all) fun main(address:Address) : [FlovatarMarketplace.FlovatarComponentSaleData] {

    return FlovatarMarketplace.getFlovatarComponentSales(address: address)

}