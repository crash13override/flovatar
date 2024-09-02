
import "FlovatarPack"
import "FlovatarDustToken"
import "FungibleToken" 
import "FlowUtilityToken"
import "FlowToken" 

transaction(storefrontAddress: Address, listingResourceID: UInt64, expectedPrice: UFix64, signature: String, flovatarAddress: Address) {
    let paymentVault: @{FungibleToken.Vault}
    let buyerFlovatarPackCollection: Capability<&{FlovatarPack.CollectionPublic}>
    let balanceBeforeTransfer: UFix64
    let mainDucVault: auth(FungibleToken.Withdraw) &FlowUtilityToken.Vault

    prepare(dapper: auth(Storage) &Account, buyer: auth(Storage, Capabilities) &Account) {

        // Initialize the buyer's account if it is not already initialized
        let flovatarPackCap = buyer.capabilities.get<&{FlovatarPack.CollectionPublic}>(FlovatarPack.CollectionPublicPath)
        if(!flovatarPackCap.check()) {
            let wallet =  buyer.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)
            buyer.storage.save<@FlovatarPack.Collection>(<- FlovatarPack.createEmptyCollection(ownerVault: wallet), to: FlovatarPack.CollectionStoragePath)

            // create a public capability for the collection
            buyer.capabilities.unpublish(FlovatarPack.CollectionPublicPath)
            buyer.capabilities.publish(
                buyer.capabilities.storage.issue<&{FlovatarPack.CollectionPublic}>(FlovatarPack.CollectionStoragePath),
                at: FlovatarPack.CollectionPublicPath
            )
        }

        // Get access to Dapper's DUC vault
        self.mainDucVault = dapper.storage.borrow<auth(FungibleToken.Withdraw) &FlowUtilityToken.Vault>(from: /storage/flowUtilityTokenVault)
            ?? panic("Cannot borrow FlowUtilityToken vault from dapper storage")

        // Withdraw the appropriate amount of DUC from the vault
        self.balanceBeforeTransfer = self.mainDucVault.balance
        self.paymentVault <- self.mainDucVault.withdraw(amount: expectedPrice)

        self.buyerFlovatarPackCollection = buyer.capabilities.get<&{FlovatarPack.CollectionPublic}>(FlovatarPack.CollectionPublicPath)

    }

    execute {

        let packmarket = getAccount(flovatarAddress).capabilities.borrow<&{FlovatarPack.CollectionPublic}>(FlovatarPack.CollectionPublicPath)
                         ?? panic("Could not borrow seller's sale reference")

        packmarket.purchaseDapper(tokenId: listingResourceID, recipientCap: self.buyerFlovatarPackCollection, buyTokens: <- self.paymentVault, signature: signature, expectedPrice: expectedPrice)

    }

    post {
        // Ensure there is no DUC leakage
        self.mainDucVault.balance == self.balanceBeforeTransfer: "transaction would leak DUC"
    }
}