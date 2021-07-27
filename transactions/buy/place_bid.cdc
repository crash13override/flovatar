
//import FungibleToken from 0xee82856bf20e2aa6
import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FUSD from "../../contracts/FUSD.cdc"
import Website from "../../contracts/Website.cdc"
import Webshot from "../../contracts/Webshot.cdc"
import Marketplace from "../../contracts/Marketplace.cdc"
import Drop from "../../contracts/Drop.cdc"


//this transaction places a bid for a specific auction
transaction(auctionAddress: Address, auctionId: UInt64, bidAmount: UFix64) {

    let vaultCap: Capability<&FUSD.Vault{FungibleToken.Receiver}>
    let collectionCap: Capability<&{Webshot.CollectionPublic}>
    let auctionCap: Capability<&{Drop.AuctionPublic}>
    let temporaryVault: @FungibleToken.Vault

    prepare(account: AuthAccount) {

        // get the references to the buyer's Vault and NFT Collection receiver
        var collectionCap = account.getCapability<&{Webshot.CollectionPublic}>(Webshot.CollectionPublicPath)

        // if collection is not created yet we make it.
        if !collectionCap.check() {
            // store an empty NFT Collection in account storage
            account.save<@NonFungibleToken.Collection>(<- Webshot.createEmptyCollection(), to: Webshot.CollectionStoragePath)

            // publish a capability to the Collection in storage
            account.link<&{Webshot.CollectionPublic}>(Webshot.CollectionPublicPath, target: Webshot.CollectionStoragePath)
        }

        self.collectionCap = collectionCap

        self.vaultCap = account.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver)

        let vaultRef = account.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow owner's Vault reference")

        let seller = getAccount(auctionAddress)
        self.auctionCap = seller.getCapability<&{Drop.AuctionPublic}>(Drop.CollectionPublicPath)

        // withdraw tokens from the buyer's Vault
        self.temporaryVault <- vaultRef.withdraw(amount: bidAmount)
    }

    execute {
        self.auctionCap.borrow()!.placeBid(auctionId: auctionId, bidTokens: <- self.temporaryVault, vaultCap: self.vaultCap, collectionCap: self.collectionCap)
    }

}
