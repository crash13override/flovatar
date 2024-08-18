import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function flovatarSaleCreateTx(flovatarId, price) {
    return await fcl
        .mutate({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

transaction(
    flovatarId: UInt64,
    price: UFix64) {

    let flovatarCollection: &Flovatar.Collection
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
        self.flovatarCollection = account.borrow<&Flovatar.Collection>(from: Flovatar.CollectionStoragePath)!
    }

    execute {
        let flovatar <- self.flovatarCollection.withdraw(withdrawID: flovatarId) as! @Flovatar.NFT
        self.marketplace.listFlovatarForSale(token: <- flovatar, price: price)
    }
}
`,
            args: (arg, t) => [
                arg(''+flovatarId, t.UInt64),
                arg(floatArg(price), t.UFix64)
            ],
            limit: 9999
        });

}
