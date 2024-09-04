import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"
import Flovatar from "../../contracts/Flovatar.cdc"
import FlovatarComponent from "../../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../../contracts/FlovatarPack.cdc"
import FlovatarMarketplace from "../../contracts/FlovatarMarketplace.cdc"
import FlovatarDustCollectible from "../../contracts/FlovatarDustCollectible.cdc"
import FlovatarDustCollectibleTemplate from "../../contracts/FlovatarDustCollectibleTemplate.cdc"
import FlovatarDustCollectibleAccessory from "../../contracts/FlovatarDustCollectibleAccessory.cdc"


transaction(templateId: UInt64, quantity: UInt64) {


    let flovatarDustAccessoryCollection: &FlovatarDustCollectibleAccessory.Collection
    let flovatarAdmin: &FlovatarDustCollectible.Admin

    prepare(account: AuthAccount) {
        self.flovatarDustAccessoryCollection = account.borrow<&FlovatarDustCollectibleAccessory.Collection>(from: FlovatarDustCollectibleAccessory.CollectionStoragePath)!

        self.flovatarAdmin = account.borrow<&FlovatarDustCollectible.Admin>(from: FlovatarDustCollectible.AdminStoragePath)!
    }

    execute {
        let collection <- self.flovatarAdmin.batchCreateCollectibles(templateId: templateId, quantity: quantity) as! @FlovatarDustCollectibleAccessory.Collection

        for id in collection.getIDs() {
            self.flovatarDustAccessoryCollection.deposit(token: <- collection.withdraw(withdrawID: id))
        }

        destroy collection

    }
}