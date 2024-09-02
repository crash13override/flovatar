import "Flovatar"
import "FlovatarComponent"
import "FlovatarMarketplace"
import "FIND"

access(all) struct Collections {

  access(all) var address: Address
  access(all) var flovatars: [Flovatar.FlovatarData]
  access(all) var components: [FlovatarComponent.ComponentData]
  access(all) var flovatarSales: [FlovatarMarketplace.FlovatarSaleData]
  access(all) var componentSales: [FlovatarMarketplace.FlovatarComponentSaleData]
  access(all) var packs: [UInt64]
  init (_ address:Address, _ flovatarSales: [FlovatarMarketplace.FlovatarSaleData]) {
    self.address = address
    self.flovatars = []
    self.components = []
    self.flovatarSales = flovatarSales
    self.componentSales = []
    self.packs = []
  }
}

access(all) fun main(name: String) :Collections? {

    let address = FIND.lookupAddress(name)

    if (address != nil) {
        
        let flovatarSales = FlovatarMarketplace.getFlovatarSales(address: address!)

        return Collections(address!, flovatarSales)
    } else {
        return nil
    }

}