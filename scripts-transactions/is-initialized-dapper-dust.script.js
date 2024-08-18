import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function isInitializedDapperDustScript(address) {
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
import FlowUtilityToken from 0xDuc
import NFTStorefrontV2 from 0xStorefront2

pub fun main(address: Address): Bool {

  let account = getAccount(address)

  let flovatarCap = account.getCapability<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath)
  let flovatarComponentCap = account.getCapability<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath)
  let storefrontRef = account.getCapability<&NFTStorefrontV2.Storefront{NFTStorefrontV2.StorefrontPublic}>(NFTStorefrontV2.StorefrontPublicPath)
  let futRef = account.getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
  let flovatarPackCap = account.getCapability<&{FlovatarPack.CollectionPublic}>(FlovatarPack.CollectionPublicPath)

  return (flovatarCap.check() && flovatarComponentCap.check() && flovatarPackCap.check() && storefrontRef.check() && futRef.check())
}
`,
            args: (arg, t) => [
                arg(address, t.Address)
            ],
        });

}
