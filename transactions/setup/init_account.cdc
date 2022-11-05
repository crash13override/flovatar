import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"
import Flovatar from "../../contracts/Flovatar.cdc"
import FlovatarComponent from "../../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../../contracts/FlovatarPack.cdc"
import FlovatarMarketplace from "../../contracts/FlovatarMarketplace.cdc"
import MetadataViews from "../contracts/MetadaViews.cdc"
import FlovatarDustToken from "../../contracts/FlovatarDustToken.cdc"

transaction {
  // We want the account's address for later so we can verify if the account was initialized properly
  let address: Address

  prepare(account: AuthAccount) {
    // save the address for the post check
    self.address = account.address


    let flovatarCap = account.getCapability<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath)
    if(!flovatarCap.check()) {
        account.save<@NonFungibleToken.Collection>(<- Flovatar.createEmptyCollection(), to: Flovatar.CollectionStoragePath)
        account.link<&Flovatar.Collection{Flovatar.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(Flovatar.CollectionPublicPath, target: Flovatar.CollectionStoragePath)
    } else {
        let flovatarCapMeta = account.getCapability<&Flovatar.Collection{Flovatar.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(Flovatar.CollectionPublicPath)
        if(!flovatarCapMeta.check()) {
            account.unlink(Flovatar.CollectionPublicPath)
            account.link<&Flovatar.Collection{Flovatar.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(Flovatar.CollectionPublicPath, target: Flovatar.CollectionStoragePath)
        }
    }

    let flovatarComponentCap = account.getCapability<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath)
    if(!flovatarComponentCap.check()) {
        account.save<@NonFungibleToken.Collection>(<- FlovatarComponent.createEmptyCollection(), to: FlovatarComponent.CollectionStoragePath)
        account.link<&FlovatarComponent.Collection{FlovatarComponent.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(FlovatarComponent.CollectionPublicPath, target: FlovatarComponent.CollectionStoragePath)
    } else {
        let flovatarComponentCapMeta = account.getCapability<&FlovatarComponent.Collection{FlovatarComponent.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(FlovatarComponent.CollectionPublicPath)
        if(!flovatarComponentCapMeta.check()) {
            account.unlink(FlovatarComponent.CollectionPublicPath)
            account.link<&FlovatarComponent.Collection{FlovatarComponent.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(FlovatarComponent.CollectionPublicPath, target: FlovatarComponent.CollectionStoragePath)
        }
    }

    let flovatarPackCap = account.getCapability<&{FlovatarPack.CollectionPublic}>(FlovatarPack.CollectionPublicPath)
    if(!flovatarPackCap.check()) {
        let wallet =  account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        account.save<@FlovatarPack.Collection>(<- FlovatarPack.createEmptyCollection(ownerVault: wallet), to: FlovatarPack.CollectionStoragePath)
        account.link<&{FlovatarPack.CollectionPublic}>(FlovatarPack.CollectionPublicPath, target: FlovatarPack.CollectionStoragePath)
    }

    let marketplaceCap = account.getCapability<&{FlovatarMarketplace.SalePublic}>(FlovatarMarketplace.CollectionPublicPath)
    if(!marketplaceCap.check()) {
        let wallet =  account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)

        // store an empty Sale Collection in account storage
        account.save<@FlovatarMarketplace.SaleCollection>(<- FlovatarMarketplace.createSaleCollection(ownerVault: wallet), to:FlovatarMarketplace.CollectionStoragePath)

        // publish a capability to the Collection in storage
        account.link<&{FlovatarMarketplace.SalePublic}>(FlovatarMarketplace.CollectionPublicPath, target: FlovatarMarketplace.CollectionStoragePath)
    }

    let dustTokenCap = account.getCapability<&FlovatarDustToken.Vault{FlovatarDustToken.Receiver}>(FlovatarDustToken.VaultReceiverPath)
    if(!dustTokenCap.check()) {
        let vault <- FlovatarDustToken.createEmptyVault()
        // Store the vault in the account storage
        account.save<@FlovatarDustToken.Vault>(<-vault, to: FlovatarDustToken.VaultStoragePath)
        // Create a public Receiver capability to the Vault
        account.link<&FlovatarDustToken.Vault{FlovatarDustToken.Receiver, FlovatarDustToken.Balance}>(FlovatarDustToken.VaultReceiverPath, target: FlovatarDustToken.VaultStoragePath)
        account.link<&FlovatarDustToken.Vault{FlovatarDustToken.Balance}>(FlovatarDustToken.VaultBalancePath, target: FlovatarDustToken.VaultStoragePath)
    }

  }

}