import "Flovatar"
import "FlovatarInbox" 

//this transaction will claim all content of the Inbox
transaction() {

    let flovatarCollection: &Flovatar.Collection
    let address: Address

    prepare(account: auth(Storage) &Account) {
        self.flovatarCollection = account.storage.borrow<&Flovatar.Collection>(from: Flovatar.CollectionStoragePath)!
        self.address = account.address

    }

    execute {


        FlovatarInbox.withdrawWalletComponent(address: self.address)

        var count: UInt32 = 0
        for id in self.flovatarCollection.getIDs() {
             if(FlovatarInbox.getFlovatarComponentIDs(id: id).length > Int(0) && count < UInt32(20)){
                FlovatarInbox.withdrawFlovatarComponent(id: id, address: self.address)
                count = count + UInt32(1)
            }
        }
    }
}