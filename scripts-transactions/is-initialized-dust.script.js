import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function isInitializedDustScript(address) {
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

pub fun main(address: Address): Bool {

  let account = getAccount(address)

  let flovatarCap = account.getCapability<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath)
  let flobotCap = account.getCapability<&{Flobot.CollectionPublic}>(Flobot.CollectionPublicPath)
  let flovatarComponentCap = account.getCapability<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath)
  let marketplaceCap = account.getCapability<&{FlovatarMarketplace.SalePublic}>(FlovatarMarketplace.CollectionPublicPath)
  let flovatarPackCap = account.getCapability<&{FlovatarPack.CollectionPublic}>(FlovatarPack.CollectionPublicPath)
  let flovatarCollectibleCap = account.getCapability<&{FlovatarDustCollectible.CollectionPublic}>(FlovatarDustCollectible.CollectionPublicPath)
  let flovatarAccessoryCap = account.getCapability<&{FlovatarDustCollectibleAccessory.CollectionPublic}>(FlovatarDustCollectibleAccessory.CollectionPublicPath)
  let dustTokenCap = account.getCapability<&FlovatarDustToken.Vault{FungibleToken.Receiver}>(FlovatarDustToken.VaultReceiverPath)
  let dustTokenCapBalance = account.getCapability<&FlovatarDustToken.Vault{FungibleToken.Balance}>(FlovatarDustToken.VaultBalancePath)

  return (flovatarCap.check() && flobotCap.check() && flovatarComponentCap.check() && marketplaceCap.check() && flovatarPackCap.check() && flovatarCollectibleCap.check() && flovatarAccessoryCap.check() && dustTokenCap.check() && dustTokenCapBalance.check())
}
`,
            args: (arg, t) => [
                arg(address, t.Address)
            ],
        });

}
