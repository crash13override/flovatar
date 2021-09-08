import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FUSD from "../../contracts/FUSD.cdc"
import Flovatar from "../../contracts/Flovatar.cdc"
import FlovatarComponent from "../../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../../contracts/FlovatarPack.cdc"
import Marketplace from "../../contracts/Marketplace.cdc"


transaction(
    flovatarId: UInt64,
    price: UFix64
    ) {

    let marketplace: &Marketplace.SaleCollection

    prepare(account: AuthAccount) {

        let marketplaceCap = account.getCapability<&{Marketplace.SalePublic}>(Marketplace.CollectionPublicPath)
        // if sale collection is not created yet we make it.
        if !marketplaceCap.check() {
             let wallet =  account.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver)
             let sale <- Marketplace.createSaleCollection(ownerVault: wallet)

            // store an empty NFT Collection in account storage
            account.save<@Marketplace.SaleCollection>(<- sale, to:Marketplace.CollectionStoragePath)

            // publish a capability to the Collection in storage
            account.link<&{Marketplace.SalePublic}>(Marketplace.CollectionPublicPath, target: Marketplace.CollectionStoragePath)
        }

        self.marketplace=account.borrow<&Marketplace.SaleCollection>(from: Marketplace.CollectionStoragePath)!
    }

    execute {
        self.marketplace.changeFlovatarPrice(tokenId: flovatarId, newPrice: price)
    }
}