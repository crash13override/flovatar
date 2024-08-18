import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function builderCheckoutTx(saleAddresses, tokenIds, amounts) {
    return await fcl
        .mutate({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken


//this transaction buy a Flovatar Component from a direct sale listing from another user
transaction(saleAddresses: [Address], tokenIds: [UInt64], amounts: [UFix64]) {

    // reference to the buyer's NFT collection where they
    // will store the bought NFT

    let vaultCap: Capability<&FlowToken.Vault{FungibleToken.Receiver}>
    let collectionCap: Capability<&{FlovatarComponent.CollectionPublic}>
    // Vault that will hold the tokens that will be used
    // to buy the NFT
    let vaultRef: &FlowToken.Vault

    prepare(account: AuthAccount) {

        // get the references to the buyer's Vault and NFT Collection receiver
        var collectionCap = account.getCapability<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath)

        // if collection is not created yet we make it.
        if !collectionCap.check() {
            // store an empty NFT Collection in account storage
            account.save<@NonFungibleToken.Collection>(<- FlovatarComponent.createEmptyCollection(), to: FlovatarComponent.CollectionStoragePath)
            // publish a capability to the Collection in storage
            account.link<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath, target: FlovatarComponent.CollectionStoragePath)
        }



        self.collectionCap = collectionCap

        self.vaultCap = account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)

        self.vaultRef = account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) ?? panic("Could not borrow owner's Vault reference")

    }

    execute {
        var i: Int = 0

        for saleAddress in saleAddresses {
            // get the read-only account storage of the seller
            let seller = getAccount(saleAddress)

            let marketplace = seller.getCapability(FlovatarMarketplace.CollectionPublicPath).borrow<&{FlovatarMarketplace.SalePublic}>()
                             ?? panic("Could not borrow seller's sale reference")

            let temporaryVault: @FungibleToken.Vault <- self.vaultRef.withdraw(amount: amounts[i])
            marketplace.purchaseFlovatarComponent(tokenId: tokenIds[i], recipientCap:self.collectionCap, buyTokens: <- temporaryVault)
            i = i + Int(1)
        }
    }

}
`,
            args: (arg, t) => [
                arg(saleAddresses, t.Array(t.Address)),
                arg(tokenIds, t.Array(t.UInt64)),
                arg(amounts, t.Array(t.UFix64))
            ],
            limit: 9999
        });

}
