
//import FungibleToken from 0xee82856bf20e2aa6
//import FungibleToken from "../../contracts/FungibleToken.cdc"
//import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
//import FUSD from "../../contracts/FUSD.cdc"
import Flovatar from "../../contracts/Flovatar.cdc"
import FlovatarComponent from "../../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../../contracts/FlovatarPack.cdc"


//this transaction will create a new Pack from a group of components
transaction(
    body: UInt64,
    hair: UInt64,
    facialHair: UInt64?,
    eyes: UInt64,
    nose: UInt64,
    mouth: UInt64,
    clothing: UInt64,
    hat: UInt64?,
    eyeglasses: UInt64?,
    accessory: UInt64?,
    secret: String
    ) {

    let flovatarComponentCollection: &FlovatarComponent.Collection
    let flovatarPackCollection: &FlovatarPack.Collection
    let flovatarAdmin: &Flovatar.Admin

    let bodyNFT: @FlovatarComponent.NFT
    let hairNFT: @FlovatarComponent.NFT
    let facialHairNFT: @FlovatarComponent.NFT?
    let eyesNFT: @FlovatarComponent.NFT
    let noseNFT: @FlovatarComponent.NFT
    let mouthNFT: @FlovatarComponent.NFT
    let clothingNFT: @FlovatarComponent.NFT
    let hatNFT: @FlovatarComponent.NFT?
    let eyeglassesNFT: @FlovatarComponent.NFT?
    let accessoryNFT: @FlovatarComponent.NFT?

    prepare(account: AuthAccount) {
        self.flovatarComponentCollection = account.borrow<&FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!

        self.flovatarPackCollection = account.borrow<&FlovatarPack.Collection>(from: FlovatarPack.CollectionStoragePath)!

        self.flovatarAdmin = account.borrow<&Flovatar.Admin>(from: Flovatar.AdminStoragePath)!

        self.bodyNFT <- self.flovatarComponentCollection.withdraw(withdrawID: body) as! @FlovatarComponent.NFT
        self.hairNFT <- self.flovatarComponentCollection.withdraw(withdrawID: hair) as! @FlovatarComponent.NFT
        if(facialHair != nil){
            self.facialHairNFT <- self.flovatarComponentCollection.withdraw(withdrawID: facialHair!) as! @FlovatarComponent.NFT
        } else {
            self.facialHairNFT <- nil
        }
        self.eyesNFT <- self.flovatarComponentCollection.withdraw(withdrawID: eyes) as! @FlovatarComponent.NFT
        self.noseNFT <- self.flovatarComponentCollection.withdraw(withdrawID: nose) as! @FlovatarComponent.NFT
        self.mouthNFT <- self.flovatarComponentCollection.withdraw(withdrawID: mouth) as! @FlovatarComponent.NFT
        self.clothingNFT <- self.flovatarComponentCollection.withdraw(withdrawID: clothing) as! @FlovatarComponent.NFT
        if(hat != nil){
            self.hatNFT <- self.flovatarComponentCollection.withdraw(withdrawID: hat!) as! @FlovatarComponent.NFT
        } else {
            self.hatNFT <- nil
        }
        if(eyeglasses != nil){
            self.eyeglassesNFT <- self.flovatarComponentCollection.withdraw(withdrawID: eyeglasses!) as! @FlovatarComponent.NFT
        } else {
            self.eyeglassesNFT <- nil
        }
        if(accessory != nil){
            self.accessoryNFT <- self.flovatarComponentCollection.withdraw(withdrawID: accessory!) as! @FlovatarComponent.NFT
        } else {
            self.accessoryNFT <- nil
        }
    }

    execute {
        let flovatarPack <- self.flovatarAdmin.createPack(
            body: <-self.bodyNFT,
            hair: <-self.hairNFT,
            facialHair: <-self.facialHairNFT,
            eyes: <-self.eyesNFT,
            nose: <-self.noseNFT,
            mouth: <-self.mouthNFT,
            clothing: <-self.clothingNFT,
            hat: <-self.hatNFT,
            eyeglasses: <-self.eyeglassesNFT,
            accessory: <-self.accessoryNFT,
            secret: secret
        ) as! @FlovatarPack.Pack

        self.flovatarPackCollection.deposit(token: <-flovatarPack)

    }
}