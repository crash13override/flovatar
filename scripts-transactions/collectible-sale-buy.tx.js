import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function collectibleSaleBuyTx(storefrontAddress, listingResourceID, expectedPrice, commissionRecipient) {
    return await fcl
        .mutate({
            cadence: `
import FungibleToken from 0xFungible
import NonFungibleToken from 0xNonFungible
import FlowToken from 0xFlowToken
import NFTStorefrontV2 from 0xStorefront2
import MetadataViews from 0xMetadataViews
import FlovatarDustCollectible from 0xFlovatar

transaction(storefrontAddress: Address, listingResourceID: UInt64, expectedPrice: UFix64, commissionRecipient: Address) {
    let paymentVault: @{FungibleToken.Vault}
    let buyerFlovatarCollection: &FlovatarDustCollectible.Collection
    let storefront: &NFTStorefrontV2.Storefront
    let listing: &NFTStorefrontV2.Listing
    let balanceBeforeTransfer: UFix64
    let mainFlowVault: auth(FungibleToken.Withdraw) &FlowToken.Vault
    let commissionRecipientCap: Capability<&{FungibleToken.Receiver}>

    prepare(buyer: auth(Storage, Capabilities) &Account) {

        // Initialize the buyer's account if it is not already initialized
        let flovatarCap = buyer.capabilities.get<&{FlovatarDustCollectible.CollectionPublic}>(FlovatarDustCollectible.CollectionPublicPath)
        if(!flovatarCap.check()) {
             // create a public capability for the collection
            buyer.capabilities.unpublish(FlovatarDustCollectible.CollectionPublicPath)
            buyer.capabilities.publish(
                buyer.capabilities.storage.issue<&FlovatarDustCollectible.Collection>(FlovatarDustCollectible.CollectionStoragePath),
                at: FlovatarDustCollectible.CollectionPublicPath
            )
        }

        // Fetch the storefront where the listing exists
        self.storefront = getAccount(storefrontAddress)
              .capabilities.borrow<&NFTStorefrontV2.Storefront>(
                  NFTStorefrontV2.StorefrontPublicPath
              ) ?? panic("Could not borrow Storefront from provided address")

        // Fetch the listing from the storefront by ID
        self.listing = self.storefront.borrowListing(listingResourceID: listingResourceID)! as! &NFTStorefrontV2.Listing


        // Get access to Flow Token vault
        let salePrice = self.listing.getDetails().salePrice
        self.mainFlowVault = buyer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Cannot borrow FlowToken vault from dapper storage")

        // Withdraw the appropriate amount of DUC from the vault
        self.balanceBeforeTransfer = self.mainFlowVault.balance
        self.paymentVault <- self.mainFlowVault.withdraw(amount: salePrice)

        // Check that the price is what we expect
        if (expectedPrice != salePrice) {
            panic("Expected price does not match sale price")
        }

        self.buyerFlovatarCollection = buyer
            .capabilities.borrow<&FlovatarDustCollectible.Collection>(FlovatarDustCollectible.CollectionPublicPath)
            ?? panic("Cannot borrow Dust Collectible collection receiver from buyer")


        // Access the capability to receive the commission.
        self.commissionRecipientCap = getAccount(commissionRecipient).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        assert(self.commissionRecipientCap.check(), message: "Commission Recipient doesn't have flowtoken receiving capability")
    }

    execute {
        let item <- self.listing.purchase(
            payment: <-self.paymentVault,
            commissionRecipient: self.commissionRecipientCap
        )

        self.buyerFlovatarCollection.deposit(token: <-item)
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
