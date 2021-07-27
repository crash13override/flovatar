
//import FungibleToken from 0xee82856bf20e2aa6
import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FUSD from "../../contracts/FUSD.cdc"
import Website from "../../contracts/Website.cdc"
import Webshot from "../../contracts/Webshot.cdc"
import Marketplace from "../../contracts/Marketplace.cdc"
import Drop from "../../contracts/Drop.cdc"


//this transaction will create a new Webshot and create and auction for it
transaction(
    websiteAddress: Address,
    webshotId: UInt64,
    minimumBidIncrement: UFix64,
    startPrice: UFix64,
    duration: UFix64,
    extensionOnLateBid:UFix64) {

    let client: &Drop.Admin
    let ownerCollection: Capability<&{Webshot.CollectionPublic}>
    let ownerWallet: Capability<&FUSD.Vault{FungibleToken.Receiver}>
    let webshotCollection: &Webshot.Collection

    prepare(account: AuthAccount) {
        self.client = account.borrow<&Drop.Admin>(from: Drop.WebshotAdminStoragePath) ?? panic("could not load webshot admin")
        self.ownerCollection = getAccount(websiteAddress).getCapability<&{Webshot.CollectionPublic}>(Webshot.CollectionPublicPath)
        self.ownerWallet =  getAccount(websiteAddress).getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver)
        self.webshotCollection= account.borrow<&Webshot.Collection>(from: Webshot.CollectionStoragePath)!
    }

    execute {
        let webshot <- self.webshotCollection.withdraw(withdrawID: webshotId) as! @Webshot.NFT

        self.client.createAuction(
            nft: <- webshot,
            minimumBidIncrement: minimumBidIncrement,
            startTime: getCurrentBlock().timestamp,
            startPrice: startPrice,
            vaultCap: self.ownerWallet,
            duration: duration,
            extensionOnLateBid: extensionOnLateBid)

    }
}
