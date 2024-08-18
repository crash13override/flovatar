import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function isInitializedDapperDustBakScript(address) {
    if (address == null)
        throw new Error("isInitialized(address) -- address required")

    return await fcl
        .query({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace, Flobot, FlovatarDustToken, FlovatarDustCollectible, FlovatarDustCollectibleAccessory, FlovatarDustCollectibleTemplate from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken
import MetadataViews from 0xMetadataViews
import FlowUtilityToken from 0xDuc
import NFTStorefrontV2 from 0xStorefront2

pub fun main(address: Address): Bool {

  let account = getAccount(address)

  let flovatarCap = account.getCapability<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath)
  let flobotCap = account.getCapability<&{Flobot.CollectionPublic}>(Flobot.CollectionPublicPath)
  let flovatarComponentCap = account.getCapability<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath)
  let storefrontRef = account.getCapability<&NFTStorefrontV2.Storefront{NFTStorefrontV2.StorefrontPublic}>(NFTStorefrontV2.StorefrontPublicPath)
  let futRef = account.getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
  let flovatarPackCap = account.getCapability<&{FlovatarPack.CollectionPublic}>(FlovatarPack.CollectionPublicPath)
  let flovatarCollectibleCap = account.getCapability<&{FlovatarDustCollectible.CollectionPublic}>(FlovatarDustCollectible.CollectionPublicPath)
  let flovatarAccessoryCap = account.getCapability<&{FlovatarDustCollectibleAccessory.CollectionPublic}>(FlovatarDustCollectibleAccessory.CollectionPublicPath)

  return (flovatarCap.check() && flobotCap.check() && flovatarComponentCap.check() && flovatarPackCap.check() && storefrontRef.check() && futRef.check() && flovatarCollectibleCap.check() && flovatarAccessoryCap.check())
}
`,
            args: (arg, t) => [
                arg(address, t.Address)
            ],
        });

}
