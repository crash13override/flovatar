import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function initAccountTx() {
    return await fcl
        .mutate({
            cadence: `
import Flobot, Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace from 0xFlovatar
import FungibleToken from 0xFungible
import NonFungibleToken from 0xNonFungible
import FlowToken from 0xFlowToken
import MetadataViews from 0xMetadataViews


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

    let marketplaceCap = account.getCapability<&{FlovatarMarketplace.SalePublic}>(FlovatarMarketplace.CollectionPublicPath)
    if(!marketplaceCap.check()) {
        let wallet =  account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)

        // store an empty Sale Collection in account storage
        account.save<@FlovatarMarketplace.SaleCollection>(<- FlovatarMarketplace.createSaleCollection(ownerVault: wallet), to:FlovatarMarketplace.CollectionStoragePath)

        // publish a capability to the Collection in storage
        account.link<&{FlovatarMarketplace.SalePublic}>(FlovatarMarketplace.CollectionPublicPath, target: FlovatarMarketplace.CollectionStoragePath)
    }


  }

}
`,
            args: (arg, t) => [
            ],
            limit: 9999
        });

}
