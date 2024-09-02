import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function initMetadataViewsTx() {
    return await fcl
        .mutate({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace from 0xFlovatar
import FungibleToken from 0xFungible
import NonFungibleToken from 0xNonFungible
import FlowToken from 0xFlowToken
import MetadataViews from 0xMetadataViews


transaction {
  // We want the account's address for later so we can verify if the account was initialized properly
  let address: Address

  prepare(account: auth(Capabilities) &Account) {
    // save the address for the post check
    self.address = account.address

    let flovatarCapMeta = account.capabilities.get<&Flovatar.Collection>(Flovatar.CollectionPublicPath)
    if(!flovatarCapMeta.check()) {
        account.capabilities.unpublish(Flovatar.CollectionPublicPath)
        account.capabilities.publish(
            account.capabilities.storage.issue<&Flovatar.Collection>(Flovatar.CollectionStoragePath),
            at: Flovatar.CollectionPublicPath
        )
    }

    let flovatarComponentCapMeta = account.capabilities.get<&FlovatarComponent.Collection>(FlovatarComponent.CollectionPublicPath)
    if(!flovatarComponentCapMeta.check()) {
        account.capabilities.unpublish(FlovatarComponent.CollectionPublicPath)
        account.capabilities.publish(
            account.capabilities.storage.issue<&FlovatarComponent.Collection>(FlovatarComponent.CollectionStoragePath),
            at: FlovatarComponent.CollectionPublicPath
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
