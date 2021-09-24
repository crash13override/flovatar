import FungibleToken from "./FungibleToken.cdc"
import NonFungibleToken from "./NonFungibleToken.cdc"
import FUSD from "./FUSD.cdc"
import FlovatarComponentTemplate from "./FlovatarComponentTemplate.cdc"
import FlovatarComponent from "./FlovatarComponent.cdc"
import Crypto

/*

 This contract defines the Flovatar Packs and a Collection to manage them.

 Each Pack will contain one item for each required Component (body, hair, eyes, nose, mouth, clothing), 
 and two other Components that are optional (facial hair, accessory, hat, eyeglasses, background).
 
 Packs will be pre-minted and can be purchased from the contract owner's account by providing a 
 verified signature that is different for each Pack (more info in the purchase function).

 Once purchased, packs cannot be re-sold and users will only be able to open them to receive
 the contained Components into their collection.

 */

pub contract FlovatarPack {

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath

    // Counter for all the Packs ever minted
    pub var totalSupply: UInt64

    // Standard events that will be emitted
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Created(id: UInt64, prefix: String)
    pub event Opened(id: UInt64)
    pub event Purchased(id: UInt64)

    // The public interface contains only the ID and the price of the Pack
    pub resource interface Public {
        pub let id: UInt64
        pub let price: UFix64
    }

    // The Pack resource that implements the Public interface and that contains 
    // different Components in a Dictionary
    pub resource Pack: Public {
        pub let id: UInt64
        pub let price: UFix64
        access(account) let components: @{String: FlovatarComponent.NFT}
        access(account) var secret: String

        // Initializes the Pack with all the required and optional Components.
        // It receives also the price and a secret String that will signed by 
        // the account owner to validate the purchase process.
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
            background: @FlovatarComponent.NFT?,
            secret: String,
            price: UFix64
        ) {

            // Makes sure that all the required Components belong to the correct category
            pre {
                body.getCategory() == "body" : "The body component belongs to the wrong category"
                hair.getCategory() == "hair" : "The hair component belongs to the wrong category"
                eyes.getCategory() == "eyes" : "The eyes component belongs to the wrong category"
                nose.getCategory() == "nose" : "The nose component belongs to the wrong category"
                mouth.getCategory() == "mouth" : "The mouth component belongs to the wrong category"
                clothing.getCategory() == "clothing" : "The clothing component belongs to the wrong category"
            }

            // Makes additional checks also for the optional Components to make sure
            // they belong to the correct category
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
            if(background != nil){
                if(background?.getCategory() != "background"){
                    panic("The background component belongs to the wrong category")
                }
            }

            // Increments the total supply counter
            FlovatarPack.totalSupply = FlovatarPack.totalSupply + UInt64(1)
            self.id = FlovatarPack.totalSupply


            // Creates an empty Dictionary and stores all the components in it
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
            if(background != nil){
                let oldBackground <- self.components["background"] <- background
                destroy oldBackground
            } else {
                destroy background
            }

            // Sets the secret text and the price
            self.secret = secret
            self.price = price
        }

        destroy() {
            destroy self.components
        }

        // This function is used to retrieve the secret string to match it 
        // against the signature passed during the purchase process
        access(contract) fun getSecret(): String {
            return self.secret
        }

        // This function reset the secret so that after the purchase nobody
        // will be able to re-use the verified signature
        access(contract) fun setSecret(secret: String) {
            self.secret = secret
        }

    }

    //Pack CollectionPublic interface that allows users to purchase a Pack
    pub resource interface CollectionPublic {
        pub fun getIDs(): [UInt64]
        pub fun deposit(token: @FlovatarPack.Pack)
        pub fun purchase(tokenId: UInt64, recipientCap: Capability<&{FlovatarPack.CollectionPublic}>, buyTokens: @FungibleToken.Vault, signature: String)
    }

    // Main Collection that implements the Public interface and that 
    // will handle the purchase transactions
    pub resource Collection: CollectionPublic {
        // Dictionary of all the Packs owned
        access(account) let ownedPacks: @{UInt64: FlovatarPack.Pack}
        // Capability to send the FUSD to the owner's account
        access(account) let ownerVault: Capability<&AnyResource{FungibleToken.Receiver}>

        // Initializes the Collection with the vault receiver capability
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

        // This function allows any Pack owner to open the pack and receive its content
        // into the owner's Component Collection.
        // The pack is destroyed after the Components are delivered.
        pub fun openPack(id: UInt64) {

            // Gets the Component Collection Public capability to be able to 
            // send there the Components contained in the Pack
            let recipientCap = self.owner!.getCapability<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath)
            let recipient=recipientCap.borrow()!

            // Removed the pack from the collection
            let pack <- self.withdraw(withdrawID: id)

            // Removes all the components from the Pack and deposits them to the 
            // Component Collection of the owner
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
            if(pack.components.containsKey("background")){
                let newBackground <-pack.components.remove(key: "background") ?? panic("Missing background")
                recipient.deposit(token: <-newBackground)
            }

            // Emits the event to notify that the pack was opened
            emit Opened(id: pack.id)

            destroy pack
        }

        // Gets the price for a specific Pack
        access(account) fun getPrice(id: UInt64): UFix64 {
            let pack: &FlovatarPack.Pack = &self.ownedPacks[id] as auth &FlovatarPack.Pack
            return pack.price
        }

        // Gets the secret String for a specific Pack 
        access(account) fun getSecret(id: UInt64): String {
            let pack: &FlovatarPack.Pack = &self.ownedPacks[id] as auth &FlovatarPack.Pack
            return pack.getSecret()
        }

        // Sets the secret String for a specific Pack
        access(account) fun setSecret(id: UInt64, secret: String) {
            let pack: &FlovatarPack.Pack = &self.ownedPacks[id] as auth &FlovatarPack.Pack
            pack.setSecret(secret: secret)
        }


        // This function provides the ability for anyone to purchase a Pack
        // It receives as parameters the Pack ID, the Pack Collection Public capability to receive the pack, 
        // a vault containing the necessary FUSD, and finally a signature to validate the process.
        // The signature is generated off-chain by the smart contract's owner account using the Crypto library
        // to generate a hash from the original secret String contained in each Pack.
        // This will guarantee that the contract owner will be able to decide which user can buy a pack, by
        // providing them the correct signature. 
        pub fun purchase(tokenId: UInt64, recipientCap: Capability<&{FlovatarPack.CollectionPublic}>, buyTokens: @FungibleToken.Vault, signature: String) {

            // Checks that the pack is still available and that the FUSD are sufficient
            pre {
                self.ownedPacks.containsKey(tokenId) == true : "Pack not found!"
                self.getPrice(id: tokenId) <= buyTokens.balance : "Not enough tokens to buy the Pack!"
            }

            // Gets the Crypto.KeyList and the public key of the collection's owner
            let keyList = Crypto.KeyList()
            let accountKey = self.owner!.keys.get(keyIndex: 0)!.publicKey

            // Adds the public key to the keyList
            keyList.add(
                PublicKey(
                    publicKey: accountKey.publicKey,
                    signatureAlgorithm: accountKey.signatureAlgorithm
                ),
                hashAlgorithm: HashAlgorithm.SHA3_256,
                weight: 1.0
            )

            // Creates a Crypto.KeyListSignature from the signature provided in the parameters
            let signatureSet: [Crypto.KeyListSignature] = []
            signatureSet.append(
                Crypto.KeyListSignature(
                    keyIndex: 0,
                    signature: signature.decodeHex()
                )
            )

            // Verifies that the signature is valid and that it was generated from the
            // owner of the collection
            if(!keyList.verify(signatureSet: signatureSet, signedData: self.getSecret(id: tokenId).utf8)){
                panic("Unable to validate the signature for the pack!")
            }


            // Borrows the recipient's capability and withdraws the Pack from the collection.
            // If this fails the transaction will revert but the signature will be exposed.
            // For this reason in case it happens, the secret will be reset when the purchase
            // reservation timeout expires by the web server back-end.
            let recipient = recipientCap.borrow()!
            let pack <- self.withdraw(withdrawID: tokenId)

            // Borrows the owner's capability for the Vault and deposits the FUSD
            let vaultRef = self.ownerVault.borrow() ?? panic("Could not borrow reference to owner pack vault")
            vaultRef.deposit(from: <-buyTokens)


            // Resets the secret so that the provided signature will become useless
            let packId: UInt64 = pack.id
            pack.setSecret(secret: unsafeRandom().toString())

            // Deposits the Pack to the recipient's collection
            recipient.deposit(token: <- pack)

            // Emits an even to notify about the purchase
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

    // Get all the packs from a specific account
    pub fun getPacks(address: Address) : [UInt64]? {

        let account = getAccount(address)

        if let packCollection = account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarPack.CollectionPublic}>()  {
            return packCollection.getIDs();
        }
        return nil
    }



    // This method can only be called from another contract in the same account (The Flovatar Admin resource)
    // It creates a new pack from a list of Components, the secret String and the price.
    // Some Components are required and others are optional
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
            background: @FlovatarComponent.NFT?,
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
            background: <-background,
            secret: secret,
            price: price
        )

        // Emits an event to notify that a Pack was created. 
        // Sends the first 4 digits of the secret to be able to sync the ID with the off-chain DB
        // that will store also the signatures once they are generated
        emit Created(id: newPack.id, prefix: secret.slice(from: 0, upTo: 4))

        return <- newPack
    }

	init() {
        // Makes sure that the contract owner's account has the FUSD capability
        if(self.account.borrow<&FUSD.Vault>(from: /storage/fusdVault) == nil) {
          self.account.save(<-FUSD.createEmptyVault(), to: /storage/fusdVault)
          self.account.link<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver, target: /storage/fusdVault)
          self.account.link<&FUSD.Vault{FungibleToken.Balance}>(/public/fusdBalance, target: /storage/fusdVault)
        }
        let wallet =  self.account.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver)

        //TODO: remove suffix before deploying to mainnet!!!
        self.CollectionPublicPath=/public/FlovatarPackCollection005
        self.CollectionStoragePath=/storage/FlovatarPackCollection005

        // Initialize the total supply
        self.totalSupply = 0

        self.account.save<@FlovatarPack.Collection>(<- FlovatarPack.createEmptyCollection(ownerVault: wallet), to: FlovatarPack.CollectionStoragePath)
        self.account.link<&{FlovatarPack.CollectionPublic}>(FlovatarPack.CollectionPublicPath, target: FlovatarPack.CollectionStoragePath)

        emit ContractInitialized()
	}
}

