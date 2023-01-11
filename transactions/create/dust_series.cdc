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
    svgPrefix: String,
    svgSuffix: String,
    priceIncrease: UFix64,
    layersId: [UInt32],
    layersName: [String],
    layersIsAccessory: [Bool],
    colorsId: [UInt32],
    colorsName: [String],
    maxMintable: UInt64) {

    let flovatarDustCollectibleTemplateCollection: &FlovatarDustCollectibleTemplate.Collection
    let flovatarAdmin: &FlovatarDustCollectible.Admin

    prepare(account: AuthAccount) {
        self.flovatarDustCollectibleTemplateCollection = account.borrow<&FlovatarDustCollectibleTemplate.Collection>(from: FlovatarDustCollectibleTemplate.CollectionStoragePath)!

        self.flovatarAdmin = account.borrow<&FlovatarDustCollectible.Admin>(from: FlovatarDustCollectible.AdminStoragePath)!
    }

    execute {
        let layers: {UInt32: FlovatarDustCollectibleTemplate.Layer}
        var i: UInt32 = UInt32(0)
        while(i <  UInt32(layersId.length)){
            layers.insert(key: layersId[i]!, Layer(id: layersId[i]!, name: layersName[i]!, isAccessory: layersIsAccessory[i]!))
        }


        let colors: {UInt32: String}
        i = UInt32(0)
        while(i <  UInt32(colorsId.length)){
            colors.insert(key: colorsId[i]!, colorsName[i]!)
        }

        let flovatarDustCollectibleSeries <- self.flovatarAdmin.createCollectibleSeries(
            name: name,
            description: description,
            svgPrefix: svgPrefix,
            svgSuffix: svgSuffix,
            priceIncrease: priceIncrease,
            layers: layers,
            colors: colors,
            metadata: {},
            maxMintable: maxMintable
            ) as! @FlovatarDustCollectibleTemplate.CollectibleSeries


        self.flovatarDustCollectibleTemplateCollection.depositSeries(collectibleSeries: <-flovatarDustCollectibleSeries)

    }
}