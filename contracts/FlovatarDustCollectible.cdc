//import FungibleToken from 0xf233dcee88fe0abe
//import NonFungibleToken from 0x1d7e57aa55817448
//import FlowToken from 0x1654653399040a61
//import FlovatarDustCollectibleTemplate from 0x921ea449dffec68a
//import MetadataViews from 0x1d7e57aa55817448
//import FlovatarDustToken from 0x921ea449dffec68a
import FungibleToken from "./FungibleToken.cdc"
import NonFungibleToken from "./NonFungibleToken.cdc"
import FlowToken from "./FlowToken.cdc"
import FlovatarDustCollectibleTemplate from "./FlovatarDustCollectibleTemplate.cdc"
import FlovatarDustCollectibleAccessory from "./FlovatarDustCollectibleAccessory.cdc"
import MetadataViews from "./MetadataViews.cdc"
import FlovatarDustToken from "./FlovatarDustToken.cdc"

/*

 The contract that defines the Dust Collectible NFT and a Collection to manage them


This contract contains also the Admin resource that can be used to manage and generate the Dust Collectible Templates.

 */

pub contract FlovatarDustCollectible: NonFungibleToken {

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
    pub event Created(id: UInt64, mint: UInt64, series: UInt64)
    pub event Updated(id: UInt64)
    pub event Destroyed(id: UInt64)
    pub event NameSet(id: UInt64, name: String)
    pub event PositionChanged(id: UInt64, position: String)
    pub event StoryAdded(id: UInt64, story: String)


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



    // The public interface can show metadata and the content for the Flovatar.
    // In addition to it, it provides methods to access the additional optional
    // components (accessory, hat, eyeglasses, background) for everyone.
    pub resource interface Public {
        pub let id: UInt64
        pub let mint: UInt64
        pub let series: UInt64
        pub let combination: String
        pub let creatorAddress: Address
        pub let createdAt: UFix64
        access(contract) let royalties: Royalties

        // these three are added because I think they will be in the standard. At least Dieter thinks it will be needed
        access(contract) var name: String
        pub let description: String
        pub let schema: String?

        pub fun getName(): String
        pub fun getSvg(): String
        pub fun getRoyalties(): Royalties
        pub fun getBio(): {String: String}
        pub fun getMetadata(): {String: String}
        pub fun getLayers(): {UInt32: UInt64?}
        pub fun getAccessories(): [UInt64]
        pub fun getSeries(): FlovatarDustCollectibleTemplate.CollectibleSeriesData?
    }

    //The private interface can update the Accessory, Hat, Eyeglasses and Background
    //for the Flovatar and is accessible only to the owner of the NFT
    pub resource interface Private {
        pub fun setName(name: String, vault: @FlovatarDustToken.Vault): String
        pub fun addStory(text: String, vault: @FlovatarDustToken.Vault): String
        pub fun setPosition(latitude: Fix64, longitude: Fix64, vault: @FlovatarDustToken.Vault): String
        pub fun setAccessory(layer: UInt32, accessory: @FlovatarDustCollectibleAccessory.NFT): @FlovatarDustCollectibleAccessory.NFT?
        pub fun removeAccessory(layer: UInt32): @FlovatarDustCollectibleAccessory.NFT?
    }

    //The NFT resource that implements both Private and Public interfaces
    pub resource NFT: NonFungibleToken.INFT, Public, Private, MetadataViews.Resolver {
        pub let id: UInt64
        pub let mint: UInt64
        pub let series: UInt64
        pub let combination: String
        pub let creatorAddress: Address
        pub let createdAt: UFix64
        access(contract) let royalties: Royalties

        access(contract) var name: String
        pub let description: String
        pub let schema: String?
        access(self) let bio: {String: String}
        access(self) let metadata: {String: String}
        access(self) let layers: {UInt32: UInt64?}
        access(self) let accessories: @{UInt32: FlovatarDustCollectibleAccessory.NFT}

        init(series: UInt64,
            layers: {UInt32: UInt64?},
            creatorAddress: Address,
            royalties: Royalties) {
            FlovatarDustCollectible.totalSupply = FlovatarDustCollectible.totalSupply + UInt64(1)
            FlovatarDustCollectibleTemplate.increaseTotalMintedCollectibles(series: series)
            let coreLayers: {UInt32: UInt64} = FlovatarDustCollectible.getCoreLayers(series: series, layers: layers)

            self.id = FlovatarDustCollectible.totalSupply
            //TODO Update to keep track of mints per series
            self.mint = FlovatarDustCollectibleTemplate.getTotalMintedCollectibles(series: series)!
            self.series = series
            self.combination = FlovatarDustCollectible.getCombinationString(series: series, layers: coreLayers)
            self.creatorAddress = creatorAddress
            self.createdAt = getCurrentBlock().timestamp
            self.royalties = royalties

            self.schema = nil
            self.name = ""
            self.description = ""
            self.bio = {}
            self.metadata = {}
            self.layers = layers
            self.accessories <- {}
        }

        destroy() {
            destroy self.accessories
            emit Destroyed(id: self.id)
        }

        pub fun getID(): UInt64 {
            return self.id
        }

        pub fun getMetadata(): {String: String} {
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

        pub fun getSeries(): FlovatarDustCollectibleTemplate.CollectibleSeriesData? {
            return FlovatarDustCollectibleTemplate.getCollectibleSeries(id: self.series)
        }

        // This will allow to change the Name of the Flovatar only once.
        // It checks for the current name is empty, otherwise it will throw an error.
        // $DUST vault must contain 100 tokens that will be burned in the process
        pub fun setName(name: String, vault: @FlovatarDustToken.Vault): String {
            pre {
                // TODO: Make sure that the text of the name is sanitized
                //and that bad words are not accepted?
                name.length > 2 : "The name is too short"
                name.length < 32 : "The name is too long"
                self.name == "" : "The name has already been set"
                vault.balance == 100.0 : "The amount of $DUST is not correct"
            }

            // Makes sure that the name is available and not taken already
            if(FlovatarDustCollectible.checkNameAvailable(name: name) == false){
                panic("This name has already been taken")
            }

            destroy vault
            self.name = name


            // Adds the name to the array to remember it
            FlovatarDustCollectible.addMintedName(name: name)
            emit NameSet(id: self.id, name: name)

            return self.name
        }

        // This will allow to add a text Story to the Flovatar Bio.
        // The String will be concatenated each time.
        // There is a limit of 300 characters per story but there is no limit in the full concatenated story length
        // $DUST vault must contain 50 tokens that will be burned in the process
        pub fun addStory(text: String, vault: @FlovatarDustToken.Vault): String {
            pre {
                // TODO: Make sure that the text of the name is sanitized
                //and that bad words are not accepted?
                text.length > 0 : "The text is too short"
                text.length <= 300 : "The text is too long"
                vault.balance == 50.0 : "The amount of $DUST is not correct"
            }

            destroy vault
            let currentStory: String = self.bio["story"] ?? ""
            let story: String = currentStory.concat(" ").concat(text)
            self.bio.insert(key: "story", story)

            emit StoryAdded(id: self.id, story: story)

            return story
        }


        // This will allow to set the GPS location of a Flovatar
        // It can be run multiple times and each time it will override the previous state
        // $DUST vault must contain 10 tokens that will be burned in the process
        pub fun setPosition(latitude: Fix64, longitude: Fix64, vault: @FlovatarDustToken.Vault): String {
            pre {
                latitude >= -90.0 : "The latitude is out of range"
                latitude <= 90.0 : "The latitude is out of range"
                longitude >= -180.0 : "The longitude is out of range"
                longitude <= 180.0 : "The longitude is out of range"
                vault.balance == 10.0 : "The amount of $DUST is not correct"
            }

            destroy vault
            let position: String = latitude.toString().concat(",").concat(longitude.toString())
            self.bio.insert(key: "gps", position)

            emit PositionChanged(id: self.id, position: position)

            return position
        }

        pub fun getLayers(): {UInt32: UInt64?} {
            return self.layers
        }


        pub fun getAccessories(): [UInt64] {
            let accessoriesIds: [UInt64] = []
            for k in self.accessories.keys {
                let accessoryId = self.accessories[k]?.id
                if(accessoryId != nil){
                    accessoriesIds.append(accessoryId!)
                }
            }
            return accessoriesIds
        }
        // This will allow to change the Accessory of the Flovatar any time.
        // It checks for the right category and series before executing.
        pub fun setAccessory(layer: UInt32, accessory: @FlovatarDustCollectibleAccessory.NFT): @FlovatarDustCollectibleAccessory.NFT? {
            pre {
                accessory.getSeries() == self.series : "The accessory belongs to a different series"
            }

            if(FlovatarDustCollectibleTemplate.isCollectibleLayerAccessory(layer: layer, series: self.series)){
                emit Updated(id: self.id)

                self.layers[layer] = accessory.templateId

                let oldAccessory <- self.accessories[layer] <- accessory
                return <- oldAccessory
            }

            panic("The Layer is out of range or it's not an accessory")
        }

        // This will allow to remove the Accessory of the Flovatar any time.
        pub fun removeAccessory(layer: UInt32): @FlovatarDustCollectibleAccessory.NFT? {
            if(FlovatarDustCollectibleTemplate.isCollectibleLayerAccessory(layer: layer, series: self.series)){
                emit Updated(id: self.id)
                self.layers[layer] = nil
                let accessory <- self.accessories[layer] <- nil
                return <-accessory
            }

            panic("The Layer is out of range or it's not an accessory")
        }


        // This function will return the full SVG of the Flovatar. It will take the
        // optional components (Accessory, Hat, Eyeglasses and Background) from their
        // original Template resources, while all the other unmutable components are
        // taken from the Metadata directly.
        pub fun getSvg(): String {
            let series = FlovatarDustCollectibleTemplate.getCollectibleSeries(id: self.series)

            var svg: String = series!.svgPrefix

            for k in self.layers.keys {
                if(self.layers[k] != nil){
                    let layer = self.layers[k]!
                    if(layer != nil){
                        let tempSvg = FlovatarDustCollectibleTemplate.getCollectibleTemplateSvg(id: layer!)
                        svg = svg.concat(tempSvg!)
                    }
                }
            }

            svg = svg.concat(series!.svgSuffix)

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
                return MetadataViews.ExternalURL("https://flovatar.com/stardust-collectible/".concat(self.id.toString()))
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
                let series = self.getSeries()
                let editionInfo = MetadataViews.Edition(name: "Flovatar Stardust Collectible Series ".concat(self.series.toString()), number: self.mint, max: series!.maxMintable)
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
                    name: "Flovatar Stardust Collectible",
                    description: "The Flovatar Stardust Collectibles are the next generation of composable and customizable NFTs that populate the Flovatar Universe and can be minted exclusively by using the $DUST token.",
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
                storagePath: FlovatarDustCollectible.CollectionStoragePath,
                publicPath: FlovatarDustCollectible.CollectionPublicPath,
                providerPath: /private/FlovatarDustCollectibleCollection,
                publicCollection: Type<&FlovatarDustCollectible.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, FlovatarDustCollectible.CollectionPublic}>(),
                publicLinkedType: Type<&FlovatarDustCollectible.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, FlovatarDustCollectible.CollectionPublic}>(),
                providerLinkedType: Type<&FlovatarDustCollectible.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, FlovatarDustCollectible.CollectionPublic}>(),
                createEmptyCollectionFunction: fun(): @NonFungibleToken.Collection {return <- FlovatarDustCollectible.createEmptyCollection()}
                )
            }

            if type == Type<MetadataViews.Display>() {
                return MetadataViews.Display(
                    name: self.name == "" ? "Stardust Collectible #".concat(self.id.toString()) : self.name,
                    description: self.description,
                    thumbnail: MetadataViews.HTTPFile(
                        url: "https://images.flovatar.com/stardust-collectible/svg/".concat(self.id.toString()).concat(".svg")
                    )
                )
            }

            if type == Type<MetadataViews.Traits>() {
                let traits: [MetadataViews.Trait] = []

                let series = self.getSeries()

                for k in self.layers.keys {
                    if(self.layers[k] != nil){
                        let layer = series!.layers[k]!
                        if(self.layers[k] != nil){
                            let layerSelf = self.layers[k]!
                            if(layer != nil){
                                let template = FlovatarDustCollectibleTemplate.getCollectibleTemplate(id: layerSelf!)
                                let trait = MetadataViews.Trait(name: layer!.name, value: template!.name, displayType:"String", rarity: MetadataViews.Rarity(score:nil, max:nil, description: template!.rarity))
                                traits.append(trait)
                            }
                        }
                    }
                }

                return MetadataViews.Traits(traits)
            }


            return nil
        }
    }


    // Standard NFT collectionPublic interface that can also borrowFlovatar as the correct type
    pub resource interface CollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowDustCollectible(id: UInt64): &FlovatarDustCollectible.NFT{FlovatarDustCollectible.Public, MetadataViews.Resolver}? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Flovatar Dust Collectible reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Main Collection to manage all the Flovatar NFT
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
            let token <- token as! @FlovatarDustCollectible.NFT

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

        // borrowFlovatar returns a borrowed reference to a Flovatar
        // so that the caller can read data and call methods from it.
        pub fun borrowDustCollectible(id: UInt64): &FlovatarDustCollectible.NFT{FlovatarDustCollectible.Public, MetadataViews.Resolver}? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                let collectibleNFT = ref as! &FlovatarDustCollectible.NFT
                return collectibleNFT as &FlovatarDustCollectible.NFT{FlovatarDustCollectible.Public, MetadataViews.Resolver}
            } else {
                return nil
            }
        }

        // borrowFlovatarPrivate returns a borrowed reference to a Flovatar using the Private interface
        // so that the caller can read data and call methods from it, like setting the optional components.
        pub fun borrowDustCollectiblePrivate(id: UInt64): &{FlovatarDustCollectible.Private}? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &FlovatarDustCollectible.NFT
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
            let collectibleNFT = nft as! &FlovatarDustCollectible.NFT
            return collectibleNFT as &AnyResource{MetadataViews.Resolver}
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    // This struct is used to send a data representation of the Flovatar Dust Collectibles
    // when retrieved using the contract helper methods outside the collection.
    pub struct FlovatarDustCollectibleData {
        pub let id: UInt64
        pub let mint: UInt64
        pub let series: UInt64
        pub let name: String
        pub let svg: String?
        pub let combination: String
        pub let creatorAddress: Address
        pub let layers: {UInt32: UInt64?}
        pub let bio: {String: String}
        pub let metadata: {String: String}
        init(
            id: UInt64,
            mint: UInt64,
            series: UInt64,
            name: String,
            svg: String?,
            combination: String,
            creatorAddress: Address,
            layers: {UInt32: UInt64?},
            bio: {String: String},
            metadata: {String: String}
            ) {
            self.id = id
            self.mint = mint
            self.series = series
            self.name = name
            self.svg = svg
            self.combination = combination
            self.creatorAddress = creatorAddress
            self.layers = layers
            self.bio = bio
            self.metadata = metadata
        }
    }


    // This function will look for a specific Flovatar on a user account and return a FlovatarData if found
    pub fun getCollectible(address: Address, collectibleId: UInt64) : FlovatarDustCollectibleData? {

        let account = getAccount(address)

        if let collectibleCollection = account.getCapability(self.CollectionPublicPath).borrow<&FlovatarDustCollectible.Collection{FlovatarDustCollectible.CollectionPublic}>()  {
            if let collectible = collectibleCollection.borrowDustCollectible(id: collectibleId) {
                return FlovatarDustCollectibleData(
                    id: collectibleId,
                    mint: collectible!.mint,
                    series: collectible!.series,
                    name: collectible!.getName(),
                    svg: collectible!.getSvg(),
                    combination: collectible!.combination,
                    creatorAddress: collectible!.creatorAddress,
                    layers: collectible!.getLayers(),
                    bio: collectible!.getBio(),
                    metadata: collectible!.getMetadata()
                )
            }
        }
        return nil
    }

    // This function will return all Flovatars on a user account and return an array of FlovatarData
    pub fun getCollectibles(address: Address) : [FlovatarDustCollectibleData] {

        var dustCollectibleData: [FlovatarDustCollectibleData] = []
        let account = getAccount(address)

        if let collectibleCollection = account.getCapability(self.CollectionPublicPath).borrow<&FlovatarDustCollectible.Collection{FlovatarDustCollectible.CollectionPublic}>()  {
            for id in collectibleCollection.getIDs() {
                if let collectible = collectibleCollection.borrowDustCollectible(id: id) {
                    dustCollectibleData.append(FlovatarDustCollectibleData(
                        id: id,
                        mint: collectible!.mint,
                        series: collectible!.series,
                        name: collectible!.getName(),
                        svg: nil,
                        combination: collectible!.combination,
                        creatorAddress: collectible!.creatorAddress,
                        layers: collectible!.getLayers(),
                        bio: collectible!.getBio(),
                        metadata: collectible!.getMetadata()
                    ))
                }
            }
        }
        return dustCollectibleData
    }


    // This returns all the previously minted combinations, so that duplicates won't be allowed
    pub fun getMintedCombinations() : [String] {
        return FlovatarDustCollectible.mintedCombinations.keys
    }
    // This returns all the previously minted names, so that duplicates won't be allowed
    pub fun getMintedNames() : [String] {
        return FlovatarDustCollectible.mintedNames.keys
    }

    // This function will add a minted combination to the array
    access(account) fun addMintedCombination(combination: String) {
        FlovatarDustCollectible.mintedCombinations.insert(key: combination, true)
    }
    // This function will add a new name to the array
    access(account) fun addMintedName(name: String) {
        FlovatarDustCollectible.mintedNames.insert(key: name, true)
    }

    pub fun getCoreLayers(series: UInt64, layers: {UInt32: UInt64?}): {UInt32: UInt64}{
        let coreLayers: {UInt32: UInt64} = {}
        for k in layers.keys {
            if(!FlovatarDustCollectibleTemplate.isCollectibleLayerAccessory(layer: k, series: series)){
                let templateId = layers[k]!
                let template = FlovatarDustCollectibleTemplate.getCollectibleTemplate(id: templateId!)!
                if(template.series != series){
                    panic("Template belonging to the wrong Dust Collectible Series")
                }
                if(template.layer != k){
                    panic("Template belonging to the wrong Layer")
                }
                coreLayers[k] = templateId!
            }
        }

        return coreLayers
    }

    // This helper function will generate a string from a list of components,
    // to be used as a sort of barcode to keep the inventory of the minted
    // Flovatars and to avoid duplicates
    pub fun getCombinationString(
        series: UInt64,
        layers: {UInt32: UInt64}
    ) : String {
        var combination = "S".concat(series.toString())

        for k in layers.keys {
            if(layers[k] != nil){
                let layerId = layers[k]!
                combination = combination.concat("-L").concat(k.toString()).concat("_").concat(layerId.toString())
            }
        }

        return combination
    }

    // This function will get a list of component IDs and will check if the
    // generated string is unique or if someone already used it before.
    pub fun checkCombinationAvailable(
        series: UInt64,
        layers: {UInt32: UInt64}
    ) : Bool {
        let combinationString = FlovatarDustCollectible.getCombinationString(
            series: series,
            layers: layers
        )
        return ! FlovatarDustCollectible.mintedCombinations.containsKey(combinationString)
    }

    // This will check if a specific Name has already been taken
    // and assigned to some Flovatar
    pub fun checkNameAvailable(name: String) : Bool {
        return name.length > 2 && name.length < 20 && ! FlovatarDustCollectible.mintedNames.containsKey(name)
    }


    // This is a public function that anyone can call to generate a new Flovatar Dust Collectible
    // A list of components resources needs to be passed to executed.
    // It will check first for uniqueness of the combination + name and will then
    // generate the Flovatar and burn all the passed components.
    // The Spark NFT will entitle to use any common basic component (body, hair, etc.)
    // In order to use special rare components a boost of the same rarity will be needed
    // for each component used
    pub fun createDustCollectible(
        series: UInt64,
        layers: [UInt64?],
        address: Address,
        vault: @FungibleToken.Vault
    ) : @FlovatarDustCollectible.NFT {
        pre {
            vault.isInstance(Type<@FlovatarDustToken.Vault>()) : "Vault not of the right Token Type"
        }

        let seriesData = FlovatarDustCollectibleTemplate.getCollectibleSeries(id: series)
        if(seriesData == nil){
            panic("Dust Collectible Series not found!")
        }
        if(seriesData!.layers.length != layers.length){
            panic("The amount of layers is not matching!")
        }

        let templates: [FlovatarDustCollectibleTemplate.CollectibleTemplateData] = []
        var totalPrice: UFix64 = 0.0
        let coreLayers: {UInt32: UInt64} = {}
        let fullLayers: {UInt32: UInt64?} = {}

        var i: UInt32 = UInt32(layers.length)
        while(i <  UInt32(layers.length)){
            if(!FlovatarDustCollectibleTemplate.isCollectibleLayerAccessory(layer: i, series: series)){
                if(layers[i] == nil){
                    panic("Core Layer missing")
                }
                let template = FlovatarDustCollectibleTemplate.getCollectibleTemplate(id: layers[i]!)!
                if(template.series != series){
                    panic("Template belonging to the wrong Dust Collectible Series")
                }
                if(template.layer != i){
                    panic("Template belonging to the wrong Layer")
                }
                coreLayers[i] = template.id
                fullLayers[i] = template.id
                templates.append(template)
                totalPrice = totalPrice + FlovatarDustCollectibleTemplate.getTemplateCurrentPrice(id: template.id)!

                FlovatarDustCollectibleTemplate.increaseTotalMintedComponents(id: template.id)
                FlovatarDustCollectibleTemplate.increaseTemplatesCurrentPrice(id: template.id)
                FlovatarDustCollectibleTemplate.setLastComponentMintedAt(id: template.id, value: getCurrentBlock().timestamp)
            } else {
                fullLayers[i] = nil
            }

            i = i + UInt32(1)
        }

        if(totalPrice > vault.balance){
            panic("Not enough tokens provided")
        }


        // Generates the combination string to check for uniqueness.
        // This is like a barcode that defines exactly which components were used
        // to create the Flovatar
        let combinationString = FlovatarDustCollectible.getCombinationString(
            series: series,
            layers: coreLayers
            )

        // Makes sure that the combination is available and not taken already
        if(FlovatarDustCollectible.mintedCombinations.containsKey(combinationString) == true) {
            panic("This combination has already been taken")
        }

        let royalties: [Royalty] = []

        let creatorAccount = getAccount(address)
        royalties.append(Royalty(
            wallet: creatorAccount.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver),
            cut: FlovatarDustCollectible.getRoyaltyCut(),
            type: RoyaltyType.percentage
        ))

        royalties.append(Royalty(
            wallet: self.account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver),
            cut: FlovatarDustCollectible.getMarketplaceCut(),
            type: RoyaltyType.percentage
        ))

        // Mint the new Flovatar NFT by passing the metadata to it
        var newNFT <- create NFT(series: series, layers: fullLayers, creatorAddress: address, royalties: Royalties(royalty: royalties))

        // Adds the combination to the arrays to remember it
        FlovatarDustCollectible.addMintedCombination(combination: combinationString)


        // Emits the Created event to notify about its existence
        emit Created(id: newNFT.id, mint: newNFT.mint, series: newNFT.series)

        //TODO: Increase counter and price for template!!!

        destroy vault

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
        pub fun createCollectibleTemplate(
                        name: String,
                        description: String,
                        series: UInt64,
                        layer: UInt32,
                        metadata: {String: String},
                        rarity: String,
                        basePrice: UFix64,
                        svg: String,
                        maxMintableComponents: UInt64
                    ) : @FlovatarDustCollectibleTemplate.CollectibleTemplate {
            return <- FlovatarDustCollectibleTemplate.createCollectibleTemplate(
                name: name,
                description: description,
                series: series,
                layer: layer,
                metadata: metadata,
                rarity: rarity,
                basePrice: basePrice,
                svg: svg,
                maxMintableComponents: maxMintableComponents
            )
        }

        //This will mint a new Component based from a selected Template
        pub fun createCollectible(templateId: UInt64) : @FlovatarDustCollectibleAccessory.NFT {
            return <- FlovatarDustCollectibleAccessory.createCollectibleAccessory(templateId: templateId)
        }
        //This will mint Components in batch and return a Collection instead of the single NFT
        pub fun batchCreateCollectibles(templateId: UInt64, quantity: UInt64) : @FlovatarDustCollectibleAccessory.Collection {
            return <- FlovatarDustCollectibleAccessory.batchCreateCollectibleAccessory(templateId: templateId, quantity: quantity)
        }


        // With this function you can generate a new Admin resource
        // and pass it to another user if needed
        pub fun createNewAdmin(): @Admin {
            return <-create Admin()
        }

        // Helper functions to update the Royalty cut
        pub fun setRoyaltyCut(value: UFix64) {
            FlovatarDustCollectible.setRoyaltyCut(value: value)
        }

        // Helper functions to update the Marketplace cut
        pub fun setMarketplaceCut(value: UFix64) {
            FlovatarDustCollectible.setMarketplaceCut(value: value)
        }
    }





	init() {
        self.CollectionPublicPath = /public/FlovatarDustCollectibleCollection
        self.CollectionStoragePath = /storage/FlovatarDustCollectibleCollection
        self.AdminStoragePath = /storage/FlovatarDustCollectibleAdmin

        // Initialize the total supply
        self.totalSupply = UInt64(0)
        self.mintedCombinations = {}
        self.mintedNames = {}

        // Set the default Royalty and Marketplace cuts
        self.royaltyCut = 0.01
        self.marketplaceCut = 0.05

        self.account.save<@NonFungibleToken.Collection>(<- FlovatarDustCollectible.createEmptyCollection(), to: FlovatarDustCollectible.CollectionStoragePath)
        self.account.link<&{FlovatarDustCollectible.CollectionPublic}>(FlovatarDustCollectible.CollectionPublicPath, target: FlovatarDustCollectible.CollectionStoragePath)

        // Put the Admin resource in storage
        self.account.save<@Admin>(<- create Admin(), to: self.AdminStoragePath)

        emit ContractInitialized()
	}
}
