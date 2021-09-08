import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FUSD from "../../contracts/FUSD.cdc"
import Flovatar from "../../contracts/Flovatar.cdc"
import FlovatarComponent from "../../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../../contracts/FlovatarPack.cdc"
import Marketplace from "../../contracts/Marketplace.cdc"


//this transaction will open a Pack from the Collection
transaction(packId: UInt64) {
    
    let flovatarPackCollection: &FlovatarPack.Collection

    prepare(account: AuthAccount) {
        self.flovatarPackCollection = account.borrow<&FlovatarPack.Collection>(from: FlovatarPack.CollectionStoragePath)!
    }

    execute {
        self.flovatarPackCollection.openPack(id: packId)
    }
}