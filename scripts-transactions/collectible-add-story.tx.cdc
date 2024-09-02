import "FlovatarDustToken"
import "FlovatarDustCollectible"
import "FungibleToken"

//this transaction will add a Story to an existing Flovatar
transaction(
    collectibleId: UInt64,
    text: String
    ) {

    let collectibleCollection: &FlovatarDustCollectible.Collection
    let temporaryVault: @{FungibleToken.Vault}

    prepare(account: auth(Storage) &Account) {
        self.collectibleCollection = account.storage.borrow<&FlovatarDustCollectible.Collection>(from: FlovatarDustCollectible.CollectionStoragePath)!

        let vaultRef = account.storage.borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Provider}>(from: FlovatarDustToken.VaultStoragePath) ?? panic("Could not borrow owner's Vault reference")

        // withdraw tokens from the buyer's Vault
        self.temporaryVault <- vaultRef.withdraw(amount: 50.0)
    }

    execute {

        let collectible = self.collectibleCollection.borrowDustCollectible(id: collectibleId)! as! auth(FlovatarDustCollectible.PrivateEnt) &FlovatarDustCollectible.NFT

        collectible.addStory(text: text, vault: <- self.temporaryVault)
    }
}