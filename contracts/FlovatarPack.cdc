import FungibleToken from "./FungibleToken.cdc"
import NonFungibleToken from "./NonFungibleToken.cdc"
import FUSD from "./FUSD.cdc"
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
    pub event Created(id: UInt64, prefix: String)
    pub event Opened(id: UInt64)
    pub event Purchased(id: UInt64)

    pub resource interface Public {
        pub let id: UInt64
        pub let price: UFix64
    }

    pub resource Pack: Public {
        pub let id: UInt64
        pub let price: UFix64
        access(account) let components: @{String: FlovatarComponent.NFT}
        access(account) var secret: String

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
            accessory: @FlovatarComponent.NFT?,
            secret: String,
            price: UFix64
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

            self.secret = secret
            self.price = price
        }

        destroy() {
            destroy self.components
        }

        access(contract) fun getSecret(): String {
            return self.secret
        }

        access(contract) fun setSecret(secret: String) {
            self.secret = secret
        }

    }

    //Standard Pack CollectionPublic interface that can also borrowPack
    pub resource interface CollectionPublic {
        pub fun getIDs(): [UInt64]
        pub fun deposit(token: @FlovatarPack.Pack)
        pub fun purchase(tokenId: UInt64, recipientCap: Capability<&{FlovatarPack.CollectionPublic}>, buyTokens: @FungibleToken.Vault, secret: String)
    }

    pub resource Collection: CollectionPublic {
        access(account) let ownedPacks: @{UInt64: FlovatarPack.Pack}
        access(account) let ownerVault: Capability<&AnyResource{FungibleToken.Receiver}>

        init (ownerVault: Capability<&{FungibleToken.Receiver}>) {
            self.ownedPacks <- {}
            self.ownerVault = ownerVault
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

        access(account) fun getPrice(id: UInt64): UFix64 {
            let pack: &FlovatarPack.Pack = &self.ownedPacks[id] as auth &FlovatarPack.Pack
            return pack.price
        }

        access(account) fun getSecret(id: UInt64): String {
            let pack: &FlovatarPack.Pack = &self.ownedPacks[id] as auth &FlovatarPack.Pack
            return pack.getSecret()
        }

        access(account) fun setSecret(id: UInt64, secret: String) {
            let pack: &FlovatarPack.Pack = &self.ownedPacks[id] as auth &FlovatarPack.Pack
            pack.setSecret(secret: secret)
        }


        pub fun purchase(tokenId: UInt64, recipientCap: Capability<&{FlovatarPack.CollectionPublic}>, buyTokens: @FungibleToken.Vault, secret: String) {
            pre {
                self.ownedPacks.containsKey(tokenId) == true : "Pack not found!"
                self.getPrice(id: tokenId) <= buyTokens.balance : "Not enough tokens to buy the Pack!"
                self.getSecret(id: tokenId) == secret : "The secret provided is not matching!"
            }

            let recipient=recipientCap.borrow()!
            let pack <- self.withdraw(withdrawID: tokenId)


            let vaultRef = self.ownerVault.borrow() ?? panic("Could not borrow reference to owner pack vault")
            vaultRef.deposit(from: <-buyTokens)


            let packId: UInt64 = pack.id
            pack.setSecret(secret: unsafeRandom().toString())
            recipient.deposit(token: <- pack)

            emit Purchased(id: packId)

        }

        destroy() {
            destroy self.ownedPacks
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(ownerVault: Capability<&{FungibleToken.Receiver}>): @FlovatarPack.Collection {
        return <- create Collection(ownerVault: ownerVault)
    }


    pub fun getPacks(address: Address) : [UInt64]? {

        let account = getAccount(address)

        if let packCollection = account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarPack.CollectionPublic}>()  {
            return packCollection.getIDs();
        }
        return nil
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
            accessory: @FlovatarComponent.NFT?,
            secret: String,
            price: UFix64
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
            accessory: <-accessory,
            secret: secret,
            price: price
        )

        emit Created(id: newPack.id, prefix: secret.slice(from: 0, upTo: 4))

        return <- newPack
    }

	init() {
        if(self.account.borrow<&FUSD.Vault>(from: /storage/fusdVault) == nil) {
          self.account.save(<-FUSD.createEmptyVault(), to: /storage/fusdVault)
          self.account.link<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver, target: /storage/fusdVault)
          self.account.link<&FUSD.Vault{FungibleToken.Balance}>(/public/fusdBalance, target: /storage/fusdVault)
        }
        let wallet =  self.account.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver)

        //TODO: remove suffix before deploying to mainnet!!!
        self.CollectionPublicPath=/public/FlovatarPackCollection004
        self.CollectionStoragePath=/storage/FlovatarPackCollection004

        // Initialize the total supply
        self.totalSupply = 0

        self.account.save<@FlovatarPack.Collection>(<- FlovatarPack.createEmptyCollection(ownerVault: wallet), to: FlovatarPack.CollectionStoragePath)
        self.account.link<&{FlovatarPack.CollectionPublic}>(FlovatarPack.CollectionPublicPath, target: FlovatarPack.CollectionStoragePath)

        emit ContractInitialized()
	}
}

