import "FungibleToken"
import "NonFungibleToken"
import "FlowToken"
import "FlovatarComponentTemplate"
import "FlovatarComponent"
import "FlovatarPack"
import "MetadataViews"
import "ViewResolver" 

/*

The contract that defines the Flobot NFT and a Collection to manage them

Base components that will be used to generate the unique combination of the Flobot
'body', 'hair', 'facialhair', 'eyes', 'nose', 'mouth', 'clothing'

Extra components that can be added in a second moment
'accessory', 'hat', eyeglass', 'background'


This contract contains also the Admin resource that can be used to manage and generate all the other ones (Components, Templates, Packs).

 */

access(all)
contract Flobot: NonFungibleToken{ 
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
	
	// Here we keep track of all the Flobot unique combinations and names
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
	event Created(id: UInt64, metadata: Metadata)
	
	access(all)
	event Updated(id: UInt64)
	
	access(all)
	event NameSet(id: UInt64, name: String)
	
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
			self.wallet = wallet
			self.cut = cut
			self.type = type
		}
	}
	
	// This Metadata struct contains all the most important informations about the Flobot
	access(all)
	struct Metadata{ 
		access(all)
		let mint: UInt64
		
		access(all)
		let series: UInt32
		
		access(all)
		let combination: String
		
		access(all)
		let rarity: String
		
		access(all)
		let creatorAddress: Address
		
		access(self)
		let components:{ String: UInt64}
		
		init(mint: UInt64, series: UInt32, combination: String, rarity: String, creatorAddress: Address, components:{ String: UInt64}){ 
			self.mint = mint
			self.series = series
			self.combination = combination
			self.rarity = rarity
			self.creatorAddress = creatorAddress
			self.components = components
		}
		
		access(all)
		fun getComponents():{ String: UInt64}{ 
			return self.components
		}
	}

	access(all) entitlement PrivateEnt
	
	// The public interface can show metadata and the content for the Flobot.
	// In addition to it, it provides methods to access the additional optional
	// components (accessory, hat, eyeglasses, background) for everyone.
	access(all)
	resource interface Public{ 
		access(all)
		let id: UInt64
		
		access(contract)
		let metadata: Metadata
		
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
		fun getBackground(): UInt64?
		
		access(all)
		fun getSvg(): String
		
		access(all)
		fun getMetadata(): Metadata
		
		access(all)
		fun getRoyalties(): Royalties
		
		access(all)
		fun getBio():{ String: String}
	}
	
	//The private interface can update the Accessory, Hat, Eyeglasses and Background
	//for the Flobot and is accessible only to the owner of the NFT
	access(all)
	resource interface Private{ 
		access(Flobot.PrivateEnt)
		fun setName(name: String): String
		
		access(Flobot.PrivateEnt)
		fun setBackground(component: @FlovatarComponent.NFT): @FlovatarComponent.NFT?
		
		access(Flobot.PrivateEnt)
		fun removeBackground(): @FlovatarComponent.NFT?
	}
	
	//The NFT resource that implements both Private and Public interfaces
	access(all)
	resource NFT: NonFungibleToken.NFT, Public, Private { 
		access(all)
		let id: UInt64
		
		access(contract)
		let metadata: Metadata
		
		access(contract)
		let royalties: Royalties
		
		access(contract)
		var background: @FlovatarComponent.NFT?
		
		access(contract)
		var name: String
		
		access(all)
		let description: String
		
		access(all)
		let schema: String?
		
		access(self)
		let bio:{ String: String}
		
		init(metadata: Metadata, royalties: Royalties){ 
			Flobot.totalSupply = Flobot.totalSupply + 1
			self.id = Flobot.totalSupply
			self.metadata = metadata
			self.royalties = royalties
			self.background <- nil
			self.schema = nil
			self.name = ""
			self.description = ""
			self.bio ={} 
		}
		
		access(all)
		fun getID(): UInt64{ 
			return self.id
		}
		
		access(all)
		fun getMetadata(): Metadata{ 
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
		
		// This will allow to change the Name of the Flobot only once.
		// It checks for the current name is empty, otherwise it will throw an error.
		access(Flobot.PrivateEnt)
		fun setName(name: String): String{ 
			pre{ 
				// TODO: Make sure that the text of the name is sanitized
				//and that bad words are not accepted?
				name.length > 2:
					"The name is too short"
				name.length < 32:
					"The name is too long"
				self.name == "":
					"The name has already been set"
			}
			
			// Makes sure that the name is available and not taken already
			if Flobot.checkNameAvailable(name: name) == false{ 
				panic("This name has already been taken")
			}
			
			// DISABLING THIS FUNCTIONALITY TO BE INTRODUCED AT A LATER DATE
			//self.name = name
			
			// Adds the name to the array to remember it
			//Flobot.addMintedName(name: name)
			//emit NameSet(id: self.id, name: name)
			return self.name
		}
		
		access(all)
		fun getBackground(): UInt64?{ 
			return self.background?.templateId
		}
		
		// This will allow to change the Background of the Flobot any time.
		// It checks for the right category and series before executing.
		access(Flobot.PrivateEnt)
		fun setBackground(component: @FlovatarComponent.NFT): @FlovatarComponent.NFT?{ 
			if(component.getCategory() != "background") {
				panic("The component needs to be a background")
			}
			if(component.getSeries() != UInt32(1)) {
				panic("The accessory doesn't belong to series 1")
			}

			emit Updated(id: self.id)
			let compNFT <- self.background <- component
			return <-compNFT
		}
		
		// This will allow to remove the Background of the Flobot any time.
		access(Flobot.PrivateEnt)
		fun removeBackground(): @FlovatarComponent.NFT?{ 
			emit Updated(id: self.id)
			let compNFT <- self.background <- nil
			return <-compNFT
		}
		
		// This function will return the full SVG of the Flobot. It will take the
		// optional components (Accessory, Hat, Eyeglasses and Background) from their
		// original Template resources, while all the other unmutable components are
		// taken from the Metadata directly.
		access(all)
		fun getSvg(): String{ 
			var svg: String = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 3000 3000' width='100%' height='100%'>"
			if let background = self.getBackground(){ 
				if let template = FlovatarComponentTemplate.getComponentTemplate(id: background){ 
					svg = svg.concat(template.svg!)
				}
			}
			svg = svg.concat(self.getTraitsSvg())
			svg = svg.concat("</svg>")
			return svg
		}
		
		access(all)
		fun getSvgNoBg(): String{ 
			var svg: String = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 3000 3000' width='100%' height='100%'>"
			svg = svg.concat(self.getTraitsSvg())
			svg = svg.concat("</svg>")
			return svg
		}
		
		access(all)
		fun getTraitsSvg(): String{ 
			var svg: String = ""
			let components:{ String: UInt64} = self.metadata.getComponents()
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
				return MetadataViews.ExternalURL("https://flovatar.com/flobots/".concat(self.id.toString()))
			}
			if view == Type<MetadataViews.Royalties>(){ 
				let royalties: [MetadataViews.Royalty] = []
				var count: Int = 0
				for royalty in self.royalties.royalty{ 
					royalties.append(MetadataViews.Royalty(receiver: royalty.wallet, cut: royalty.cut, description: "Flovatar Royalty ".concat(count.toString())))
					count = count + 1
				}
				return MetadataViews.Royalties(royalties)
			}
			if view == Type<MetadataViews.Serial>(){ 
				return MetadataViews.Serial(self.id)
			}
			if view == Type<MetadataViews.Editions>(){ 
				let editionInfo = MetadataViews.Edition(name: "Flobots", number: self.id, max: 9999)
				let editionList: [MetadataViews.Edition] = [editionInfo]
				return MetadataViews.Editions(editionList)
			}
			if view == Type<MetadataViews.NFTCollectionDisplay>(){ 
				let mediaSquare = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://images.flovatar.com/logo.svg"), mediaType: "image/svg+xml")
				let mediaBanner = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://images.flovatar.com/logo-horizontal.svg"), mediaType: "image/svg+xml")
				return MetadataViews.NFTCollectionDisplay(name: "Flovatar Flobot", description: "Flovatar is pioneering a new way to unleash community creativity in Web3 by allowing users to be co-creators of their prized NFTs, instead of just being passive collectors.", externalURL: MetadataViews.ExternalURL("https://flovatar.com"), squareImage: mediaSquare, bannerImage: mediaBanner, socials:{ "discord": MetadataViews.ExternalURL("https://discord.gg/flovatar"), "twitter": MetadataViews.ExternalURL("https://twitter.com/flovatar"), "instagram": MetadataViews.ExternalURL("https://instagram.com/flovatar_nft"), "tiktok": MetadataViews.ExternalURL("https://www.tiktok.com/@flovatar")})
			}
			if view == Type<MetadataViews.NFTCollectionData>(){ 
				return MetadataViews.NFTCollectionData(storagePath: Flobot.CollectionStoragePath, publicPath: Flobot.CollectionPublicPath, publicCollection: Type<&Flobot.Collection>(), publicLinkedType: Type<&Flobot.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
						return <-Flobot.createEmptyCollection(nftType: Type<@Flobot.Collection>())
					})
			}
			if view == Type<MetadataViews.Display>(){ 
				return MetadataViews.Display(name: self.name == "" ? "Flobot #".concat(self.id.toString()) : self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: "https://images.flovatar.com/flobot/svg/".concat(self.id.toString()).concat(".svg")))
			}
			if view == Type<MetadataViews.Traits>(){ 
				let traits: [MetadataViews.Trait] = []
				let components:{ String: UInt64} = self.metadata.getComponents()
				for k in components.keys{ 
					if let template = FlovatarComponentTemplate.getComponentTemplate(id: components[k]!){ 
						let trait = MetadataViews.Trait(name: k, value: template.name, displayType: "String", rarity: MetadataViews.Rarity(score: nil, max: nil, description: template.rarity))
						traits.append(trait)
					}
				}
				if let background = self.getBackground(){ 
					if let template = FlovatarComponentTemplate.getComponentTemplate(id: background){ 
						let trait = MetadataViews.Trait(name: template.category, value: template.name, displayType: "String", rarity: MetadataViews.Rarity(score: nil, max: nil, description: template.rarity))
						traits.append(trait)
					}
				}
				return MetadataViews.Traits(traits)
			}
			if view == Type<MetadataViews.Rarity>(){ 
				var score: UFix64 = 10.0
				if self.metadata.rarity == "legendary"{ 
					score = 100.0
				} else if self.metadata.rarity == "epic"{ 
					score = 50.0
				}
				return MetadataViews.Rarity(score: score, max: 100.0, description: nil)
			}
			if view == Type<MetadataViews.EVMBridgedMetadata>(){ 
				let contractLevel = Flobot.resolveContractView(
						resourceType: nil,
						viewType: Type<MetadataViews.EVMBridgedMetadata>()
					) as! MetadataViews.EVMBridgedMetadata?
					?? panic("Could not resolve contract-level EVMBridgedMetadata")
				
				return MetadataViews.EVMBridgedMetadata(
					name: contractLevel.name,
					symbol: contractLevel.symbol,
					uri: MetadataViews.URI(
						baseURI: "https://flovatar.com/flobots/json/",
						value: self.id.toString()
					)
				)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-Flobot.createEmptyCollection(nftType: Type<@Flobot.NFT>())
		}
	}
	
	// Standard NFT collectionPublic interface that can also borrowFlobot as the correct type
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowFlobot(id: UInt64): &Flobot.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Flobot reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Main Collection to manage all the Flobot NFT
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Collection { 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}

		/// getSupportedNFTTypes returns a list of NFT types that this receiver accepts
        access(all) 
		view fun getSupportedNFTTypes(): {Type: Bool} {
            let supportedTypes: {Type: Bool} = {}
            supportedTypes[Type<@Flobot.NFT>()] = true
            return supportedTypes
        }

        /// Returns whether or not the given type is accepted by the collection
        /// A collection that can accept any type should just return true by default
        access(all) 
		view fun isSupportedNFTType(type: Type): Bool {
            return type == Type<@Flobot.NFT>()
        }
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @Flobot.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			destroy oldToken
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all) view fun getLength(): Int {
			return self.ownedNFTs.length
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)
		}

		
		
		// borrowFlobot returns a borrowed reference to a Flobot
		// so that the caller can read data and call methods from it.
		access(all)
		fun borrowFlobot(id: UInt64): &Flobot.NFT?{ 
			if self.ownedNFTs[id] != nil {
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				let flobotNFT = ref as! &Flobot.NFT
				return flobotNFT
			} else {
				return nil
			}
		}
		
		/*
		// borrowFlobotPrivate returns a borrowed reference to a Flobot using the Private interface
		// so that the caller can read data and call methods from it, like setting the optional components.
		*/
		access(Flobot.PrivateEnt)
		fun borrowFlobotPrivate(id: UInt64): auth(Flobot.PrivateEnt) &Flobot.NFT?{
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as auth(Flobot.PrivateEnt) &{NonFungibleToken.NFT}?)!
				return ref as! auth(Flobot.PrivateEnt) &Flobot.NFT
			} else{ 
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
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-Flobot.createEmptyCollection(nftType: Type<@Flobot.NFT>())
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
                    publicCollection: Type<&Flobot.Collection>(),
                    publicLinkedType: Type<&Flobot.Collection>(),
                    createEmptyCollectionFunction: (fun(): @{NonFungibleToken.Collection} {
                        return <-Flobot.createEmptyCollection(nftType: Type<@Flobot.NFT>())
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
                    name: "Flovatar Flobot Collection",
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
                    name: "Flobot",
                    symbol: "XMPL",
                    uri: MetadataViews.URI(
                        baseURI: nil, // setting baseURI as nil sets the given value as the uri field value
                        value: "https://example-nft.onflow.org/contract-metadata.json"
                    )
                )
        }
        return nil
    }


	
	// This struct is used to send a data representation of the Flobots
	// when retrieved using the contract helper methods outside the collection.
	access(all)
	struct FlobotData{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let metadata: Flobot.Metadata
		
		access(all)
		let backgroundId: UInt64?
		
		access(all)
		let bio:{ String: String}
		
		init(id: UInt64, name: String, metadata: Flobot.Metadata, backgroundId: UInt64?, bio:{ String: String}){ 
			self.id = id
			self.name = name
			self.metadata = metadata
			self.backgroundId = backgroundId
			self.bio = bio
		}
	}
	
	// This function will look for a specific Flobot on a user account and return a FlobotData if found
	access(all)
	fun getFlobot(address: Address, flobotId: UInt64): FlobotData?{ 
		
		let account = getAccount(address)
		if let flobotCollection = account.capabilities.borrow<&Flobot.Collection>(Flobot.CollectionPublicPath){ 
			if let flobot = flobotCollection.borrowFlobot(id: flobotId){ 
				return FlobotData(id: flobotId, name: flobot.getName(), metadata: flobot.getMetadata(), backgroundId: flobot.getBackground(), bio: flobot.getBio())
			}
		}
		
		return nil
	}
	
	// This function will return all Flobots on a user account and return an array of FlobotData
	access(all)
	fun getFlobots(address: Address): [FlobotData]{ 
		var flobotData: [FlobotData] = []
		
		let account = getAccount(address)
		if let flobotCollection = account.capabilities.borrow<&Flobot.Collection>(Flobot.CollectionPublicPath){ 
			for id in flobotCollection.getIDs(){ 
				var flobot = flobotCollection.borrowFlobot(id: id)
				flobotData.append(FlobotData(id: id, name: (flobot!).getName(), metadata: (flobot!).getMetadata(), backgroundId: (flobot!).getBackground(), bio: (flobot!).getBio()))
			}
		}
		
		return flobotData
	}
	
	// This returns all the previously minted combinations, so that duplicates won't be allowed
	access(all)
	fun getMintedCombinations(): [String]{ 
		return Flobot.mintedCombinations.keys
	}
	
	// This returns all the previously minted names, so that duplicates won't be allowed
	access(all)
	fun getMintedNames(): [String]{ 
		return Flobot.mintedNames.keys
	}
	
	// This function will add a minted combination to the array
	access(account)
	fun addMintedCombination(combination: String){ 
		Flobot.mintedCombinations.insert(key: combination, true)
	}
	
	// This function will add a new name to the array
	access(account)
	fun addMintedName(name: String){ 
		Flobot.mintedNames.insert(key: name, true)
	}
	
	// This helper function will generate a string from a list of components,
	// to be used as a sort of barcode to keep the inventory of the minted
	// Flobots and to avoid duplicates
	access(all)
	fun getCombinationString(body: UInt64, head: UInt64, arms: UInt64, legs: UInt64, face: UInt64): String{ 
		return "B".concat(body.toString()).concat("H").concat(head.toString()).concat("A").concat(arms.toString()).concat("L").concat(legs.toString()).concat("F").concat(face.toString())
	}
	
	// This function will get a list of component IDs and will check if the
	// generated string is unique or if someone already used it before.
	access(all)
	fun checkCombinationAvailable(body: UInt64, head: UInt64, arms: UInt64, legs: UInt64, face: UInt64): Bool{ 
		let combinationString = Flobot.getCombinationString(body: body, head: head, arms: arms, legs: legs, face: face)
		return !Flobot.mintedCombinations.containsKey(combinationString)
	}
	
	// This will check if a specific Name has already been taken
	// and assigned to some Flobot
	access(all)
	fun checkNameAvailable(name: String): Bool{ 
		return name.length > 2 && name.length < 20 && !Flobot.mintedNames.containsKey(name)
	}
	
	// This is a public function that anyone can call to generate a new Flobot
	// A list of components resources needs to be passed to executed.
	// It will check first for uniqueness of the combination + name and will then
	// generate the Flobot and burn all the passed components.
	// The Spark NFT will entitle to use any common basic component (body, hair, etc.)
	// In order to use special rare components a boost of the same rarity will be needed
	// for each component used
	access(all)
	fun createFlobot(flobotkit: @[FlovatarComponent.NFT], body: UInt64, head: UInt64, arms: UInt64, legs: UInt64, face: UInt64, background: @FlovatarComponent.NFT?, address: Address): @Flobot.NFT{ 
		var i: Int = 0
		var flobotkitSeries: UInt32 = 0
		var flobotkitRarity: String = ""
		var checkFlobotRarity: Bool = false
		var checkFlobotSeries: Bool = false
		while i < flobotkit.length{ 
			if flobotkit[i].getCategory() != "flobotkit"{ 
				panic("The Flobot Kit belongs to the wrong category")
			}
			if flobotkit[i].getSeries() != 2 { 
				panic("The Flobot Kit doesn't belong to the correct series")
			}
			if flobotkitRarity != flobotkit[i].getRarity(){ 
				if flobotkitRarity != ""{ 
					checkFlobotRarity = true
				}
				flobotkitRarity = flobotkit[i].getRarity()
			}
			if flobotkitSeries != flobotkit[i].getSeries(){ 
				if flobotkitSeries != 0 { 
					checkFlobotSeries = true
				}
				flobotkitSeries = flobotkit[i].getSeries()
			}
			i = i + 1
		}
		if checkFlobotRarity{ 
			panic("The Flobot Kits need to belong to the same Rarity level")
		}
		if checkFlobotSeries{ 
			panic("The Flobot Kits need to belong to the same Series")
		}
		if flobotkit.length != 1 && flobotkit.length != 5{ 
			panic("You need to pass either 1 Flobot Kit or 5 of them to access the next rarity level")
		}
		if flobotkit.length == 5{ 
			if flobotkitRarity == "common"{ 
				flobotkitRarity = "epic"
			} else if flobotkitRarity == "epic"{ 
				flobotkitRarity = "legendary"
			} else{ 
				panic("Impossible to upgrade the Rarity level for the Flobot Kit")
			}
		}
		let bodyTemplate: FlovatarComponentTemplate.ComponentTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: body)!
		let headTemplate: FlovatarComponentTemplate.ComponentTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: head)!
		let armsTemplate: FlovatarComponentTemplate.ComponentTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: arms)!
		let legsTemplate: FlovatarComponentTemplate.ComponentTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: legs)!
		let faceTemplate: FlovatarComponentTemplate.ComponentTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: face)!
		
		// Make sure that all components belong to the correct category
		if bodyTemplate.category != "body"{ 
			panic("The body component belongs to the wrong category")
		}
		if headTemplate.category != "head"{ 
			panic("The head component belongs to the wrong category")
		}
		if armsTemplate.category != "arms"{ 
			panic("The arms component belongs to the wrong category")
		}
		if legsTemplate.category != "legs"{ 
			panic("The legs component belongs to the wrong category")
		}
		if faceTemplate.category != "face"{ 
			panic("The face component belongs to the wrong category")
		}
		
		// Make sure that all the components belong to the same series like the flobotkit
		if bodyTemplate.series != flobotkitSeries{ 
			panic("The body doesn't belong to the correct series")
		}
		if headTemplate.series != flobotkitSeries{ 
			panic("The head doesn't belong to the correct series")
		}
		if armsTemplate.series != flobotkitSeries{ 
			panic("The arms doesn't belong to the correct series")
		}
		if legsTemplate.series != flobotkitSeries{ 
			panic("The legs doesn't belong to the correct series")
		}
		if faceTemplate.series != flobotkitSeries{ 
			panic("The face doesn't belong to the correct series")
		}
		var flobotRarity: String = "common"
		if bodyTemplate.rarity == "rare"{ 
			flobotRarity = "rare"
		}
		if headTemplate.rarity == "rare"{ 
			flobotRarity = "rare"
		}
		if armsTemplate.rarity == "rare"{ 
			flobotRarity = "rare"
		}
		if legsTemplate.rarity == "rare"{ 
			flobotRarity = "rare"
		}
		if faceTemplate.rarity == "rare"{ 
			flobotRarity = "rare"
		}
		if bodyTemplate.rarity == "epic"{ 
			flobotRarity = "epic"
		}
		if headTemplate.rarity == "epic"{ 
			flobotRarity = "epic"
		}
		if armsTemplate.rarity == "epic"{ 
			flobotRarity = "epic"
		}
		if legsTemplate.rarity == "epic"{ 
			flobotRarity = "epic"
		}
		if faceTemplate.rarity == "epic"{ 
			flobotRarity = "epic"
		}
		if bodyTemplate.rarity == "legendary"{ 
			flobotRarity = "legendary"
		}
		if headTemplate.rarity == "legendary"{ 
			flobotRarity = "legendary"
		}
		if armsTemplate.rarity == "legendary"{ 
			flobotRarity = "legendary"
		}
		if legsTemplate.rarity == "legendary"{ 
			flobotRarity = "legendary"
		}
		if faceTemplate.rarity == "legendary"{ 
			flobotRarity = "legendary"
		}
		if background != nil{ 
			if background?.getSeries() != 1 && !background?.checkCategorySeries(category: "background", series: flobotkitSeries)!{ 
				panic("The background component belongs to the wrong category or the wrong series")
			}
		}
		if flobotRarity != flobotkitRarity{ 
			if flobotRarity == "rare" && flobotkitRarity == "common" || flobotRarity == "epic" && (flobotkitRarity == "common" || flobotkitRarity == "rare") || flobotRarity == "legendary" && (flobotkitRarity == "common" || flobotkitRarity == "rare" || flobotkitRarity == "epic"){ 
				panic("The Rarity of your Flobot Constructor Kit is not high enough")
			}
		}
		
		// Generates the combination string to check for uniqueness.
		// This is like a barcode that defines exactly which components were used
		// to create the Flobot
		let combinationString = Flobot.getCombinationString(body: body, head: head, arms: arms, legs: legs, face: face)
		
		// Makes sure that the combination is available and not taken already
		if Flobot.mintedCombinations.containsKey(combinationString) == true{ 
			panic("This combination has already been taken")
		}
		
		// Creates the metadata for the new Flobot
		let metadata = Metadata(mint: Flobot.totalSupply + 1, series: flobotkitSeries, combination: combinationString, rarity: flobotRarity, creatorAddress: address, components:{ "body": body, "head": head, "arms": arms, "legs": legs, "face": face})
		let royalties: [Royalty] = []
		let creatorAccount = getAccount(address)
		royalties.append(Royalty(wallet: creatorAccount.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver), cut: Flobot.getRoyaltyCut(), type: RoyaltyType.percentage))
		royalties.append(Royalty(wallet: self.account.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver), cut: Flobot.getMarketplaceCut(), type: RoyaltyType.percentage))
		
		// Mint the new Flobot NFT by passing the metadata to it
		var newNFT <- create NFT(metadata: metadata, royalties: Royalties(royalty: royalties))
		
		// Adds the combination to the arrays to remember it
		Flobot.addMintedCombination(combination: combinationString)
		
		// Checks for any additional optional component (accessory, hat,
		// eyeglasses, background) and assigns it to the Flobot if present.
		if background != nil{ 
			let temp <- newNFT.setBackground(component: <-background!)
			destroy temp
		} else{ 
			destroy background
		}
		
		// Emits the Created event to notify about its existence
		emit Created(id: newNFT.id, metadata: metadata)
		
		// Destroy all the flobotkit and the rarity boost since they are not needed anymore.
		destroy flobotkit
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
		
		// With this function you can generate a new Admin resource
		// and pass it to another user if needed
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
		
		// Helper functions to update the Royalty cut
		access(all)
		fun setRoyaltyCut(value: UFix64){ 
			Flobot.setRoyaltyCut(value: value)
		}
		
		// Helper functions to update the Marketplace cut
		access(all)
		fun setMarketplaceCut(value: UFix64){ 
			Flobot.setMarketplaceCut(value: value)
		}
	}
	
	init(){ 
		self.CollectionPublicPath = /public/FlobotCollection
		self.CollectionStoragePath = /storage/FlobotCollection
		self.AdminStoragePath = /storage/FlobotAdmin
		
		// Initialize the total supply
		self.totalSupply = 0
		self.mintedCombinations ={} 
		self.mintedNames ={} 
		
		// Set the default Royalty and Marketplace cuts
		self.royaltyCut = 0.01
		self.marketplaceCut = 0.05
		self.account.storage.save<@{NonFungibleToken.Collection}>(<-Flobot.createEmptyCollection(nftType: Type<@Flobot.Collection>()), to: Flobot.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&{Flobot.CollectionPublic}>(Flobot.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: Flobot.CollectionPublicPath)
		
		// Put the Admin resource in storage
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
