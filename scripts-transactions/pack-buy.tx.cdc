
import "FlovatarPack"
import "FlovatarDustToken"
import "FungibleToken" 
import "FlowToken" 

//this transaction buy a Pack
transaction(saleAddress: Address, tokenId: UInt64, amount: UFix64, signature: String) {

    // reference to the buyer's NFT collection where they
    // will store the bought NFT

    let vaultCap: Capability<&FlovatarDustToken.Vault>
    let collectionCap: Capability<&{FlovatarPack.CollectionPublic}>
    // Vault that will hold the tokens that will be used
    // to buy the NFT
    let temporaryVault: @{FungibleToken.Vault}

    prepare(account: auth(Storage, Capabilities) &Account) {

        let flovatarPackCap = account.capabilities.get<&FlovatarPack.Collection>(FlovatarPack.CollectionPublicPath)
        if(!flovatarPackCap.check()) {
            let wallet =  account.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)
            account.storage.save<@FlovatarPack.Collection>(<- FlovatarPack.createEmptyCollection(ownerVault: wallet), to: FlovatarPack.CollectionStoragePath)

            // create a public capability for the collection
            account.capabilities.unpublish(FlovatarPack.CollectionPublicPath)
            account.capabilities.publish(
                account.capabilities.storage.issue<&FlovatarPack.Collection>(FlovatarPack.CollectionStoragePath),
                at: FlovatarPack.CollectionPublicPath
            )
        }


        self.collectionCap = flovatarPackCap

        self.vaultCap = account.capabilities.get<&FlovatarDustToken.Vault>(FlovatarDustToken.VaultReceiverPath)

        let vaultRef = account.storage.borrow<auth(FungibleToken.Withdraw) &FlovatarDustToken.Vault>(from: FlovatarDustToken.VaultStoragePath) ?? panic("Could not borrow owner's Vault reference")

        // withdraw tokens from the buyer's Vault
        self.temporaryVault <- vaultRef.withdraw(amount: amount)
    }

    execute {
        // get the read-only account storage of the seller
        let seller = getAccount(saleAddress)

        let packmarket = seller.capabilities.borrow<&{FlovatarPack.CollectionPublic}>(FlovatarPack.CollectionPublicPath)
                         ?? panic("Could not borrow seller's sale reference")

        packmarket.purchaseWithDust(tokenId: tokenId, recipientCap: self.collectionCap, buyTokens: <- self.temporaryVault, signature: signature)
    }

}