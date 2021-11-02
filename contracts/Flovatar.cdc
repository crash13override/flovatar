import FungibleToken from "./FungibleToken.cdc"
import NonFungibleToken from "./NonFungibleToken.cdc"
import FlowToken from "./FlowToken.cdc"
import FlovatarComponentTemplate from "./FlovatarComponentTemplate.cdc"
import FlovatarComponent from "./FlovatarComponent.cdc"
import FlovatarPack from "./FlovatarPack.cdc"

/*

 The contract that defines the Flovatar NFT and a Collection to manage them

Base components that will be used to generate the unique combination of the Flovatar
'body', 'hair', 'facialhair', 'eyes', 'nose', 'mouth', 'clothing'

Extra components that can be added in a second moment
'accessory', 'hat', eyeglass', 'background'


This contract contains also the Admin resource that can be used to manage and generate all the other ones (Components, Templates, Packs).

 */

pub contract Flovatar: NonFungibleToken {

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let AdminStoragePath: StoragePath

    // These will be used in the Marketplace to pay out 
    // royalties to the creator and to the marketplace
    access(account) var royaltyCut: UFix64
    access(account) var marketplaceCut: UFix64

    // Here we keep track of all the Flovatar unique combinations and names 
    // that people will generate to make sure that there are no duplicates
    pub var totalSupply: UInt64
    access(contract) let mintedCombinations: {String: Bool}
    access(contract) let mintedNames: {String: Bool}

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Created(id: UInt64, metadata: Metadata)
    pub event Updated(id: UInt64)


    pub struct Royalties{
        pub let royalty: [Royalty]
        init(royalty: [Royalty]) {
            self.royalty=royalty
        }
    }

    pub enum RoyaltyType: UInt8{
        pub case fixed
        pub case percentage
    }

    pub struct Royalty{
        pub let wallet:Capability<&{FungibleToken.Receiver}> 
        pub let cut: UFix64

        //can be percentage
        pub let type: RoyaltyType

        init(wallet:Capability<&{FungibleToken.Receiver}>, cut: UFix64, type: RoyaltyType ){
            self.wallet=wallet
            self.cut=cut
            self.type=type
        }
    }


    // This Metada struct contains all the most important informations about the Flovatar
    pub struct Metadata {
        pub let name: String
        pub let mint: UInt64
        pub let series: UInt32
        pub let svg: String
        pub let combination: String
        pub let creatorAddress: Address
        access(self) let components: {String: UInt64}


        init(
            name: String,
            mint: UInt64,
            series: UInt32,
            svg: String,
            combination: String,
            creatorAddress: Address,
            components: {String: UInt64}
        ) {
                self.name = name
                self.mint = mint
                self.series = series
                self.svg = svg
                self.combination = combination
                self.creatorAddress = creatorAddress
                self.components = components
        }
    }

    // The public interface can show metadata and the content for the Flovatar. 
    // In addition to it, it provides methods to access the additional optional 
    // components (accessory, hat, eyeglasses, background) for everyone.
    pub resource interface Public {
        pub let id: UInt64
        access(contract) let metadata: Metadata
        access(contract) let royalties: Royalties

        //these three are added because I think they will be in the standard. At least Dieter thinks it will be needed
        access(contract) var name: String
        pub let description: String
        pub let schema: String?

        pub fun getAccessory(): UInt64?
        pub fun getHat(): UInt64?
        pub fun getEyeglasses(): UInt64?
        pub fun getBackground(): UInt64?

        pub fun getSvg(): String
        pub fun getMetadata(): Metadata
        pub fun getRoyalties(): Royalties
        pub fun getBio(): {String: String}
    }

    //The private interface can update the Accessory, Hat, Eyeglasses and Background 
    //for the Flovatar and is accessible only to the owner of the NFT
    pub resource interface Private {
        pub fun setName(name: String): String
        pub fun setAccessory(component: @FlovatarComponent.NFT): UInt64?
        pub fun setHat(component: @FlovatarComponent.NFT): UInt64?
        pub fun setEyeglasses(component: @FlovatarComponent.NFT): UInt64?
        pub fun setBackground(component: @FlovatarComponent.NFT): UInt64?
    }

    //The NFT resource that implements both Private and Public interfaces
    pub resource NFT: NonFungibleToken.INFT, Public, Private {
        pub let id: UInt64
        access(contract) let metadata: Metadata
        access(contract) let royalties: Royalties
        access(contract) var accessory: UInt64?
        access(contract) var hat: UInt64?
        access(contract) var eyeglasses: UInt64?
        access(contract) var background: UInt64?

        access(contract) var name: String
        pub let description: String
        pub let schema: String?
        access(self) let bio: {String: String}

        init(metadata: Metadata,
            royalties: Royalties) {
            Flovatar.totalSupply = Flovatar.totalSupply + UInt64(1)

            self.id = Flovatar.totalSupply
            self.metadata = metadata
            self.royalties = royalties
            self.accessory = nil
            self.hat = nil
            self.eyeglasses = nil
            self.background = nil

            self.schema = nil
            self.name = metadata.name
            self.description = metadata.name
            self.bio = {}
        }

        pub fun getID(): UInt64 {
            return self.id
        }

        pub fun getMetadata(): Metadata {
            return self.metadata
        }

        pub fun getRoyalties(): Royalties {
            return self.royalties
        }

        pub fun getBio(): {String: String} {
            return self.bio
        }

        pub fun getName(): String {
            return self.name
        }
        
        // This will allow to change the Name of the Flovatar only once. 
        // It checks for the current name is empty, otherwise it will throw an error. 
        pub fun setName(name: String): String {
            pre {
                // TODO: Make sure that the text of the name is sanitized 
                //and that bad words are not accepted?
                name.length > 2 : "The name is too short"
                name.length < 32 : "The name is too long" 
                self.name == "" : "The name has already been set"
            }

            // Makes sure that the name is available and not taken already
            if(Flovatar.checkNameAvailable(name: name) == false){
                panic("This name has already been taken")
            }

            self.name = name


            // Adds the name to the array to remember it
            Flovatar.addMintedName(name: name)

            return self.name
        }

        pub fun getAccessory(): UInt64? {
            return self.accessory
        }
        
        // This will allow to change the Accessory of the Flovatar any time. 
        // It checks for the right category and series before executing. 
        // The Accessory component will be burned in the process and if a previous 
        // one was set, it will be lost.
        pub fun setAccessory(component: @FlovatarComponent.NFT): UInt64? {
            pre {
                component.getCategory() == "accessory" : "The component needs to be an accessory"
                component.getSeries() == self.metadata.series : "The accessory belongs to a different series"
            }

            self.accessory = component.templateId

            emit Updated(id: self.id)

            destroy component
            return self.accessory
        }

        pub fun getHat(): UInt64? {
            return self.hat
        }

        // This will allow to change the Hat of the Flovatar any time. 
        // It checks for the right category and series before executing. 
        // The Hat component will be burned in the process and if a previous one 
        // was set, it will be lost.
        pub fun setHat(component: @FlovatarComponent.NFT): UInt64? {
            pre {
                component.getCategory() == "hat" : "The component needs to be a hat"
                component.getSeries() == self.metadata.series : "The hat belongs to a different series"
            }

            self.hat = component.templateId

            emit Updated(id: self.id)

            destroy component
            return self.hat
        }

        pub fun getEyeglasses(): UInt64? {
            return self.eyeglasses
        }
        
        // This will allow to change the Eyeglasses of the Flovatar any time. 
        // It checks for the right category and series before executing. 
        // The Eyeglasses component will be burned in the process and if a previous one 
        // was set, it will be lost.
        pub fun setEyeglasses(component: @FlovatarComponent.NFT): UInt64? {
            pre {
                component.getCategory() == "eyeglasses" : "The component needs to be a pair of eyeglasses"
                component.getSeries() == self.metadata.series : "The eyeglasses belongs to a different series"
            }

            self.eyeglasses = component.templateId

            emit Updated(id: self.id)

            destroy component
            return self.eyeglasses
        }

        pub fun getBackground(): UInt64? {
            return self.background
        }
        
        // This will allow to change the Background of the Flovatar any time. 
        // It checks for the right category and series before executing. 
        // The Eyeglasses component will be burned in the process and if a previous one 
        // was set, it will be lost.
        pub fun setBackground(component: @FlovatarComponent.NFT): UInt64? {
            pre {
                component.getCategory() == "background" : "The component needs to be a background"
                component.getSeries() == self.metadata.series : "The accessory belongs to a different series"
            }

            self.background = component.templateId

            emit Updated(id: self.id)

            destroy component
            return self.background
        }

        // This function will return the full SVG of the Flovatar. It will take the 
        // optional components (Accessory, Hat, Eyeglasses and Background) from their 
        // original Template resources, while all the other unmutable components are 
        // taken from the Metadata directly.
        pub fun getSvg(): String {
            let svg: String = "<svg viewBox='0 0 100 100' xmlns='http://www.w3.org/2000/svg'>"

            if let background = self.getBackground() {
                if let template = FlovatarComponentTemplate.getComponentTemplate(id: background) {
                    svg.concat(template.svg!)
                }
            }

            svg.concat(self.metadata.svg)

            if let eyeglasses = self.getEyeglasses() {
                if let template = FlovatarComponentTemplate.getComponentTemplate(id: eyeglasses) {
                    svg.concat(template.svg!)
                }
            }

            if let hat = self.getHat() {
                if let template = FlovatarComponentTemplate.getComponentTemplate(id: hat) {
                    svg.concat(template.svg!)
                }
            }

            if let accessory = self.getAccessory() {
                if let template = FlovatarComponentTemplate.getComponentTemplate(id: accessory) {
                    svg.concat(template.svg!)
                }
            }

            svg.concat("</svg>")

            return svg

        }
    }


    // Standard NFT collectionPublic interface that can also borrowFlovatar as the correct type
    pub resource interface CollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowFlovatar(id: UInt64): &Flovatar.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Flovatar reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Main Collection to manage all the Flovatar NFT
    pub resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        // withdraw removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <- token
        }

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @Flovatar.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT
        }

        // borrowFlovatar returns a borrowed reference to a Flovatar
        // so that the caller can read data and call methods from it.
        pub fun borrowFlovatar(id: UInt64): &Flovatar.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &Flovatar.NFT
            } else {
                return nil
            }
        }

        // borrowFlovatarPrivate returns a borrowed reference to a Flovatar using the Private interface
        // so that the caller can read data and call methods from it, like setting the optional components.
        pub fun borrowFlovatarPrivate(id: UInt64): &{Flovatar.Private}? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &Flovatar.NFT
            } else {
                return nil
            }
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    // This struct is used to send a data representation of the Flovatars 
    // when retrieved using the contract helper methods outside the collection.
    pub struct FlovatarData {
        pub let id: UInt64
        pub let metadata: Flovatar.Metadata
        pub let accessoryId: UInt64?
        pub let hatId: UInt64?
        pub let eyeglassesId: UInt64?
        pub let backgroundId: UInt64?
        pub let bio: {String: String}
        init(
            id: UInt64, 
            metadata: Flovatar.Metadata,
            accessoryId: UInt64?,
            hatId: UInt64?,
            eyeglassesId: UInt64?,
            backgroundId: UInt64?,
            bio: {String: String}
            ) {
            self.id = id
            self.metadata = metadata
            self.accessoryId = accessoryId
            self.hatId = hatId
            self.eyeglassesId = eyeglassesId
            self.backgroundId = backgroundId
            self.bio = bio
        }
    }


    // This function will look for a specific Flovatar on a user account and return a FlovatarData if found
    pub fun getFlovatar(address: Address, flovatarId: UInt64) : FlovatarData? {

        let account = getAccount(address)

        if let flovatarCollection = account.getCapability(self.CollectionPublicPath).borrow<&{Flovatar.CollectionPublic}>()  {
            if let flovatar = flovatarCollection.borrowFlovatar(id: flovatarId) {
                return FlovatarData(
                    id: flovatarId,
                    metadata: flovatar!.getMetadata(),
                    accessoryId: flovatar!.getAccessory(),
                    hatId: flovatar!.getHat(),
                    eyeglassesId: flovatar!.getEyeglasses(),
                    backgroundId: flovatar!.getBackground(),
                    bio: flovatar!.getBio()
                )
            }
        }
        return nil
    }

    // This function will return all Flovatars on a user account and return an array of FlovatarData
    pub fun getFlovatars(address: Address) : [FlovatarData] {

        var flovatarData: [FlovatarData] = []
        let account = getAccount(address)

        if let flovatarCollection = account.getCapability(self.CollectionPublicPath).borrow<&{Flovatar.CollectionPublic}>()  {
            for id in flovatarCollection.getIDs() {
                var flovatar = flovatarCollection.borrowFlovatar(id: id)
                flovatarData.append(FlovatarData(
                    id: id,
                    metadata: flovatar!.getMetadata(),
                    accessoryId: flovatar!.getAccessory(),
                    hatId: flovatar!.getHat(),
                    eyeglassesId: flovatar!.getEyeglasses(),
                    backgroundId: flovatar!.getBackground(),
                    bio: flovatar!.getBio()
                    ))
            }
        }
        return flovatarData
    }


    // This returns all the previously minted combinations, so that duplicates won't be allowed
    pub fun getMintedCombinations() : [String] {
        return Flovatar.mintedCombinations.keys
    }
    // This returns all the previously minted names, so that duplicates won't be allowed
    pub fun getMintedNames() : [String] {
        return Flovatar.mintedNames.keys
    }

    // This function will add a minted combination to the array
    access(account) fun addMintedCombination(combination: String) {
        Flovatar.mintedCombinations.insert(key: combination, true)
    }
    // This function will add a new name to the array
    access(account) fun addMintedName(name: String) {
        Flovatar.mintedNames.insert(key: name, true)
    }

    // This helper function will generate a string from a list of components, 
    // to be used as a sort of barcode to keep the inventory of the minted 
    // Flovatars and to avoid duplicates
    pub fun getCombinationString(
        body: UInt64,
        hair: UInt64,
        facialHair: UInt64?,
        eyes: UInt64,
        nose: UInt64,
        mouth: UInt64,
        clothing: UInt64
    ) : String {
        let facialHairString = (facialHair != nil) ? facialHair!.toString() : "x"
        return "B".concat(body.toString()).concat("H").concat(hair.toString()).concat("F").concat(facialHairString).concat("E").concat(eyes.toString()).concat("N").concat(nose.toString()).concat("M").concat(mouth.toString()).concat("C").concat(clothing.toString())
    }

    // This function will get a list of component IDs and will check if the 
    // generated string is unique or if someone already used it before.
    pub fun checkCombinationAvailable(
        body: UInt64,
        hair: UInt64,
        facialHair: UInt64?,
        eyes: UInt64,
        nose: UInt64,
        mouth: UInt64,
        clothing: UInt64
    ) : Bool {
        let combinationString = Flovatar.getCombinationString(
            body: body,
            hair: hair,
            facialHair: facialHair,
            eyes: eyes,
            nose: nose,
            mouth: mouth,
            clothing: clothing
        )
        return ! Flovatar.mintedCombinations.containsKey(combinationString)
    }

    // This will check if a specific Name has already been taken 
    // and assigned to some Flovatar
    pub fun checkNameAvailable(name: String) : Bool {
        return name.length > 2 && name.length < 20 && ! Flovatar.mintedNames.containsKey(name)
    }


    // This is a public function that anyone can call to generate a new Flovatar
    // A list of components resources needs to be passed to executed.
    // It will check first for uniqueness of the combination + name and will then 
    // generate the Flovatar and burn all the passed components.
    pub fun createFlovatar(
        body: @FlovatarComponent.NFT,
        hair: @FlovatarComponent.NFT,
        facialHair: @FlovatarComponent.NFT?,
        eyes: @FlovatarComponent.NFT,
        nose: @FlovatarComponent.NFT,
        mouth: @FlovatarComponent.NFT,
        clothing: @FlovatarComponent.NFT,
        accessory: @FlovatarComponent.NFT?,
        hat: @FlovatarComponent.NFT?,
        eyeglasses: @FlovatarComponent.NFT?,
        background: @FlovatarComponent.NFT?,
        address: Address
    ) : @Flovatar.NFT {


        pre {

            // Make sure that all components belong to the correct category
            body.getCategory() == "body" : "The body component belongs to the wrong category"
            hair.getCategory() == "hair" : "The hair component belongs to the wrong category"
            eyes.getCategory() == "eyes" : "The eyes component belongs to the wrong category"
            nose.getCategory() == "nose" : "The nose component belongs to the wrong category"
            mouth.getCategory() == "mouth" : "The mouth component belongs to the wrong category"
            clothing.getCategory() == "clothing" : "The clothing component belongs to the wrong category"

            // Make sure that all the components belong to the same series like the body
            body.getSeries() == hair.getSeries() : "The hair doesn't belong to the same series like the body"
            body.getSeries() == eyes.getSeries() : "The eyes doesn't belong to the same series like the body"
            body.getSeries() == nose.getSeries() : "The nose doesn't belong to the same series like the body"
            body.getSeries() == mouth.getSeries() : "The mouth doesn't belong to the same series like the body"
            body.getSeries() == clothing.getSeries() : "The clothing doesn't belong to the same series like the body"

        }

        // Make more checks for the additional components to check for the right category and uniqueness
        if(facialHair != nil){
            if(facialHair?.getCategory() != "facialHair"){
                panic("The facial hair component belongs to the wrong category")
            }
            if(facialHair?.getSeries() != body.getSeries()){
                panic("The facial hair doesn't belong to the same series like the body")
            }
        }

        if(accessory != nil){
            if(accessory?.getCategory() != "accessory"){
                panic("The accessory component belongs to the wrong category")
            }
            if(accessory?.getSeries() != body.getSeries()){
                panic("The accessory doesn't belong to the same series like the body")
            }
        }

        if(hat != nil){
            if(hat?.getCategory() != "hat"){
                panic("The hat component belongs to the wrong category")
            }
            if(hat?.getSeries() != body.getSeries()){
                panic("The hat doesn't belong to the same series like the body")
            }
        }

        if(eyeglasses != nil){
            if(eyeglasses?.getCategory() != "eyeglasses"){
                panic("The eyeglasses component belongs to the wrong category")
            }
            if(eyeglasses?.getSeries() != body.getSeries()){
                panic("The eyeglasses doesn't belong to the same series like the body")
            }
        }

        if(background != nil){
            if(background?.getCategory() != "background"){
                panic("The background component belongs to the wrong category")
            }
            if(background?.getSeries() != body.getSeries()){
                panic("The background doesn't belong to the same series like the body")
            }
        }


        // Generates the combination string to check for uniqueness. 
        // This is like a barcode that defines exactly which components were used
        // to create the Flovatar
        let combinationString = Flovatar.getCombinationString(
            body: body.templateId, 
            hair: hair.templateId, 
            facialHair: facialHair != nil ? facialHair?.templateId : nil, 
            eyes: eyes.templateId, 
            nose: nose.templateId, 
            mouth: mouth.templateId, 
            clothing: clothing.templateId)

        // Makes sure that the combination is available and not taken already
        if(Flovatar.mintedCombinations.containsKey(combinationString) == true) {
            panic("This combination has already been taken")
        }

        let facialHairSvg:String  = facialHair != nil ? facialHair?.getSvg()! : ""
        let svg = (body.getSvg()!).concat(facialHairSvg).concat(eyes.getSvg()!).concat(nose.getSvg()!).concat(mouth.getSvg()!).concat(clothing.getSvg()!).concat(hair.getSvg()!)

        // TODO fix this with optional if possible. If I define it as UInt64? 
        // instead of UInt64 it's throwing an error even if it's defined in Metadata struct
        let facialHairId: UInt64 = facialHair != nil ? facialHair?.templateId! : 0

        // Creates the metadata for the new Flovatar
        let metadata = Metadata(
            name: "",
            mint: Flovatar.totalSupply + UInt64(1),
            series: body.getSeries(),
            svg: svg,
            combination: combinationString,
            creatorAddress: address,
            components: {
                "body": body.templateId, 
                "hair": hair.templateId, 
                "facialHair": facialHairId, 
                "eyes": eyes.templateId, 
                "nose": nose.templateId, 
                "mouth": mouth.templateId, 
                "clothing": clothing.templateId
            }
        )

        let royalties: [Royalty] = []

        let creatorAccount = getAccount(address)
        royalties.append(Royalty(
            wallet: creatorAccount.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver), 
            cut: Flovatar.getRoyaltyCut(), 
            type: RoyaltyType.percentage
        ))

        royalties.append(Royalty(
            wallet: self.account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver), 
            cut: Flovatar.getMarketplaceCut(), 
            type: RoyaltyType.percentage
        ))

        // Mint the new Flovatar NFT by passing the metadata to it
        var newNFT <- create NFT(metadata: metadata, royalties: Royalties(royalty: royalties))

        // Adds the combination to the arrays to remember it
        Flovatar.addMintedCombination(combination: combinationString)


        // Checks for any additional optional component (accessory, hat, 
        // eyeglasses, background) and assigns it to the Flovatar if present.
        if(accessory != nil){
            newNFT.setAccessory(component: <-accessory!)
        } else {
            destroy accessory
        }
        if(hat != nil){
            newNFT.setHat(component: <-hat!)
        } else {
            destroy hat
        }
        if(eyeglasses != nil){
            newNFT.setEyeglasses(component: <-eyeglasses!)
        } else {
            destroy eyeglasses
        }
        if(background != nil){
            newNFT.setBackground(component: <-background!)
        } else {
            destroy background
        }

        // Emits the Created event to notify about its existence
        emit Created(id: newNFT.id, metadata: metadata)

        // Destroy all the main components since they are not needed anymore.
        destroy body
        destroy hair
        destroy facialHair
        destroy eyes
        destroy nose
        destroy mouth
        destroy clothing

        return <- newNFT
    }



    // These functions will return the current Royalty cuts for 
    // both the Creator and the Marketplace.
    pub fun getRoyaltyCut(): UFix64{
        return self.royaltyCut
    }
    pub fun getMarketplaceCut(): UFix64{
        return self.marketplaceCut
    }
    // Only Admins will be able to call the set functions to 
    // manage Royalties and Marketplace cuts.
    access(account) fun setRoyaltyCut(value: UFix64){
        self.royaltyCut = value
    }
    access(account) fun setMarketplaceCut(value: UFix64){
        self.marketplaceCut = value
    }

    


    // This is the main Admin resource that will allow the owner 
    // to generate new Templates, Components and Packs
    pub resource Admin {

        //This will create a new FlovatarComponentTemplate that 
        // contains all the SVG and basic informations to represent 
        // a specific part of the Flovatar (body, hair, eyes, mouth, etc.)
        // More info in the FlovatarComponentTemplate.cdc file
        pub fun createComponentTemplate(
            name: String,
            category: String,
            color: String,
            description: String,
            svg: String,
            series: UInt32,
            maxMintableComponents: UInt64
        ) : @FlovatarComponentTemplate.ComponentTemplate {
            return <- FlovatarComponentTemplate.createComponentTemplate(
                name: name,
                category: category,
                color: color,
                description: description,
                svg: svg,
                series: series,
                maxMintableComponents: maxMintableComponents
            )
        }

        // This will mint a new Component based from a selected Template
        pub fun createComponent(templateId: UInt64) : @FlovatarComponent.NFT {
            return <- FlovatarComponent.createComponent(templateId: templateId)
        }
        // This will mint Components in batch and return a Collection instead of the single NFT
        pub fun batchCreateComponents(templateId: UInt64, quantity: UInt64) : @FlovatarComponent.Collection {
            return <- FlovatarComponent.batchCreateComponents(templateId: templateId, quantity: quantity)
        }

        // This function will generate a new Pack containing a set of components.
        // A random string is passed to manage permissions for the 
        // purchase of it (more info on FlovatarPack.cdc).
        // Finally the sale price is set as well.
        pub fun createPack(
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
            randomString: String,
            price: UFix64
        ) : @FlovatarPack.Pack {

            return <- FlovatarPack.createPack(
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
                randomString: randomString,
                price: price
            )
        }

        // With this function you can generate a new Admin resource 
        // and pass it to another user if needed
        pub fun createNewAdmin(): @Admin {
            return <-create Admin()
        }

        // Helper functions to update the Royalty cut
        pub fun setRoyaltyCut(value: UFix64) {
            Flovatar.setRoyaltyCut(value: value)
        }

        // Helper functions to update the Marketplace cut
        pub fun setMarketplaceCut(value: UFix64) {
            Flovatar.setMarketplaceCut(value: value)
        }
    }





	init() {
        // TODO: remove suffix before deploying to mainnet!!!
        self.CollectionPublicPath = /public/FlovatarCollection006
        self.CollectionStoragePath = /storage/FlovatarCollection006
        self.AdminStoragePath = /storage/FlovatarAdmin006

        // Initialize the total supply
        self.totalSupply = UInt64(0)
        self.mintedCombinations = {}
        self.mintedNames = {}

        // Set the default Royalty and Marketplace cuts
        self.royaltyCut = 0.01
        self.marketplaceCut = 0.03

        self.account.save<@NonFungibleToken.Collection>(<- Flovatar.createEmptyCollection(), to: Flovatar.CollectionStoragePath)
        self.account.link<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath, target: Flovatar.CollectionStoragePath)

        // Put the Admin resource in storage
        self.account.save<@Admin>(<- create Admin(), to: self.AdminStoragePath)

        emit ContractInitialized()
	}
}

