import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function componentSaleCancelTx(componentId) {
    return await fcl
        .mutate({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

transaction(
    componentId: UInt64
    ) {

    let componentCollection: &FlovatarComponent.Collection
    let marketplace: &FlovatarMarketplace.SaleCollection

    prepare(account: AuthAccount) {

        let marketplaceCap = account.getCapability<&{FlovatarMarketplace.SalePublic}>(FlovatarMarketplace.CollectionPublicPath)
        // if sale collection is not created yet we make it.
        if !marketplaceCap.check() {
             let wallet =  account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)
             let sale <- FlovatarMarketplace.createSaleCollection(ownerVault: wallet)

            // store an empty NFT Collection in account storage
            account.save<@FlovatarMarketplace.SaleCollection>(<- sale, to:FlovatarMarketplace.CollectionStoragePath)

            // publish a capability to the Collection in storage
            account.link<&{FlovatarMarketplace.SalePublic}>(FlovatarMarketplace.CollectionPublicPath, target: FlovatarMarketplace.CollectionStoragePath)
        }

        self.marketplace = account.borrow<&FlovatarMarketplace.SaleCollection>(from: FlovatarMarketplace.CollectionStoragePath)!
        self.componentCollection = account.borrow<&FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!
    }

    execute {
        let component <- self.marketplace.withdrawFlovatarComponent(tokenId: componentId)
        self.componentCollection.deposit(token: <- component);
    }
}
`,
            args: (arg, t) => [
                arg(''+componentId, t.UInt64)
            ],
            limit: 9999
        });

}
