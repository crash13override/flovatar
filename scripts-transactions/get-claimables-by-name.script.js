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

access(all) struct Claimables {

    access(all) var address: Address
    access(all) var ownerAddress: Address?
    access(all) var childAddresses: [Address]
    access(all) var flovatarComponents: [UInt64]
    access(all) var flovatarsWithDust: [UInt64]
    access(all) var childFlovatarsWithDust: [UInt64]
    access(all) var childFlovatarsWithDustAddress: [Address]
    access(all) var walletComponents: [UInt64]
    access(all) var flovatarDust: UFix64
    access(all) var walletDust: UFix64
    access(all) var flovatarCommunityDust: UFix64
  init (_ address:Address, _ ownerAddress: Address?, _ childAddresses: [Address], _ flovatarComponents: [UInt64], _ flovatarsWithDust: [UInt64], _ childFlovatarsWithDust: [UInt64], _ childFlovatarsWithDustAddress: [Address], _ walletComponents: [UInt64], _ flovatarDust: UFix64, _ walletDust: UFix64, _ flovatarCommunityDust: UFix64) {
    self.address = address
    self.ownerAddress = ownerAddress
    self.childAddresses = childAddresses
    self.flovatarComponents = flovatarComponents
    self.flovatarsWithDust = flovatarsWithDust
    self.childFlovatarsWithDust = childFlovatarsWithDust
    self.childFlovatarsWithDustAddress = childFlovatarsWithDustAddress
    self.walletComponents = walletComponents
    self.flovatarDust = flovatarDust
    self.walletDust = walletDust
    self.flovatarCommunityDust = flovatarCommunityDust
  }
}

access(all) fun main(name: String) : Claimables {

    let address = FIND.lookupAddress(name)!
    // get the accounts' public address objects
    let account = getAccount(address)
    let authAccount =  getAuthAccount<auth(Storage) &Account>(address)


    var ownerAddress: Address? = nil
    var childAddresses: [Address] = []
    var flovatarComponents: [UInt64] = []
    var flovatarsWithDust: [UInt64] = []
    var childFlovatarsWithDust: [UInt64] = []
    var childFlovatarsWithDustAddress: [Address] = []
    var walletComponents: [UInt64] = []
    var flovatarDust: UFix64 = 0.0
    var walletDust: UFix64 = 0.0
    var flovatarCommunityDust: UFix64 = 0.0

    if let flovatarCollection = account.capabilities.borrow<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath)  {
        for id in flovatarCollection.getIDs() {
            let flovatarDustBalance = FlovatarInbox.getFlovatarDustBalance(id: id)
            flovatarDust = flovatarDust + flovatarDustBalance
            if(flovatarDustBalance > UFix64(0.0)){
                flovatarsWithDust.append(id)
            }
            if let claimableCommunityDust = FlovatarInbox.getClaimableFlovatarCommunityDust(id: id, address: address) {
                flovatarCommunityDust = flovatarCommunityDust + claimableCommunityDust.amount
                if(claimableCommunityDust.amount > UFix64(0.0)){
                    flovatarsWithDust.append(id)
                }
            }
            flovatarComponents = flovatarComponents.concat(FlovatarInbox.getFlovatarComponentIDs(id: id))
        }
    }

    if let manager = authAccount.storage.borrow<&HybridCustody.Manager>(from: HybridCustody.ManagerStoragePath) {
        childAddresses = manager.getChildAddresses()
        for childAddress in childAddresses {
            let tempAccount = getAccount(childAddress)
            if let flovatarChildCollection = tempAccount.capabilities.borrow<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath)  {
                for id in flovatarChildCollection.getIDs() {
                    if let claimableCommunityDust = FlovatarInbox.getClaimableFlovatarCommunityDust(id: id, address: childAddress) {
                        flovatarCommunityDust = flovatarCommunityDust + claimableCommunityDust.amount
                        if(claimableCommunityDust.amount > UFix64(0.0)){
                            childFlovatarsWithDust.append(id)
                            childFlovatarsWithDustAddress.append(childAddress)
                        }
                    }
                }
            }
        }
    }


    if let o = authAccount.storage.borrow<&HybridCustody.OwnedAccount>(from: HybridCustody.OwnedAccountStoragePath) {
        let parentAddr: [Address] = o.getParentAddresses()
        if parentAddr.length > 0 {
            ownerAddress = parentAddr[0]
        }
    }

    walletComponents = FlovatarInbox.getWalletComponentIDs(address: address)
    walletDust = FlovatarInbox.getWalletDustBalance(address: address)

    return Claimables(address, ownerAddress, childAddresses, flovatarComponents, flovatarsWithDust, childFlovatarsWithDust, childFlovatarsWithDustAddress, walletComponents, flovatarDust, walletDust, flovatarCommunityDust)
}
`,
            args: (arg, t) => [
                arg(name, t.String)
            ],
        });
}
