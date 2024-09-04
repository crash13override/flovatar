import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"
import Flovatar from "../../contracts/Flovatar.cdc"
import FlovatarComponent from "../../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../../contracts/FlovatarPack.cdc"
import FlovatarMarketplace from "../../contracts/FlovatarMarketplace.cdc"


transaction(templateId: UInt64, quantity: UInt64) {

    let flovatarComponentCollection: &FlovatarComponent.Collection
    let flovatarAdmin: &Flovatar.Admin

    prepare(account: AuthAccount) {
        self.flovatarComponentCollection = account.borrow<&FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!

        self.flovatarAdmin = account.borrow<&Flovatar.Admin>(from: Flovatar.AdminStoragePath)!
    }

    execute {
        let collection <- self.flovatarAdmin.batchCreateComponents(templateId: templateId, quantity: quantity) as! @FlovatarComponent.Collection

        for id in collection.getIDs() {
            self.flovatarComponentCollection.deposit(token: <- collection.withdraw(withdrawID: id))
        }

        destroy collection

    }
}