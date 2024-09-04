import "FungibleToken"
import "NonFungibleToken"
import "FlowUtilityToken"
import "NFTStorefrontV2"
import "MetadataViews"
import "Flobot"

transaction(storefrontAddress: Address, listingResourceID: UInt64, expectedPrice: UFix64, commissionRecipient: Address) {
    let paymentVault: @{FungibleToken.Vault}
    let buyerFlovatarCollection: &Flobot.Collection
    let storefront: &NFTStorefrontV2.Storefront
    let listing: &NFTStorefrontV2.Listing
    let balanceBeforeTransfer: UFix64
    let mainDucVault: auth(FungibleToken.Withdraw)  &FlowUtilityToken.Vault
    let commissionRecipientCap: Capability<&{FungibleToken.Receiver}>

    prepare(dapper: auth(Storage) &Account, buyer: auth(Storage, Capabilities) &Account) {

        // Initialize the buyer's account if it is not already initialized
        let flovatarCap = buyer.capabilities.get<&{Flobot.CollectionPublic}>(Flobot.CollectionPublicPath)
        if(!flovatarCap.check()) {
            buyer.storage.save<@{NonFungibleToken.Collection}>(<- Flobot.createEmptyCollection(nftType: Type<@Flobot.Collection>()), to: Flobot.CollectionStoragePath)

            buyer.capabilities.unpublish(Flobot.CollectionPublicPath)
            buyer.capabilities.publish(
                buyer.capabilities.storage.issue<&Flobot.Collection>(Flobot.CollectionStoragePath),
                at: Flobot.CollectionPublicPath
            )
        }

        // Fetch the storefront where the listing exists
        self.storefront = getAccount(storefrontAddress)
              .capabilities.borrow<&NFTStorefrontV2.Storefront>(
                  NFTStorefrontV2.StorefrontPublicPath
              )
              ?? panic("Could not borrow Storefront from provided address")

        // Fetch the listing from the storefront by ID
        self.listing = self.storefront.borrowListing(listingResourceID: listingResourceID) as! &NFTStorefrontV2.Listing

        // Get access to Dapper's DUC vault
        let salePrice = self.listing.getDetails().salePrice
        self.mainDucVault = dapper.storage.borrow<auth(FungibleToken.Withdraw) &FlowUtilityToken.Vault>(from: /storage/flowUtilityTokenVault)
            ?? panic("Cannot borrow FlowUtilityToken vault from dapper storage")

        // Withdraw the appropriate amount of DUC from the vault
        self.balanceBeforeTransfer = self.mainDucVault.balance
        self.paymentVault <- self.mainDucVault.withdraw(amount: salePrice)

        // Check that the price is what we expect
        if (expectedPrice != salePrice) {
            panic("Expected price does not match sale price")
        }

        self.buyerFlovatarCollection = buyer
            .capabilities.get<&Flobot.Collection>(Flobot.CollectionPublicPath)
            .borrow()
            ?? panic("Cannot borrow Flovatar collection receiver from buyer")

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

    post {
        // Ensure there is no DUC leakage
        self.mainDucVault.balance == self.balanceBeforeTransfer: "transaction would leak DUC"
    }
}