
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
  init (_ address:Address,_ flovatars: [Flovatar.FlovatarData], _ flovatarIds: [UInt64], _ components: [FlovatarComponent.ComponentData], _ flovatarSales: [FlovatarMarketplace.FlovatarSaleData], _ componentSales: [FlovatarMarketplace.FlovatarComponentSaleData], _ packs: [UInt64]) {
    self.address = address
    self.flovatars = flovatars
    self.flovatarIds = flovatarIds
    self.components = components
    self.flovatarSales = flovatarSales
    self.componentSales = componentSales
    self.packs = packs
  }
}

access(all) fun main(name: String) :Collections? {

    var flovatarIds: [UInt64] = []
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

        if let flovatarCollection = account.capabilities.borrow<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath)  {
            flovatarIds = flovatarCollection.getIDs()
        }

        return Collections(address!, flovatars, flovatarIds, components, flovatarSales, componentSales, packs)
    } else {
        return nil
    }

}