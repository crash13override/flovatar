import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function isMetadataInitializedScript(address) {
    if (address == null)
        throw new Error("isInitialized(address) -- address required")

    return await fcl
        .query({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken
import MetadataViews from 0xMetadataViews

pub fun main(address: Address): Bool {

  let account = getAccount(address)

  let flovatarCap = account.getCapability<&Flovatar.Collection{Flovatar.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(Flovatar.CollectionPublicPath)
  let flovatarComponentCap = account.getCapability<&FlovatarComponent.Collection{FlovatarComponent.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(FlovatarComponent.CollectionPublicPath)

  return (flovatarCap.check() && flovatarComponentCap.check())
}
`,
            args: (arg, t) => [
                arg(address, t.Address)
            ],
        });

}
