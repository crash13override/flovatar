import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"
import {collectibleAddStoryTx} from "./collectible-add-story.tx";

export async function collectibleSetNameTx(collectibleId, name) {

    return await fcl
        .mutate({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace, FlovatarDustToken, FlovatarDustCollectible, FlovatarDustCollectibleAccessory, FlovatarDustCollectibleTemplate from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

//this transaction will set the name to an existing Flovatar
transaction(
    collectibleId: UInt64,
    name: String
    ) {

    let collectibleCollection: auth(FlovatarDustCollectible.PrivateEnt) &FlovatarDustCollectible.Collection
    let temporaryVault: @{FungibleToken.Vault}

    prepare(account: auth(Storage) &Account) {
        self.collectibleCollection = account.storage.borrow<auth(FlovatarDustCollectible.PrivateEnt) &FlovatarDustCollectible.Collection>(from: FlovatarDustCollectible.CollectionStoragePath)!

        let vaultRef = account.storage.borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Provider}>(from: FlovatarDustToken.VaultStoragePath) ?? panic("Could not borrow owner's Vault reference")

        // withdraw tokens from the buyer's Vault
        self.temporaryVault <- vaultRef.withdraw(amount: 100.0)
    }

    execute {

        let collectible = self.collectibleCollection.borrowDustCollectiblePrivate(id: collectibleId)!

        collectible.setName(name: name, vault: <- self.temporaryVault)
    }
}
`,
            args: (arg, t) => [
                arg(''+collectibleId, t.UInt64),
                arg(name, t.String)
            ],
            limit: 9999
        });

}
