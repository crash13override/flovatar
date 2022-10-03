import FungibleToken from 0xf233dcee88fe0abe
import NonFungibleToken from 0x1d7e57aa55817448
import FlowToken from 0x1654653399040a61
import FlovatarComponentTemplate from 0x921ea449dffec68a
import FlovatarComponent from 0x921ea449dffec68a
import FlovatarPack from 0x921ea449dffec68a
import MetadataViews from 0x1d7e57aa55817448

/*

The contract that defines the Flobot NFT and a Collection to manage them

Base components that will be used to generate the unique combination of the Flobot
'body', 'hair', 'facialhair', 'eyes', 'nose', 'mouth', 'clothing'

Extra components that can be added in a second moment
'accessory', 'hat', eyeglass', 'background'


This contract contains also the Admin resource that can be used to manage and generate all the other ones (Components, Templates, Packs).

 */

pub contract Flobot: NonFungibleToken {

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let AdminStoragePath: StoragePath

    // These will be used in the Marketplace to pay out
    // royalties to the creator and to the marketplace
    access(account) var royaltyCut: UFix64
    access(account) var marketplaceCut: UFix64

    // Here we keep track of all the Flobot unique combinations and names
    // that people will generate to make sure that there are no duplicates
    pub var totalSupply: UInt64
    access(contract) let mintedCombinations: {String: Bool}
    access(contract) let mintedNames: {String: Bool}

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Created(id: UInt64, metadata: Metadata)
    pub event Updated(id: UInt64)
    pub event NameSet(id: UInt64, name: String)


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


    // This Metadata struct contains all the most important informations about the Flobot
    pub struct Metadata {
        pub let mint: UInt64
        pub let series: UInt32
        pub let combination: String
        pub let rarity: String
        pub let creatorAddress: Address
        access(self) let components: {String: UInt64}


        init(
            mint: UInt64,
            series: UInt32,
            combination: String,
            rarity: String,
            creatorAddress: Address,
            components: {String: UInt64}
        ) {
                self.mint = mint
                self.series = series
                self.combination = combination
                self.rarity = rarity
                self.creatorAddress = creatorAddress
                self.components = components
        }
        pub fun getComponents(): {String: UInt64} {
            return self.components
        }
    }

    // The public interface can show metadata and the content for the Flobot.
    // In addition to it, it provides methods to access the additional optional
    // components (accessory, hat, eyeglasses, background) for everyone.
    pub resource interface Public {
        pub let id: UInt64
        access(contract) let metadata: Metadata
        access(contract) let royalties: Royalties

        // these three are added because I think they will be in the standard. At least Dieter thinks it will be needed
        access(contract) var name: String
        pub let description: String
        pub let schema: String?

        pub fun getName(): String
        pub fun getBackground(): UInt64?

        pub fun getSvg(): String
        pub fun getMetadata(): Metadata
        pub fun getRoyalties(): Royalties
        pub fun getBio(): {String: String}
    }

    //The private interface can update the Accessory, Hat, Eyeglasses and Background
    //for the Flobot and is accessible only to the owner of the NFT
    pub resource interface Private {
        pub fun setName(name: String): String
        pub fun setBackground(component: @FlovatarComponent.NFT): @FlovatarComponent.NFT?
        pub fun removeBackground(): @FlovatarComponent.NFT?
    }

    //The NFT resource that implements both Private and Public interfaces
    pub resource NFT: NonFungibleToken.INFT, Public, Private, MetadataViews.Resolver {
        pub let id: UInt64
        access(contract) let metadata: Metadata
        access(contract) let royalties: Royalties
        access(contract) var background: @FlovatarComponent.NFT?

        access(contract) var name: String
        pub let description: String
        pub let schema: String?
        access(self) let bio: {String: String}

        init(metadata: Metadata,
            royalties: Royalties) {
            Flobot.totalSupply = Flobot.totalSupply + UInt64(1)

            self.id = Flobot.totalSupply
            self.metadata = metadata
            self.royalties = royalties
            self.background <- nil

            self.schema = nil
            self.name = ""
            self.description = ""
            self.bio = {}
        }

        destroy() {
            destroy self.background
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

        // This will allow to change the Name of the Flobot only once.
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
            if(Flobot.checkNameAvailable(name: name) == false){
                panic("This name has already been taken")
            }

            // DISABLING THIS FUNCTIONALITY TO BE INTRODUCED AT A LATER DATE
            //self.name = name


            // Adds the name to the array to remember it
            //Flobot.addMintedName(name: name)
            //emit NameSet(id: self.id, name: name)

            return self.name
        }


        pub fun getBackground(): UInt64? {
            return self.background?.templateId
        }

        // This will allow to change the Background of the Flobot any time.
        // It checks for the right category and series before executing.
        pub fun setBackground(component: @FlovatarComponent.NFT): @FlovatarComponent.NFT? {
            pre {
                component.getCategory() == "background" : "The component needs to be a background"
                (component.getSeries() == self.metadata.series || component.getSeries() == UInt32(1)) : "The accessory belongs to a different series"
            }

            emit Updated(id: self.id)

            let compNFT <- self.background <- component
            return <-compNFT
        }

        // This will allow to remove the Background of the Flobot any time.
        pub fun removeBackground(): @FlovatarComponent.NFT? {
            emit Updated(id: self.id)
            let compNFT <- self.background <- nil
            return <-compNFT
        }

        // This function will return the full SVG of the Flobot. It will take the
        // optional components (Accessory, Hat, Eyeglasses and Background) from their
        // original Template resources, while all the other unmutable components are
        // taken from the Metadata directly.
        pub fun getSvg(): String {
            var svg: String = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 3000 3000' width='100%' height='100%'>"

            if let background = self.getBackground() {
                if let template = FlovatarComponentTemplate.getComponentTemplate(id: background) {
                    svg = svg.concat(template.svg!)
                }
            }

            svg = svg.concat(self.getTraitsSvg())

            svg = svg.concat("</svg>")

            return svg

        }
        pub fun getSvgNoBg(): String {
            var svg: String = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 3000 3000' width='100%' height='100%'>"

            svg = svg.concat(self.getTraitsSvg())

            svg = svg.concat("</svg>")

            return svg

        }

        pub fun getTraitsSvg(): String {
            var svg: String = ""

            let components: {String: UInt64} = self.metadata.getComponents()

            let armsTemplate: FlovatarComponentTemplate.ComponentTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: components["arms"]!)!
            let legsTemplate: FlovatarComponentTemplate.ComponentTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: components["legs"]!)!
            let bodyTemplate: FlovatarComponentTemplate.ComponentTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: components["body"]!)!
            let headTemplate: FlovatarComponentTemplate.ComponentTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: components["head"]!)!
            let faceTemplate: FlovatarComponentTemplate.ComponentTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: components["face"]!)!

            svg = svg.concat(armsTemplate.svg!)
            svg = svg.concat(legsTemplate.svg!)
            svg = svg.concat(bodyTemplate.svg!)
            svg = svg.concat(headTemplate.svg!)
            svg = svg.concat(faceTemplate.svg!)

            svg = svg.concat("</svg>")

            return svg

        }


        pub fun getViews() : [Type] {
            var views : [Type]=[]
            views.append(Type<MetadataViews.NFTCollectionData>())
            views.append(Type<MetadataViews.NFTCollectionDisplay>())
            views.append(Type<MetadataViews.Display>())
            views.append(Type<MetadataViews.Royalties>())
            views.append(Type<MetadataViews.Edition>())
            views.append(Type<MetadataViews.ExternalURL>())
            views.append(Type<MetadataViews.Serial>())
            views.append(Type<MetadataViews.Traits>())
            return views
        }
        pub fun resolveView(_ type: Type): AnyStruct? {

            if type == Type<MetadataViews.ExternalURL>() {
                return MetadataViews.ExternalURL("https://flovatar.com/flobots/".concat(self.id.toString()))
            }

            if type == Type<MetadataViews.Royalties>() {
                let royalties : [MetadataViews.Royalty] = []
                var count: Int = 0
                for royalty in self.royalties.royalty {
                    royalties.append(MetadataViews.Royalty(recepient: royalty.wallet, cut: royalty.cut, description: "Flovatar Royalty ".concat(count.toString())))
                    count = count + Int(1)
                }
                return MetadataViews.Royalties(cutInfos: royalties)
            }

            if type == Type<MetadataViews.Serial>() {
                return MetadataViews.Serial(self.id)
            }

            if type ==  Type<MetadataViews.Editions>() {
                let editionInfo = MetadataViews.Edition(name: "Flobots", number: self.id, max: UInt64(9999))
                let editionList: [MetadataViews.Edition] = [editionInfo]
                return MetadataViews.Editions(
                    editionList
                )
            }

            if type == Type<MetadataViews.NFTCollectionDisplay>() {
                let mediaSquare = MetadataViews.Media(
                    file: MetadataViews.HTTPFile(
                        url: "https://images.flovatar.com/logo.svg"
                    ),
                    mediaType: "image/svg+xml"
                )
                let mediaBanner = MetadataViews.Media(
                    file: MetadataViews.HTTPFile(
                        url: "https://images.flovatar.com/logo-horizontal.svg"
                    ),
                    mediaType: "image/svg+xml"
                )
                return MetadataViews.NFTCollectionDisplay(
                    name: "Flovatar Flobot",
                    description: "Flovatar is pioneering a new way to unleash community creativity in Web3 by allowing users to be co-creators of their prized NFTs, instead of just being passive collectors.",
                    externalURL: MetadataViews.ExternalURL("https://flovatar.com"),
                    squareImage: mediaSquare,
                    bannerImage: mediaBanner,
                    socials: {
                        "discord": MetadataViews.ExternalURL("https://discord.gg/flovatar"),
                        "twitter": MetadataViews.ExternalURL("https://twitter.com/flovatar"),
                        "instagram": MetadataViews.ExternalURL("https://instagram.com/flovatar_nft"),
                        "tiktok": MetadataViews.ExternalURL("https://www.tiktok.com/@flovatar")
                    }
                )
            }

            if type == Type<MetadataViews.NFTCollectionData>() {
                return MetadataViews.NFTCollectionData(
                storagePath: Flobot.CollectionStoragePath,
                publicPath: Flobot.CollectionPublicPath,
                providerPath: /private/FlobotCollection,
                publicCollection: Type<&Flobot.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Flobot.CollectionPublic}>(),
                publicLinkedType: Type<&Flobot.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Flobot.CollectionPublic}>(),
                providerLinkedType: Type<&Flobot.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Flobot.CollectionPublic}>(),
                createEmptyCollectionFunction: fun(): @NonFungibleToken.Collection {return <- Flobot.createEmptyCollection()}
                )
            }

            if type == Type<MetadataViews.Display>() {
                return MetadataViews.Display(
                    name: self.name,
                    description: self.description,
                    thumbnail: MetadataViews.HTTPFile(
                        url: "https://images.flovatar.com/flobot/svg/".concat(self.id.toString()).concat(".svg")
                    )
                )
            }

            if type == Type<MetadataViews.Traits>() {
                let traits: [MetadataViews.Trait] = []
                let components: {String: UInt64} = self.metadata.getComponents()

                for k in components.keys {
                    if let template = FlovatarComponentTemplate.getComponentTemplate(id: components[k]!) {
                        let trait = MetadataViews.Trait(name: k, value: template.name, displayType:"String", rarity: MetadataViews.Rarity(score:nil, max:nil, description: template.rarity))
                        traits.append(trait)
                    }
                }
                if let background = self.getBackground() {
                    if let template = FlovatarComponentTemplate.getComponentTemplate(id: background) {
                        let trait = MetadataViews.Trait(name: template.category, value: template.name, displayType:"String", rarity: MetadataViews.Rarity(score:nil, max:nil, description: template.rarity))
                        traits.append(trait)
                    }
                }

                return MetadataViews.Traits(traits)
            }

            if type == Type<MetadataViews.Rarity>() {
                var score:UFix64 = 10.0
                if(self.metadata.rarity == "legendary"){
                    score = 100.0
                } else if(self.metadata.rarity == "epic"){
                     score = 50.0
                 }
                return MetadataViews.Rarity(score: score, max: 100.0, description: nil)
            }

            return nil
        }
    }


    // Standard NFT collectionPublic interface that can also borrowFlobot as the correct type
    pub resource interface CollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowFlobot(id: UInt64): &Flobot.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Flobot reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Main Collection to manage all the Flobot NFT
    pub resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
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
            let token <- token as! @Flobot.NFT

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
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        // borrowFlobot returns a borrowed reference to a Flobot
        // so that the caller can read data and call methods from it.
        pub fun borrowFlobot(id: UInt64): &Flobot.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &Flobot.NFT
            } else {
                return nil
            }
        }

        // borrowFlobotPrivate returns a borrowed reference to a Flobot using the Private interface
        // so that the caller can read data and call methods from it, like setting the optional components.
        pub fun borrowFlobotPrivate(id: UInt64): &{Flobot.Private}? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &Flobot.NFT
            } else {
                return nil
            }
        }

        destroy() {
            destroy self.ownedNFTs
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            pre {
                self.ownedNFTs[id] != nil : "NFT does not exist"
            }
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let flobotNFT = nft as! &Flobot.NFT
            return flobotNFT as &AnyResource{MetadataViews.Resolver}
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    // This struct is used to send a data representation of the Flobots
    // when retrieved using the contract helper methods outside the collection.
    pub struct FlobotData {
        pub let id: UInt64
        pub let name: String
        pub let metadata: Flobot.Metadata
        pub let backgroundId: UInt64?
        pub let bio: {String: String}
        init(
            id: UInt64,
            name: String,
            metadata: Flobot.Metadata,
            backgroundId: UInt64?,
            bio: {String: String}
            ) {
            self.id = id
            self.name = name
            self.metadata = metadata
            self.backgroundId = backgroundId
            self.bio = bio
        }
    }


    // This function will look for a specific Flobot on a user account and return a FlobotData if found
    pub fun getFlobot(address: Address, flobotId: UInt64) : FlobotData? {

        let account = getAccount(address)

        if let flobotCollection = account.getCapability(self.CollectionPublicPath).borrow<&{Flobot.CollectionPublic}>()  {
            if let flobot = flobotCollection.borrowFlobot(id: flobotId) {
                return FlobotData(
                    id: flobotId,
                    name: flobot!.getName(),
                    metadata: flobot!.getMetadata(),
                    backgroundId: flobot!.getBackground(),
                    bio: flobot!.getBio()
                )
            }
        }
        return nil
    }

    // This function will return all Flobots on a user account and return an array of FlobotData
    pub fun getFlobots(address: Address) : [FlobotData] {

        var flobotData: [FlobotData] = []
        let account = getAccount(address)

        if let flobotCollection = account.getCapability(self.CollectionPublicPath).borrow<&{Flobot.CollectionPublic}>()  {
            for id in flobotCollection.getIDs() {
                var flobot = flobotCollection.borrowFlobot(id: id)
                flobotData.append(FlobotData(
                    id: id,
                    name: flobot!.getName(),
                    metadata: flobot!.getMetadata(),
                    backgroundId: flobot!.getBackground(),
                    bio: flobot!.getBio()
                    ))
            }
        }
        return flobotData
    }


    // This returns all the previously minted combinations, so that duplicates won't be allowed
    pub fun getMintedCombinations() : [String] {
        return Flobot.mintedCombinations.keys
    }
    // This returns all the previously minted names, so that duplicates won't be allowed
    pub fun getMintedNames() : [String] {
        return Flobot.mintedNames.keys
    }

    // This function will add a minted combination to the array
    access(account) fun addMintedCombination(combination: String) {
        Flobot.mintedCombinations.insert(key: combination, true)
    }
    // This function will add a new name to the array
    access(account) fun addMintedName(name: String) {
        Flobot.mintedNames.insert(key: name, true)
    }

    // This helper function will generate a string from a list of components,
    // to be used as a sort of barcode to keep the inventory of the minted
    // Flobots and to avoid duplicates
    pub fun getCombinationString(
        body: UInt64,
        head: UInt64,
        arms: UInt64,
        legs: UInt64,
        face: UInt64
    ) : String {
        return "B".concat(body.toString()).concat("H").concat(head.toString()).concat("A").concat(arms.toString()).concat("L").concat(legs.toString()).concat("F").concat(face.toString())
    }

    // This function will get a list of component IDs and will check if the
    // generated string is unique or if someone already used it before.
    pub fun checkCombinationAvailable(
        body: UInt64,
        head: UInt64,
        arms: UInt64,
        legs: UInt64,
        face: UInt64
    ) : Bool {
        let combinationString = Flobot.getCombinationString(
            body: body,
            head: head,
            arms: arms,
            legs: legs,
            face: face
        )
        return ! Flobot.mintedCombinations.containsKey(combinationString)
    }

    // This will check if a specific Name has already been taken
    // and assigned to some Flobot
    pub fun checkNameAvailable(name: String) : Bool {
        return name.length > 2 && name.length < 20 && ! Flobot.mintedNames.containsKey(name)
    }


    // This is a public function that anyone can call to generate a new Flobot
    // A list of components resources needs to be passed to executed.
    // It will check first for uniqueness of the combination + name and will then
    // generate the Flobot and burn all the passed components.
    // The Spark NFT will entitle to use any common basic component (body, hair, etc.)
    // In order to use special rare components a boost of the same rarity will be needed
    // for each component used
    pub fun createFlobot(
        flobotkit: @[FlovatarComponent.NFT],
        body: UInt64,
        head: UInt64,
        arms: UInt64,
        legs: UInt64,
        face: UInt64,
        background: @FlovatarComponent.NFT?,
        address: Address
    ) : @Flobot.NFT {

        var i: Int = 0
        var flobotkitSeries:UInt32 = UInt32(0)
        var flobotkitRarity: String = ""
        var checkFlobotRarity:Bool = false
        var checkFlobotSeries:Bool = false

        while( i < flobotkit.length) {
            if(flobotkit[i].getCategory() != "flobotkit") {
                panic("The Flobot Kit belongs to the wrong category")
            }
            if(flobotkit[i].getSeries() != UInt32(2)) {
                panic("The Flobot Kit doesn't belong to the correct series")
            }
            if(flobotkitRarity != flobotkit[i].getRarity()){
                if(flobotkitRarity != ""){
                    checkFlobotRarity = true
                }
                flobotkitRarity = flobotkit[i].getRarity()
            }
            if(flobotkitSeries != flobotkit[i].getSeries()){
                if(flobotkitSeries != UInt32(0)){
                    checkFlobotSeries = true
                }
                flobotkitSeries = flobotkit[i].getSeries()
            }
            i = i + 1
        }

        if(checkFlobotRarity){
            panic("The Flobot Kits need to belong to the same Rarity level")
        }
        if(checkFlobotSeries){
            panic("The Flobot Kits need to belong to the same Series")
        }
        if(flobotkit.length != 1 && flobotkit.length != 5){
            panic("You need to pass either 1 Flobot Kit or 5 of them to access the next rarity level")
        }

        if(flobotkit.length == 5){
            if(flobotkitRarity == "common"){
                flobotkitRarity = "epic"
            } else if(flobotkitRarity == "epic"){
               flobotkitRarity = "legendary"
            } else {
                panic("Impossible to upgrade the Rarity level for the Flobot Kit")
            }
        }


        let bodyTemplate: FlovatarComponentTemplate.ComponentTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: body)!
        let headTemplate: FlovatarComponentTemplate.ComponentTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: head)!
        let armsTemplate: FlovatarComponentTemplate.ComponentTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: arms)!
        let legsTemplate: FlovatarComponentTemplate.ComponentTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: legs)!
        let faceTemplate: FlovatarComponentTemplate.ComponentTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: face)!


        // Make sure that all components belong to the correct category
        if(bodyTemplate.category != "body") { panic("The body component belongs to the wrong category") }
        if(headTemplate.category != "head") { panic("The head component belongs to the wrong category") }
        if(armsTemplate.category != "arms") { panic("The arms component belongs to the wrong category") }
        if(legsTemplate.category != "legs") { panic("The legs component belongs to the wrong category") }
        if(faceTemplate.category != "face") { panic("The face component belongs to the wrong category") }


        // Make sure that all the components belong to the same series like the flobotkit
        if(bodyTemplate.series != flobotkitSeries) { panic("The body doesn't belong to the correct series") }
        if(headTemplate.series != flobotkitSeries) { panic("The head doesn't belong to the correct series") }
        if(armsTemplate.series != flobotkitSeries) { panic("The arms doesn't belong to the correct series") }
        if(legsTemplate.series != flobotkitSeries) { panic("The legs doesn't belong to the correct series") }
        if(faceTemplate.series != flobotkitSeries) { panic("The face doesn't belong to the correct series") }

        var flobotRarity: String = "common"

        if(bodyTemplate.rarity == "rare" ) { flobotRarity = "rare" }
        if(headTemplate.rarity == "rare" ) { flobotRarity = "rare" }
        if(armsTemplate.rarity == "rare" ) { flobotRarity = "rare" }
        if(legsTemplate.rarity == "rare" ) { flobotRarity = "rare" }
        if(faceTemplate.rarity == "rare" ) { flobotRarity = "rare" }

        if(bodyTemplate.rarity == "epic" ) { flobotRarity = "epic" }
        if(headTemplate.rarity == "epic" ) { flobotRarity = "epic" }
        if(armsTemplate.rarity == "epic" ) { flobotRarity = "epic" }
        if(legsTemplate.rarity == "epic" ) { flobotRarity = "epic" }
        if(faceTemplate.rarity == "epic" ) { flobotRarity = "epic" }

        if(bodyTemplate.rarity == "legendary" ) { flobotRarity = "legendary" }
        if(headTemplate.rarity == "legendary" ) { flobotRarity = "legendary" }
        if(armsTemplate.rarity == "legendary" ) { flobotRarity = "legendary" }
        if(legsTemplate.rarity == "legendary" ) { flobotRarity = "legendary" }
        if(faceTemplate.rarity == "legendary" ) { flobotRarity = "legendary" }


        if(background != nil){
            if(background?.getSeries() != UInt32(1) && !(background?.checkCategorySeries(category: "background", series: flobotkitSeries)!)){
                panic("The background component belongs to the wrong category or the wrong series")
            }
        }




        if(flobotRarity != flobotkitRarity){
            if((flobotRarity == "rare" && flobotkitRarity == "common")
                || (flobotRarity == "epic" && (flobotkitRarity == "common" || flobotkitRarity == "rare"))
                || flobotRarity == "legendary" && (flobotkitRarity == "common" || flobotkitRarity == "rare" || flobotkitRarity == "epic")){
                panic("The Rarity of your Flobot Constructor Kit is not high enough")
            }
        }




        // Generates the combination string to check for uniqueness.
        // This is like a barcode that defines exactly which components were used
        // to create the Flobot
        let combinationString = Flobot.getCombinationString(
            body: body,
            head: head,
            arms: arms,
            legs: legs,
            face: face)

        // Makes sure that the combination is available and not taken already
        if(Flobot.mintedCombinations.containsKey(combinationString) == true) {
            panic("This combination has already been taken")
        }


        // Creates the metadata for the new Flobot
        let metadata = Metadata(
            mint: Flobot.totalSupply + UInt64(1),
            series: flobotkitSeries,
            combination: combinationString,
            rarity: flobotRarity,
            creatorAddress: address,
            components: {
                "body": body,
                "head": head,
                "arms": arms,
                "legs": legs,
                "face": face
            }
        )

        let royalties: [Royalty] = []

        let creatorAccount = getAccount(address)
        royalties.append(Royalty(
            wallet: creatorAccount.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver),
            cut: Flobot.getRoyaltyCut(),
            type: RoyaltyType.percentage
        ))

        royalties.append(Royalty(
            wallet: self.account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver),
            cut: Flobot.getMarketplaceCut(),
            type: RoyaltyType.percentage
        ))

        // Mint the new Flobot NFT by passing the metadata to it
        var newNFT <- create NFT(metadata: metadata, royalties: Royalties(royalty: royalties))

        // Adds the combination to the arrays to remember it
        Flobot.addMintedCombination(combination: combinationString)


        // Checks for any additional optional component (accessory, hat,
        // eyeglasses, background) and assigns it to the Flobot if present.

        if(background != nil){
            let temp <- newNFT.setBackground(component: <-background!)
            destroy temp
        } else {
            destroy background
        }

        // Emits the Created event to notify about its existence
        emit Created(id: newNFT.id, metadata: metadata)

        // Destroy all the flobotkit and the rarity boost since they are not needed anymore.

        destroy flobotkit

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


        // With this function you can generate a new Admin resource
        // and pass it to another user if needed
        pub fun createNewAdmin(): @Admin {
            return <-create Admin()
        }

        // Helper functions to update the Royalty cut
        pub fun setRoyaltyCut(value: UFix64) {
            Flobot.setRoyaltyCut(value: value)
        }

        // Helper functions to update the Marketplace cut
        pub fun setMarketplaceCut(value: UFix64) {
            Flobot.setMarketplaceCut(value: value)
        }
    }





	init() {
        self.CollectionPublicPath = /public/FlobotCollection
        self.CollectionStoragePath = /storage/FlobotCollection
        self.AdminStoragePath = /storage/FlobotAdmin

        // Initialize the total supply
        self.totalSupply = UInt64(0)
        self.mintedCombinations = {}
        self.mintedNames = {}

        // Set the default Royalty and Marketplace cuts
        self.royaltyCut = 0.01
        self.marketplaceCut = 0.05

        self.account.save<@NonFungibleToken.Collection>(<- Flobot.createEmptyCollection(), to: Flobot.CollectionStoragePath)
        self.account.link<&{Flobot.CollectionPublic}>(Flobot.CollectionPublicPath, target: Flobot.CollectionStoragePath)

        // Put the Admin resource in storage
        self.account.save<@Admin>(<- create Admin(), to: self.AdminStoragePath)

        emit ContractInitialized()
	}
}
