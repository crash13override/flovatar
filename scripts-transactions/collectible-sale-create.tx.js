import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function collectibleSaleCreateTx(saleItemID, saleItemPrice, customID, expiry) {
    return await fcl
        .mutate({
            cadence: `
import FungibleToken from 0xFungible
import NonFungibleToken from 0xNonFungible
import FlowToken from 0xFlowToken
import NFTStorefrontV2 from 0xStorefront2
import MetadataViews from 0xMetadataViews
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace, FlovatarDustToken, FlovatarDustCollectible, FlovatarDustCollectibleAccessory, FlovatarDustCollectibleTemplate from 0xFlovatar

pub fun getOrCreateStorefront(account: AuthAccount): &NFTStorefrontV2.Storefront {
    if let storefrontRef = account.borrow<&NFTStorefrontV2.Storefront>(from: NFTStorefrontV2.StorefrontStoragePath) {
        return storefrontRef
    }

    let storefront <- NFTStorefrontV2.createStorefront() as! @NFTStorefrontV2.Storefront

    let storefrontRef = &storefront as &NFTStorefrontV2.Storefront

    account.save(<-storefront, to: NFTStorefrontV2.StorefrontStoragePath)

    account.link<&NFTStorefrontV2.Storefront{NFTStorefrontV2.StorefrontPublic}>(NFTStorefrontV2.StorefrontPublicPath, target: NFTStorefrontV2.StorefrontStoragePath)

    return storefrontRef
}

transaction(saleItemID: UInt64, saleItemPrice: UFix64, customID: String?, expiry: UInt64) {
    let flowReceiver: Capability<&{FungibleToken.Receiver}>
    let flowReceiverMarket: Capability<&{FungibleToken.Receiver}>
    let flovatarNFTProvider: Capability<&FlovatarDustCollectible.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
    let storefront: &NFTStorefrontV2.Storefront
    var saleCuts: [NFTStorefrontV2.SaleCut]

    prepare(acct: AuthAccount) {
        self.saleCuts = []

        let flovatarCollectionProviderPrivatePath = /private/FlovatarDustCollectibleCollection
        // Check if the Provider capability exists or not if \`no\` then create a new link for the same.
        if !acct.getCapability<&FlovatarDustCollectible.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(flovatarCollectionProviderPrivatePath)!.check() {
            acct.link<&FlovatarDustCollectible.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(flovatarCollectionProviderPrivatePath, target: FlovatarDustCollectible.CollectionStoragePath)
        }


        self.flowReceiver = acct.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        assert(self.flowReceiver.borrow() != nil, message: "Missing or mis-typed Flow receiver for seller")

        let marketAccount = getAccount(0xComponent)
        self.flowReceiverMarket = marketAccount.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        assert(self.flowReceiverMarket.borrow() != nil, message: "Missing or mis-typed Flow receiver for merchant account")

        // Initialize the buyer's account if it is not already initialized
        let flovatarCollectibleCap = acct.getCapability<&{FlovatarDustCollectible.CollectionPublic}>(FlovatarDustCollectible.CollectionPublicPath)
        if(!flovatarCollectibleCap.check()) {
            acct.unlink(FlovatarDustCollectible.CollectionPublicPath)
            acct.link<&FlovatarDustCollectible.Collection{FlovatarDustCollectible.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(FlovatarDustCollectible.CollectionPublicPath, target: FlovatarDustCollectible.CollectionStoragePath)
        }

        self.flovatarNFTProvider = acct.getCapability<&FlovatarDustCollectible.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(flovatarCollectionProviderPrivatePath)
        assert(self.flovatarNFTProvider.borrow() != nil, message: "Missing or mis-typed FlovatarDustCollectible.Collection provider")

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
`,
            args: (arg, t) => [
                arg(''+saleItemID, t.UInt64),
                arg(floatArg(saleItemPrice), t.UFix64),
                arg(customID, t.String),
                arg(''+expiry, t.UInt64)
            ],
            limit: 9999
        });

}
