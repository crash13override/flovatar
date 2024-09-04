import "Flovatar"
import "FlovatarComponent"
import "NonFungibleToken"

//this transaction will add a new pair of Eyeglasses to an existing Flovatar
transaction(
    flovatarId: UInt64,
    eyeglasses: UInt64
    ) {

    let flovatarCollection: &Flovatar.Collection
    let flovatarComponentCollection: auth(NonFungibleToken.Withdraw) &FlovatarComponent.Collection

    let eyeglassesNFT: @FlovatarComponent.NFT

    prepare(account: auth(Storage) &Account) {
        self.flovatarCollection = account.storage.borrow<&Flovatar.Collection>(from: Flovatar.CollectionStoragePath)!

        self.flovatarComponentCollection = account.storage.borrow<auth(NonFungibleToken.Withdraw) &FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!

        self.eyeglassesNFT <- self.flovatarComponentCollection.withdraw(withdrawID: eyeglasses) as! @FlovatarComponent.NFT
    }

    execute {

        let flovatar = self.flovatarCollection.borrowFlovatar(id: flovatarId)! as! auth(Flovatar.PrivateEnt) &Flovatar.NFT

        let eyeglasses <-flovatar.setEyeglasses(component: <-self.eyeglassesNFT)
        if(eyeglasses != nil){
            self.flovatarComponentCollection.deposit(token: <-eyeglasses!)
        } else {
            destroy eyeglasses
        }
    }
}