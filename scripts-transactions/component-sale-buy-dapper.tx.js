import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function componentSaleBuyDapperTx(storefrontAddress, listingResourceID, expectedPrice, commissionRecipient) {
    return await fcl
        .mutate({
            cadence: `
import FungibleToken from 0xFungible
import NonFungibleToken from 0xNonFungible
import FlowUtilityToken from 0xDuc
import NFTStorefrontV2 from 0xStorefront2
import MetadataViews from 0xMetadataViews
import Flovatar, FlovatarComponent from 0xFlovatar

transaction(storefrontAddress: Address, listingResourceID: UInt64, expectedPrice: UFix64, commissionRecipient: Address) {
    let paymentVault: @FungibleToken.Vault
    let buyerFlovatarCollection: &FlovatarComponent.Collection{NonFungibleToken.Receiver}
    let storefront: &NFTStorefrontV2.Storefront{NFTStorefrontV2.StorefrontPublic}
    let listing: &NFTStorefrontV2.Listing{NFTStorefrontV2.ListingPublic}
    let balanceBeforeTransfer: UFix64
    let mainDucVault: &FlowUtilityToken.Vault
    let commissionRecipientCap: Capability<&{FungibleToken.Receiver}>

    prepare(dapper: AuthAccount, buyer: AuthAccount) {

        // Initialize the buyer's account if it is not already initialized
        let flovatarCap = buyer.getCapability<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath)
        if(!flovatarCap.check()) {
            buyer.save<@NonFungibleToken.Collection>(<- FlovatarComponent.createEmptyCollection(), to: FlovatarComponent.CollectionStoragePath)
            buyer.link<&FlovatarComponent.Collection{FlovatarComponent.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(FlovatarComponent.CollectionPublicPath, target: FlovatarComponent.CollectionStoragePath)
        }

        // Fetch the storefront where the listing exists
        self.storefront = getAccount(storefrontAddress)
              .getCapability<&NFTStorefrontV2.Storefront{NFTStorefrontV2.StorefrontPublic}>(
                  NFTStorefrontV2.StorefrontPublicPath
              )!
              .borrow()
              ?? panic("Could not borrow Storefront from provided address")

        // Fetch the listing from the storefront by ID
        self.listing = self.storefront.borrowListing(listingResourceID: listingResourceID)
            ?? panic("No Offer with that ID in Storefront")

        // Get access to Dapper's DUC vault
        let salePrice = self.listing.getDetails().salePrice
        self.mainDucVault = dapper.borrow<&FlowUtilityToken.Vault>(from: /storage/flowUtilityTokenVault)
            ?? panic("Cannot borrow FlowUtilityToken vault from dapper storage")

        // Withdraw the appropriate amount of DUC from the vault
        self.balanceBeforeTransfer = self.mainDucVault.balance
        self.paymentVault <- self.mainDucVault.withdraw(amount: salePrice)

        // Check that the price is what we expect
        if (expectedPrice != salePrice) {
            panic("Expected price does not match sale price")
        }

        self.buyerFlovatarCollection = buyer
            .getCapability<&FlovatarComponent.Collection{NonFungibleToken.Receiver}>(FlovatarComponent.CollectionPublicPath)
            .borrow()
            ?? panic("Cannot borrow Flovatar collection receiver from buyer")

        // Access the capability to receive the commission.
        self.commissionRecipientCap = getAccount(commissionRecipient).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        assert(self.commissionRecipientCap.check(), message: "Commission Recipient doesn't have flowtoken receiving capability")
    }

    execute {
        let item <- self.listing.purchase(
            payment: <-self.paymentVault,
            commissionRecipient: self.commissionRecipientCap
        )

        self.buyerFlovatarCollection.deposit(token: <-item)
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
                arg(commissionRecipient, t.Address),
            ],
            limit: 9999
        });

}
