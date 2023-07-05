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


//this transaction will create a new Webshot and create and auction for it
transaction(
    name: String,
    description: String,
    series: UInt64,
    layer: UInt32,
    rarity: String,
    basePrice: UFix64,
    svg: String,
    maxMintableComponents: UInt64) {

    let flovatarDustCollectibleTemplateCollection: &FlovatarDustCollectibleTemplate.Collection
    let flovatarAdmin: &FlovatarDustCollectible.Admin

    prepare(account: AuthAccount) {
        self.flovatarDustCollectibleTemplateCollection = account.borrow<&FlovatarDustCollectibleTemplate.Collection>(from: FlovatarDustCollectibleTemplate.CollectionStoragePath)!

        self.flovatarAdmin = account.borrow<&FlovatarDustCollectible.Admin>(from: FlovatarDustCollectible.AdminStoragePath)!
    }

    execute {
        let flovatarDustCollectibleTemplate <- self.flovatarAdmin.createComponentTemplate(
            name: name,
            description: description,
            series: series,
            layer: layer,
            metadata: {},
            rarity: rarity,
            basePrice: basePrice,
            svg: svg,
            maxMintableComponents: maxMintableComponents
            ) as! @FlovatarDustCollectibleTemplate.CollectibleTemplate


        self.flovatarDustCollectibleTemplateCollection.deposit(collectibleTemplate: <-flovatarDustCollectibleTemplate)

    }
}