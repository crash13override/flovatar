import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FUSD from "../../contracts/FUSD.cdc"
import Flovatar from "../../contracts/Flovatar.cdc"
import FlovatarComponent from "../../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../../contracts/FlovatarPack.cdc"
import Marketplace from "../../contracts/Marketplace.cdc"


//this transaction buys a Pack by providing the secret key to allow it
transaction(saleAddress: Address, tokenId: UInt64, amount: UFix64, secret: String) {

    // reference to the buyer's NFT collection where they
    // will store the bought NFT

    let vaultCap: Capability<&FUSD.Vault{FungibleToken.Receiver}>
    let collectionCap: Capability<&{FlovatarPack.CollectionPublic}>
    // Vault that will hold the tokens that will be used
    // to buy the NFT
    let temporaryVault: @FungibleToken.Vault

    prepare(account: AuthAccount) {

        let flovatarPackCap = account.getCapability<&{FlovatarPack.CollectionPublic}>(FlovatarPack.CollectionPublicPath)
        if(!flovatarPackCap.check()) {
            let wallet =  account.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver)
            account.save<@FlovatarPack.Collection>(<- FlovatarPack.createEmptyCollection(ownerVault: wallet), to: FlovatarPack.CollectionStoragePath)
            account.link<&{FlovatarPack.CollectionPublic}>(FlovatarPack.CollectionPublicPath, target: FlovatarPack.CollectionStoragePath)
        }

        if(account.borrow<&FUSD.Vault>(from: /storage/fusdVault) == nil) {
          account.save(<-FUSD.createEmptyVault(), to: /storage/fusdVault)
          account.link<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver, target: /storage/fusdVault)
          account.link<&FUSD.Vault{FungibleToken.Balance}>(/public/fusdBalance, target: /storage/fusdVault)
        }


        self.collectionCap = flovatarPackCap

        self.vaultCap = account.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver)

        let vaultRef = account.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow owner's Vault reference")

        // withdraw tokens from the buyer's Vault
        self.temporaryVault <- vaultRef.withdraw(amount: amount)
    }

    execute {
        // get the read-only account storage of the seller
        let seller = getAccount(saleAddress)

        let packmarket = seller.getCapability(FlovatarPack.CollectionPublicPath).borrow<&{FlovatarPack.CollectionPublic}>()
                         ?? panic("Could not borrow seller's sale reference")

        packmarket.purchase(tokenId: tokenId, recipientCap: self.collectionCap, buyTokens: <- self.temporaryVault, secret: secret)
    }

}