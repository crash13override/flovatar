import "FungibleToken"
import "NonFungibleToken"
import "FlowToken"
import "NFTStorefrontV2"
import "MetadataViews"
import "TokenForwarding"
import "FlovatarDustCollectible"

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
    let flowReceiver: Capability<&{FungibleToken.Receiver}>
    let flowReceiverMarket: Capability<&{FungibleToken.Receiver}>
    let flovatarNFTProvider: Capability<auth(NonFungibleToken.Withdraw) &FlovatarDustCollectible.Collection>
    let storefront: auth(NFTStorefrontV2.CreateListing) &NFTStorefrontV2.Storefront
    var saleCuts: [NFTStorefrontV2.SaleCut]

    prepare(acct: auth(Storage, Capabilities) &Account) {
        self.saleCuts = []

        self.flovatarNFTProvider = acct.capabilities.storage.issue<auth(NonFungibleToken.Withdraw) &FlovatarDustCollectible.Collection>(FlovatarDustCollectible.CollectionStoragePath)
        assert(self.flovatarNFTProvider.borrow() != nil, message: "Missing or mis-typed FlovatarDustCollectible.Collection provider")

        self.flowReceiver = acct.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)
        assert(self.flowReceiver.borrow() != nil, message: "Missing or mis-typed Flow receiver for seller")

        let marketAccount = getAccount(0xComponent)
        self.flowReceiverMarket = marketAccount.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)
        assert(self.flowReceiverMarket.borrow() != nil, message: "Missing or mis-typed Flow receiver for merchant account")

        // Initialize the buyer's account if it is not already initialized
        let flovatarCap = acct.capabilities.get<&{FlovatarDustCollectible.CollectionPublic}>(FlovatarDustCollectible.CollectionPublicPath)
        if(!flovatarCap.check()) {
            acct.storage.save<@{NonFungibleToken.Collection}>(<- FlovatarDustCollectible.createEmptyCollection(nftType: Type<@FlovatarDustCollectible.Collection>()), to: FlovatarDustCollectible.CollectionStoragePath)

            acct.capabilities.unpublish(FlovatarDustCollectible.CollectionPublicPath)
            acct.capabilities.publish(
                acct.capabilities.storage.issue<&FlovatarDustCollectible.Collection>(FlovatarDustCollectible.CollectionStoragePath),
                at: FlovatarDustCollectible.CollectionPublicPath
            )
        }

        self.storefront = getOrCreateStorefront(account: acct)

        self.saleCuts.append(NFTStorefrontV2.SaleCut(
            receiver: self.flowReceiver,
            amount: saleItemPrice * 0.95
        ))

        self.saleCuts.append(NFTStorefrontV2.SaleCut(
            receiver: self.flowReceiverMarket,
            amount: saleItemPrice * 0.05
        ))
    }

    execute {
        self.storefront.createListing(
            nftProviderCapability: self.flovatarNFTProvider,
            nftType: Type<@FlovatarDustCollectible.NFT>(),
            nftID: saleItemID,
            salePaymentVaultType: Type<@FlowToken.Vault>(),
            saleCuts: self.saleCuts,
            marketplacesCapability: nil,
            customID: customID,
            commissionAmount: 0.0,
            expiry: expiry
        )
    }
}