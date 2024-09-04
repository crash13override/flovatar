import "Flovatar"
import "FlovatarDustToken"
import "FlovatarInbox" 

//this transaction will claim all content of the Inbox
transaction(ids: [UInt64]) {

    let address: Address

    prepare(account: auth(Storage, Capabilities) &Account) {
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

        for id in ids {
            FlovatarInbox.claimFlovatarCommunityDust(id: id, address: self.address)

            if(FlovatarInbox.getFlovatarDustBalance(id: id) > UFix64(0)){
                FlovatarInbox.withdrawFlovatarDust(id: id, address: self.address)
            }
        }
    }
}