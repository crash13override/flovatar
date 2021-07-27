
//import FungibleToken from 0xee82856bf20e2aa6
import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import Website from "../../contracts/Website.cdc"
import Webshot from "../../contracts/Webshot.cdc"
import Marketplace from "../../contracts/Marketplace.cdc"
import Drop from "../../contracts/Drop.cdc"


//this transaction is run as the account that will host and own the marketplace to set up the
//webshotAdmin client and create the empty content and webshot collection
transaction() {

    prepare(account: AuthAccount) {
        if(account.getCapability<&{Webshot.CollectionPublic}>(Webshot.CollectionPublicPath) == nil) {
            account.save<@NonFungibleToken.Collection>(<- Webshot.createEmptyCollection(), to: Webshot.CollectionStoragePath)
            account.link<&{Webshot.CollectionPublic}>(Webshot.CollectionPublicPath, target: Webshot.CollectionStoragePath)
        }
    }

}