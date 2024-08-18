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

pub struct Claimables {

  pub(set) var address: Address
  pub(set) var flovatarComponents: [UInt64]
  pub(set) var walletComponents: [UInt64]
  pub(set) var flovatarDust: UFix64
  pub(set) var walletDust: UFix64
  pub(set) var flovatarCommunityDust: UFix64
  init (_ address:Address) {
    self.address = address
    self.flovatarComponents = []
    self.walletComponents = []
    self.flovatarDust = 0.0
    self.walletDust = 0.0
    self.flovatarCommunityDust = 0.0
  }
}

pub fun main(address:Address, id: UInt64) : Claimables {
    // get the accounts' public address objects
    let status = Claimables(address)
    let account = getAccount(address)

    if let flovatarCollection = account.getCapability(Flovatar.CollectionPublicPath).borrow<&Flovatar.Collection{Flovatar.CollectionPublic}>()  {
        status.flovatarDust = FlovatarInbox.getFlovatarDustBalance(id: id)
        if let claimableCommunityDust = FlovatarInbox.getClaimableFlovatarCommunityDust(id: id, address: address) {
            status.flovatarCommunityDust = claimableCommunityDust.amount
        }
        status.flovatarComponents = status.flovatarComponents.concat(FlovatarInbox.getFlovatarComponentIDs(id: id))
    }

    return status
}
`,
            args: (arg, t) => [
                arg(address, t.Address),
                arg(''+id, t.UInt64)
            ],
        });

}
