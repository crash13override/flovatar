//import FungibleToken from 0xf233dcee88fe0abe
//import NonFungibleToken from 0x1d7e57aa55817448
//import FlowToken from 0x1654653399040a61
//import FlovatarDustCollectibleTemplate from 0x921ea449dffec68a
//import MetadataViews from 0x1d7e57aa55817448
import FungibleToken from "./FungibleToken.cdc"
import NonFungibleToken from "./NonFungibleToken.cdc"
import FlowToken from "./FlowToken.cdc"
import FlovatarDustCollectibleTemplate from "./FlovatarDustCollectibleTemplate.cdc"
import MetadataViews from "./MetadataViews.cdc"

/*

 This contract defines the Flovatar Dust Collectible Accessory NFT and the Collection to manage them.
 Components are linked to a specific Template that will ultimately contain the SVG and all the other metadata

 */

pub contract FlovatarDustCollectibleAccessory: NonFungibleToken {

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath

    // Counter for all the Components ever minted
    pub var totalSupply: UInt64

    // Standard events that will be emitted
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Created(id: UInt64, templateId: UInt64, mint: UInt64)
    pub event Destroyed(id: UInt64, templateId: UInt64)

    // The public interface provides all the basic informations about
    // the Component and also the Template ID associated with it.
    pub resource interface Public {
        pub let id: UInt64
        pub let templateId: UInt64
        pub let mint: UInt64
        pub fun getTemplate(): FlovatarDustCollectibleTemplate.CollectibleTemplateData
        pub fun getSvg(): String
        pub fun getSeries(): UInt64
        pub fun getRarity(): String
        pub fun getMetadata(): {String: String}
        pub fun getLayer(): UInt32
        pub fun getBasePrice(): UFix64
        pub fun getCurrentPrice(): UFix64
        pub fun getTotalMinted(): UInt64

        //these three are added because I think they will be in the standard. At least Dieter thinks it will be needed
        pub let name: String
        pub let description: String
        pub let schema: String?
    }


    // The NFT resource that implements the Public interface as well
    pub resource NFT: NonFungibleToken.INFT, Public, MetadataViews.Resolver {
        pub let id: UInt64
        pub let templateId: UInt64
        pub let mint: UInt64
        pub let name: String
        pub let description: String
        pub let schema: String?

        // Initiates the NFT from a Template ID.
        init(templateId: UInt64) {

            FlovatarDustCollectibleAccessory.totalSupply = FlovatarDustCollectibleAccessory.totalSupply + UInt64(1)

            let collectibleTemplate = FlovatarDustCollectibleTemplate.getCollectibleTemplate(id: templateId)!

            self.id = FlovatarDustCollectibleAccessory.totalSupply
            self.templateId = templateId
            self.mint = FlovatarDustCollectibleTemplate.getTotalMintedComponents(id: templateId)! + UInt64(1)
            self.name = collectibleTemplate.name
            self.description = collectibleTemplate.description
            self.schema = nil

            // Increments the counter and stores the timestamp
            FlovatarDustCollectibleTemplate.setTotalMintedComponents(id: templateId, value: self.mint)
            FlovatarDustCollectibleTemplate.setLastComponentMintedAt(id: templateId, value: getCurrentBlock().timestamp)
            FlovatarDustCollectibleTemplate.increaseTemplatesCurrentPrice(id: templateId)
        }

        pub fun getID(): UInt64 {
            return self.id
        }

        // Returns the Template associated to the current Component
        pub fun getTemplate(): FlovatarDustCollectibleTemplate.CollectibleTemplateData {
            return FlovatarDustCollectibleTemplate.getCollectibleTemplate(id: self.templateId)!
        }

        // Gets the SVG from the parent Template
        pub fun getSvg(): String {
            return self.getTemplate().svg!
        }

        // Gets the series number from the parent Template
        pub fun getSeries(): UInt64 {
            return self.getTemplate().series
        }

        // Gets the rarity from the parent Template
        pub fun getRarity(): String {
            return self.getTemplate().rarity
        }


        pub fun getMetadata(): {String: String} {
            return self.getTemplate().metadata
        }

        pub fun getLayer(): UInt32 {
          return self.getTemplate().layer
        }

        pub fun getBasePrice(): UFix64 {
            return self.getTemplate().basePrice
        }

        pub fun getCurrentPrice(): UFix64 {
            return self.getTemplate().currentPrice
        }

        pub fun getTotalMinted(): UInt64 {
            return self.getTemplate().totalMintedComponents
        }

        // Emit a Destroyed event when it will be burned to create a Flovatar
        // This will help to keep track of how many Components are still
        // available on the market.
        destroy() {
            emit Destroyed(id: self.id, templateId: self.templateId)
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
                return MetadataViews.ExternalURL("https://flovatar.com")
            }

            if type == Type<MetadataViews.Royalties>() {
                let royalties : [MetadataViews.Royalty] = []
                royalties.append(MetadataViews.Royalty(receiver: FlovatarDustCollectibleAccessory.account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver), cut: 0.05, description: "Flovatar Royalty"))
                return MetadataViews.Royalties(cutInfos: royalties)
            }

            if type == Type<MetadataViews.Serial>() {
                return MetadataViews.Serial(self.id)
            }

            if type ==  Type<MetadataViews.Editions>() {
                let componentTemplate: FlovatarDustCollectibleTemplate.CollectibleTemplateData = self.getTemplate()

                let editionInfo = MetadataViews.Edition(name: "Flovatar Dust Collectible Accessory", number: self.mint, max: componentTemplate.maxMintableComponents)
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
                    name: "Flovatar Dust Collectible Accessory",
                    description: "The Flovatar Stardust Collectibles Accessories allow you customize and make your beloved Stardust Collectible even more unique and exclusive.",
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
                storagePath: FlovatarDustCollectibleAccessory.CollectionStoragePath,
                publicPath: FlovatarDustCollectibleAccessory.CollectionPublicPath,
                providerPath: /private/FlovatarComponentCollection,
                publicCollection: Type<&FlovatarDustCollectibleAccessory.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, FlovatarDustCollectibleAccessory.CollectionPublic}>(),
                publicLinkedType: Type<&FlovatarDustCollectibleAccessory.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, FlovatarDustCollectibleAccessory.CollectionPublic}>(),
                providerLinkedType: Type<&FlovatarDustCollectibleAccessory.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, FlovatarDustCollectibleAccessory.CollectionPublic}>(),
                createEmptyCollectionFunction: fun(): @NonFungibleToken.Collection {return <- FlovatarDustCollectibleAccessory.createEmptyCollection()}
                )
            }

            if type == Type<MetadataViews.Display>() {
                return MetadataViews.Display(
                    name: self.name,
                    description: self.description,
                    thumbnail: MetadataViews.HTTPFile(
                        url: "https://flovatar.com/api/image/template/".concat(self.templateId.toString())
                    )
                )
            }

            if type == Type<MetadataViews.Traits>() {
                let traits: [MetadataViews.Trait] = []

                let template = self.getTemplate()
                let trait = MetadataViews.Trait(name: "Name", value: template.name, displayType:"String", rarity: MetadataViews.Rarity(score:nil, max:nil, description: template.rarity))
                traits.append(trait)

                return MetadataViews.Traits(traits)
            }

            if type == Type<MetadataViews.Rarity>() {
                let template = self.getTemplate()
                return MetadataViews.Rarity(score: nil, max: nil, description: template.rarity)
            }

            return nil
        }
    }

    // Standard NFT collectionPublic interface that can also borrowCollectibleAccessory as the correct type
    pub resource interface CollectionPublic {

        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowCollectibleAccessory(id: UInt64): &FlovatarDustCollectibleAccessory.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Component reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Main Collection to manage all the Components NFT
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
            let token <- token as! @FlovatarDustCollectibleAccessory.NFT

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

        // borrowCollectibleAccessory returns a borrowed reference to a FlovatarComponent
        // so that the caller can read data and call methods from it.
        pub fun borrowCollectibleAccessory(id: UInt64): &FlovatarDustCollectibleAccessory.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &FlovatarDustCollectibleAccessory.NFT
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
            let componentNFT = nft as! &FlovatarDustCollectibleAccessory.NFT
            return componentNFT as &AnyResource{MetadataViews.Resolver}
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    // This struct is used to send a data representation of the Components
    // when retrieved using the contract helper methods outside the collection.
    pub struct CollectibleAccessoryData {
        pub let id: UInt64
        pub let templateId: UInt64
        pub let mint: UInt64
        pub let name: String
        pub let description: String
        pub let rarity: String
        pub let metadata: {String: String}
        pub let layer: UInt32
        pub let basePrice: UFix64
        pub let currentPrice: UFix64
        pub let totalMinted: UInt64

        init(id: UInt64, templateId: UInt64, mint: UInt64) {
            self.id = id
            self.templateId = templateId
            self.mint = mint
            let collectibleTemplate = FlovatarDustCollectibleTemplate.getCollectibleTemplate(id: templateId)!
            self.name = collectibleTemplate.name
            self.description = collectibleTemplate.description
            self.rarity = collectibleTemplate.rarity
            self.metadata = collectibleTemplate.metadata
            self.layer = collectibleTemplate.layer
            self.basePrice = collectibleTemplate.basePrice
            self.currentPrice = collectibleTemplate.currentPrice
            self.totalMinted = collectibleTemplate.totalMintedComponents
        }
    }

    // Get the SVG of a specific Component from an account and the ID
    pub fun getSvgForComponent(address: Address, componentId: UInt64) : String? {
        let account = getAccount(address)
        if let componentCollection = account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarDustCollectibleAccessory.CollectionPublic}>()  {
            return componentCollection.borrowCollectibleAccessory(id: componentId)!.getSvg()
        }
        return nil
    }

    // Get a specific Component from an account and the ID as CollectibleAccessoryData
    pub fun getAccessory(address: Address, componentId: UInt64) : CollectibleAccessoryData? {
        let account = getAccount(address)
        if let componentCollection = account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarDustCollectibleAccessory.CollectionPublic}>()  {
            if let component = componentCollection.borrowCollectibleAccessory(id: componentId) {
                return CollectibleAccessoryData(
                    id: componentId,
                    templateId: component!.templateId,
                    mint: component!.mint
                )
            }
        }
        return nil
    }

    // Get an array of all the components in a specific account as CollectibleAccessoryData
    pub fun getAccessories(address: Address) : [CollectibleAccessoryData] {

        var componentData: [CollectibleAccessoryData] = []
        let account = getAccount(address)

        if let componentCollection = account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarDustCollectibleAccessory.CollectionPublic}>()  {
            for id in componentCollection.getIDs() {
                var component = componentCollection.borrowCollectibleAccessory(id: id)
                componentData.append(CollectibleAccessoryData(
                    id: id,
                    templateId: component!.templateId,
                    mint: component!.mint
                    ))
            }
        }
        return componentData
    }

    // This method can only be called from another contract in the same account.
    // In FlovatarComponent case it is called from the Flovatar Admin that is used
    // to administer the components.
    // The only parameter is the parent Template ID and it will return a Component NFT resource
    access(account) fun createCollectibleAccessory(templateId: UInt64) : @FlovatarDustCollectibleAccessory.NFT {

        let collectibleTemplate: FlovatarDustCollectibleTemplate.CollectibleTemplateData = FlovatarDustCollectibleTemplate.getCollectibleTemplate(id: templateId)!
        let totalMintedComponents: UInt64 = FlovatarDustCollectibleTemplate.getTotalMintedComponents(id: templateId)!

        // Makes sure that the original minting limit set for each Template has not been reached
        if(totalMintedComponents >= collectibleTemplate.maxMintableComponents) {
            panic("Reached maximum mintable components for this type")
        }

        var newNFT <- create NFT(templateId: templateId)
        emit Created(id: newNFT.id, templateId: templateId, mint: newNFT.mint)

        return <- newNFT
    }

    // This function will batch create multiple Components and pass them back as a Collection
    access(account) fun batchCreateCollectibleAccessory(templateId: UInt64, quantity: UInt64): @Collection {
        let newCollection <- create Collection()

        var i: UInt64 = 0
        while i < quantity {
            newCollection.deposit(token: <-self.createCollectibleAccessory(templateId: templateId))
            i = i + UInt64(1)
        }

        return <-newCollection
    }

	init() {
        self.CollectionPublicPath = /public/FlovatarDustCollectibleAccessoryCollection
        self.CollectionStoragePath = /storage/FlovatarDustCollectibleAccessoryCollection

        // Initialize the total supply
        self.totalSupply = UInt64(0)

        self.account.save<@NonFungibleToken.Collection>(<- FlovatarDustCollectibleAccessory.createEmptyCollection(), to: FlovatarDustCollectibleAccessory.CollectionStoragePath)
        self.account.link<&{FlovatarDustCollectibleAccessory.CollectionPublic}>(FlovatarDustCollectibleAccessory.CollectionPublicPath, target: FlovatarDustCollectibleAccessory.CollectionStoragePath)

        emit ContractInitialized()
	}
}

