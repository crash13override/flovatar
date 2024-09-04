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

access(all) fun main(address: Address): Bool {

  let account = getAccount(address)

  let flovatarCap = account.capabilities.get<&Flovatar.Collection>(Flovatar.CollectionPublicPath)
  let flovatarComponentCap = account.capabilities.get<&FlovatarComponent.Collection>(FlovatarComponent.CollectionPublicPath)
  let marketplaceCap = account.capabilities.get<&FlovatarMarketplace.SaleCollection>(FlovatarMarketplace.CollectionPublicPath)
  let flovatarPackCap = account.capabilities.get<&FlovatarPack.Collection>(FlovatarPack.CollectionPublicPath)


  return (flovatarCap.check() && flovatarComponentCap.check() && marketplaceCap.check() && flovatarPackCap.check())
}
`,
            args: (arg, t) => [
                arg(address, t.Address)
            ],
        });

}
