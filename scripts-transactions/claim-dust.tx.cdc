import "Flovatar"
import "FlovatarDustToken"
import "FlovatarInbox" 

//this transaction will claim all content of the Inbox
transaction() {

    let flovatarCollection: &Flovatar.Collection
    let address: Address

    prepare(account: auth(Storage, Capabilities) &Account) {
        self.flovatarCollection = account.storage.borrow<&Flovatar.Collection>(from: Flovatar.CollectionStoragePath)!
        self.address = account.address


        if account.storage.borrow<&FlovatarDustToken.Vault>(from: FlovatarDustToken.VaultStoragePath) == nil {
            let vault <- FlovatarDustToken.createEmptyVault(vaultType: Type<@FlovatarDustToken.Vault>())
            account.storage.save(<-vault, to: FlovatarDustToken.VaultStoragePath)
        }

        let dustTokenCap = account.capabilities.get<&FlovatarDustToken.Vault>(FlovatarDustToken.VaultReceiverPath)
        if(!dustTokenCap.check()) {
            account.capabilities.unpublish(FlovatarDustToken.VaultReceiverPath)
            // Create a public Receiver capability to the Vault
            account.capabilities.publish(
                account.capabilities.storage.issue<&FlovatarDustToken.Vault>(FlovatarDustToken.VaultStoragePath),
                at: FlovatarDustToken.VaultReceiverPath
            )
        }

        let dustTokenCapBalance = account.capabilities.get<&FlovatarDustToken.Vault>(FlovatarDustToken.VaultBalancePath)
        if(!dustTokenCapBalance.check()) {
            account.capabilities.unpublish(FlovatarDustToken.VaultBalancePath)
            // Create a public Receiver capability to the Vault
            account.capabilities.publish(
                account.capabilities.storage.issue<&FlovatarDustToken.Vault>(FlovatarDustToken.VaultStoragePath),
                at: FlovatarDustToken.VaultBalancePath
            )
        }
    }

    execute {

        FlovatarInbox.withdrawWalletDust(address: self.address)

        var count: UInt32 = 0
        for id in self.flovatarCollection.getIDs() {
            if(count < UInt32(20)){
                if let claimableCommunityDust = FlovatarInbox.getClaimableFlovatarCommunityDust(id: id, address: self.address) {
                    if(claimableCommunityDust.amount > UFix64(0)){
                        FlovatarInbox.claimFlovatarCommunityDust(id: id, address: self.address)
                        count = count + UInt32(1)
                    }
                }

                if(FlovatarInbox.getFlovatarDustBalance(id: id) > UFix64(0)){
                    FlovatarInbox.withdrawFlovatarDust(id: id, address: self.address)
                    count = count + UInt32(1)
                }
            }
        }
    }
}