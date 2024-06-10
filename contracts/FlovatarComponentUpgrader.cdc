import "FungibleToken"
import "NonFungibleToken"
import "FlowToken"
import "FlovatarComponentTemplate"
import "FlovatarComponent"
import "FlovatarPack"
import "FlovatarDustToken"
import "FlovatarInbox"
import "Flovatar"

/*

 This contract provides the ability for users to upgrade their Flobits

 */

access(all)
contract FlovatarComponentUpgrader{ 
	
	// The withdrawEnabled will allow to put all withdraws on hold while the distribution of new airdrops is happening
	// So that everyone will be then be able to access his rewards at the same time
	access(account)
	var upgradeEnabled: Bool
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	// Event to notify about the Inbox creation
	access(all)
	event ContractInitialized()
	
	// Events to notify when Dust or Components are deposited or withdrawn
	access(all)
	event FlovatarComponentUpgraded(
		newId: UInt64,
		rarity: String,
		category: String,
		burnedIds: [
			UInt64
		]
	)
	
	//Randomize code gently provided by @bluesign
	access(all)
	struct RandomInt{ 
		access(self)
		var value: UInt64?
		
		access(self)
		let maxValue: UInt64
		
		access(self)
		let minValue: UInt64
		
		access(self)
		let field: String
		
		access(self)
		let uuid: UInt64
		
		access(all)
		init(uuid: UInt64, field: String, minValue: UInt64, maxValue: UInt64){ 
			self.uuid = uuid
			self.field = field
			self.minValue = minValue
			self.maxValue = maxValue
			self.value = nil
		}
		
		access(all)
		fun getValue(): UInt64{ 
			if let value = self.value{ 
				return value
			}
			let h: [UInt8] = HashAlgorithm.SHA3_256.hash(self.uuid.toBigEndianBytes())
			let f: [UInt8] = HashAlgorithm.SHA3_256.hash(self.field.utf8)
			var id = (getBlock(at: getCurrentBlock().height)!).id
			var random: UInt64 = 0
			var i = 0
			while i < 8{ 
				random = random + (UInt64(id[i]) ^ UInt64(h[i]) ^ UInt64(f[i]))
				random = random << 8
				i = i + 1
			}
			self.value = self.minValue + random % (self.maxValue - self.minValue)
			return self.minValue + random % (self.maxValue - self.minValue)
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun depositComponent(component: @FlovatarComponent.NFT)
	}
	
	// The main Collection that manages the Containers
	access(all)
	resource Collection: CollectionPublic{ 
		access(contract)
		let flovatarComponents: @{UInt64: FlovatarComponent.NFT}
		
		access(contract)
		let rarityLookup:{ UInt32:{ String:{ String:{ UInt64: UInt64}}}}
		
		init(){ 
			self.flovatarComponents <-{} 
			self.rarityLookup ={} 
		}
		
		access(all)
		fun depositComponent(component: @FlovatarComponent.NFT){ 
			if !self.rarityLookup.containsKey(component.getSeries()){ 
				self.rarityLookup.insert(key: component.getSeries(),{}  as{ String:{ String:{ UInt64: UInt64}}})
			}
			if !(self.rarityLookup[component.getSeries()]!).containsKey(component.getRarity()){ 
				(self.rarityLookup[component.getSeries()]!).insert(key: component.getRarity(),{}  as{ String:{ UInt64: UInt64}})
				((self.rarityLookup[component.getSeries()]!)[component.getRarity()]!).insert(key: "all",{}  as{ UInt64: UInt64})
			}
			if !((self.rarityLookup[component.getSeries()]!)[component.getRarity()]!).containsKey(component.getCategory()){ 
				((self.rarityLookup[component.getSeries()]!)[component.getRarity()]!).insert(key: component.getCategory(),{}  as{ UInt64: UInt64})
			}
			(((self.rarityLookup[component.getSeries()]!)[component.getRarity()]!)["all"]!).insert(key: component.id, component.id)
			(((self.rarityLookup[component.getSeries()]!)[component.getRarity()]!)[component.getCategory()]!).insert(key: component.id, component.id)
			let oldComponent <- self.flovatarComponents[component.id] <- component
			destroy oldComponent
		}
		
		access(all)
		fun withdrawComponent(id: UInt64): @FlovatarComponent.NFT{ 
			let component <- self.flovatarComponents.remove(key: id) ?? panic("missing NFT")
			(((self.rarityLookup[component.getSeries()]!)[component.getRarity()]!)["all"]!).remove(key: component.id)
			(((self.rarityLookup[component.getSeries()]!)[component.getRarity()]!)[component.getCategory()]!).remove(key: component.id)
			return <-component
		}
		
		access(all)
		fun withdrawRandomComponent(series: UInt32, rarity: String, category: String?): @FlovatarComponent.NFT{ 
			//FILTER BY SERIES AND RARITY AND THEN RANDOMIZE AND PICK ONE
			var components: [UInt64] = []
			if self.rarityLookup[series] == nil{ 
				panic("No Components found for the provided Series")
			}
			if (self.rarityLookup[series]!)[rarity] == nil{ 
				panic("No Components found for the provided Rarity")
			}
			if category != nil{ 
				if ((self.rarityLookup[series]!)[rarity]!)[category!] == nil{ 
					//panic("No Components found for the provided Category")
					components = (((self.rarityLookup[series]!)[rarity]!)["all"]!).keys
				} else{ 
					components = (((self.rarityLookup[series]!)[rarity]!)[category!]!).keys
				}
			} else{ 
				components = (((self.rarityLookup[series]!)[rarity]!)["all"]!).keys
			}
			if components.length < 1{ 
				panic("No Components found!")
			}
			let randInt: UInt64 = revertibleRandom<UInt64>()
			var fieldString: String = series.toString().concat(rarity)
			if category != nil{ 
				fieldString = fieldString.concat(category!)
			}
			if components.length == Int(1){ 
				let component <- self.withdrawComponent(id: components[UInt64(0)])
				return <-component
			}
			let randomPos: RandomInt = RandomInt(uuid: revertibleRandom<UInt64>(), field: fieldString, minValue: UInt64(0), maxValue: UInt64(components.length - Int(1)))
			let component <- self.withdrawComponent(id: components[randomPos.getValue()])
			return <-component
		}
		
		access(all)
		fun getComponentIDs(): [UInt64]{ 
			return self.flovatarComponents.keys
		}
	}
	
	// This function can only be called by the account owner to create an empty Collection
	access(account)
	fun createEmptyCollection(): @FlovatarComponentUpgrader.Collection{ 
		return <-create Collection()
	}
	
	// This function withdraws all the Components assigned to a Flovatar and sends them to the Owner's address
	access(all)
	fun upgradeFlovatarComponent(
		components: @[
			FlovatarComponent.NFT
		],
		vault: @{FungibleToken.Vault},
		address: Address
	){ 
		pre{ 
			self.upgradeEnabled:
				"Upgrade is not enabled!"
			vault.balance == 20.0:
				"The amount of $DUST is not correct"
			vault.isInstance(Type<@FlovatarDustToken.Vault>()):
				"Vault not of the right Token Type"
			components.length == 10:
				"You need to provide exactly 10 Flobits for the upgrade"
		}
		if let upgraderCollection =
			self.account.storage.borrow<&FlovatarComponentUpgrader.Collection>(
				from: self.CollectionStoragePath
			){ 
			var componentSeries: UInt32 = 0
			var checkCategory: Bool = true
			var componentCategory: String? = nil
			var componentRarity: String = ""
			var outputRarity: String = ""
			var i: UInt32 = 0
			while i < UInt32(components.length){ 
				let template = FlovatarComponentTemplate.getComponentTemplate(id: components[i].templateId)!
				if i == UInt32(0){ 
					componentSeries = template.series
					componentCategory = template.category
					componentRarity = template.rarity
				}
				if componentSeries != template.series{ 
					panic("All the Flovatar Components need to be belong to the same Series")
				}
				if componentRarity != template.rarity{ 
					panic("All the Flovatar Components need to be belong to the same Rarity Level")
				}
				if componentCategory != template.category{ 
					checkCategory = false
				}
				i = i + UInt32(1)
			}
			if componentRarity == "common"{ 
				outputRarity = "rare"
			} else if componentRarity == "rare"{ 
				outputRarity = "epic"
			} else if componentRarity == "epic"{ 
				outputRarity = "legendary"
			} else{ 
				panic("Rarity needs to be Common, Rare or Epic")
			}
			if !checkCategory{ 
				componentCategory = nil
			}
			//TODO Crescendo: Update self.account.Storage
			/* 
			let component <-
				upgraderCollection.withdrawRandomComponent(
					series: componentSeries,
					rarity: outputRarity,
					category: componentCategory
				)
			destroy components
			destroy vault
			if let inboxCollection =
				self.account.storage.borrow<&FlovatarInbox.Collection>(
					from: FlovatarInbox.CollectionStoragePath
				){ 
				inboxCollection.depositComponentToWallet(address: address, component: <-component)
			} else{ 
				panic("Couldn't borrow Flovatar Inbox Collection")
			}
			*/
			destroy components
			destroy vault
		} else{ 
			panic("Can't borrow the Upgrader Collection")
		}
	}
	
	// Admin function to temporarly enable or disable the airdrop and reward withdraw so that
	// we can distribute them to everyone at the same time
	access(account)
	fun setUpgradeEnable(enabled: Bool){ 
		self.upgradeEnabled = enabled
	}
	
	init(){ 
		self.upgradeEnabled = true
		self.CollectionPublicPath = /public/FlovatarComponentUpgraderCollection
		self.CollectionStoragePath = /storage/FlovatarComponentUpgraderCollection
		self.account.storage.save<@FlovatarComponentUpgrader.Collection>(
			<-FlovatarComponentUpgrader.createEmptyCollection(),
			to: FlovatarComponentUpgrader.CollectionStoragePath
		)
		var capability_1 =
			self.account.capabilities.storage.issue<&{FlovatarComponentUpgrader.CollectionPublic}>(
				FlovatarComponentUpgrader.CollectionStoragePath
			)
		self.account.capabilities.publish(
			capability_1,
			at: FlovatarComponentUpgrader.CollectionPublicPath
		)
		emit ContractInitialized()
	}
}
