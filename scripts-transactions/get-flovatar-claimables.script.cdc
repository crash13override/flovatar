
import "Flovatar"
import "FlovatarInbox"

access(all) struct Claimables {

  access(all) var address: Address
  access(all) var flovatarComponents: [UInt64]
  access(all) var walletComponents: [UInt64]
  access(all) var flovatarDust: UFix64
  access(all) var walletDust: UFix64
  access(all) var flovatarCommunityDust: UFix64
  init (_ address:Address, _ flovatarComponents: [UInt64], _ walletComponents: [UInt64], _ flovatarDust: UFix64, _ walletDust: UFix64, _ flovatarCommunityDust: UFix64) {
    self.address = address
    self.flovatarComponents = flovatarComponents
    self.walletComponents = walletComponents
    self.flovatarDust = flovatarDust
    self.walletDust = walletDust
    self.flovatarCommunityDust = flovatarCommunityDust
  }
}

access(all) fun main(address:Address, id: UInt64) : Claimables {
    // get the accounts' public address objects
    let account = getAccount(address)
    var flovatarComponents: [UInt64] = []
    var walletComponents: [UInt64] = []
    var flovatarDust: UFix64 = 0.0
    var walletDust: UFix64 = 0.0
    var flovatarCommunityDust: UFix64 = 0.0

    if let flovatarCollection = account.capabilities.borrow<&Flovatar.Collection>(Flovatar.CollectionPublicPath)  {
        flovatarDust = FlovatarInbox.getFlovatarDustBalance(id: id)
        if let claimableCommunityDust = FlovatarInbox.getClaimableFlovatarCommunityDust(id: id, address: address) {
            flovatarCommunityDust = claimableCommunityDust.amount
        }
        flovatarComponents = flovatarComponents.concat(FlovatarInbox.getFlovatarComponentIDs(id: id))
    }

    return Claimables(address, flovatarComponents, walletComponents, flovatarDust, walletDust, flovatarCommunityDust)
}