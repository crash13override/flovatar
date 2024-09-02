import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function getFlovatarClaimablesScript(address, id) {
    if (address == null) return null

    return await fcl
        .query({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace, FlovatarInbox from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

access(all) struct Claimables {

  access(all) var address: Address
  access(all) var flovatarComponents: [UInt64]
  access(all) var walletComponents: [UInt64]
  access(all) var flovatarDust: UFix64
  access(all) var walletDust: UFix64
  access(all) var flovatarCommunityDust: UFix64
  init (_ address:Address, _ flovatarComponents: [UInt64], _ walletComponents: [UInt64], _ flovatarDust: UFix64, _ walletDust: UFix64, _ flovatarCommunityDust: UFix64) {
    self.address = address
    self.flovatarComponents = []
    self.walletComponents = []
    self.flovatarDust = 0.0
    self.walletDust = 0.0
    self.flovatarCommunityDust = 0.0
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
`,
            args: (arg, t) => [
                arg(address, t.Address),
                arg(''+id, t.UInt64)
            ],
        });

}
