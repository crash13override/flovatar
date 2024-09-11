import "Flovatar"
import "FlovatarComponent"

//this transaction will remove the Accessory from an existing Flovatar
transaction(
    flovatarId: UInt64
    ) {

    let flovatarCollection: auth(Flovatar.PrivateEnt) &Flovatar.Collection
    let flovatarComponentCollection: &FlovatarComponent.Collection


    prepare(account: auth(Storage) &Account) {
        self.flovatarCollection = account.storage.borrow<auth(Flovatar.PrivateEnt) &Flovatar.Collection>(from: Flovatar.CollectionStoragePath)!

        self.flovatarComponentCollection = account.storage.borrow<&FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!
    }

    execute {

        let flovatar = self.flovatarCollection.borrowFlovatarPrivate(id: flovatarId)!

        let accessory <-flovatar.removeAccessory()
        if(accessory != nil){
            self.flovatarComponentCollection.deposit(token: <-accessory!)
        } else {
            destroy accessory
        }
    }
}