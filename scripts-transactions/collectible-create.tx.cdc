import "FlovatarDustToken"
import "FlovatarDustCollectible"
import "FungibleToken"

//this transaction will create a new Webshot and create and auction for it
transaction(
    series: UInt64,
    layers: [UInt32],
    templates: [UInt64?],
    amount: UFix64
    ){

    let flovatarCollectibleCollection: &FlovatarDustCollectible.Collection
    let temporaryVault: @{FungibleToken.Vault}

    let accountAddress: Address

    prepare(account: auth(Storage) &Account) {
        self.flovatarCollectibleCollection = account.storage.borrow<&FlovatarDustCollectible.Collection>(from: FlovatarDustCollectible.CollectionStoragePath)!
        self.accountAddress = account.address


        let vaultRef = account.storage.borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Provider}>(from: FlovatarDustToken.VaultStoragePath) ?? panic("Could not borrow owner's Vault reference")
        // withdraw tokens from the buyer's Vault
        self.temporaryVault <- vaultRef.withdraw(amount: amount)
    }

    execute {

        let collectible <- FlovatarDustCollectible.createDustCollectible(
            series: series,
            layers: layers,
            templateIds: templates,
            address: self.accountAddress,
            vault: <-self.temporaryVault
        )

        self.flovatarCollectibleCollection.deposit(token: <-collectible)
    }
}