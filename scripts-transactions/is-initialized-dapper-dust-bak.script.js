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

access(all) fun main(address: Address): Bool {

  let account = getAccount(address)

  let flovatarCap = account.capabilities.get<&Flovatar.Collection>(Flovatar.CollectionPublicPath)
  let flobotCap = account.capabilities.get<&Flobot.Collection>(Flobot.CollectionPublicPath)
  let flovatarComponentCap = account.capabilities.get<&FlovatarComponent.Collection>(FlovatarComponent.CollectionPublicPath)
  let storefrontRef = account.capabilities.get<&NFTStorefrontV2.Storefront>(NFTStorefrontV2.StorefrontPublicPath)
  let futRef = account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
  let flovatarPackCap = account.capabilities.get<&FlovatarPack.Collection>(FlovatarPack.CollectionPublicPath)
  let flovatarCollectibleCap = account.capabilities.get<&FlovatarDustCollectible.Collection>(FlovatarDustCollectible.CollectionPublicPath)
  let flovatarAccessoryCap = account.capabilities.get<&FlovatarDustCollectibleAccessory.Collection>(FlovatarDustCollectibleAccessory.CollectionPublicPath)

  return (flovatarCap.check() && flobotCap.check() && flovatarComponentCap.check() && flovatarPackCap.check() && storefrontRef.check() && futRef.check() && flovatarCollectibleCap.check() && flovatarAccessoryCap.check())
}
`,
            args: (arg, t) => [
                arg(address, t.Address)
            ],
        });

}
