import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"
import Flovatar from "../../contracts/Flovatar.cdc"
import FlovatarComponent from "../../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../../contracts/FlovatarPack.cdc"
import FlovatarMarketplace from "../../contracts/FlovatarMarketplace.cdc"


//this transaction will create a new Pack from a group of components
transaction(
    components: [UInt64],
    randomString: String,
    price: UFix64,
    sparkCount: UInt32,
    series: UInt32,
    name: String
    ) {

    let flovatarComponentCollection: &FlovatarComponent.Collection
    let flovatarPackCollection: &FlovatarPack.Collection
    let flovatarAdmin: &Flovatar.Admin

    let componentsNFT: @[FlovatarComponent.NFT]


    prepare(account: AuthAccount) {
        self.flovatarComponentCollection = account.borrow<&FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!

        self.flovatarPackCollection = account.borrow<&FlovatarPack.Collection>(from: FlovatarPack.CollectionStoragePath)!

        self.flovatarAdmin = account.borrow<&Flovatar.Admin>(from: Flovatar.AdminStoragePath)!

        for(componentId in components) {
            self.componentsNFT.append(<- self.flovatarComponentCollection.withdraw(withdrawID: componentId) as! @FlovatarComponent.NFT)
        }

    }

    execute {
        let flovatarPack <- self.flovatarAdmin.createPack(
            components: <-self.componentsNFT,
            randomString: randomString,
            price: price
        ) as! @FlovatarPack.Pack

        self.flovatarPackCollection.deposit(token: <-flovatarPack)

    }
}
