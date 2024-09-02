
import "Flovatar"
import "FlovatarComponent"
import "FlovatarMarketplace"
import "FlovatarPack"
import "FIND"

access(all) struct Collections {

  access(all) var address: Address
  access(all) var flovatars: [Flovatar.FlovatarData]
  access(all) var components: [FlovatarComponent.ComponentData]
  access(all) var flovatarSales: [FlovatarMarketplace.FlovatarSaleData]
  access(all) var componentSales: [FlovatarMarketplace.FlovatarComponentSaleData]
  access(all) var packs: [UInt64]
  init (_ address:Address,_ flovatars: [Flovatar.FlovatarData], _ components: [FlovatarComponent.ComponentData], _ flovatarSales: [FlovatarMarketplace.FlovatarSaleData], _ componentSales: [FlovatarMarketplace.FlovatarComponentSaleData], _ packs: [UInt64]) {
    self.address = address
    self.flovatars = []
    self.components = []
    self.flovatarSales = []
    self.componentSales = []
    self.packs = []
  }
}

access(all) fun main(name: String) :Collections? {

    let address = FIND.lookupAddress(name)
    var flovatars: [Flovatar.FlovatarData] = []
    var components: [FlovatarComponent.ComponentData] = []
    var packs: [UInt64] = []
    var flovatarSales: [FlovatarMarketplace.FlovatarSaleData] = []
    var componentSales: [FlovatarMarketplace.FlovatarComponentSaleData] = []

    if (address != nil) {
        flovatars = Flovatar.getFlovatars(address: address!)
        components = FlovatarComponent.getComponents(address: address!)
        packs = FlovatarPack.getPacks(address: address!) ?? []
        flovatarSales = FlovatarMarketplace.getFlovatarSales(address: address!)
        componentSales = FlovatarMarketplace.getFlovatarComponentSales(address: address!)

        return Collections(address!, flovatars, components, flovatarSales, componentSales, packs)
    } else {
        return nil
    }

}