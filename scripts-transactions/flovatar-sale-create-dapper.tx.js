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
    let ducReceiverCreator: Capability<&{FungibleToken.Receiver}>
    let flovatarNFTProvider: Capability<auth(NonFungibleToken.Withdraw) &Flovatar.Collection>
    let storefront: auth(NFTStorefrontV2.CreateListing) &NFTStorefrontV2.Storefront
    var saleCuts: [NFTStorefrontV2.SaleCut]

    prepare(acct: auth(Storage, Capabilities) &Account) {
        self.saleCuts = []

        self.flovatarNFTProvider = acct.capabilities.storage.issue<auth(NonFungibleToken.Withdraw) &Flovatar.Collection>(Flovatar.CollectionStoragePath)
        assert(self.flovatarNFTProvider.borrow() != nil, message: "Missing or mis-typed Flovatar.Collection provider")

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

        let flovatarData = Flovatar.getFlovatar(address: acct.address, flovatarId: saleItemID)!
        let creatorAccount = getAccount(flovatarData.metadata.creatorAddress)
        self.ducReceiverCreator = creatorAccount.capabilities.get<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)


        // Initialize the buyer's account if it is not already initialized
        let flovatarCap = acct.capabilities.get<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath)
        if(!flovatarCap.check()) {
            acct.storage.save<@{NonFungibleToken.Collection}>(<- Flovatar.createEmptyCollection(nftType: Type<@Flovatar.Collection>()), to: Flovatar.CollectionStoragePath)

            acct.capabilities.unpublish(Flovatar.CollectionPublicPath)
            acct.capabilities.publish(
                acct.capabilities.storage.issue<&Flovatar.Collection>(Flovatar.CollectionStoragePath),
                at: Flovatar.CollectionPublicPath
            )
        }

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
