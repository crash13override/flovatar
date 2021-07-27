
//import FungibleToken from 0xee82856bf20e2aa6
import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import Website from "../../contracts/Website.cdc"
import Webshot from "../../contracts/Webshot.cdc"
import Marketplace from "../../contracts/Marketplace.cdc"
import Drop from "../../contracts/Drop.cdc"


//this transaction creates a new webshot
transaction(
    websiteAddress: Address,
    websiteId: UInt64,
    ipfs: {String: String},
    content: String,
    imgUrl: String) {

    let client: &Drop.Admin
    let ownerCollection: Capability<&{Webshot.CollectionPublic}>

    prepare(account: AuthAccount) {
        self.client = account.borrow<&Drop.Admin>(from: Drop.WebshotAdminStoragePath) ?? panic("could not load webshot admin")
        self.ownerCollection = getAccount(websiteAddress).getCapability<&{Webshot.CollectionPublic}>(Webshot.CollectionPublicPath)
    }

    execute {
        let webshot <-  self.client.mintWebshot(
            websiteAddress: websiteAddress,
            websiteId: websiteId,
            ipfs: ipfs,
            content: content,
            imgUrl: imgUrl
            )
        self.ownerCollection.borrow()!.deposit(token: <- webshot)
    }
}