
import "Flobot"
import "Flovatar"
import "FlovatarComponent"
import "FlovatarPack"
import "FlovatarMarketplace"
import "FlovatarDustCollectible"
import "FlovatarDustCollectibleAccessory"
import "FlovatarDustToken"
import "FlowToken"
import "NonFungibleToken"

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

    let marketplaceCap = account.capabilities.get<&FlovatarMarketplace.SaleCollection>(FlovatarMarketplace.CollectionPublicPath)
    if(!marketplaceCap.check()) {
        let wallet =  account.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)

        // store an empty Sale Collection in account storage
        account.storage.save<@FlovatarMarketplace.SaleCollection>(<- FlovatarMarketplace.createSaleCollection(ownerVault: wallet), to:FlovatarMarketplace.CollectionStoragePath)

        // publish a capability to the Collection in storage
        account.capabilities.unpublish(FlovatarMarketplace.CollectionPublicPath)
        account.capabilities.publish(
            account.capabilities.storage.issue<&FlovatarMarketplace.SaleCollection>(FlovatarMarketplace.CollectionStoragePath),
            at: FlovatarMarketplace.CollectionPublicPath
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



    if account.storage.borrow<&FlovatarDustToken.Vault>(from: FlovatarDustToken.VaultStoragePath) == nil {
        let vault <- FlovatarDustToken.createEmptyVault(vaultType: Type<@FlovatarDustToken.Vault>())
        account.storage.save(<-vault, to: FlovatarDustToken.VaultStoragePath)
    }

    let dustTokenCap = account.capabilities.get<&FlovatarDustToken.Vault>(FlovatarDustToken.VaultReceiverPath)
    if(!dustTokenCap.check()) {
        account.capabilities.unpublish(FlovatarDustToken.VaultReceiverPath)
            // Create a public Receiver capability to the Vault
        account.capabilities.publish(
            account.capabilities.storage.issue<&FlovatarDustToken.Vault>(FlovatarDustToken.VaultStoragePath),
            at: FlovatarDustToken.VaultReceiverPath
        )
    }

    let dustTokenCapBalance = account.capabilities.get<&FlovatarDustToken.Vault>(FlovatarDustToken.VaultBalancePath)
    if(!dustTokenCapBalance.check()) {
        account.capabilities.unpublish(FlovatarDustToken.VaultBalancePath)
        // Create a public Receiver capability to the Vault
        account.capabilities.publish(
            account.capabilities.storage.issue<&FlovatarDustToken.Vault>(FlovatarDustToken.VaultStoragePath),
            at: FlovatarDustToken.VaultBalancePath
        )
    }

  }

}