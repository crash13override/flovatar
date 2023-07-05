import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"
import Flovatar from "../../contracts/Flovatar.cdc"
import FlovatarComponent from "../../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../../contracts/FlovatarPack.cdc"
import FlovatarMarketplace from "../../contracts/FlovatarMarketplace.cdc"
import FlovatarDustToken from "../../contracts/FlovatarDustToken.cdc"
import FlovatarInbox from "../../contracts/FlovatarInbox.cdc"


//this transaction will claim all components and Dust for a Flovatar
transaction(id: : UInt64) {

    let address: Address

    prepare(account: AuthAccount) {

        let dustTokenCap = account.getCapability<&FlovatarDustToken.Vault{FlovatarDustToken.Receiver}>(FlovatarDustToken.VaultReceiverPath)
        if(!dustTokenCap.check()) {
            let vault <- FlovatarDustToken.createEmptyVault()
            // Store the vault in the account storage
            account.save<@FlovatarDustToken.Vault>(<-vault, to: FlovatarDustToken.VaultStoragePath)
            // Create a public Receiver capability to the Vault
            let ReceiverRef = account.link<&FlovatarDustToken.Vault{FlovatarDustToken.Receiver, FlovatarDustToken.Balance}>(FlovatarDustToken.VaultReceiverPath, target: FlovatarDustToken.VaultStoragePath)
        }

        self.address = account.address
    }

    execute {

        FlovatarInbox.withdrawFlovatarComponent(id: id, address: self.address)
        FlovatarInbox.withdrawFlovatarDust(id: id, address: self.address)
        FlovatarInbox.claimFlovatarCommunityDust(id: id, address: self.address)

    }
}