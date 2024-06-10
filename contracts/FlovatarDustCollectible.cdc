import "FungibleToken"
import "NonFungibleToken"
import "FlowToken"
import "FlovatarDustCollectibleTemplate"
import "FlovatarDustCollectibleAccessory"
import "MetadataViews"
import "FlovatarDustToken"
import "ViewResolver"

/*

 The contract that defines the Dust Collectible NFT and a Collection to manage them


This contract contains also the Admin resource that can be used to manage and generate the Dust Collectible Templates.

 */

access(all)
contract FlovatarDustCollectible: NonFungibleToken{ 
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	// These will be used in the Marketplace to pay out
	// royalties to the creator and to the marketplace
	access(account)
	var royaltyCut: UFix64
	
	access(account)
	var marketplaceCut: UFix64
	
	// Here we keep track of all the Flovatar unique combinations and names
	// that people will generate to make sure that there are no duplicates
	access(all)
	var totalSupply: UInt64
	
	access(contract)
	let mintedCombinations:{ String: Bool}
	
	access(contract)
	let mintedNames:{ String: Bool}
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Created(id: UInt64, mint: UInt64, series: UInt64, address: Address)
	
	access(all)
	event Updated(id: UInt64)
	
	access(all)
	event Destroyed(id: UInt64)
	
	access(all)
	event NameSet(id: UInt64, name: String)
	
	access(all)
	event PositionChanged(id: UInt64, position: String)
	
	access(all)
	event StoryAdded(id: UInt64, story: String)
	
	access(all)
	struct Royalties{ 
		access(all)
		let royalty: [Royalty]
		
		init(royalty: [Royalty]){ 
			self.royalty = royalty
		}
	}
	
	access(all)
	enum RoyaltyType: UInt8{ 
		access(all)
		case fixed
		
		access(all)
		case percentage
	}
	
	access(all)
	struct Royalty{ 
		access(all)
		let wallet: Capability<&{FungibleToken.Receiver}>
		
		access(all)
		let cut: UFix64
		
		//can be percentage
		access(all)
		let type: RoyaltyType
		
		init(wallet: Capability<&{FungibleToken.Receiver}>, cut: UFix64, type: RoyaltyType){ 
			if !wallet.check(){} 
			//panic("Capability not valid!")
			self.wallet = wallet
			self.cut = cut
			self.type = type
		}
	}

	access(all) entitlement PrivateEnt
	
	// The public interface can show metadata and the content for the Flovatar.
	// In addition to it, it provides methods to access the additional optional
	// components (accessory, hat, eyeglasses, background) for everyone.
	access(all)
	resource interface Public{ 
		access(all)
		let id: UInt64
		
		access(all)
		let mint: UInt64
		
		access(all)
		let series: UInt64
		
		access(all)
		let combination: String
		
		access(all)
		let creatorAddress: Address
		
		access(all)
		let createdAt: UFix64
		
		access(contract)
		let royalties: Royalties
		
		// these three are added because I think they will be in the standard. At least Dieter thinks it will be needed
		access(contract)
		var name: String
		
		access(all)
		let description: String
		
		access(all)
		let schema: String?
		
		access(all)
		fun getName(): String
		
		access(all)
		fun getSvg(): String
		
		access(all)
		fun getRoyalties(): Royalties
		
		access(all)
		fun getBio():{ String: String}
		
		access(all)
		fun getMetadata():{ String: String}
		
		access(all)
		fun getLayers():{ UInt32: UInt64?}
		
		access(all)
		fun getAccessories(): [UInt64]
		
		access(all)
		fun getSeries(): FlovatarDustCollectibleTemplate.CollectibleSeriesData?
	}
	
	//The private interface can update the Accessory, Hat, Eyeglasses and Background
	//for the Flovatar and is accessible only to the owner of the NFT
	access(all)
	resource interface Private{ 
		access(FlovatarDustCollectible.PrivateEnt)
		fun setName(name: String, vault: @{FungibleToken.Vault}): String
		
		access(FlovatarDustCollectible.PrivateEnt)
		fun addStory(text: String, vault: @{FungibleToken.Vault}): String
		
		access(FlovatarDustCollectible.PrivateEnt)
		fun setPosition(latitude: Fix64, longitude: Fix64, vault: @{FungibleToken.Vault}): String
		
		access(FlovatarDustCollectible.PrivateEnt)
		fun setAccessory(layer: UInt32, accessory: @FlovatarDustCollectibleAccessory.NFT): @FlovatarDustCollectibleAccessory.NFT?
		
		access(FlovatarDustCollectible.PrivateEnt)
		fun removeAccessory(layer: UInt32): @FlovatarDustCollectibleAccessory.NFT?
	}
	
	//The NFT resource that implements both Private and Public interfaces
	access(all)
	resource NFT: NonFungibleToken.NFT, Public, Private { 
		access(all)
		let id: UInt64
		
		access(all)
		let mint: UInt64
		
		access(all)
		let series: UInt64
		
		access(all)
		let combination: String
		
		access(all)
		let creatorAddress: Address
		
		access(all)
		let createdAt: UFix64
		
		access(contract)
		let royalties: Royalties
		
		access(contract)
		var name: String
		
		access(all)
		let description: String
		
		access(all)
		let schema: String?
		
		access(self)
		let bio:{ String: String}
		
		access(self)
		let metadata:{ String: String}
		
		access(self)
		let layers:{ UInt32: UInt64?}
		
		access(self)
		let accessories: @{UInt32: FlovatarDustCollectibleAccessory.NFT}
		
		init(series: UInt64, layers:{ UInt32: UInt64?}, creatorAddress: Address, royalties: Royalties){ 
			FlovatarDustCollectible.totalSupply = FlovatarDustCollectible.totalSupply + UInt64(1)

			FlovatarDustCollectibleTemplate.increaseTotalMintedCollectibles(series: series)
			let coreLayers:{ UInt32: UInt64} = FlovatarDustCollectible.getCoreLayers(series: series, layers: layers)
			self.id = FlovatarDustCollectible.totalSupply
			self.mint = FlovatarDustCollectibleTemplate.getTotalMintedCollectibles(series: series)!
			self.series = series
			self.combination = FlovatarDustCollectible.getCombinationString(series: series, layers: coreLayers)
			self.creatorAddress = creatorAddress
			self.createdAt = getCurrentBlock().timestamp
			self.royalties = royalties
			self.schema = nil
			self.name = ""
			self.description = ""
			self.bio ={} 
			self.metadata ={} 
			self.layers = layers
			self.accessories <-{} 
		}
		
		access(all)
		fun getID(): UInt64{ 
			return self.id
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(all)
		fun getRoyalties(): Royalties{ 
			return self.royalties
		}
		
		access(all)
		fun getBio():{ String: String}{ 
			return self.bio
		}
		
		access(all)
		fun getName(): String{ 
			return self.name
		}
		
		access(all)
		fun getSeries(): FlovatarDustCollectibleTemplate.CollectibleSeriesData?{ 
			return FlovatarDustCollectibleTemplate.getCollectibleSeries(id: self.series)
		}
		
		// This will allow to change the Name of the Flovatar only once.
		// It checks for the current name is empty, otherwise it will throw an error.
		// $DUST vault must contain 100 tokens that will be burned in the process
		access(FlovatarDustCollectible.PrivateEnt)
		fun setName(name: String, vault: @{FungibleToken.Vault}): String{ 
			pre{ 
				// TODO: Make sure that the text of the name is sanitized
				//and that bad words are not accepted?
				name.length > 2:
					"The name is too short"
				name.length < 32:
					"The name is too long"
				self.name == "":
					"The name has already been set"
				vault.balance == 100.0:
					"The amount of $DUST is not correct"
				vault.isInstance(Type<@FlovatarDustToken.Vault>()):
					"Vault not of the right Token Type"
			}
			
			// Makes sure that the name is available and not taken already
			if FlovatarDustCollectible.checkNameAvailable(name: name) == false{ 
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
		access(FlovatarDustCollectible.PrivateEnt)
		fun addStory(text: String, vault: @{FungibleToken.Vault}): String{ 
			pre{ 
				// TODO: Make sure that the text of the name is sanitized
				//and that bad words are not accepted?
				text.length > 0:
					"The text is too short"
				text.length <= 300:
					"The text is too long"
				vault.balance == 50.0:
					"The amount of $DUST is not correct"
				vault.isInstance(Type<@FlovatarDustToken.Vault>()):
					"Vault not of the right Token Type"
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
		access(FlovatarDustCollectible.PrivateEnt)
		fun setPosition(latitude: Fix64, longitude: Fix64, vault: @{FungibleToken.Vault}): String{ 
			pre{ 
				latitude >= -90.0:
					"The latitude is out of range"
				latitude <= 90.0:
					"The latitude is out of range"
				longitude >= -180.0:
					"The longitude is out of range"
				longitude <= 180.0:
					"The longitude is out of range"
				vault.balance == 10.0:
					"The amount of $DUST is not correct"
				vault.isInstance(Type<@FlovatarDustToken.Vault>()):
					"Vault not of the right Token Type"
			}
			destroy vault
			let position: String = latitude.toString().concat(",").concat(longitude.toString())
			self.bio.insert(key: "position", position)
			emit PositionChanged(id: self.id, position: position)
			return position
		}
		
		access(all)
		fun getLayers():{ UInt32: UInt64?}{ 
			return self.layers
		}
		
		access(all)
		fun getAccessories(): [UInt64]{ 
			let accessoriesIds: [UInt64] = []
			for k in self.accessories.keys{ 
				let accessoryId = self.accessories[k]?.id
				if accessoryId != nil{ 
					accessoriesIds.append(accessoryId!)
				}
			}
			return accessoriesIds
		}
		
		// This will allow to change the Accessory of the Flovatar any time.
		// It checks for the right category and series before executing.
		access(FlovatarDustCollectible.PrivateEnt)
		fun setAccessory(layer: UInt32, accessory: @FlovatarDustCollectibleAccessory.NFT): @FlovatarDustCollectibleAccessory.NFT?{ 
			if(accessory.getSeries() != self.series) {
				panic("The accessory belongs to a different series")
			}
			if FlovatarDustCollectibleTemplate.isCollectibleLayerAccessory(layer: layer, series: self.series){ 
				emit Updated(id: self.id)
				self.layers[layer] = accessory.templateId
				let oldAccessory <- self.accessories[layer] <- accessory
				return <-oldAccessory
			}
			panic("The Layer is out of range or it's not an accessory")
		}
		
		// This will allow to remove the Accessory of the Flovatar any time.
		access(FlovatarDustCollectible.PrivateEnt)
		fun removeAccessory(layer: UInt32): @FlovatarDustCollectibleAccessory.NFT?{ 
			if FlovatarDustCollectibleTemplate.isCollectibleLayerAccessory(layer: layer, series: self.series){ 
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
		access(all)
		fun getSvg(): String{ 
			let series = FlovatarDustCollectibleTemplate.getCollectibleSeries(id: self.series)
			let layersArr: [String] = []
			for k in (series!).layers.keys{ 
				layersArr.append("")
			}
			var svg: String = (series!).svgPrefix
			for k in self.layers.keys{ 
				if self.layers[k] != nil{ 
					let layer = self.layers[k]!
					if layer != nil{ 
						let tempSvg = FlovatarDustCollectibleTemplate.getCollectibleTemplateSvg(id: layer!)
						//svg = svg.concat(tempSvg!)
						layersArr[k - UInt32(1)] = tempSvg!
					}
				}
			}
			for tempLayer in layersArr{ 
				svg = svg.concat(tempLayer)
			}
			svg = svg.concat((series!).svgSuffix)
			return svg
		}
		
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
				return MetadataViews.ExternalURL("https://flovatar.com/collectibles/".concat(self.id.toString()))
			}
			if view == Type<MetadataViews.Royalties>(){ 
				let royalties: [MetadataViews.Royalty] = []
				var count: Int = 0
				for royalty in self.royalties.royalty{ 
					royalties.append(MetadataViews.Royalty(receiver: royalty.wallet, cut: royalty.cut, description: "Flovatar Royalty ".concat(count.toString())))
					count = count + Int(1)
				}
				return MetadataViews.Royalties(royalties)
			}
			if view == Type<MetadataViews.Serial>(){ 
				return MetadataViews.Serial(self.id)
			}
			if view == Type<MetadataViews.Editions>(){ 
				let series = self.getSeries()
				var maxMint: UInt64 = (series!).maxMintable
				if maxMint == UInt64(0){ 
					maxMint = UInt64(999999)
				}
				let editionInfo = MetadataViews.Edition(name: "Flovatar Stardust Collectible Series ".concat(self.series.toString()), number: self.mint, max: maxMint)
				let editionList: [MetadataViews.Edition] = [editionInfo]
				return MetadataViews.Editions(editionList)
			}
			if view == Type<MetadataViews.NFTCollectionDisplay>(){ 
				let mediaSquare = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://images.flovatar.com/logo.svg"), mediaType: "image/svg+xml")
				let mediaBanner = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://images.flovatar.com/logo-horizontal.svg"), mediaType: "image/svg+xml")
				return MetadataViews.NFTCollectionDisplay(name: "Flovatar Stardust Collectible", description: "The Flovatar Stardust Collectibles are the next generation of composable and customizable NFTs that populate the Flovatar Universe and can be minted exclusively by using the $DUST token.", externalURL: MetadataViews.ExternalURL("https://flovatar.com"), squareImage: mediaSquare, bannerImage: mediaBanner, socials:{ "discord": MetadataViews.ExternalURL("https://discord.gg/flovatar"), "twitter": MetadataViews.ExternalURL("https://twitter.com/flovatar"), "instagram": MetadataViews.ExternalURL("https://instagram.com/flovatar_nft"), "tiktok": MetadataViews.ExternalURL("https://www.tiktok.com/@flovatar")})
			}
			if view == Type<MetadataViews.Display>(){ 
				return MetadataViews.Display(name: self.name == "" ? "Stardust Collectible #".concat(self.id.toString()) : self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: "https://images.flovatar.com/collectible/svg/".concat(self.id.toString()).concat(".svg")))
			}
			if view == Type<MetadataViews.Traits>(){ 
				let traits: [MetadataViews.Trait] = []
				let series = self.getSeries()
				for k in self.layers.keys{ 
					if self.layers[k] != nil{ 
						let layer = (series!).layers[k]!
						if self.layers[k] != nil{ 
							let layerSelf = self.layers[k]!
							if layer != nil{ 
								let template = FlovatarDustCollectibleTemplate.getCollectibleTemplate(id: layerSelf!)
								let trait = MetadataViews.Trait(name: (layer!).name, value: (template!).name, displayType: "String", rarity: MetadataViews.Rarity(score: nil, max: nil, description: (template!).rarity))
								traits.append(trait)
							}
						}
					}
				}
				return MetadataViews.Traits(traits)
			}
			if view == Type<MetadataViews.NFTCollectionData>(){ 
				return MetadataViews.NFTCollectionData(storagePath: FlovatarDustCollectible.CollectionStoragePath, publicPath: FlovatarDustCollectible.CollectionPublicPath, publicCollection: Type<&FlovatarDustCollectible.Collection>(), publicLinkedType: Type<&FlovatarDustCollectible.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
						return <-FlovatarDustCollectible.createEmptyCollection(nftType: Type<@FlovatarDustCollectible.Collection>())
					})
			}
			if view == Type<MetadataViews.EVMBridgedMetadata>(){ 
				let contractLevel = FlovatarDustCollectible.resolveContractView(
						resourceType: nil,
						viewType: Type<MetadataViews.EVMBridgedMetadata>()
					) as! MetadataViews.EVMBridgedMetadata?
					?? panic("Could not resolve contract-level EVMBridgedMetadata")
				
				return MetadataViews.EVMBridgedMetadata(
					name: contractLevel.name,
					symbol: contractLevel.symbol,
					uri: MetadataViews.URI(
						baseURI: "https://flovatar.com/collectibles/json/",
						value: self.id.toString()
					)
				)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// Standard NFT collectionPublic interface that can also borrowFlovatar as the correct type
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowDustCollectible(id: UInt64): &FlovatarDustCollectible.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Flovatar Dust Collectible reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Main Collection to manage all the Flovatar NFT
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
			let token <- token as! @FlovatarDustCollectible.NFT
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
		
		// borrowFlovatar returns a borrowed reference to a Flovatar
		// so that the caller can read data and call methods from it.
		access(all)
		fun borrowDustCollectible(id: UInt64): &FlovatarDustCollectible.NFT?{ 
			if self.ownedNFTs[id] != nil {
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)
				let collectibleNFT = ref as! &FlovatarDustCollectible.NFT
				return collectibleNFT
			} else {
				return nil
			}
		}
		
		/*
		// borrowFlovatarPrivate returns a borrowed reference to a Flovatar using the Private interface
		// so that the caller can read data and call methods from it, like setting the optional components.
		access(all)
		fun borrowDustCollectiblePrivate(id: UInt64): &{FlovatarDustCollectible.Private}?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &FlovatarDustCollectible.NFT
			} else{ 
				return nil
			}
		}
		 */
		
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
			supportedTypes[Type<@FlovatarDustCollectible.NFT>()] = true
			return supportedTypes
		}

		/// Returns whether or not the given type is accepted by the collection
		/// A collection that can accept any type should just return true by default
		access(all) 
		view fun isSupportedNFTType(type: Type): Bool {
			return type == Type<@FlovatarDustCollectible.NFT>()
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-FlovatarDustCollectible.createEmptyCollection(nftType: Type<@FlovatarDustCollectible.NFT>())
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
					publicCollection: Type<&FlovatarDustCollectible.Collection>(),
					publicLinkedType: Type<&FlovatarDustCollectible.Collection>(),
					createEmptyCollectionFunction: (fun(): @{NonFungibleToken.Collection} {
						return <-FlovatarDustCollectible.createEmptyCollection(nftType: Type<@FlovatarDustCollectible.NFT>())
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
					name: "Flovatar Dust Collectible Collection",
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
					name: "FlovatarDustCollectible",
					symbol: "XMPL",
					uri: MetadataViews.URI(
						baseURI: nil, // setting baseURI as nil sets the given value as the uri field value
						value: "https://flovatar.com"
					)
				)
		}
		return nil
	}



	
	// This struct is used to send a data representation of the Flovatar Dust Collectibles
	// when retrieved using the contract helper methods outside the collection.
	access(all)
	struct FlovatarDustCollectibleData{ 
		access(all)
		let id: UInt64
		
		access(all)
		let mint: UInt64
		
		access(all)
		let series: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let svg: String?
		
		access(all)
		let combination: String
		
		access(all)
		let creatorAddress: Address
		
		access(all)
		let layers:{ UInt32: UInt64?}
		
		access(all)
		let bio:{ String: String}
		
		access(all)
		let metadata:{ String: String}
		
		init(id: UInt64, mint: UInt64, series: UInt64, name: String, svg: String?, combination: String, creatorAddress: Address, layers:{ UInt32: UInt64?}, bio:{ String: String}, metadata:{ String: String}){ 
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
	access(all)
	fun getCollectible(address: Address, collectibleId: UInt64): FlovatarDustCollectibleData?{ 
		let account = getAccount(address)

		if let collectibleCollection = account.capabilities.borrow<&FlovatarDustCollectible.Collection>(FlovatarDustCollectible.CollectionPublicPath){ 
			if let collectible = collectibleCollection.borrowDustCollectible(id: collectibleId){ 
				return FlovatarDustCollectibleData(id: collectibleId, mint: (collectible!).mint, series: (collectible!).series, name: (collectible!).getName(), svg: (collectible!).getSvg(), combination: (collectible!).combination, creatorAddress: (collectible!).creatorAddress, layers: (collectible!).getLayers(), bio: (collectible!).getBio(), metadata: (collectible!).getMetadata())
			}
		}
		
		return nil
	}
	
	// This function will return all Flovatars on a user account and return an array of FlovatarData
	access(all)
	fun getCollectibles(address: Address): [FlovatarDustCollectibleData]{ 
		var dustCollectibleData: [FlovatarDustCollectibleData] = []

		let account = getAccount(address)
		if let collectibleCollection = account.capabilities.borrow<&FlovatarDustCollectible.Collection>(FlovatarDustCollectible.CollectionPublicPath){ 
			for id in collectibleCollection.getIDs(){ 
				if let collectible = collectibleCollection.borrowDustCollectible(id: id){ 
					dustCollectibleData.append(FlovatarDustCollectibleData(id: id, mint: (collectible!).mint, series: (collectible!).series, name: (collectible!).getName(), svg: nil, combination: (collectible!).combination, creatorAddress: (collectible!).creatorAddress, layers: (collectible!).getLayers(), bio: (collectible!).getBio(), metadata: (collectible!).getMetadata()))
				}
			}
		}
		
		return dustCollectibleData
	}
	
	// This returns all the previously minted combinations, so that duplicates won't be allowed
	access(all)
	fun getMintedCombinations(): [String]{ 
		return FlovatarDustCollectible.mintedCombinations.keys
	}
	
	// This returns all the previously minted names, so that duplicates won't be allowed
	access(all)
	fun getMintedNames(): [String]{ 
		return FlovatarDustCollectible.mintedNames.keys
	}
	
	// This function will add a minted combination to the array
	access(account)
	fun addMintedCombination(combination: String){ 
		FlovatarDustCollectible.mintedCombinations.insert(key: combination, true)
	}
	
	// This function will add a new name to the array
	access(account)
	fun addMintedName(name: String){ 
		FlovatarDustCollectible.mintedNames.insert(key: name, true)
	}
	
	access(all)
	fun getCoreLayers(series: UInt64, layers:{ UInt32: UInt64?}):{ UInt32: UInt64}{ 
		let coreLayers:{ UInt32: UInt64} ={} 
		for k in layers.keys{ 
			if !FlovatarDustCollectibleTemplate.isCollectibleLayerAccessory(layer: k, series: series){ 
				let templateId = layers[k]!
				let template = FlovatarDustCollectibleTemplate.getCollectibleTemplate(id: templateId!)!
				if template.series != series{ 
					panic("Template belonging to the wrong Dust Collectible Series")
				}
				if template.layer != k{ 
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
	access(all)
	fun getCombinationString(series: UInt64, layers:{ UInt32: UInt64}): String{ 
		var combination = "S".concat(series.toString())
		var i: UInt32 = UInt32(2)
		while i < UInt32(7){ 
			if layers[i] != nil{ 
				let layerId = layers[i]!
				combination = combination.concat("-L").concat(i.toString()).concat("_").concat(layerId.toString())
			}
			i = i + UInt32(1)
		}
		//Disabling because is not ordered and will generate duplicates
		//for k in layers.keys {
		//	if(layers[k] != nil){
		//		let layerId = layers[k]!
		//		combination = combination.concat("-L").concat(k.toString()).concat("_").concat(layerId.toString())
		//	}
		//}
		return combination
	}
	
	// This function will get a list of component IDs and will check if the
	// generated string is unique or if someone already used it before.
	access(all)
	fun checkCombinationAvailable(series: UInt64, layers:{ UInt32: UInt64}): Bool{ 
		let combinationString = FlovatarDustCollectible.getCombinationString(series: series, layers: layers)
		return !FlovatarDustCollectible.mintedCombinations.containsKey(combinationString)
	}
	
	// This will check if a specific Name has already been taken
	// and assigned to some Flovatar
	access(all)
	fun checkNameAvailable(name: String): Bool{ 
		return name.length > 2 && name.length < 20 && !FlovatarDustCollectible.mintedNames.containsKey(name)
	}
	
	// This is a public function that anyone can call to generate a new Flovatar Dust Collectible
	// A list of components resources needs to be passed to executed.
	// It will check first for uniqueness of the combination + name and will then
	// generate the Flovatar and burn all the passed components.
	// The Spark NFT will entitle to use any common basic component (body, hair, etc.)
	// In order to use special rare components a boost of the same rarity will be needed
	// for each component used
	access(all)
	fun createDustCollectible(series: UInt64, layers: [UInt32], templateIds: [UInt64?], address: Address, vault: @{FungibleToken.Vault}): @FlovatarDustCollectible.NFT{ 
		pre{ 
			vault.isInstance(Type<@FlovatarDustToken.Vault>()):
				"Vault not of the right Token Type"
		}
		let seriesData = FlovatarDustCollectibleTemplate.getCollectibleSeries(id: series)
		if seriesData == nil{ 
			panic("Dust Collectible Series not found!")
		}
		if (seriesData!).layers.length != layers.length{ 
			panic("The amount of layers is not matching!")
		}
		if templateIds.length != layers.length{ 
			panic("The amount of layers and templates is not matching!")
		}
		let mintedCollectibles = FlovatarDustCollectibleTemplate.getTotalMintedCollectibles(series: series)
		if mintedCollectibles != nil{ 
			if mintedCollectibles! >= (seriesData!).maxMintable{ 
				panic("Reached the maximum mint number for this Series!")
			}
		}
		let templates: [FlovatarDustCollectibleTemplate.CollectibleTemplateData] = []
		var totalPrice: UFix64 = 0.0
		let coreLayers:{ UInt32: UInt64} ={} 
		let fullLayers:{ UInt32: UInt64?} ={} 
		var i: UInt32 = UInt32(0)
		while i < UInt32(layers.length){ 
			let layerId: UInt32 = layers[i]!
			let templateId: UInt64? = templateIds[i] ?? nil
			if !FlovatarDustCollectibleTemplate.isCollectibleLayerAccessory(layer: layerId, series: series){ 
				if templateId == nil{ 
					panic("Core Layer missing ".concat(layerId.toString()).concat(" - ").concat(i.toString()).concat("/").concat(layers.length.toString()))
				}
				let template = FlovatarDustCollectibleTemplate.getCollectibleTemplate(id: templateId!)!
				if template.series != series{ 
					panic("Template belonging to the wrong Dust Collectible Series")
				}
				if template.layer != layerId{ 
					panic("Template belonging to the wrong Layer")
				}
				let totalMintedComponents: UInt64 = FlovatarDustCollectibleTemplate.getTotalMintedComponents(id: template.id)!
				// Makes sure that the original minting limit set for each Template has not been reached
				if totalMintedComponents >= template.maxMintableComponents{ 
					panic("Reached maximum mintable count for this trait")
				}
				coreLayers[layerId] = template.id
				fullLayers[layerId] = template.id
				templates.append(template)
				totalPrice = totalPrice + FlovatarDustCollectibleTemplate.getTemplateCurrentPrice(id: template.id)!


				FlovatarDustCollectibleTemplate.increaseTotalMintedComponents(id: template.id)
				FlovatarDustCollectibleTemplate.increaseTemplatesCurrentPrice(id: template.id)
				FlovatarDustCollectibleTemplate.setLastComponentMintedAt(id: template.id, value: getCurrentBlock().timestamp)
				
			} else{ 
				fullLayers[layerId] = nil
			}
			i = i + UInt32(1)
		}
		if totalPrice > vault.balance{ 
			panic("Not enough tokens provided")
		}
		
		// Generates the combination string to check for uniqueness.
		// This is like a barcode that defines exactly which components were used
		// to create the Flovatar
		let combinationString = FlovatarDustCollectible.getCombinationString(series: series, layers: coreLayers)
		
		// Makes sure that the combination is available and not taken already
		if FlovatarDustCollectible.mintedCombinations.containsKey(combinationString) == true{ 
			panic("This combination has already been taken")
		}
		let royalties: [Royalty] = []
		let creatorAccount = getAccount(address)
		royalties.append(Royalty(wallet: creatorAccount.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver), cut: FlovatarDustCollectible.getRoyaltyCut(), type: RoyaltyType.percentage))
		royalties.append(Royalty(wallet: self.account.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver), cut: FlovatarDustCollectible.getMarketplaceCut(), type: RoyaltyType.percentage))
		
		// Mint the new Flovatar NFT by passing the metadata to it
		var newNFT <- create NFT(series: series, layers: fullLayers, creatorAddress: address, royalties: Royalties(royalty: royalties))
		
		// Adds the combination to the arrays to remember it
		FlovatarDustCollectible.addMintedCombination(combination: combinationString)
		
		// Emits the Created event to notify about its existence
		emit Created(id: newNFT.id, mint: newNFT.mint, series: newNFT.series, address: address)
		destroy vault
		return <-newNFT
	}
	
	// These functions will return the current Royalty cuts for
	// both the Creator and the Marketplace.
	access(all)
	fun getRoyaltyCut(): UFix64{ 
		return self.royaltyCut
	}
	
	access(all)
	fun getMarketplaceCut(): UFix64{ 
		return self.marketplaceCut
	}
	
	// Only Admins will be able to call the set functions to
	// manage Royalties and Marketplace cuts.
	access(account)
	fun setRoyaltyCut(value: UFix64){ 
		self.royaltyCut = value
	}
	
	access(account)
	fun setMarketplaceCut(value: UFix64){ 
		self.marketplaceCut = value
	}
	
	// This is the main Admin resource that will allow the owner
	// to generate new Templates, Components and Packs
	access(all)
	resource Admin{ 
		

		//This will create a new FlovatarComponentTemplate that
		// contains all the SVG and basic informations to represent
		// a specific part of the Flovatar (body, hair, eyes, mouth, etc.)
		// More info in the FlovatarComponentTemplate.cdc file
		access(all)
		fun createCollectibleSeries(name: String, description: String, svgPrefix: String, svgSuffix: String, priceIncrease: UFix64, layers:{ UInt32: FlovatarDustCollectibleTemplate.Layer}, colors:{ UInt32: String}, metadata:{ String: String}, maxMintable: UInt64): @FlovatarDustCollectibleTemplate.CollectibleSeries{ 
			return <-FlovatarDustCollectibleTemplate.createCollectibleSeries(name: name, description: description, svgPrefix: svgPrefix, svgSuffix: svgSuffix, priceIncrease: priceIncrease, layers: layers, colors: colors, metadata: metadata, maxMintable: maxMintable)
		}
		
		//This will create a new FlovatarComponentTemplate that
		// contains all the SVG and basic informations to represent
		// a specific part of the Flovatar (body, hair, eyes, mouth, etc.)
		// More info in the FlovatarComponentTemplate.cdc file
		access(all)
		fun createCollectibleTemplate(name: String, description: String, series: UInt64, layer: UInt32, metadata:{ String: String}, rarity: String, basePrice: UFix64, svg: String, maxMintableComponents: UInt64): @FlovatarDustCollectibleTemplate.CollectibleTemplate{ 
			return <-FlovatarDustCollectibleTemplate.createCollectibleTemplate(name: name, description: description, series: series, layer: layer, metadata: metadata, rarity: rarity, basePrice: basePrice, svg: svg, maxMintableComponents: maxMintableComponents)
		}
		
		//This will mint a new Component based from a selected Template
		access(all)
		fun createCollectible(templateId: UInt64): @FlovatarDustCollectibleAccessory.NFT{ 
			return <-FlovatarDustCollectibleAccessory.createCollectibleAccessoryInternal(templateId: templateId)
		}
		
		//This will mint Components in batch and return a Collection instead of the single NFT
		access(all)
		fun batchCreateCollectibles(templateId: UInt64, quantity: UInt64): @FlovatarDustCollectibleAccessory.Collection{ 
			return <-FlovatarDustCollectibleAccessory.batchCreateCollectibleAccessory(templateId: templateId, quantity: quantity)
		}
		
		// With this function you can generate a new Admin resource
		// and pass it to another user if needed
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
		
		// Helper functions to update the Royalty cut
		access(all)
		fun setRoyaltyCut(value: UFix64){ 
			FlovatarDustCollectible.setRoyaltyCut(value: value)
		}
		
		// Helper functions to update the Marketplace cut
		access(all)
		fun setMarketplaceCut(value: UFix64){ 
			FlovatarDustCollectible.setMarketplaceCut(value: value)
		}
		
	}
	
	init(){ 
		self.CollectionPublicPath = /public/FlovatarDustCollectibleCollection
		self.CollectionStoragePath = /storage/FlovatarDustCollectibleCollection
		self.AdminStoragePath = /storage/FlovatarDustCollectibleAdmin
		
		// Initialize the total supply
		self.totalSupply = UInt64(0)
		self.mintedCombinations ={} 
		self.mintedNames ={} 
		
		// Set the default Royalty and Marketplace cuts
		self.royaltyCut = 0.01
		self.marketplaceCut = 0.05
		self.account.storage.save<@{NonFungibleToken.Collection}>(<-FlovatarDustCollectible.createEmptyCollection(nftType: Type<@FlovatarDustCollectible.Collection>()), to: FlovatarDustCollectible.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&{FlovatarDustCollectible.CollectionPublic}>(FlovatarDustCollectible.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: FlovatarDustCollectible.CollectionPublicPath)
		
		// Put the Admin resource in storage
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
