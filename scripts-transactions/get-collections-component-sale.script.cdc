
import "Flovatar"
import "FlovatarComponent"
import "FlovatarMarketplace"

access(all) struct Collections {

  access(all) var address: Address
  access(all) var flovatars: [Flovatar.FlovatarData]
  access(all) var components: [FlovatarComponent.ComponentData]
  access(all) var flovatarSales: [FlovatarMarketplace.FlovatarSaleData]
  access(all) var componentSales: [FlovatarMarketplace.FlovatarComponentSaleData]
  access(all) var packs: [UInt64]
  init (_ address:Address, _ componentSales: [FlovatarMarketplace.FlovatarComponentSaleData]) {
    self.address = address
    self.flovatars = []
    self.components = []
    self.flovatarSales = []
    self.componentSales = componentSales
    self.packs = []
  }
}

access(all) fun main(address:Address) : Collections {
    let componentSales = FlovatarMarketplace.getFlovatarComponentSales(address: address)

    return Collections(address, componentSales)
}