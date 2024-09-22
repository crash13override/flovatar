import "Flovatar"
import "FlovatarComponent"
import "NonFungibleToken"

//this transaction will add a new Hat to an existing Flovatar
transaction(
    flovatarId: UInt64,
    hat: UInt64
    ) {

    let flovatarCollection: auth(Flovatar.PrivateEnt) &Flovatar.Collection
    let flovatarComponentCollection: auth(NonFungibleToken.Withdraw) &FlovatarComponent.Collection

    let hatNFT: @FlovatarComponent.NFT

    prepare(account: auth(Storage) &Account) {
        self.flovatarCollection = account.storage.borrow<auth(Flovatar.PrivateEnt) &Flovatar.Collection>(from: Flovatar.CollectionStoragePath)!

        self.flovatarComponentCollection = account.storage.borrow<auth(NonFungibleToken.Withdraw) &FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!

        self.hatNFT <- self.flovatarComponentCollection.withdraw(withdrawID: hat) as! @FlovatarComponent.NFT
    }

    execute {

        let flovatar = self.flovatarCollection.borrowFlovatarPrivate(id: flovatarId)!

        let hat <-flovatar.setHat(component: <-self.hatNFT)
        if(hat != nil){
            self.flovatarComponentCollection.deposit(token: <-hat!)
        } else {
            destroy hat
        }
    }
}