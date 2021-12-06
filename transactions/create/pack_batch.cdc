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
    randomString: [String],
    price: UFix64,
    sparkCount: UInt32,
    series: UInt32,
    name: String,
    packCount: UInt32,
    compPerPack: UInt32
    ) {

    let flovatarComponentCollection: &FlovatarComponent.Collection
    let flovatarPackCollection: &FlovatarPack.Collection
    let flovatarAdmin: &Flovatar.Admin



    prepare(account: AuthAccount) {

        self.flovatarComponentCollection = account.borrow<&FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!

        self.flovatarPackCollection = account.borrow<&FlovatarPack.Collection>(from: FlovatarPack.CollectionStoragePath)!

        self.flovatarAdmin = account.borrow<&Flovatar.Admin>(from: Flovatar.AdminStoragePath)!


    }

    execute {

        var i: UInt32 = 0
        while i < packCount {

            let componentsNFT: @[FlovatarComponent.NFT] <- []

            var j: UInt32 = 0
            while j < compPerPack {
                let tempNFT <- self.flovatarComponentCollection.withdraw(withdrawID: components[(i*compPerPack) + j]) as! @FlovatarComponent.NFT
                componentsNFT.append(<-tempNFT)
                j = j + UInt32(1)
            }

            let flovatarPack <- self.flovatarAdmin.createPack(
                        components: <-componentsNFT,
                        randomString: randomString[i],
                        price: price,
                        sparkCount: sparkCount,
                        series: series,
                        name: name
                    ) as! @FlovatarPack.Pack

            self.flovatarPackCollection.deposit(token: <-flovatarPack)

            i = i + UInt32(1)
        }




    }
}
