import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function isInitializedScript(address) {
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

  let flovatarCap = account.getCapability<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath)
  let flovatarComponentCap = account.getCapability<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath)
  let marketplaceCap = account.getCapability<&{FlovatarMarketplace.SalePublic}>(FlovatarMarketplace.CollectionPublicPath)
  let flovatarPackCap = account.getCapability<&{FlovatarPack.CollectionPublic}>(FlovatarPack.CollectionPublicPath)


  return (flovatarCap.check() && flovatarComponentCap.check() && marketplaceCap.check() && flovatarPackCap.check())
}
`,
            args: (arg, t) => [
                arg(address, t.Address)
            ],
        });

}
