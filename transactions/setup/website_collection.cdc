
//import FungibleToken from 0xee82856bf20e2aa6
import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import Website from "../../contracts/Website.cdc"
import Webshot from "../../contracts/Webshot.cdc"
import Marketplace from "../../contracts/Marketplace.cdc"
import Drop from "../../contracts/Drop.cdc"


//this transaction will add teh website collection
transaction() {

    prepare(account: AuthAccount) {
        if(account.getCapability<&{Website.CollectionPublic}>(Website.CollectionPublicPath) == nil) {
            account.save<@NonFungibleToken.Collection>(<- Website.createEmptyCollection(), to: Website.CollectionStoragePath)
            account.link<&{Website.CollectionPublic}>(Website.CollectionPublicPath, target: Website.CollectionStoragePath)
        }
    }

}
