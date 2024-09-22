import "Flovatar"
import "FlovatarComponent"
import "NonFungibleToken"

//this transaction will add a new Accessory to an existing Flovatar
transaction(
    flovatarId: UInt64,
    accessory: UInt64
    ) {

    let flovatarCollection: auth(Flovatar.PrivateEnt) &Flovatar.Collection
    let flovatarComponentCollection: auth(NonFungibleToken.Withdraw) &FlovatarComponent.Collection

    let accessoryNFT: @FlovatarComponent.NFT

    prepare(account: auth(Storage) &Account) {
        self.flovatarCollection = account.storage.borrow<auth(Flovatar.PrivateEnt) &Flovatar.Collection>(from: Flovatar.CollectionStoragePath)!

        self.flovatarComponentCollection = account.storage.borrow<auth(NonFungibleToken.Withdraw) &FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!

        self.accessoryNFT <- self.flovatarComponentCollection.withdraw(withdrawID: accessory) as! @FlovatarComponent.NFT
    }

    execute {

        let flovatar = self.flovatarCollection.borrowFlovatarPrivate(id: flovatarId)!

        let accessory <-flovatar.setAccessory(component: <-self.accessoryNFT)
        if(accessory != nil){
            self.flovatarComponentCollection.deposit(token: <-accessory!)
        } else {
            destroy accessory
        }
    }
}