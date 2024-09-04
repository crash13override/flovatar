import "FlovatarDustCollectible"
import "NonFungibleToken"

transaction(
    collectibleId: UInt64,
    address: Address) {

    let collectibleCollection: auth(NonFungibleToken.Withdraw) &FlovatarDustCollectible.Collection
    let collectibleReceiverCollection: Capability<&{FlovatarDustCollectible.CollectionPublic}>

    prepare(account: auth(Storage) &Account) {
        self.collectibleCollection = account.storage.borrow<auth(NonFungibleToken.Withdraw) &FlovatarDustCollectible.Collection>(from: FlovatarDustCollectible.CollectionStoragePath)!


        let receiverAccount = getAccount(address)
        self.collectibleReceiverCollection = receiverAccount.capabilities.get<&{FlovatarDustCollectible.CollectionPublic}>(FlovatarDustCollectible.CollectionPublicPath)
    }

    execute {
        let collectible <- self.collectibleCollection.withdraw(withdrawID: collectibleId)
        if(collectible == nil){
            panic("Collectible not found!")
        }
        self.collectibleReceiverCollection.borrow()!.deposit(token: <-collectible)
    }
}