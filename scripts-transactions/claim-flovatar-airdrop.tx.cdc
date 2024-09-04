import "Flovatar"
import "FlovatarInbox" 

//this transaction will claim all content of the Inbox
transaction(id: UInt64) {

    let flovatarCollection: &Flovatar.Collection
    let address: Address

    prepare(account: auth(Storage) &Account) {
        self.flovatarCollection = account.storage.borrow<&Flovatar.Collection>(from: Flovatar.CollectionStoragePath)!
        self.address = account.address

    }

    execute {

        FlovatarInbox.withdrawFlovatarComponent(id: id, address: self.address)
        FlovatarInbox.withdrawFlovatarDust(id: id, address: self.address)

    }
}