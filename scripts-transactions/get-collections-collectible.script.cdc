
import "Flovatar"
import "FlovatarComponent"
import "FlovatarMarketplace"
import "FlovatarDustCollectible"

access(all) struct Collections {

  access(all) var address: Address
  access(all) var flovatars: [Flovatar.FlovatarData]
  access(all) var components: [FlovatarComponent.ComponentData]
  access(all) var flovatarSales: [FlovatarMarketplace.FlovatarSaleData]
  access(all) var componentSales: [FlovatarMarketplace.FlovatarComponentSaleData]
  access(all) var collectibles: [FlovatarDustCollectible.FlovatarDustCollectibleData]
  access(all) var packs: [UInt64]
  init (_ address:Address, _ collectibles: [FlovatarDustCollectible.FlovatarDustCollectibleData]) {
    self.address = address
    self.flovatars = []
    self.components = []
    self.flovatarSales = []
    self.componentSales = []
    self.collectibles = []
    self.packs = []
  }
}

access(all) fun main(address:Address) : Collections {
    let collectibles = FlovatarDustCollectible.getCollectibles(address: address)

    return Collections(address, collectibles)
}