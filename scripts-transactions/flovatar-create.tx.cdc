import "Flovatar"
import "FlovatarComponent"
import "NonFungibleToken"

// This transaction will create a new Flovatar by burning a Spark and all the necessary rarity Boosters
transaction(
    spark: UInt64,
    body: UInt64,
    hair: UInt64,
    facialHair: UInt64?,
    eyes: UInt64,
    nose: UInt64,
    mouth: UInt64,
    clothing: UInt64,
    accessory: UInt64?,
    hat: UInt64?,
    eyeglasses: UInt64?,
    background: UInt64?,
    rareBoost: [UInt64],
    epicBoost: [UInt64],
    legendaryBoost: [UInt64]
    ) {


    let flovatarCollection: &Flovatar.Collection
    let flovatarComponentCollection: auth(NonFungibleToken.Withdraw) &FlovatarComponent.Collection

    let sparkNFT: @FlovatarComponent.NFT
    let accessoryNFT: @FlovatarComponent.NFT?
    let hatNFT: @FlovatarComponent.NFT?
    let eyeglassesNFT: @FlovatarComponent.NFT?
    let backgroundNFT: @FlovatarComponent.NFT?
    let rareBoostNFT: @[FlovatarComponent.NFT]
    let epicBoostNFT: @[FlovatarComponent.NFT]
    let legendaryBoostNFT: @[FlovatarComponent.NFT]
    let accountAddress: Address

    prepare(account: auth(Storage) &Account) {
        self.flovatarCollection = account.storage.borrow<&Flovatar.Collection>(from: Flovatar.CollectionStoragePath)!

        self.flovatarComponentCollection = account.storage.borrow<auth(NonFungibleToken.Withdraw) &FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!

        self.rareBoostNFT <-[]
        for componentId in rareBoost {
            let tempNFT <-self.flovatarComponentCollection.withdraw(withdrawID: componentId) as! @FlovatarComponent.NFT
            self.rareBoostNFT.append(<-tempNFT)
        }
        self.epicBoostNFT <-[]
        for componentId in epicBoost {
            let tempNFT <-self.flovatarComponentCollection.withdraw(withdrawID: componentId) as! @FlovatarComponent.NFT
            self.epicBoostNFT.append(<-tempNFT)
        }
        self.legendaryBoostNFT <-[]
        for componentId in legendaryBoost {
            let tempNFT <-self.flovatarComponentCollection.withdraw(withdrawID: componentId) as! @FlovatarComponent.NFT
            self.legendaryBoostNFT.append(<-tempNFT)
        }


        if(accessory != nil){
            self.accessoryNFT <- self.flovatarComponentCollection.withdraw(withdrawID: accessory!) as! @FlovatarComponent.NFT
        } else {
            self.accessoryNFT <- nil
        }

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

        if(background != nil){
            self.backgroundNFT <- self.flovatarComponentCollection.withdraw(withdrawID: background!) as! @FlovatarComponent.NFT
        } else {
            self.backgroundNFT <- nil
        }

        self.sparkNFT <-self.flovatarComponentCollection.withdraw(withdrawID: spark) as! @FlovatarComponent.NFT

        self.accountAddress = account.address

    }

    execute {

        let flovatar <- Flovatar.createFlovatar(
            spark: <-self.sparkNFT,
            body: body,
            hair: hair,
            facialHair: facialHair,
            eyes: eyes,
            nose: nose,
            mouth: mouth,
            clothing: clothing,
            accessory: <-self.accessoryNFT,
            hat: <-self.hatNFT,
            eyeglasses: <-self.eyeglassesNFT,
            background: <-self.backgroundNFT,
            rareBoost: <-self.rareBoostNFT,
            epicBoost: <-self.epicBoostNFT,
            legendaryBoost: <-self.legendaryBoostNFT,
            address: self.accountAddress
        )

        self.flovatarCollection.deposit(token: <-flovatar)
    }

}