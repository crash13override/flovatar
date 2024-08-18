import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function flovatarSaleCreateDapperTx(saleItemID, saleItemPrice, customID, expiry) {
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
    let ducReceiverCreator: Capability<&{FungibleToken.Receiver}>
    let flovatarNFTProvider: Capability<&Flovatar.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
    let storefront: &NFTStorefrontV2.Storefront
    var saleCuts: [NFTStorefrontV2.SaleCut]

    prepare(acct: AuthAccount) {
        self.saleCuts = []

        let flovatarCollectionProviderPrivatePath = /private/FlovatarCollection
        // Check if the Provider capability exists or not if \`no\` then create a new link for the same.
        if !acct.getCapability<&Flovatar.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(flovatarCollectionProviderPrivatePath)!.check() {
            acct.link<&Flovatar.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(flovatarCollectionProviderPrivatePath, target: Flovatar.CollectionStoragePath)
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

        let flovatarData = Flovatar.getFlovatar(address: acct.address, flovatarId: saleItemID)!
        let creatorAccount = getAccount(flovatarData.metadata.creatorAddress)
        self.ducReceiverCreator = creatorAccount.getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)


        // Initialize the buyer's account if it is not already initialized
        let flovatarCap = acct.getCapability<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath)
        if(!flovatarCap.check()) {
            acct.save<@NonFungibleToken.Collection>(<- Flovatar.createEmptyCollection(), to: Flovatar.CollectionStoragePath)
            acct.link<&Flovatar.Collection{Flovatar.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(Flovatar.CollectionPublicPath, target: Flovatar.CollectionStoragePath)
        }

        self.flovatarNFTProvider = acct.getCapability<&Flovatar.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(flovatarCollectionProviderPrivatePath)
        assert(self.flovatarNFTProvider.borrow() != nil, message: "Missing or mis-typed Flovatar.Collection provider")

        self.storefront = getOrCreateStorefront(account: acct)


        if(self.ducReceiverCreator.borrow() == nil){
            self.saleCuts.append(NFTStorefrontV2.SaleCut(
                receiver: self.ducReceiver,
                amount: saleItemPrice * 0.95
            ))
        } else {
            self.saleCuts.append(NFTStorefrontV2.SaleCut(
                receiver: self.ducReceiver,
                amount: saleItemPrice * 0.94
            ))
            self.saleCuts.append(NFTStorefrontV2.SaleCut(
                receiver: self.ducReceiverCreator,
                amount: saleItemPrice * 0.01
            ))
        }
        self.saleCuts.append(NFTStorefrontV2.SaleCut(
            receiver: self.ducReceiverMarket,
            amount: saleItemPrice * 0.05
        ))
    }

    execute {
        self.storefront.createListing(
            nftProviderCapability: self.flovatarNFTProvider,
            nftType: Type<@Flovatar.NFT>(),
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
