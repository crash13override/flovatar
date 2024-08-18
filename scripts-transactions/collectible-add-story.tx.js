import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function collectibleAddStoryTx(collectibleId, text) {

    return await fcl
        .mutate({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace, FlovatarDustToken, FlovatarDustCollectible, FlovatarDustCollectibleAccessory, FlovatarDustCollectibleTemplate from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

//this transaction will add a Story to an existing Flovatar
transaction(
    collectibleId: UInt64,
    text: String
    ) {

    let collectibleCollection: &FlovatarDustCollectible.Collection
    let vaultCap: Capability<&FlovatarDustToken.Vault{FungibleToken.Receiver}>
    let temporaryVault: @FungibleToken.Vault

    prepare(account: AuthAccount) {
        self.collectibleCollection = account.borrow<&FlovatarDustCollectible.Collection>(from: FlovatarDustCollectible.CollectionStoragePath)!

        self.vaultCap = account.getCapability<&FlovatarDustToken.Vault{FungibleToken.Receiver}>(FlovatarDustToken.VaultReceiverPath)

        let vaultRef = account.borrow<&{FungibleToken.Provider}>(from: FlovatarDustToken.VaultStoragePath) ?? panic("Could not borrow owner's Vault reference")

        // withdraw tokens from the buyer's Vault
        self.temporaryVault <- vaultRef.withdraw(amount: 50.0)
    }

    execute {

        let collectible: &{FlovatarDustCollectible.Private} = self.collectibleCollection.borrowDustCollectiblePrivate(id: collectibleId)!

        collectible.addStory(text: text, vault: <- self.temporaryVault)
    }
}
`,
            args: (arg, t) => [
                arg(''+collectibleId, t.UInt64),
                arg(text, t.String)
            ],
            limit: 9999
        });

}
