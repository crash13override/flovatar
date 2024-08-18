import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function getClaimablesByNameScript(name) {
    if (name == null) return null

    return await fcl
        .query({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace, FlovatarInbox from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken
import FIND from 0xFind
import HybridCustody from 0xHybridCustody

pub struct Claimables {

  pub(set) var address: Address
  pub(set) var ownerAddress: Address?
  pub(set) var childAddresses: [Address]
  pub(set) var flovatarComponents: [UInt64]
  pub(set) var flovatarsWithDust: [UInt64]
  pub(set) var childFlovatarsWithDust: [UInt64]
  pub(set) var childFlovatarsWithDustAddress: [Address]
  pub(set) var walletComponents: [UInt64]
  pub(set) var flovatarDust: UFix64
  pub(set) var walletDust: UFix64
  pub(set) var flovatarCommunityDust: UFix64
  init (_ address:Address) {
    self.address = address
    self.ownerAddress = nil
    self.childAddresses = []
    self.flovatarComponents = []
    self.flovatarsWithDust = []
    self.childFlovatarsWithDust = []
    self.childFlovatarsWithDustAddress = []
    self.walletComponents = []
    self.flovatarDust = 0.0
    self.walletDust = 0.0
    self.flovatarCommunityDust = 0.0
  }
}

pub fun main(name: String) : Claimables {

    let address = FIND.lookupAddress(name)!
    // get the accounts' public address objects
    let status = Claimables(address)
    let account = getAccount(address)
    let authAccount = getAuthAccount(address)

    if let flovatarCollection = account.getCapability(Flovatar.CollectionPublicPath).borrow<&{Flovatar.CollectionPublic}>()  {
        for id in flovatarCollection.getIDs() {
            let flovatarDustBalance = FlovatarInbox.getFlovatarDustBalance(id: id)
            status.flovatarDust = status.flovatarDust + flovatarDustBalance
            if(flovatarDustBalance > UFix64(0.0)){
                status.flovatarsWithDust.append(id)
            }
            if let claimableCommunityDust = FlovatarInbox.getClaimableFlovatarCommunityDust(id: id, address: address) {
                status.flovatarCommunityDust = status.flovatarCommunityDust + claimableCommunityDust.amount
                if(claimableCommunityDust.amount > UFix64(0.0)){
                    status.flovatarsWithDust.append(id)
                }
            }
            status.flovatarComponents = status.flovatarComponents.concat(FlovatarInbox.getFlovatarComponentIDs(id: id))
        }
    }

    if let manager = authAccount.borrow<&HybridCustody.Manager>(from: HybridCustody.ManagerStoragePath) {
        status.childAddresses = manager.getChildAddresses()
        for childAddress in status.childAddresses {
            let tempAccount = getAccount(childAddress)
            if let flovatarChildCollection = tempAccount.getCapability(Flovatar.CollectionPublicPath).borrow<&{Flovatar.CollectionPublic}>()  {
                for id in flovatarChildCollection.getIDs() {
                    if let claimableCommunityDust = FlovatarInbox.getClaimableFlovatarCommunityDust(id: id, address: childAddress) {
                        status.flovatarCommunityDust = status.flovatarCommunityDust + claimableCommunityDust.amount
                        if(claimableCommunityDust.amount > UFix64(0.0)){
                            status.childFlovatarsWithDust.append(id)
                            status.childFlovatarsWithDustAddress.append(childAddress)
                        }
                    }
                }
            }
        }
    }


    if let o = authAccount.borrow<&HybridCustody.OwnedAccount>(from: HybridCustody.OwnedAccountStoragePath) {
        let parentAddr: [Address] = o.getParentAddresses()
        if parentAddr.length > 0 {
            status.ownerAddress = parentAddr[0]
        }
    }

    status.walletComponents = FlovatarInbox.getWalletComponentIDs(address: address)
    status.walletDust = FlovatarInbox.getWalletDustBalance(address: address)

    return status
}
`,
            args: (arg, t) => [
                arg(name, t.String)
            ],
        });
}
