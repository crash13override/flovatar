import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FUSD from "../../contracts/FUSD.cdc"
import Flovatar from "../../contracts/Flovatar.cdc"
import FlovatarComponent from "../../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../../contracts/FlovatarPack.cdc"
import NFTStorefront from "../../contracts/NFTStorefront.cdc"

transaction {
  // We want the account's address for later so we can verify if the account was initialized properly
  let address: Address

  prepare(account: AuthAccount) {
    // save the address for the post check
    self.address = account.address


    if(account.borrow<&FUSD.Vault>(from: /storage/fusdVault) == nil) {
      account.save(<-FUSD.createEmptyVault(), to: /storage/fusdVault)
      account.link<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver, target: /storage/fusdVault)
      account.link<&FUSD.Vault{FungibleToken.Balance}>(/public/fusdBalance, target: /storage/fusdVault)
    }

    let flovatarCap = account.getCapability<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath)
    if(!flovatarCap.check()) {
        // store an empty NFT Collection in account storage
        account.save<@NonFungibleToken.Collection>(<- Flovatar.createEmptyCollection(), to: Flovatar.CollectionStoragePath)

        // publish a capability to the Collection in storage
        account.link<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath, target: Flovatar.CollectionStoragePath)
    }

    let flovatarComponentCap = account.getCapability<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath)
    if(!flovatarComponentCap.check()) {
        account.save<@NonFungibleToken.Collection>(<- FlovatarComponent.createEmptyCollection(), to: FlovatarComponent.CollectionStoragePath)
        account.link<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath, target: FlovatarComponent.CollectionStoragePath)
    }

    let flovatarPackCap = account.getCapability<&{FlovatarPack.CollectionPublic}>(FlovatarPack.CollectionPublicPath)
    if(!flovatarPackCap.check()) {
        account.save<@FlovatarPack.Collection>(<- FlovatarPack.createEmptyCollection(), to: FlovatarPack.CollectionStoragePath)
        account.link<&{FlovatarPack.CollectionPublic}>(FlovatarPack.CollectionPublicPath, target: FlovatarPack.CollectionStoragePath)
    }

    if account.borrow<&NFTStorefront.Storefront>(from: NFTStorefront.StorefrontStoragePath) == nil {
          let storefront <- NFTStorefront.createStorefront() as! @NFTStorefront.Storefront
          account.save(<-storefront, to: NFTStorefront.StorefrontStoragePath)
          account.link<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(NFTStorefront.StorefrontPublicPath, target: NFTStorefront.StorefrontStoragePath)
    }
  }

}