import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FUSD from "../../contracts/FUSD.cdc"
import Flovatar from "../../contracts/Flovatar.cdc"
import FlovatarComponent from "../../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../../contracts/FlovatarPack.cdc"
import Marketplace from "../../contracts/Marketplace.cdc"


//this transaction will send a Pack to an address
transaction(packId: UInt64, address: Address) {
    
    let flovatarPackCollection: &FlovatarPack.Collection
    let flovatarPackReceiverCollection: Capability<&{FlovatarPack.CollectionPublic}>

    prepare(account: AuthAccount) {
        self.flovatarPackCollection = account.borrow<&FlovatarPack.Collection>(from: FlovatarPack.CollectionStoragePath)!


        let receiverAccount = getAccount(address)
        self.flovatarPackReceiverCollection = receiverAccount.getCapability<&{FlovatarPack.CollectionPublic}>(FlovatarPack.CollectionPublicPath)
    }

    execute {
        let pack <- self.flovatarPackCollection.withdraw(withdrawID: packId)
        if(pack == nil){
            panic("Pack not found!")
        }
        self.flovatarPackReceiverCollection.borrow()!.deposit(token: <-pack)
    }
}