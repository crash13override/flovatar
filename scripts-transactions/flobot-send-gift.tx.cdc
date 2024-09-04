import "NonFungibleToken"
import "Flobot"

transaction(
    flobotId: UInt64,
    address: Address) {

    let flobotCollection: auth(NonFungibleToken.Withdraw) &Flobot.Collection
    let flobotReceiverCollection: Capability<&{Flobot.CollectionPublic}>

    prepare(account: auth(Storage) &Account) {
        self.flobotCollection = account.storage.borrow<auth(NonFungibleToken.Withdraw) &Flobot.Collection>(from: Flobot.CollectionStoragePath)!


        let receiverAccount = getAccount(address)
        self.flobotReceiverCollection = receiverAccount.capabilities.get<&{Flobot.CollectionPublic}>(Flobot.CollectionPublicPath)
    }

    execute {
        let flobot <- self.flobotCollection.withdraw(withdrawID: flobotId)
        if(flobot == nil){
            panic("Flobot not found!")
        }
        self.flobotReceiverCollection.borrow()!.deposit(token: <-flobot)
    }
}