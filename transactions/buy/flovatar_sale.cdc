import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FUSD from "../../contracts/FUSD.cdc"
import Flovatar from "../../contracts/Flovatar.cdc"
import FlovatarComponent from "../../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../../contracts/FlovatarPack.cdc"
import Marketplace from "../../contracts/Marketplace.cdc"


//this transaction buy a Flovatar from a direct sale listing from another user
transaction(saleAddress: Address, tokenId: UInt64, amount: UFix64) {

    // reference to the buyer's NFT collection where they
    // will store the bought NFT

    let vaultCap: Capability<&FUSD.Vault{FungibleToken.Receiver}>
    let collectionCap: Capability<&{Flovatar.CollectionPublic}>
    // Vault that will hold the tokens that will be used
    // to buy the NFT
    let temporaryVault: @FungibleToken.Vault

    prepare(account: AuthAccount) {

        // get the references to the buyer's Vault and NFT Collection receiver
        var collectionCap = account.getCapability<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath)

        // if collection is not created yet we make it.
        if !collectionCap.check() {
            // store an empty NFT Collection in account storage
            account.save<@NonFungibleToken.Collection>(<- Flovatar.createEmptyCollection(), to: Flovatar.CollectionStoragePath)
            // publish a capability to the Collection in storage
            account.link<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath, target: Flovatar.CollectionStoragePath)
        }


        if(account.borrow<&FUSD.Vault>(from: /storage/fusdVault) == nil) {
          account.save(<-FUSD.createEmptyVault(), to: /storage/fusdVault)
          account.link<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver, target: /storage/fusdVault)
          account.link<&FUSD.Vault{FungibleToken.Balance}>(/public/fusdBalance, target: /storage/fusdVault)
        }


        self.collectionCap = collectionCap

        self.vaultCap = account.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver)

        let vaultRef = account.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow owner's Vault reference")

        // withdraw tokens from the buyer's Vault
        self.temporaryVault <- vaultRef.withdraw(amount: amount)
    }

    execute {
        // get the read-only account storage of the seller
        let seller = getAccount(saleAddress)

        let marketplace = seller.getCapability(Marketplace.CollectionPublicPath).borrow<&{Marketplace.SalePublic}>()
                         ?? panic("Could not borrow seller's sale reference")

        marketplace.purchaseFlovatar(tokenId: tokenId, recipientCap:self.collectionCap, buyTokens: <- self.temporaryVault)
    }

}