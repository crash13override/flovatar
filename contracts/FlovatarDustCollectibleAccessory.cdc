import "FungibleToken"
import "NonFungibleToken"
import "FlowToken"
import "FlovatarDustCollectibleTemplate"
import "MetadataViews"
import "FlovatarDustToken"
import "ViewResolver"

/*

 This contract defines the Flovatar Dust Collectible Accessory NFT and the Collection to manage them.
 Components are linked to a specific Template that will ultimately contain the SVG and all the other metadata

 */

access(all)
contract FlovatarDustCollectibleAccessory: NonFungibleToken{ 
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	// Counter for all the Components ever minted
	access(all)
	var totalSupply: UInt64
	
	// Standard events that will be emitted
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Created(id: UInt64, templateId: UInt64, mint: UInt64)
	
	access(all)
	event Destroyed(id: UInt64, templateId: UInt64)

	
	// The public interface provides all the basic informations about
	// the Component and also the Template ID associated with it.
	access(all)
	resource interface Public{ 
		access(all)
		let id: UInt64
		
		access(all)
		let templateId: UInt64
		
		access(all)
		let mint: UInt64
		
		access(all)
		fun getTemplate(): FlovatarDustCollectibleTemplate.CollectibleTemplateData
		
		access(all)
		fun getSvg(): String
		
		access(all)
		fun getSeries(): UInt64
		
		access(all)
		fun getRarity(): String
		
		access(all)
		fun getMetadata():{ String: String}
		
		access(all)
		fun getLayer(): UInt32
		
		access(all)
		fun getBasePrice(): UFix64
		
		access(all)
		fun getCurrentPrice(): UFix64
		
		access(all)
		fun getTotalMinted(): UInt64
		
		//these three are added because I think they will be in the standard. At least Dieter thinks it will be needed
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let schema: String?
	}
	
	// The NFT resource that implements the Public interface as well
	access(all)
	resource NFT: NonFungibleToken.NFT, Public { 
		access(all)
		let id: UInt64
		
		access(all)
		let templateId: UInt64
		
		access(all)
		let mint: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let schema: String?
		
		// Initiates the NFT from a Template ID.
		init(templateId: UInt64){ 
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
		
		access(all)
		fun getID(): UInt64{ 
			return self.id
		}
		
		// Returns the Template associated to the current Component
		access(all)
		fun getTemplate(): FlovatarDustCollectibleTemplate.CollectibleTemplateData{ 
			return FlovatarDustCollectibleTemplate.getCollectibleTemplate(id: self.templateId)!
		}
		
		// Gets the SVG from the parent Template
		access(all)
		fun getSvg(): String{ 
			return self.getTemplate().svg!
		}
		
		// Gets the series number from the parent Template
		access(all)
		fun getSeries(): UInt64{ 
			return self.getTemplate().series
		}
		
		// Gets the rarity from the parent Template
		access(all)
		fun getRarity(): String{ 
			return self.getTemplate().rarity
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.getTemplate().metadata
		}
		
		access(all)
		fun getLayer(): UInt32{ 
			return self.getTemplate().layer
		}
		
		access(all)
		fun getBasePrice(): UFix64{ 
			return self.getTemplate().basePrice
		}
		
		access(all)
		fun getCurrentPrice(): UFix64{ 
			return self.getTemplate().currentPrice
		}
		
		access(all)
		fun getTotalMinted(): UInt64{ 
			return self.getTemplate().totalMintedComponents
		}
		
		// Emit a Destroyed event when it will be burned to create a Flovatar
		// This will help to keep track of how many Components are still
		// available on the market.
		access(all)
		view fun getViews(): [Type]{ 
			return [
			Type<MetadataViews.NFTCollectionData>(),
			Type<MetadataViews.NFTCollectionDisplay>(),
			Type<MetadataViews.Display>(),
			Type<MetadataViews.Royalties>(),
			Type<MetadataViews.Edition>(),
			Type<MetadataViews.ExternalURL>(),
			Type<MetadataViews.Serial>(),
			Type<MetadataViews.Traits>(),
			Type<MetadataViews.EVMBridgedMetadata>()
			]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			if view == Type<MetadataViews.ExternalURL>(){ 
				return MetadataViews.ExternalURL("https://flovatar.com")
			}
			if view == Type<MetadataViews.Royalties>(){ 
				let royalties: [MetadataViews.Royalty] = []
				royalties.append(MetadataViews.Royalty(receiver: FlovatarDustCollectibleAccessory.account.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver), cut: 0.05, description: "Flovatar Royalty"))
				return MetadataViews.Royalties(royalties)
			}
			if view == Type<MetadataViews.Serial>(){ 
				return MetadataViews.Serial(self.id)
			}
			if view == Type<MetadataViews.Editions>(){ 
				let componentTemplate: FlovatarDustCollectibleTemplate.CollectibleTemplateData = self.getTemplate()
				let editionInfo = MetadataViews.Edition(name: "Flovatar Dust Collectible Accessory", number: self.mint, max: componentTemplate.maxMintableComponents)
				let editionList: [MetadataViews.Edition] = [editionInfo]
				return MetadataViews.Editions(editionList)
			}
			if view == Type<MetadataViews.NFTCollectionDisplay>(){ 
				let mediaSquare = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://images.flovatar.com/logo.svg"), mediaType: "image/svg+xml")
				let mediaBanner = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://images.flovatar.com/logo-horizontal.svg"), mediaType: "image/svg+xml")
				return MetadataViews.NFTCollectionDisplay(name: "Flovatar Dust Collectible Accessory", description: "The Flovatar Stardust Collectibles Accessories allow you customize and make your beloved Stardust Collectible even more unique and exclusive.", externalURL: MetadataViews.ExternalURL("https://flovatar.com"), squareImage: mediaSquare, bannerImage: mediaBanner, socials:{ "discord": MetadataViews.ExternalURL("https://discord.gg/flovatar"), "twitter": MetadataViews.ExternalURL("https://twitter.com/flovatar"), "instagram": MetadataViews.ExternalURL("https://instagram.com/flovatar_nft"), "tiktok": MetadataViews.ExternalURL("https://www.tiktok.com/@flovatar")})
			}
			if view == Type<MetadataViews.Display>(){ 
				return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: "https://flovatar.com/api/image/template/".concat(self.templateId.toString())))
			}
			if view == Type<MetadataViews.Traits>(){ 
				let traits: [MetadataViews.Trait] = []
				let template = self.getTemplate()
				let trait = MetadataViews.Trait(name: "Name", value: template.name, displayType: "String", rarity: MetadataViews.Rarity(score: nil, max: nil, description: template.rarity))
				traits.append(trait)
				return MetadataViews.Traits(traits)
			}
			if view == Type<MetadataViews.Rarity>(){ 
				let template = self.getTemplate()
				return MetadataViews.Rarity(score: nil, max: nil, description: template.rarity)
			}
			if view == Type<MetadataViews.NFTCollectionData>(){ 
				return MetadataViews.NFTCollectionData(storagePath: FlovatarDustCollectibleAccessory.CollectionStoragePath, publicPath: FlovatarDustCollectibleAccessory.CollectionPublicPath, publicCollection: Type<&FlovatarDustCollectibleAccessory.Collection>(), publicLinkedType: Type<&FlovatarDustCollectibleAccessory.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
						return <-FlovatarDustCollectibleAccessory.createEmptyCollection(nftType: Type<@FlovatarDustCollectibleAccessory.Collection>())
					})
			}
			if view == Type<MetadataViews.EVMBridgedMetadata>(){ 
				let contractLevel = FlovatarDustCollectibleAccessory.resolveContractView(
						resourceType: nil,
						viewType: Type<MetadataViews.EVMBridgedMetadata>()
					) as! MetadataViews.EVMBridgedMetadata?
					?? panic("Could not resolve contract-level EVMBridgedMetadata")
				
				return MetadataViews.EVMBridgedMetadata(
					name: contractLevel.name,
					symbol: contractLevel.symbol,
					uri: MetadataViews.URI(
						baseURI: "https://flovatar.com/flovatars/json/",
						value: self.id.toString()
					)
				)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-FlovatarDustCollectibleAccessory.createEmptyCollection(nftType: Type<@FlovatarDustCollectibleAccessory.NFT>())
		}
	}
	
	// Standard NFT collectionPublic interface that can also borrowCollectibleAccessory as the correct type
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowCollectibleAccessory(id: UInt64): &FlovatarDustCollectibleAccessory.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Component reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Main Collection to manage all the Components NFT
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Collection { 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(all) view fun getLength(): Int {
			return self.ownedNFTs.length
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @FlovatarDustCollectibleAccessory.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)
		}
		
		// borrowCollectibleAccessory returns a borrowed reference to a FlovatarComponent
		// so that the caller can read data and call methods from it.
		access(all)
		fun borrowCollectibleAccessory(id: UInt64): &FlovatarDustCollectibleAccessory.NFT?{ 
			if self.ownedNFTs[id] != nil {
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)
				let collectibleNFT = ref as! &FlovatarDustCollectibleAccessory.NFT
				return collectibleNFT
			} else {
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			if let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}? {
				return nft as &{ViewResolver.Resolver}
			}
			return nil
		}
		
		/// getSupportedNFTTypes returns a list of NFT types that this receiver accepts
		access(all) 
		view fun getSupportedNFTTypes(): {Type: Bool} {
			let supportedTypes: {Type: Bool} = {}
			supportedTypes[Type<@FlovatarDustCollectibleAccessory.NFT>()] = true
			return supportedTypes
		}

		/// Returns whether or not the given type is accepted by the collection
		/// A collection that can accept any type should just return true by default
		access(all) 
		view fun isSupportedNFTType(type: Type): Bool {
			return type == Type<@FlovatarDustCollectibleAccessory.NFT>()
		}

		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-FlovatarDustCollectibleAccessory.createEmptyCollection(nftType: Type<@FlovatarDustCollectibleAccessory.NFT>())
		}
	}
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}


	access(all) 
	view fun getContractViews(resourceType: Type?): [Type] {
		return [
			Type<MetadataViews.NFTCollectionData>(),
			Type<MetadataViews.NFTCollectionDisplay>(),
			Type<MetadataViews.EVMBridgedMetadata>()
		]
	}


	access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
		switch viewType {
			case Type<MetadataViews.NFTCollectionData>():
				let collectionData = MetadataViews.NFTCollectionData(
					storagePath: self.CollectionStoragePath,
					publicPath: self.CollectionPublicPath,
					publicCollection: Type<&FlovatarDustCollectibleAccessory.Collection>(),
					publicLinkedType: Type<&FlovatarDustCollectibleAccessory.Collection>(),
					createEmptyCollectionFunction: (fun(): @{NonFungibleToken.Collection} {
						return <-FlovatarDustCollectibleAccessory.createEmptyCollection(nftType: Type<@FlovatarDustCollectibleAccessory.NFT>())
					})
				)
				return collectionData
			case Type<MetadataViews.NFTCollectionDisplay>():
				let media = MetadataViews.Media(
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
					name: "Flovatar Dust Collectible Accessory Collection",
					description: "Flovatar is pioneering a new way to unleash community creativity in Web3 by allowing users to be co-creators of their prized NFTs, instead of just being passive collectors.",
					externalURL: MetadataViews.ExternalURL("https://flovatar.com"),
					squareImage: media,
					bannerImage: mediaBanner,
					socials: {
						"twitter": MetadataViews.ExternalURL("https://x.com/flovatar"),
						"discord": MetadataViews.ExternalURL("https://discord.gg/flovatar"),
						"instagram": MetadataViews.ExternalURL("https://instagram.com/flovatar_nft"),
						"tiktok": MetadataViews.ExternalURL("https://www.tiktok.com/@flovatar")
					}
				)
			case Type<MetadataViews.EVMBridgedMetadata>():
				// Implementing this view gives the project control over how the bridged NFT is represented as an ERC721
				// when bridged to EVM on Flow via the public infrastructure bridge.

				// Compose the contract-level URI. In this case, the contract metadata is located on some HTTP host,
				// but it could be IPFS, S3, a data URL containing the JSON directly, etc.
				return MetadataViews.EVMBridgedMetadata(
					name: "Flovatar Dust Collectible Accessory",
					symbol: "XMPL",
					uri: MetadataViews.URI(
						baseURI: nil, // setting baseURI as nil sets the given value as the uri field value
						value: "https://flovatar.com"
					)
				)
		}
		return nil
	}

	
	// This struct is used to send a data representation of the Components
	// when retrieved using the contract helper methods outside the collection.
	access(all)
	struct CollectibleAccessoryData{ 
		access(all)
		let id: UInt64
		
		access(all)
		let templateId: UInt64
		
		access(all)
		let mint: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let rarity: String
		
		access(all)
		let metadata:{ String: String}
		
		access(all)
		let layer: UInt32
		
		access(all)
		let basePrice: UFix64
		
		access(all)
		let currentPrice: UFix64
		
		access(all)
		let totalMinted: UInt64
		
		init(id: UInt64, templateId: UInt64, mint: UInt64){ 
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
	access(all)
	fun getSvgForComponent(address: Address, componentId: UInt64): String?{ 
		let account = getAccount(address)

		if let componentCollection = account.capabilities.borrow<&FlovatarDustCollectibleAccessory.Collection>(FlovatarDustCollectibleAccessory.CollectionPublicPath){ 
			return (componentCollection.borrowCollectibleAccessory(id: componentId)!).getSvg()
		}
		
		return nil
	}
	
	// Get a specific Component from an account and the ID as CollectibleAccessoryData
	access(all)
	fun getAccessory(address: Address, componentId: UInt64): CollectibleAccessoryData?{ 
		let account = getAccount(address)
		if let componentCollection = account.capabilities.borrow<&FlovatarDustCollectibleAccessory.Collection>(FlovatarDustCollectibleAccessory.CollectionPublicPath){ 
			if let component = componentCollection.borrowCollectibleAccessory(id: componentId){ 
				return CollectibleAccessoryData(id: componentId, templateId: (component!).templateId, mint: (component!).mint)
			}
		}
		return nil
	}
	
	// Get an array of all the components in a specific account as CollectibleAccessoryData
	access(all)
	fun getAccessories(address: Address): [CollectibleAccessoryData]{ 
		var componentData: [CollectibleAccessoryData] = []
		let account = getAccount(address)
		if let componentCollection = account.capabilities.borrow<&FlovatarDustCollectibleAccessory.Collection>(FlovatarDustCollectibleAccessory.CollectionPublicPath){ 
			for id in componentCollection.getIDs(){ 
				var component = componentCollection.borrowCollectibleAccessory(id: id)
				componentData.append(CollectibleAccessoryData(id: id, templateId: (component!).templateId, mint: (component!).mint))
			}
		}
		return componentData
	}
	
	//This method is used to mint a new Dust Accessory by paying the necessary amount of DUST
	// The only parameters are the parent Template ID and the vault with the DUST token. It will return a Component NFT resource
	access(all)
	fun createCollectibleAccessory(templateId: UInt64, vault: @{FungibleToken.Vault}): @FlovatarDustCollectibleAccessory.NFT{ 
		pre{ 
			vault.isInstance(Type<@FlovatarDustToken.Vault>()):
				"Vault not of the right Token Type"
		}
		let collectibleTemplate: FlovatarDustCollectibleTemplate.CollectibleTemplateData = FlovatarDustCollectibleTemplate.getCollectibleTemplate(id: templateId)!
		let totalMintedComponents: UInt64 = FlovatarDustCollectibleTemplate.getTotalMintedComponents(id: templateId)!
		
		// Makes sure that the original minting limit set for each Template has not been reached
		if totalMintedComponents >= collectibleTemplate.maxMintableComponents{ 
			panic("Reached maximum mintable components for this template")
		}
		if vault.balance < FlovatarDustCollectibleTemplate.getTemplateCurrentPrice(id: templateId)!{ 
			panic("Price mismatch between the current price and amount paid")
		}
		var newNFT <- create NFT(templateId: templateId)
		emit Created(id: newNFT.id, templateId: templateId, mint: newNFT.mint)
		destroy vault
		return <-newNFT
	}
	
	access(account)
	fun createCollectibleAccessoryInternal(templateId: UInt64): @FlovatarDustCollectibleAccessory.NFT{ 
		let collectibleTemplate: FlovatarDustCollectibleTemplate.CollectibleTemplateData = FlovatarDustCollectibleTemplate.getCollectibleTemplate(id: templateId)!
		let totalMintedComponents: UInt64 = FlovatarDustCollectibleTemplate.getTotalMintedComponents(id: templateId)!
		
		// Makes sure that the original minting limit set for each Template has not been reached
		if totalMintedComponents >= collectibleTemplate.maxMintableComponents{ 
			panic("Reached maximum mintable components for this template")
		}


		FlovatarDustCollectibleTemplate.increaseTotalMintedComponents(id: templateId)
		FlovatarDustCollectibleTemplate.increaseTemplatesCurrentPrice(id: templateId)
		FlovatarDustCollectibleTemplate.setLastComponentMintedAt(id: templateId, value: getCurrentBlock().timestamp)
		
		
		var newNFT <- create NFT(templateId: templateId)
		emit Created(id: newNFT.id, templateId: templateId, mint: newNFT.mint)
		return <-newNFT
	}
	
	// This method can only be called from another contract in the same account.
	// In FlovatarComponent case it is called from the Flovatar Dust Collectible Admin that is used
	// to administer the components.
	// This function will batch create multiple Components and pass them back as a Collection
	access(account)
	fun batchCreateCollectibleAccessory(templateId: UInt64, quantity: UInt64): @Collection{ 
		let newCollection <- create Collection()
		var i: UInt64 = 0
		while i < quantity{ 
			newCollection.deposit(token: <-self.createCollectibleAccessoryInternal(templateId: templateId))
			i = i + UInt64(1)
		}
		return <-newCollection
	}
	
	init(){ 
		self.CollectionPublicPath = /public/FlovatarDustCollectibleAccessoryCollection
		self.CollectionStoragePath = /storage/FlovatarDustCollectibleAccessoryCollection
		
		// Initialize the total supply
		self.totalSupply = UInt64(0)
		self.account.storage.save<@{NonFungibleToken.Collection}>(<-FlovatarDustCollectibleAccessory.createEmptyCollection(nftType: Type<@FlovatarDustCollectibleAccessory.Collection>()), to: FlovatarDustCollectibleAccessory.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&{FlovatarDustCollectibleAccessory.CollectionPublic}>(FlovatarDustCollectibleAccessory.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: FlovatarDustCollectibleAccessory.CollectionPublicPath)
		emit ContractInitialized()
	}
}
