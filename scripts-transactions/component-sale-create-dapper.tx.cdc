import "FungibleToken"
import "NonFungibleToken"
import "FlowUtilityToken"
import "NFTStorefrontV2"
import "MetadataViews"
import "TokenForwarding"
import "Flovatar"
import "FlovatarComponent"

access(all) fun getOrCreateStorefront(account: auth(Storage, Capabilities) &Account): auth(NFTStorefrontV2.CreateListing) &NFTStorefrontV2.Storefront {
    if let storefrontRef = account.storage.borrow<auth(NFTStorefrontV2.CreateListing) &NFTStorefrontV2.Storefront>(from: NFTStorefrontV2.StorefrontStoragePath) {
        return storefrontRef
    }

    let storefront <- NFTStorefrontV2.createStorefront()

    account.storage.save(<-storefront, to: NFTStorefrontV2.StorefrontStoragePath)

    // create a public capability for the .Storefront & publish
    let storefrontPublicCap = account.capabilities.storage.issue<&NFTStorefrontV2.Storefront>(
            NFTStorefrontV2.StorefrontStoragePath
        )
    account.capabilities.unpublish(NFTStorefrontV2.StorefrontPublicPath)
    account.capabilities.publish(storefrontPublicCap, at: NFTStorefrontV2.StorefrontPublicPath)

     let storefrontRef = account.storage.borrow<auth(NFTStorefrontV2.CreateListing)  &NFTStorefrontV2.Storefront>(from: NFTStorefrontV2.StorefrontStoragePath)
        ?? panic("Could not borrow Storefront from provided address")

    return storefrontRef
}

transaction(saleItemID: UInt64, saleItemPrice: UFix64, customID: String?, expiry: UInt64) {
    let ducReceiver: Capability<&{FungibleToken.Receiver}>
    let ducReceiverMarket: Capability<&{FungibleToken.Receiver}>
    let flovatarNFTProvider: Capability<auth(NonFungibleToken.Withdraw) &FlovatarComponent.Collection>
    let storefront: auth(NFTStorefrontV2.CreateListing) &NFTStorefrontV2.Storefront
    var saleCuts: [NFTStorefrontV2.SaleCut]

    prepare(acct: auth(Storage, Capabilities) &Account) {
        self.saleCuts = []

        self.flovatarNFTProvider = acct.capabilities.storage.issue<auth(NonFungibleToken.Withdraw) &FlovatarComponent.Collection>(FlovatarComponent.CollectionStoragePath)
        assert(self.flovatarNFTProvider.borrow() != nil, message: "Missing or mis-typed FlovatarComponent.Collection provider")

        if acct.storage.borrow<&{FungibleToken.Receiver}>(from: /storage/flowUtilityTokenReceiver) == nil {
            let dapper = getAccount(0xFut)
            let dapperFUTReceiver = dapper.capabilities.get<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)

            // Create a new Forwarder resource for FUT and store it in the new account's storage
            let futForwarder <- TokenForwarding.createNewForwarder(recipient: dapperFUTReceiver)
            acct.storage.save(<-futForwarder, to: /storage/flowUtilityTokenReceiver)

            // Publish a Receiver capability for the new account, which is linked to the FUT Forwarder
            acct.capabilities.unpublish(/public/flowUtilityTokenReceiver)
            // Create a public Receiver capability to the Vault
            acct.capabilities.publish(
                acct.capabilities.storage.issue<&FlowUtilityToken.Vault>(/storage/flowUtilityTokenReceiver),
                at: /public/flowUtilityTokenReceiver
            )
        }

        self.ducReceiver = acct.capabilities.get<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
        assert(self.ducReceiver.borrow() != nil, message: "Missing or mis-typed FUT receiver for seller")

        let marketAccount = getAccount(0xDapperMerchant)
        self.ducReceiverMarket = marketAccount.capabilities.get<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
        assert(self.ducReceiverMarket.borrow() != nil, message: "Missing or mis-typed FUT receiver for merchant account")

        // Initialize the buyer's account if it is not already initialized
        let flovatarCap = acct.capabilities.get<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath)
        if(!flovatarCap.check()) {
            acct.storage.save<@{NonFungibleToken.Collection}>(<- FlovatarComponent.createEmptyCollection(nftType: Type<@FlovatarComponent.Collection>()), to: FlovatarComponent.CollectionStoragePath)

            acct.capabilities.unpublish(FlovatarComponent.CollectionPublicPath)
            acct.capabilities.publish(
                acct.capabilities.storage.issue<&FlovatarComponent.Collection>(FlovatarComponent.CollectionStoragePath),
                at: FlovatarComponent.CollectionPublicPath
            )
        }

        self.storefront = getOrCreateStorefront(account: acct)

        self.saleCuts.append(NFTStorefrontV2.SaleCut(
            receiver: self.ducReceiver,
            amount: saleItemPrice * 0.95
        ))

        self.saleCuts.append(NFTStorefrontV2.SaleCut(
            receiver: self.ducReceiverMarket,
            amount: saleItemPrice * 0.05
        ))
    }

    execute {
        self.storefront.createListing(
            nftProviderCapability: self.flovatarNFTProvider,
            nftType: Type<@FlovatarComponent.NFT>(),
            nftID: saleItemID,
            salePaymentVaultType: Type<@FlowUtilityToken.Vault>(),
            saleCuts: self.saleCuts,
            marketplacesCapability: nil,
            customID: customID,
            commissionAmount: 0.0,
            expiry: expiry
        )
    }
}