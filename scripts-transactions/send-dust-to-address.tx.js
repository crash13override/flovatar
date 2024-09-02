import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function sendDustToAddressTx(amount, to) {
    return await fcl
        .mutate({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace, FlovatarDustToken, FlovatarInbox from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

//This transactions transfers flow on testnet from one account to another
transaction(
    amount: UFix64,
    to: Address) {

      let sentVault: @{FungibleToken.Vault}

      prepare(signer: auth(Storage) &Account) {
        let vaultRef = signer.storage.borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Provider}>(from: FlovatarDustToken.VaultStoragePath)
          ?? panic("Could not borrow reference to the owner's Vault!")

        self.sentVault <- vaultRef.withdraw(amount: amount)
      }

      execute {
        let recipient = getAccount(to)

        let receiverRef = recipient.capabilities.borrow<&{FungibleToken.Receiver}>(FlovatarDustToken.VaultReceiverPath)
          ?? panic("Could not borrow receiver reference to the recipient's Vault")

        receiverRef.deposit(from: <-self.sentVault)
      }
}
`,
            args: (arg, t) => [
                arg(amount, t.UFix64),
                arg(to, t.Address)
            ],
            limit: 9999
        });

}
