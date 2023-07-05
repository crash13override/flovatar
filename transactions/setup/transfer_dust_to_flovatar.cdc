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

//This transactions transfers flow on testnet from one account to another
transaction(
    amount: UFix64,
    to: UInt64) {

      let sentVault: @FungibleToken.Vault

      prepare(signer: AuthAccount) {
        let vaultRef = signer.borrow<&{FungibleToken.Provider}>(from: FlovatarDustToken.VaultStoragePath)
          ?? panic("Could not borrow reference to the owner's Vault!")

        self.sentVault <- vaultRef.withdraw(amount: amount)
      }

      execute {
        if let inboxCollection = signer.getCapability(FlovatarInbox.CollectionPublicPath).borrow<&{FlovatarInbox.CollectionPublic}>() {
            inboxCollection.depositDustToFlovatar(id: to, vault: <-self.sentVault)
        }
      }
}
