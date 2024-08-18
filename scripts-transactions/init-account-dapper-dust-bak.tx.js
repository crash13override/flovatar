import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function initAccountDapperDustBakTx() {
    let cad = `
import FungibleToken from 0xFungible
import NonFungibleToken from 0xNonFungible
import FlowUtilityToken from 0xDuc
import NFTStorefrontV2 from 0xStorefront2
import MetadataViews from 0xMetadataViews
import TokenForwarding from 0xTokenForwarding
import FlowToken from 0xFlowToken
import Flovatar, FlovatarComponent, FlovatarPack, Flobot, FlovatarDustCollectible, FlovatarDustCollectibleAccessory from 0xFlovatar

transaction {
  // We want the account's address for later so we can verify if the account was initialized properly
  let address: Address

  prepare(account: AuthAccount) {
    // save the address for the post check
    self.address = account.address


    if account.borrow<&Flovatar.Collection>(from: Flovatar.CollectionStoragePath) == nil {
        account.save<@NonFungibleToken.Collection>(<- Flovatar.createEmptyCollection(), to: Flovatar.CollectionStoragePath)
    }
    let flovatarCap = account.getCapability<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath)
    if(!flovatarCap.check()) {
        account.unlink(Flovatar.CollectionPublicPath)
        account.link<&Flovatar.Collection{Flovatar.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(Flovatar.CollectionPublicPath, target: Flovatar.CollectionStoragePath)
    }


    if account.borrow<&Flobot.Collection>(from: Flobot.CollectionStoragePath) == nil {
        account.save<@NonFungibleToken.Collection>(<- Flobot.createEmptyCollection(), to: Flobot.CollectionStoragePath)
    }
    let flobotCap = account.getCapability<&{Flobot.CollectionPublic}>(Flobot.CollectionPublicPath)
    if(!flobotCap.check()) {
        account.unlink(Flobot.CollectionPublicPath)
        account.link<&Flobot.Collection{Flobot.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(Flobot.CollectionPublicPath, target: Flobot.CollectionStoragePath)
    }


    if account.borrow<&FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath) == nil {
        account.save<@NonFungibleToken.Collection>(<- FlovatarComponent.createEmptyCollection(), to: FlovatarComponent.CollectionStoragePath)
    }
    let flovatarComponentCap = account.getCapability<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath)
    if(!flovatarComponentCap.check()) {
        account.unlink(FlovatarComponent.CollectionPublicPath)
        account.link<&FlovatarComponent.Collection{FlovatarComponent.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(FlovatarComponent.CollectionPublicPath, target: FlovatarComponent.CollectionStoragePath)
    }

    let flovatarPackCap = account.getCapability<&{FlovatarPack.CollectionPublic}>(FlovatarPack.CollectionPublicPath)
    if(!flovatarPackCap.check()) {
        let wallet =  account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        account.save<@FlovatarPack.Collection>(<- FlovatarPack.createEmptyCollection(ownerVault: wallet), to: FlovatarPack.CollectionStoragePath)
        account.link<&{FlovatarPack.CollectionPublic}>(FlovatarPack.CollectionPublicPath, target: FlovatarPack.CollectionStoragePath)
    }

    if account.borrow<&FlovatarDustCollectible.Collection>(from: FlovatarDustCollectible.CollectionStoragePath) == nil {
        account.save<@NonFungibleToken.Collection>(<- FlovatarDustCollectible.createEmptyCollection(), to: FlovatarDustCollectible.CollectionStoragePath)
    }
    let flovatarCollectibleCap = account.getCapability<&{FlovatarDustCollectible.CollectionPublic}>(FlovatarDustCollectible.CollectionPublicPath)
    if(!flovatarCollectibleCap.check()) {
        account.unlink(FlovatarDustCollectible.CollectionPublicPath)
        account.link<&FlovatarDustCollectible.Collection{FlovatarDustCollectible.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(FlovatarDustCollectible.CollectionPublicPath, target: FlovatarDustCollectible.CollectionStoragePath)
    }

    if account.borrow<&FlovatarDustCollectibleAccessory.Collection>(from: FlovatarDustCollectibleAccessory.CollectionStoragePath) == nil {
        account.save<@NonFungibleToken.Collection>(<- FlovatarDustCollectibleAccessory.createEmptyCollection(), to: FlovatarDustCollectibleAccessory.CollectionStoragePath)
    }
    let flovatarAccessoryCap = account.getCapability<&{FlovatarDustCollectibleAccessory.CollectionPublic}>(FlovatarDustCollectibleAccessory.CollectionPublicPath)
    if(!flovatarAccessoryCap.check()) {
        account.unlink(FlovatarDustCollectibleAccessory.CollectionPublicPath)
        account.link<&FlovatarDustCollectibleAccessory.Collection{FlovatarDustCollectibleAccessory.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(FlovatarDustCollectibleAccessory.CollectionPublicPath, target: FlovatarDustCollectibleAccessory.CollectionStoragePath)
    }

    // If the account doesn't already have a Storefront
    if account.borrow<&NFTStorefrontV2.Storefront>(from: NFTStorefrontV2.StorefrontStoragePath) == nil {

        // Create a new empty Storefront
        let storefront <- NFTStorefrontV2.createStorefront() as! @NFTStorefrontV2.Storefront

        // save it to the account
        account.save(<-storefront, to: NFTStorefrontV2.StorefrontStoragePath)

        // create a public capability for the Storefront
        account.link<&NFTStorefrontV2.Storefront{NFTStorefrontV2.StorefrontPublic}>(NFTStorefrontV2.StorefrontPublicPath, target: NFTStorefrontV2.StorefrontStoragePath)
    }

    if account.borrow<&{FungibleToken.Receiver}>(from: /storage/flowUtilityTokenReceiver) == nil {
        let dapper = getAccount(0xFut)
        let dapperFUTReceiver = dapper.getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)!

        // Create a new Forwarder resource for FUT and store it in the new account's storage
        let futForwarder <- TokenForwarding.createNewForwarder(recipient: dapperFUTReceiver)
        account.save(<-futForwarder, to: /storage/flowUtilityTokenReceiver)

        // Publish a Receiver capability for the new account, which is linked to the FUT Forwarder
        account.link<&FlowUtilityToken.Vault{FungibleToken.Receiver}>(
            /public/flowUtilityTokenReceiver,
            target: /storage/flowUtilityTokenReceiver
        )
    }

  }

}
`;
    //console.log(cad);
    return await fcl
        .mutate({
            cadence: cad,
            args: (arg, t) => [
            ],
            limit: 9999
        });

}
