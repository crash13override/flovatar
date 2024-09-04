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


  }

}
`,
            args: (arg, t) => [
            ],
            limit: 9999
        });

}
