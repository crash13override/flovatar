import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function collectibleCreateTx(series, layers, templates, amount) {

    return await fcl
        .mutate({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace, FlovatarDustToken, FlovatarDustCollectible, FlovatarDustCollectibleAccessory, FlovatarDustCollectibleTemplate from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

//this transaction will create a new Webshot and create and auction for it
transaction(
    series: UInt64,
    layers: [UInt32],
    templates: [UInt64?],
    amount: UFix64
    ){

    let flovatarCollectibleCollection: &FlovatarDustCollectible.Collection
    let temporaryVault: @FungibleToken.Vault

    let accountAddress: Address

    prepare(account: AuthAccount) {
        self.flovatarCollectibleCollection = account.borrow<&FlovatarDustCollectible.Collection>(from: FlovatarDustCollectible.CollectionStoragePath)!
        self.accountAddress = account.address


        let vaultRef = account.borrow<&{FungibleToken.Provider}>(from: FlovatarDustToken.VaultStoragePath) ?? panic("Could not borrow owner's Vault reference")
        // withdraw tokens from the buyer's Vault
        self.temporaryVault <- vaultRef.withdraw(amount: amount)
    }

    execute {

        let collectible <- FlovatarDustCollectible.createDustCollectible(
            series: series,
            layers: layers,
            templateIds: templates,
            address: self.accountAddress,
            vault: <-self.temporaryVault
        )

        self.flovatarCollectibleCollection.deposit(token: <-collectible)
    }
}
`,
            args: (arg, t) => [
                arg(''+series, t.UInt64),
                arg(layers, t.Array(t.UInt32)),
                arg(templates, t.Array(t.Optional(t.UInt64))),
                arg(''+amount, t.UFix64)
            ],
            limit: 9999
        });

}
