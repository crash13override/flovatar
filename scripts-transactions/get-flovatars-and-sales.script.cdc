
import "Flovatar"
import "FlovatarMarketplace"

access(all) struct Collections {

  access(all) var address: Address
  access(all) var flovatars: [Flovatar.FlovatarData]
  access(all) var flovatarSales: [FlovatarMarketplace.FlovatarSaleData]
  init (_ address:Address, _ flovatars: [Flovatar.FlovatarData], _ flovatarSales: [FlovatarMarketplace.FlovatarSaleData]) {
    self.address = address
    self.flovatars = []
    self.flovatarSales = []
  }
}

access(all) fun main(address:Address) : Collections {
    let flovatars = Flovatar.getFlovatars(address: address)
    let flovatarSales = FlovatarMarketplace.getFlovatarSales(address: address)
    let status = Collections(address, flovatars, flovatarSales)

    return status
}