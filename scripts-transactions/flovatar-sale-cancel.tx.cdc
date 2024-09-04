import "Flovatar"
import "FlovatarMarketplace"
import "NonFungibleToken"
import "FungibleToken"
import "FlowToken"


transaction(
    flovatarId: UInt64
    ) {

    let flovatarCollection: &Flovatar.Collection
    let marketplace: auth(FlovatarMarketplace.Withdraw) &FlovatarMarketplace.SaleCollection

    prepare(account: auth(Storage, Capabilities) &Account) {

        let marketplaceCap = account.capabilities.get<&FlovatarMarketplace.SaleCollection>(FlovatarMarketplace.CollectionPublicPath)
        // if sale collection is not created yet we make it.
        if !marketplaceCap.check() {
             let wallet =  account.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)
             let sale <- FlovatarMarketplace.createSaleCollection(ownerVault: wallet)

            // store an empty NFT Collection in account storage
            account.storage.save<@FlovatarMarketplace.SaleCollection>(<- sale, to:FlovatarMarketplace.CollectionStoragePath)

            // publish a capability to the Collection in storage
            account.capabilities.unpublish(FlovatarMarketplace.CollectionPublicPath)
            account.capabilities.publish(
                account.capabilities.storage.issue<&FlovatarMarketplace.SaleCollection>(FlovatarMarketplace.CollectionStoragePath),
                at: FlovatarMarketplace.CollectionPublicPath
            )
        }

        self.marketplace = account.storage.borrow<auth(FlovatarMarketplace.Withdraw) &FlovatarMarketplace.SaleCollection>(from: FlovatarMarketplace.CollectionStoragePath)!
        self.flovatarCollection = account.storage.borrow<&Flovatar.Collection>(from: Flovatar.CollectionStoragePath)!
    }

    execute {
        let flovatar <- self.marketplace.withdrawFlovatar(tokenId: flovatarId)
        self.flovatarCollection.deposit(token: <- flovatar);
    }
}