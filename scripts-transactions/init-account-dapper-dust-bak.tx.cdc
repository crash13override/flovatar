import "Flobot"
import "Flovatar"
import "FlovatarComponent"
import "FlovatarPack"
import "FlovatarDustCollectible"
import "FlovatarMarketplace"
import "FlovatarDustCollectibleAccessory"
import "FlovatarDustToken"
import "FlowToken"
import "NonFungibleToken"
import "FungibleToken"
import "FlowUtilityToken"
import "NFTStorefrontV2"
import "TokenForwarding"

transaction {
  // We want the account's address for later so we can verify if the account was initialized properly
  let address: Address

  prepare(account: auth(Storage, Capabilities) &Account) {
    // save the address for the post check
    self.address = account.address


    if account.storage.borrow<&Flovatar.Collection>(from: Flovatar.CollectionStoragePath) == nil {
        account.storage.save<@{NonFungibleToken.Collection}>(<- Flovatar.createEmptyCollection(nftType: Type<@Flovatar.Collection>()), to: Flovatar.CollectionStoragePath)
    }
    let flovatarCap = account.capabilities.get<&Flovatar.Collection>(Flovatar.CollectionPublicPath)
    if(!flovatarCap.check()) {
        account.capabilities.unpublish(Flovatar.CollectionPublicPath)
        account.capabilities.publish(
            account.capabilities.storage.issue<&Flovatar.Collection>(Flovatar.CollectionStoragePath),
            at: Flovatar.CollectionPublicPath
        )
    }


    if account.storage.borrow<&Flobot.Collection>(from: Flobot.CollectionStoragePath) == nil {
        account.storage.save<@{NonFungibleToken.Collection}>(<- Flobot.createEmptyCollection(nftType: Type<@Flobot.Collection>()), to: Flobot.CollectionStoragePath)
    }
    let flobotCap = account.capabilities.get<&Flobot.Collection>(Flobot.CollectionPublicPath)
    if(!flobotCap.check()) {
        account.capabilities.unpublish(Flobot.CollectionPublicPath)
        account.capabilities.publish(
            account.capabilities.storage.issue<&Flobot.Collection>(Flobot.CollectionStoragePath),
            at: Flobot.CollectionPublicPath
        )
    }


    if account.storage.borrow<&FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath) == nil {
        account.storage.save<@{NonFungibleToken.Collection}>(<- FlovatarComponent.createEmptyCollection(nftType: Type<@FlovatarComponent.Collection>()), to: FlovatarComponent.CollectionStoragePath)
    }
    let flovatarComponentCap = account.capabilities.get<&FlovatarComponent.Collection>(FlovatarComponent.CollectionPublicPath)
    if(!flovatarComponentCap.check()) {
        account.capabilities.unpublish(FlovatarComponent.CollectionPublicPath)
        account.capabilities.publish(
            account.capabilities.storage.issue<&FlovatarComponent.Collection>(FlovatarComponent.CollectionStoragePath),
            at: FlovatarComponent.CollectionPublicPath
        )
    }


    let flovatarPackCap = account.capabilities.get<&FlovatarPack.Collection>(FlovatarPack.CollectionPublicPath)
    if(!flovatarPackCap.check()) {
        let wallet =  account.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)
        account.storage.save<@FlovatarPack.Collection>(<- FlovatarPack.createEmptyCollection(ownerVault: wallet), to: FlovatarPack.CollectionStoragePath)
        account.capabilities.unpublish(FlovatarPack.CollectionPublicPath)
        account.capabilities.publish(
            account.capabilities.storage.issue<&FlovatarPack.Collection>(FlovatarPack.CollectionStoragePath),
            at: FlovatarPack.CollectionPublicPath
        )
    }


    if account.storage.borrow<&FlovatarDustCollectible.Collection>(from: FlovatarDustCollectible.CollectionStoragePath) == nil {
        account.storage.save<@{NonFungibleToken.Collection}>(<- FlovatarDustCollectible.createEmptyCollection(nftType: Type<@FlovatarDustCollectible.Collection>()), to: FlovatarDustCollectible.CollectionStoragePath)
    }
    let flovatarCollectibleCap = account.capabilities.get<&FlovatarDustCollectible.Collection>(FlovatarDustCollectible.CollectionPublicPath)
    if(!flovatarCollectibleCap.check()) {
        account.capabilities.unpublish(FlovatarDustCollectible.CollectionPublicPath)
        account.capabilities.publish(
            account.capabilities.storage.issue<&FlovatarDustCollectible.Collection>(FlovatarDustCollectible.CollectionStoragePath),
            at: FlovatarDustCollectible.CollectionPublicPath
        )
    }


    if account.storage.borrow<&FlovatarDustCollectibleAccessory.Collection>(from: FlovatarDustCollectibleAccessory.CollectionStoragePath) == nil {
        account.storage.save<@{NonFungibleToken.Collection}>(<- FlovatarDustCollectibleAccessory.createEmptyCollection(nftType: Type<@FlovatarDustCollectibleAccessory.Collection>()), to: FlovatarDustCollectibleAccessory.CollectionStoragePath)
    }
    let flovatarAccessoryCap = account.capabilities.get<&FlovatarDustCollectibleAccessory.Collection>(FlovatarDustCollectibleAccessory.CollectionPublicPath)
    if(!flovatarAccessoryCap.check()) {
        account.capabilities.unpublish(FlovatarDustCollectibleAccessory.CollectionPublicPath)
        account.capabilities.publish(
            account.capabilities.storage.issue<&FlovatarDustCollectibleAccessory.Collection>(FlovatarDustCollectibleAccessory.CollectionStoragePath),
            at: FlovatarDustCollectibleAccessory.CollectionPublicPath
        )
    }

    // If the account doesn't already have a Storefront
    if account.storage.borrow<&NFTStorefrontV2.Storefront>(from: NFTStorefrontV2.StorefrontStoragePath) == nil {

        // Create a new empty Storefront
        let storefront <- NFTStorefrontV2.createStorefront() as! @NFTStorefrontV2.Storefront

        // save it to the account
        account.storage.save(<-storefront, to: NFTStorefrontV2.StorefrontStoragePath)

        // create a public capability for the .Storefront & publish
        let storefrontPublicCap = account.capabilities.storage.issue<&NFTStorefrontV2.Storefront>(
                NFTStorefrontV2.StorefrontStoragePath
            )
        account.capabilities.unpublish(NFTStorefrontV2.StorefrontPublicPath)
        account.capabilities.publish(storefrontPublicCap, at: NFTStorefrontV2.StorefrontPublicPath)
    
    }

    if account.storage.borrow<&{FungibleToken.Receiver}>(from: /storage/flowUtilityTokenReceiver) == nil {
        let dapper = getAccount(0xFut)
        let dapperFUTReceiver = dapper.capabilities.get<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)

        // Create a new Forwarder resource for FUT and store it in the new account's storage
        let futForwarder <- TokenForwarding.createNewForwarder(recipient: dapperFUTReceiver)
        account.storage.save(<-futForwarder, to: /storage/flowUtilityTokenReceiver)

        // Publish a Receiver capability for the new account, which is linked to the FUT Forwarder
        account.capabilities.unpublish(/public/flowUtilityTokenReceiver)
        // Create a public Receiver capability to the Vault
        account.capabilities.publish(
            account.capabilities.storage.issue<&FlowUtilityToken.Vault>(/storage/flowUtilityTokenReceiver),
            at: /public/flowUtilityTokenReceiver
        )
    }

  }

}