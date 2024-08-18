import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function claimDustByIdTx(ids) {
    return await fcl
        .mutate({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace, FlovatarDustToken, FlovatarInbox from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

//this transaction will claim all content of the Inbox
transaction(ids: [UInt64]) {

    let flovatarCollection: &Flovatar.Collection
    let address: Address

    prepare(account: AuthAccount) {
        self.flovatarCollection = account.borrow<&Flovatar.Collection>(from: Flovatar.CollectionStoragePath)!
        self.address = account.address


        if account.borrow<&FlovatarDustToken.Vault>(from: FlovatarDustToken.VaultStoragePath) == nil {
            let vault <- FlovatarDustToken.createEmptyVault()
            account.save<@FlovatarDustToken.Vault>(<-vault, to: FlovatarDustToken.VaultStoragePath)
        }

        let dustTokenCap = account.getCapability<&FlovatarDustToken.Vault{FungibleToken.Receiver}>(FlovatarDustToken.VaultReceiverPath)
        if(!dustTokenCap.check()) {
            account.unlink(FlovatarDustToken.VaultReceiverPath)
            // Create a public Receiver capability to the Vault
            account.link<&FlovatarDustToken.Vault{FungibleToken.Receiver, FungibleToken.Balance}>(FlovatarDustToken.VaultReceiverPath, target: FlovatarDustToken.VaultStoragePath)
        }

        let dustTokenCapBalance = account.getCapability<&FlovatarDustToken.Vault{FungibleToken.Balance}>(FlovatarDustToken.VaultBalancePath)
        if(!dustTokenCapBalance.check()) {
            account.unlink(FlovatarDustToken.VaultBalancePath)
            // Create a public Receiver capability to the Vault
            account.link<&FlovatarDustToken.Vault{FungibleToken.Balance}>(FlovatarDustToken.VaultBalancePath, target: FlovatarDustToken.VaultStoragePath)
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
`,
            args: (arg, t) => [
                arg(ids, t.Array(t.UInt64))
            ],
            limit: 9999
        });

}
