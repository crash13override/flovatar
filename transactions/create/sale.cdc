
//import FungibleToken from 0xee82856bf20e2aa6
import FungibleToken from "../../contracts/FungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FUSD from "../../contracts/FUSD.cdc"
import Website from "../../contracts/Website.cdc"
import Webshot from "../../contracts/Webshot.cdc"
import Marketplace from "../../contracts/Marketplace.cdc"
import Drop from "../../contracts/Drop.cdc"


//this transaction will create the saleCollection if not already present and will then put the NFT for sale

transaction(
    webshotId: UInt64,
    price: UFix64) {

    let webshotCollection: &Webshot.Collection
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

        self.marketplace = account.borrow<&Marketplace.SaleCollection>(from: Marketplace.CollectionStoragePath)!
        self.webshotCollection = account.borrow<&Webshot.Collection>(from: Webshot.CollectionStoragePath)!
    }

    execute {
        let webshot <- self.webshotCollection.withdraw(withdrawID: webshotId) as! @Webshot.NFT
        self.marketplace.listForSale(token: <- webshot, price: price)
    }
}
