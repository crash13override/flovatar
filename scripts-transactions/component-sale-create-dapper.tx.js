import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function componentSaleCreateDapperTx(saleItemID, saleItemPrice, customID, expiry) {
    return await fcl
        .mutate({
            cadence: `
import FungibleToken from 0xFungible
import NonFungibleToken from 0xNonFungible
import FlowUtilityToken from 0xDuc
import NFTStorefrontV2 from 0xStorefront2
import MetadataViews from 0xMetadataViews
import TokenForwarding from 0xTokenForwarding
import Flovatar, FlovatarComponent from 0xFlovatar

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
    let ducReceiver: Capability<&{FungibleToken.Receiver}>
    let ducReceiverMarket: Capability<&{FungibleToken.Receiver}>
    let flovatarNFTProvider: Capability<&FlovatarComponent.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
    let storefront: &NFTStorefrontV2.Storefront
    var saleCuts: [NFTStorefrontV2.SaleCut]

    prepare(acct: AuthAccount) {
        self.saleCuts = []

        let flovatarCollectionProviderPrivatePath = /private/FlovatarComponentCollection
        // Check if the Provider capability exists or not if \`no\` then create a new link for the same.
        if !acct.getCapability<&FlovatarComponent.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(flovatarCollectionProviderPrivatePath)!.check() {
            acct.link<&FlovatarComponent.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(flovatarCollectionProviderPrivatePath, target: FlovatarComponent.CollectionStoragePath)
        }

        if acct.borrow<&{FungibleToken.Receiver}>(from: /storage/flowUtilityTokenReceiver) == nil {
            let dapper = getAccount(0xFut)
            let dapperFUTReceiver = dapper.getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)!

            // Create a new Forwarder resource for FUT and store it in the new account's storage
            let futForwarder <- TokenForwarding.createNewForwarder(recipient: dapperFUTReceiver)
            acct.save(<-futForwarder, to: /storage/flowUtilityTokenReceiver)

            // Publish a Receiver capability for the new account, which is linked to the FUT Forwarder
            acct.link<&FlowUtilityToken.Vault{FungibleToken.Receiver}>(
                /public/flowUtilityTokenReceiver,
                target: /storage/flowUtilityTokenReceiver
            )
        }

        self.ducReceiver = acct.getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
        assert(self.ducReceiver.borrow() != nil, message: "Missing or mis-typed FUT receiver for seller")

        let marketAccount = getAccount(0xDapperMerchant)
        self.ducReceiverMarket = marketAccount.getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
        assert(self.ducReceiverMarket.borrow() != nil, message: "Missing or mis-typed FUT receiver for merchant account")

        // Initialize the buyer's account if it is not already initialized
        let flovatarCap = acct.getCapability<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath)
        if(!flovatarCap.check()) {
            acct.save<@NonFungibleToken.Collection>(<- FlovatarComponent.createEmptyCollection(), to: FlovatarComponent.CollectionStoragePath)
            acct.link<&FlovatarComponent.Collection{FlovatarComponent.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(FlovatarComponent.CollectionPublicPath, target: FlovatarComponent.CollectionStoragePath)
        }

        self.flovatarNFTProvider = acct.getCapability<&FlovatarComponent.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(flovatarCollectionProviderPrivatePath)
        assert(self.flovatarNFTProvider.borrow() != nil, message: "Missing or mis-typed FlovatarComponent.Collection provider")

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
