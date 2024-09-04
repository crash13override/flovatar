
import "Flovatar"
import "FlovatarComponent"
import "FlovatarPack"
import "FlovatarMarketplace"

access(all) struct Collections {

  access(all) var address: Address
  access(all) var flovatars: [Flovatar.FlovatarData]
  access(all) var components: [FlovatarComponent.ComponentData]
  access(all) var flovatarSales: [FlovatarMarketplace.FlovatarSaleData]
  access(all) var componentSales: [FlovatarMarketplace.FlovatarComponentSaleData]
  access(all) var packs: [UInt64]
  init (_ address:Address, _ packs: [UInt64]) {
    self.address = address
    self.flovatars = []
    self.components = []
    self.flovatarSales = []
    self.componentSales = []
    self.packs = packs
  }
}

access(all) fun main(address:Address) : Collections {
    let account = getAccount(address)

    let packs = FlovatarPack.getPacks(address: address) ?? []

    return Collections(address, packs)
}