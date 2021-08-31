import FlovatarComponentTemplate from "./FlovatarComponentTemplate.cdc"
import FlovatarComponent from "./FlovatarComponent.cdc"

/*

 The contract that defines the Flovatar Packs and a Collection to manage them

 */

pub contract FlovatarPack {

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath

    pub var totalSupply: UInt64

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Created(id: UInt64)
    pub event Opened(id: UInt64)

    pub resource interface Public {
        pub let id: UInt64
        access(account) let components: @{String: FlovatarComponent.NFT}
    }

    pub resource Pack: Public {
        pub let id: UInt64
        access(account) let components: @{String: FlovatarComponent.NFT}

        init(
            body: @FlovatarComponent.NFT,
            hair: @FlovatarComponent.NFT,
            facialHair: @FlovatarComponent.NFT?,
            eyes: @FlovatarComponent.NFT,
            nose: @FlovatarComponent.NFT,
            mouth: @FlovatarComponent.NFT,
            clothing: @FlovatarComponent.NFT,
            hat: @FlovatarComponent.NFT?,
            eyeglasses: @FlovatarComponent.NFT?,
            accessory: @FlovatarComponent.NFT?
        ) {

            pre {
                body.getCategory() == "body" : "The body component belongs to the wrong category"
                hair.getCategory() == "hair" : "The hair component belongs to the wrong category"
                eyes.getCategory() == "eyes" : "The eyes component belongs to the wrong category"
                nose.getCategory() == "nose" : "The nose component belongs to the wrong category"
                mouth.getCategory() == "mouth" : "The mouth component belongs to the wrong category"
                clothing.getCategory() == "clothing" : "The clothing component belongs to the wrong category"
            }

            if(facialHair != nil) {
                if(facialHair?.getCategory() != "facialHair"){
                    panic("The facial hair component belongs to the wrong category")
                }
            }
            
            if(hat != nil){
                if(hat?.getCategory() != "hat") {
                    panic("The hat component belongs to the wrong category")
                }
            }
            if(eyeglasses != nil){
                if(eyeglasses?.getCategory() != "eyeglasses"){
                    panic("The eyeglasses component belongs to the wrong category")
                }
            }
            if(accessory != nil){
                if(accessory?.getCategory() != "accessory"){
                    panic("The accessory component belongs to the wrong category")
                }
            }

            FlovatarPack.totalSupply = FlovatarPack.totalSupply + UInt64(1)
            self.id = FlovatarPack.totalSupply

            self.components <- {}

            let oldBody <- self.components["body"] <- body
            destroy oldBody

            let oldHair <- self.components["hair"] <- hair
            destroy oldHair

            if(facialHair != nil) {
                let oldFacialHair <-self.components["facialHair"] <- facialHair
                destroy oldFacialHair
            } else {
                destroy facialHair
            }

            let oldEyes <- self.components["eyes"] <- eyes
            destroy oldEyes

            let oldNose <- self.components["nose"] <- nose
            destroy oldNose

            let oldMouth <- self.components["mouth"] <- mouth
            destroy oldMouth

            let oldClothing <- self.components["clothing"] <- clothing
            destroy oldClothing

            if(hat != nil){
                let oldHat <- self.components["hat"] <- hat
                destroy oldHat
            } else {
                destroy hat
            }

            if(eyeglasses != nil){
                let oldEyeglasses <- self.components["eyeglasses"] <- eyeglasses
                destroy oldEyeglasses
            } else {
                destroy eyeglasses
            }

            if(accessory != nil){
                let oldAccessory <- self.components["accessory"] <- accessory
                destroy oldAccessory
            } else {
                destroy accessory
            }
        }

        destroy() {
            destroy self.components
        }

    }

    //Standard Pack CollectionPublic interface that can also borrowPack
    pub resource interface CollectionPublic {
        pub fun getIDs(): [UInt64]
        pub fun deposit(token: @FlovatarPack.Pack)
    }

    pub resource Collection: CollectionPublic {
        pub var ownedPacks: @{UInt64: FlovatarPack.Pack}

        init () {
            self.ownedPacks <- {}
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedPacks.keys
        }

        // deposit takes a Pack and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @FlovatarPack.Pack) {
            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedPacks[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // withdraw removes a Pack from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @FlovatarPack.Pack {
            let token <- self.ownedPacks.remove(key: withdrawID) ?? panic("Missing Pack")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        pub fun openPack(id: UInt64) {
            let recipientCap = self.owner!.getCapability<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath)
            let recipient=recipientCap.borrow()!

            let pack <- self.ownedPacks.remove(key: id) ?? panic("Missing Pack")

            let newBody <-pack.components.remove(key: "body") ?? panic("Missing body")
            recipient.deposit(token: <-newBody)

            let newHair <-pack.components.remove(key: "hair") ?? panic("Missing hair")
            recipient.deposit(token: <-newHair)

            if(pack.components.containsKey("facialHair")){
                let newFacialHair <-pack.components.remove(key: "facialHair") ?? panic("Missing facial hair")
                recipient.deposit(token: <-newFacialHair)
            }

            let newEyes <-pack.components.remove(key: "eyes") ?? panic("Missing eyes")
            recipient.deposit(token: <-newEyes)

            let newNose <-pack.components.remove(key: "nose") ?? panic("Missing nose")
            recipient.deposit(token: <-newNose)

            let newMouth <-pack.components.remove(key: "mouth") ?? panic("Missing mouth")
            recipient.deposit(token: <-newMouth)

            let newClothing <-pack.components.remove(key: "clothing") ?? panic("Missing clothing")
            recipient.deposit(token: <-newClothing)

            if(pack.components.containsKey("hat")){
                let newHat <-pack.components.remove(key: "hat") ?? panic("Missing hat")
                recipient.deposit(token: <-newHat)
            }

            if(pack.components.containsKey("eyeglasses")){
                let newEyeglasses <-pack.components.remove(key: "eyeglasses") ?? panic("Missing eyeglasses")
                recipient.deposit(token: <-newEyeglasses)
            }

            if(pack.components.containsKey("accessory")){
                let newAccessory <-pack.components.remove(key: "accessory") ?? panic("Missing accessory")
                recipient.deposit(token: <-newAccessory)
            }

            emit Opened(id: pack.id)

            destroy pack
        }


        destroy() {
            destroy self.ownedPacks
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @FlovatarPack.Collection {
        return <- create Collection()
    }



    //This method can only be called from another contract in the same account. 
    access(account) fun createPack(
            body: @FlovatarComponent.NFT,
            hair: @FlovatarComponent.NFT,
            facialHair: @FlovatarComponent.NFT?,
            eyes: @FlovatarComponent.NFT,
            nose: @FlovatarComponent.NFT,
            mouth: @FlovatarComponent.NFT,
            clothing: @FlovatarComponent.NFT,
            hat: @FlovatarComponent.NFT?,
            eyeglasses: @FlovatarComponent.NFT?,
            accessory: @FlovatarComponent.NFT?
        ) : @FlovatarPack.Pack {

        var newPack <- create Pack(
            body: <-body,
            hair: <-hair,
            facialHair: <-facialHair,
            eyes: <-eyes,
            nose: <-nose,
            mouth: <-mouth,
            clothing: <-clothing,
            hat: <-hat,
            eyeglasses: <-eyeglasses,
            accessory: <-accessory
        )

        emit Created(id: newPack.id)

        return <- newPack
    }

	init() {
        //TODO: remove suffix before deploying to mainnet!!!
        self.CollectionPublicPath=/public/FlovatarPackCollection001
        self.CollectionStoragePath=/storage/FlovatarPackCollection001

        // Initialize the total supply
        self.totalSupply = 0

        self.account.save<@FlovatarPack.Collection>(<- FlovatarPack.createEmptyCollection(), to: FlovatarPack.CollectionStoragePath)
        self.account.link<&{FlovatarPack.CollectionPublic}>(FlovatarPack.CollectionPublicPath, target: FlovatarPack.CollectionStoragePath)

        emit ContractInitialized()
	}
}

