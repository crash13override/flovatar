import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"
import Flovatar from "../../contracts/Flovatar.cdc"
import FlovatarComponent from "../../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../../contracts/FlovatarPack.cdc"
import FlovatarMarketplace from "../../contracts/FlovatarMarketplace.cdc"
import FlovatarDustCollectible from "../../contracts/FlovatarDustCollectible.cdc"
import FlovatarDustCollectibleTemplate from "../../contracts/FlovatarDustCollectibleTemplate.cdc"
import FlovatarDustToken from "../../contracts/FlovatarDustToken.cdc"


//this transaction will create a new Webshot and create and auction for it
transaction(
    series: UInt64,
    layers: [UInt32],
    templates: [UInt64?],
    amount: UFix64
    ){

    let flovatarCollectibleCollection: &FlovatarDustCollectible.Collection
    let temporaryVault: @FungibleToken.Vault

    let accountAddress: Address

    prepare(account: AuthAccount) {
        self.flovatarCollectibleCollection = account.borrow<&FlovatarDustCollectible.Collection>(from: FlovatarDustCollectible.CollectionStoragePath)!
        self.accountAddress = account.address


        let vaultRef = account.borrow<&{FungibleToken.Provider}>(from: FlovatarDustToken.VaultStoragePath) ?? panic("Could not borrow owner's Vault reference")
        // withdraw tokens from the buyer's Vault
        self.temporaryVault <- vaultRef.withdraw(amount: amount)
    }

    execute {

        let collectible <- FlovatarDustCollectible.createDustCollectible(
            series: series,
            layers: layers,
            templates: templates,
            address: self.accountAddress,
            vault: <-self.temporaryVault
        )

        self.flovatarCollectibleCollection.deposit(token: <-collectible)
    }
}