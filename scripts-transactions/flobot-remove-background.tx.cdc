import "Flobot"
import "FlovatarComponent"

//this transaction will remove the Background from an existing Flobot
transaction(
    flobotId: UInt64
    ) {

    let flobotCollection: &Flobot.Collection
    let flovatarComponentCollection: &FlovatarComponent.Collection


    prepare(account: auth(Storage) &Account) {
        self.flobotCollection = account.storage.borrow<&Flobot.Collection>(from: Flobot.CollectionStoragePath)!

        self.flovatarComponentCollection = account.storage.borrow<&FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!
    }

    execute {

        let flobot = self.flobotCollection.borrowFlobot(id: flobotId)! as! auth(Flobot.PrivateEnt) &Flobot.NFT

        let background <-flobot.removeBackground()
        if(background != nil){
            self.flovatarComponentCollection.deposit(token: <-background!)
        } else {
            destroy background
        }
    }
}