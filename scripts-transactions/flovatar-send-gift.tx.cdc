
import "NonFungibleToken"
import "Flovatar"

transaction(
    flovatarId: UInt64,
    address: Address) {

    let flovatarCollection: auth(NonFungibleToken.Withdraw) &Flovatar.Collection
    let flovatarReceiverCollection: Capability<&{Flovatar.CollectionPublic}>

    prepare(account: auth(Storage) &Account) {
        self.flovatarCollection = account.storage.borrow<auth(NonFungibleToken.Withdraw) &Flovatar.Collection>(from: Flovatar.CollectionStoragePath)!


        let receiverAccount = getAccount(address)
        self.flovatarReceiverCollection = receiverAccount.capabilities.get<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath)
    }

    execute {
        let flovatar <- self.flovatarCollection.withdraw(withdrawID: flovatarId)
        if(flovatar == nil){
            panic("Flovatar not found!")
        }
        self.flovatarReceiverCollection.borrow()!.deposit(token: <-flovatar)
    }
}