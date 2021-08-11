
//import FungibleToken from 0xee82856bf20e2aa6
//import FungibleToken from "../../contracts/FungibleToken.cdc"
//import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
//import FUSD from "../../contracts/FUSD.cdc"
import Flovatar from "../../contracts/Flovatar.cdc"
import FlovatarComponent from "../../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../../contracts/FlovatarPack.cdc"


transaction(
    name: String,
    body: UInt64
    hair: UInt64,
    facialHair: UInt64?,
    eyes: UInt64,
    nose: UInt64,
    mouth: UInt64,
    clothing: UInt64
    ) {


    let flovatarCollection: &Flovatar.Collection
    let flovatarComponentCollection: &FlovatarComponent.Collection

    let bodyNFT: @FlovatarComponent.NFT
    let hairNFT: @FlovatarComponent.NFT
    let facialHairNFT: @FlovatarComponent.NFT?
    let eyesNFT: @FlovatarComponent.NFT
    let noseNFT: @FlovatarComponent.NFT
    let mouthNFT: @FlovatarComponent.NFT
    let clothingNFT: @FlovatarComponent.NFT
    let accountAddress: Address

    prepare(account: AuthAccount) {
        self.flovatarCollection = account.borrow<&Flovatar.Collection>(from: Flovatar.CollectionStoragePath)!

        self.flovatarComponentCollection = account.borrow<&FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!

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

        self.accountAddress = account.address
    }

    execute {

        let flovatar <- Flovatar.createFlovatar(
            name: name,
            body: <-self.bodyNFT,
            hair: <-self.hairNFT,
            facialHair: <-self.facialHairNFT,
            eyes: <-self.eyesNFT,
            nose: <-self.noseNFT,
            mouth: <-self.mouthNFT,
            clothing: <-self.clothingNFT,
            address: self.accountAddress
        )

        self.flovatarCollection.deposit(token: <-flovatar)
    }

}