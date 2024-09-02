
import "Flovatar"
import "FlovatarComponent"
import "FlovatarPack"
import "FlovatarMarketplace"

access(all) struct Collections {

  access(all) var address: Address
  access(all) var flovatars: [Flovatar.FlovatarData]
  access(all) var flovatarIds: [UInt64]
  access(all) var components: [FlovatarComponent.ComponentData]
  access(all) var flovatarSales: [FlovatarMarketplace.FlovatarSaleData]
  access(all) var componentSales: [FlovatarMarketplace.FlovatarComponentSaleData]
  access(all) var packs: [UInt64]
  init (_ address:Address, _ flovatars: [Flovatar.FlovatarData], _ flovatarIds: [UInt64], _ components: [FlovatarComponent.ComponentData], _ flovatarSales: [FlovatarMarketplace.FlovatarSaleData], _ componentSales: [FlovatarMarketplace.FlovatarComponentSaleData], _ packs: [UInt64]) {
    self.address = address
    self.flovatars = flovatars
    self.flovatarIds = flovatarIds
    self.components = components
    self.flovatarSales = flovatarSales
    self.componentSales = componentSales
    self.packs = packs
  }
}

access(all) fun main(address:Address) : Collections {
    // get the accounts' public address objects
    let account = getAccount(address)

    var flovatarIds: [UInt64] = []
    let flovatars = Flovatar.getFlovatars(address: address)
    let components = FlovatarComponent.getComponents(address: address)
    let packs = FlovatarPack.getPacks(address: address) ?? []
    let flovatarSales = FlovatarMarketplace.getFlovatarSales(address: address)
    let componentSales = FlovatarMarketplace.getFlovatarComponentSales(address: address)

    if let flovatarCollection = account.capabilities.borrow<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath)  {
        flovatarIds = flovatarCollection.getIDs()
    }

    return Collections(address, flovatars, flovatarIds, components, flovatarSales, componentSales, packs)
}