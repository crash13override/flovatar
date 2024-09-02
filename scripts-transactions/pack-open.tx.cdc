import "FlovatarPack"

transaction(packId: UInt64) {

    let flovatarPackCollection: auth(FlovatarPack.WithdrawEnt) &FlovatarPack.Collection

    prepare(account: auth(Storage) &Account) {
        self.flovatarPackCollection = account.storage.borrow<auth(FlovatarPack.WithdrawEnt) &FlovatarPack.Collection>(from: FlovatarPack.CollectionStoragePath)!
    }

    execute {
        self.flovatarPackCollection.openPack(id: packId)
    }

}
