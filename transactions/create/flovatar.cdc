
//import FungibleToken from 0xee82856bf20e2aa6
import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FUSD from "../../contracts/FUSD.cdc"
import Flovatar from "../../contracts/Flovatar.cdc"
import FlovatarComponent from "../../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../../contracts/FlovatarPack.cdc"


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