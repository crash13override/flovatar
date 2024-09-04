import "FlovatarComponent"
import "NonFungibleToken"

transaction(
    componentId: UInt64,
    address: Address) {

    let flovatarComponentCollection: auth(NonFungibleToken.Withdraw) &FlovatarComponent.Collection
    let flovatarComponentReceiverCollection: Capability<&{FlovatarComponent.CollectionPublic}>

    prepare(account: auth(Storage) &Account) {
        self.flovatarComponentCollection = account.storage.borrow<auth(NonFungibleToken.Withdraw) &FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!

        let receiverAccount = getAccount(address)
        self.flovatarComponentReceiverCollection = receiverAccount.capabilities.get<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath)
    }

    execute {
        let component <- self.flovatarComponentCollection.withdraw(withdrawID: componentId)
        if(component == nil){
            panic("Component not found!")
        }
        self.flovatarComponentReceiverCollection.borrow()!.deposit(token: <-component)
    }
}