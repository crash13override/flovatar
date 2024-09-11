import "FlovatarDustToken"
import "FlovatarDustCollectible"
import "FungibleToken"

//this transaction will set the name to an existing Flovatar
transaction(
    collectibleId: UInt64,
    latitude: Fix64,
    longitude: Fix64
    ) {

    let collectibleCollection: auth(FlovatarDustCollectible.PrivateEnt) &FlovatarDustCollectible.Collection
    let temporaryVault: @{FungibleToken.Vault}

    prepare(account: auth(Storage) &Account) {
        self.collectibleCollection = account.storage.borrow<auth(FlovatarDustCollectible.PrivateEnt) &FlovatarDustCollectible.Collection>(from: FlovatarDustCollectible.CollectionStoragePath)!

        let vaultRef = account.storage.borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Provider}>(from: FlovatarDustToken.VaultStoragePath) ?? panic("Could not borrow owner's Vault reference")

        // withdraw tokens from the buyer's Vault
        self.temporaryVault <- vaultRef.withdraw(amount: 10.0)
    }

    execute {

        let collectible = self.collectibleCollection.borrowDustCollectible(id: collectibleId)!

        collectible.setPosition(latitude: latitude, longitude: longitude, vault: <- self.temporaryVault)
    }
}