import "Flovatar"
import "FlovatarDustToken"
import "FlovatarInbox" 

//this transaction will claim all content of the Inbox
transaction(ids: [UInt64], addresses: [Address]) {

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

        var i: UInt32 = 0

        while i < UInt32(ids.length) {
            FlovatarInbox.claimFlovatarCommunityDustFromChild(id: ids[i], parent: self.address, child: addresses[i])
            i = i + UInt32(1)
        }
    }
}