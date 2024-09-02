import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function claimAllTx() {
    return await fcl
        .mutate({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace, FlovatarDustToken, FlovatarInbox from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

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


        FlovatarInbox.withdrawWalletComponent(address: self.address)
        FlovatarInbox.withdrawWalletDust(address: self.address)


        var count: UInt32 = 0
        for id in self.flovatarCollection.getIDs() {
             if(FlovatarInbox.getFlovatarComponentIDs(id: id).length > Int(0) && count < UInt32(20)){
                FlovatarInbox.withdrawFlovatarComponent(id: id, address: self.address)
                FlovatarInbox.withdrawFlovatarDust(id: id, address: self.address)
                FlovatarInbox.claimFlovatarCommunityDust(id: id, address: self.address)
                count = count + UInt32(1)
            }
        }
    }
}
`,
            args: (arg, t) => [],
            limit: 9999
        });

}
