
//import FungibleToken from 0xee82856bf20e2aa6
import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import Website from "../../contracts/Website.cdc"
import Webshot from "../../contracts/Webshot.cdc"
import Marketplace from "../../contracts/Marketplace.cdc"
import Drop from "../../contracts/Drop.cdc"


//this transaction places a bid for a specific auction
transaction(auctionId: UInt64) {

    let client: &Drop.Admin

    prepare(account: AuthAccount) {

        self.client = account.borrow<&Drop.Admin>(from: Drop.WebshotAdminStoragePath) ?? panic("could not load webshot admin")
    }

    execute {
        self.client.settle(auctionId)
    }

}