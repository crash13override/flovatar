
//import FungibleToken from 0xee82856bf20e2aa6
import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import Website from "../../contracts/Website.cdc"
import Webshot from "../../contracts/Webshot.cdc"
import Marketplace from "../../contracts/Marketplace.cdc"
import Drop from "../../contracts/Drop.cdc"


//this transaction is run as the account that will host and own the marketplace to set up the
//webshotAdmin client and create the empty content and webshot collection
transaction(
    name: String,
    url: String,
    ownerName: String,
    ownerAddress: Address,
    description: String,
    webshotMinInterval: UInt64,
    isRecurring: Bool) {

    let client: &Drop.Admin
    let ownerCollection: Capability<&{Website.CollectionPublic}>
    let selfAddress: Address

    prepare(account: AuthAccount) {
        self.client = account.borrow<&Drop.Admin>(from: Drop.WebshotAdminStoragePath) ?? panic("could not load webshot admin")
        self.ownerCollection = getAccount(ownerAddress).getCapability<&{Website.CollectionPublic}>(Website.CollectionPublicPath)
        self.selfAddress = account.address
    }

    execute {
        let website <-  self.client.createWebsite(
            name: name,
            url: url,
            ownerName: ownerName,
            ownerAddress: ownerAddress,
            description: description,
            webshotMinInterval: webshotMinInterval,
            isRecurring: isRecurring
            )

        self.ownerCollection.borrow()!.deposit(token: <- website)

    }

}