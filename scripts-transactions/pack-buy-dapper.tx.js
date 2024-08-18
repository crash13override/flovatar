import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function packBuyDapperTx(storefrontAddress, listingResourceID, expectedPrice, signature, flovatarAddress) {
    return await fcl
        .mutate({
            cadence: `
import FungibleToken from 0xFungible
import NonFungibleToken from 0xNonFungible
import FlowUtilityToken from 0xDuc
import FlowToken from 0xFlowToken
import Flovatar, FlovatarComponent, FlovatarPack from 0xFlovatar

transaction(storefrontAddress: Address, listingResourceID: UInt64, expectedPrice: UFix64, signature: String, flovatarAddress: Address) {
    let paymentVault: @FungibleToken.Vault
    let buyerFlovatarPackCollection: Capability<&{FlovatarPack.CollectionPublic}>
    let balanceBeforeTransfer: UFix64
    let mainDucVault: &FlowUtilityToken.Vault

    prepare(dapper: AuthAccount, buyer: AuthAccount) {

        // Initialize the buyer's account if it is not already initialized
        let flovatarPackCap = buyer.getCapability<&{FlovatarPack.CollectionPublic}>(FlovatarPack.CollectionPublicPath)
        if(!flovatarPackCap.check()) {
            let wallet =  buyer.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)
            buyer.save<@FlovatarPack.Collection>(<- FlovatarPack.createEmptyCollection(ownerVault: wallet), to: FlovatarPack.CollectionStoragePath)
            buyer.link<&{FlovatarPack.CollectionPublic}>(FlovatarPack.CollectionPublicPath, target: FlovatarPack.CollectionStoragePath)
        }

        // Get access to Dapper's DUC vault
        self.mainDucVault = dapper.borrow<&FlowUtilityToken.Vault>(from: /storage/flowUtilityTokenVault)
            ?? panic("Cannot borrow FlowUtilityToken vault from dapper storage")

        // Withdraw the appropriate amount of DUC from the vault
        self.balanceBeforeTransfer = self.mainDucVault.balance
        self.paymentVault <- self.mainDucVault.withdraw(amount: expectedPrice)

        self.buyerFlovatarPackCollection = buyer.getCapability<&{FlovatarPack.CollectionPublic}>(FlovatarPack.CollectionPublicPath)

    }

    execute {

        let packmarket = getAccount(flovatarAddress).getCapability(FlovatarPack.CollectionPublicPath).borrow<&{FlovatarPack.CollectionPublic}>()
                         ?? panic("Could not borrow seller's sale reference")

        packmarket.purchaseDapper(tokenId: listingResourceID, recipientCap: self.buyerFlovatarPackCollection, buyTokens: <- self.paymentVault, signature: signature, expectedPrice: expectedPrice)

    }

    post {
        // Ensure there is no DUC leakage
        self.mainDucVault.balance == self.balanceBeforeTransfer: "transaction would leak DUC"
    }
}
`,
            args: (arg, t) => [
                arg(storefrontAddress, t.Address),
                arg(''+listingResourceID, t.UInt64),
                arg(floatArg(expectedPrice), t.UFix64),
                arg(signature, t.String),
                arg(flovatarAddress, t.Address)
            ],
            limit: 9999
        });

}
