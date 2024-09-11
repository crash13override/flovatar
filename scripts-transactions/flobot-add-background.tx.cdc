import "FlovatarComponent"
import "Flobot"
import "NonFungibleToken"

//this transaction will add a new Background to an existing Flobot
transaction(
    flobotId: UInt64,
    background: UInt64
    ) {

    let flobotCollection: auth(Flobot.PrivateEnt) &Flobot.Collection
    let flovatarComponentCollection: auth(NonFungibleToken.Withdraw) &FlovatarComponent.Collection

    let backgroundNFT: @FlovatarComponent.NFT


    prepare(account: auth(Storage) &Account) {
        self.flobotCollection = account.storage.borrow<auth(Flobot.PrivateEnt) &Flobot.Collection>(from: Flobot.CollectionStoragePath)!

        self.flovatarComponentCollection = account.storage.borrow<auth(NonFungibleToken.Withdraw) &FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!

        self.backgroundNFT <- self.flovatarComponentCollection.withdraw(withdrawID: background) as! @FlovatarComponent.NFT
    }

    execute {

        let flobot= self.flobotCollection.borrowFlobotPrivate(id: flobotId)!

        let background <-flobot.setBackground(component: <-self.backgroundNFT)
        if(background != nil){
            self.flovatarComponentCollection.deposit(token: <-background!)
        } else {
            destroy background
        }
    }
}