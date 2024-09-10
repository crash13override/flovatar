import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function flovatarSetNameTx(flovatarId, name) {

    return await fcl
        .mutate({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace, FlovatarDustToken from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

//this transaction will set the name to an existing Flovatar
transaction(
    flovatarId: UInt64,
    name: String
    ) {

    let flovatarCollection: auth(Flovatar.PrivateEnt) &Flovatar.Collection
    let vaultCap: Capability<&FlovatarDustToken.Vault>
    let temporaryVault: @{FungibleToken.Vault}

    prepare(account: auth(Storage) &Account) {
        self.flovatarCollection = account.storage.borrow<auth(Flovatar.PrivateEnt) &Flovatar.Collection>(from: Flovatar.CollectionStoragePath)!

        self.vaultCap = account.capabilities.get<&FlovatarDustToken.Vault>(FlovatarDustToken.VaultReceiverPath)

        let vaultRef = account.storage.borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Provider}>(from: FlovatarDustToken.VaultStoragePath) ?? panic("Could not borrow owner's Vault reference")

        // withdraw tokens from the buyer's Vault
        self.temporaryVault <- vaultRef.withdraw(amount: 100.0)
    }

    execute {

        let flovatar = self.flovatarCollection.borrowFlovatarPrivate(id: flovatarId)!

        flovatar.setName(name: name, vault: <- self.temporaryVault)
    }
}
`,
            args: (arg, t) => [
                arg(''+flovatarId, t.UInt64),
                arg(name, t.String)
            ],
            limit: 9999
        });

}
