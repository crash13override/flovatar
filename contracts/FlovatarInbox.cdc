import "FungibleToken"
import "NonFungibleToken"
import "FlowToken"
import "FlovatarComponentTemplate"
import "FlovatarComponent"
import "FlovatarPack"
import "FlovatarDustToken"
import "Flovatar"
import "HybridCustody"

/*

 This contract defines the Inbox for Flovatars and Flovatar owners where they can withdraw their
 airdrops and rewards and claim the daily DUST distributed for each Flovatar.

 This contract contains also the Admin resource that can be used to manage the different inboxes.

 The following inboxes are provided:
 - DUST reward vault for each Flovatar
 - Flobit (FlovatarComponent) airdrop/reward collection for each Flovatar
 - DUST reward vault for each Flovatar owner wallet
 - Flobit (FlovatarComponent) airdrop/reward collection for each Flovatar owner wallet
 - DUST for each Flovatar that can be claimed daily and that is coming from the Community Vault distribution

 */

access(all)
contract FlovatarInbox{

    access(all) entitlement Withdraw
	
	// The withdrawEnabled will allow to put all withdraws on hold while the distribution of new airdrops is happening
	// So that everyone will be then be able to access his rewards at the same time
	access(account)
	var withdrawEnabled: Bool
	
	//The communityVault holds the total of the DUST assigned to the community distribution over a period of 10 years
	access(account)
	let communityVault: @FlovatarDustToken.Vault
	
	//Stores the timestamp when Dust was first release and when the community distribution should start
	access(all)
	let dustDistributionStart: UFix64
	
	//Defines the amount of Dust to distribute to each Flovatar for each Rarity Score point
	access(all)
	var dustPerDayPerScore: UFix64
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	// Event to notify about the Inbox creation
	access(all)
	event ContractInitialized()
	
	// Events to notify when Dust or Components are deposited or withdrawn
	access(all)
	event FlovatarDepositComponent(flovatarId: UInt64, componentId: UInt64)
	
	access(all)
	event FlovatarDepositDust(id: UInt64, amount: UFix64)
	
	access(all)
	event FlovatarWithdrawComponent(flovatarId: UInt64, componentId: UInt64, to: Address)
	
	access(all)
	event FlovatarWithdrawDust(id: UInt64, amount: UFix64, to: Address)
	
	access(all)
	event WalletDepositComponent(address: Address, componentId: UInt64)
	
	access(all)
	event WalletDepositDust(address: Address, amount: UFix64)
	
	access(all)
	event WalletWithdrawComponent(address: Address, componentId: UInt64)
	
	access(all)
	event WalletWithdrawDust(address: Address, amount: UFix64)
	
	access(all)
	event FlovatarClaimedCommunityDust(id: UInt64, amount: UFix64, to: Address)
	
	// This struct contains all the information about the Dust the be claimed for each Flovatar by the user
	access(all)
	struct ClaimableDust{ 
		access(all)
		let amount: UFix64
		
		access(all)
		let days: UInt64
		
		access(all)
		let rarityScore: UFix64
		
		access(all)
		let flovatarId: UInt64
		
		access(all)
		let wallet: Address
		
		init(
			amount: UFix64,
			days: UInt64,
			rarityScore: UFix64,
			flovatarId: UInt64,
			wallet: Address
		){ 
			self.amount = amount
			self.days = days
			self.rarityScore = rarityScore
			self.flovatarId = flovatarId
			self.wallet = wallet
		}
	}
	
	// The Container resounce holds both the FlovatarComponent Dictionary and the DUST Vault
	access(all)
	resource Container{ 
		access(contract)
		let dustVault: @FlovatarDustToken.Vault
		
		access(contract)
		let flovatarComponents: @{UInt64: FlovatarComponent.NFT}
		
		access(self)
		var blockHeight: UInt64
		
		// Initialize a Template with all the necessary data
		init(){ 
			self.dustVault <- FlovatarDustToken.createEmptyDustVault()
			self.flovatarComponents <-{} 
			self.blockHeight = getCurrentBlock().height
		}
		
		access(all)
		fun insertComponent(component: @FlovatarComponent.NFT){ 
			let oldComponent <- self.flovatarComponents[component.id] <- component
			destroy oldComponent
			self.blockHeight = getCurrentBlock().height
		}
		
		access(all)
		fun withdrawComponent(id: UInt64): @FlovatarComponent.NFT{ 
			pre{ 
				self.blockHeight <= getCurrentBlock().height:
					"You need to wait at least one Block to withdraw the NFT"
			}
			let token <- self.flovatarComponents.remove(key: id) ?? panic("missing NFT")
			return <-token
		}

		access(all)
		fun withdrawDust(amount: UFix64): @{FungibleToken.Vault}{ 
			return <-self.dustVault.withdraw(amount: amount)
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun depositDustToFlovatar(id: UInt64, vault: @{FungibleToken.Vault})
		
		access(all)
		fun depositDustToWallet(address: Address, vault: @{FungibleToken.Vault})
		
		access(all)
		fun depositComponentToFlovatar(id: UInt64, component: @FlovatarComponent.NFT)
		
		access(all)
		fun depositComponentToWallet(address: Address, component: @FlovatarComponent.NFT)
		
		access(all)
		fun getFlovatarDustBalance(id: UInt64): UFix64
		
		access(all)
		fun getWalletDustBalance(address: Address): UFix64
		
		access(all)
		fun getFlovatarComponentIDs(id: UInt64): [UInt64]
		
		access(all)
		fun getWalletComponentIDs(address: Address): [UInt64]
		
		access(all)
		fun getLastClaimedDust(id: UInt64): UFix64
	}
	
	// The main Collection that manages the Containers
	access(all)
	resource Collection: CollectionPublic{ 
		
		// Dictionary of Containers for the Flovatars and the Flovatar Owners Wallets
		access(all)
		var flovatarContainers: @{UInt64: FlovatarInbox.Container}
		
		access(all)
		var walletContainers: @{Address: FlovatarInbox.Container}
		
		// Dictionary to remember the last time that DUST was claimed by each Flovatar
		// so that it can calculate the right amount to be claimable
		access(all)
		var lastClaimedDust:{ UInt64: UFix64}
		
		init(){ 
			self.flovatarContainers <-{} 
			self.walletContainers <-{} 
			self.lastClaimedDust ={} 
		}
		
		// Borrows the Container Collection for the Flovatar and if not present it initializes it
		access(all)
		fun borrowFlovatarContainer(id: UInt64): &FlovatarInbox.Container{ 
			if self.flovatarContainers[id] == nil{ 
				let oldContainer <- self.flovatarContainers[id] <- create Container()
				destroy oldContainer
			}
			return (&self.flovatarContainers[id] as &FlovatarInbox.Container?)!
		}
		
		// Borrows the Container Collection for the Flovatar Owner Wallet and if not present it initializes it
		access(all)
		fun borrowWalletContainer(address: Address): &FlovatarInbox.Container{ 
			if self.walletContainers[address] == nil{ 
				let oldContainer <- self.walletContainers[address] <- create Container()
				destroy oldContainer
			}
			return (&self.walletContainers[address] as &FlovatarInbox.Container?)!
		}
		
		access(all)
		fun depositDustToFlovatar(id: UInt64, vault: @{FungibleToken.Vault}){ 
			pre{ 
				vault.isInstance(Type<@FlovatarDustToken.Vault>()):
					"Vault not of the right Token Type"
			}
			let ref = self.borrowFlovatarContainer(id: id)
			emit FlovatarDepositDust(id: id, amount: vault.balance)
			ref.dustVault.deposit(from: <-vault)
		}
		
		access(all)
		fun depositDustToWallet(address: Address, vault: @{FungibleToken.Vault}){ 
			pre{ 
				vault.isInstance(Type<@FlovatarDustToken.Vault>()):
					"Vault not of the right Token Type"
			}
			let ref = self.borrowWalletContainer(address: address)
			emit WalletDepositDust(address: address, amount: vault.balance)
			ref.dustVault.deposit(from: <-vault)
		}
		
		access(all)
		fun depositComponentToFlovatar(id: UInt64, component: @FlovatarComponent.NFT){ 
			let ref = self.borrowFlovatarContainer(id: id)
			emit FlovatarDepositComponent(flovatarId: id, componentId: component.id)
			ref.insertComponent(component: <-component)
		}
		
		access(all)
		fun depositComponentToWallet(address: Address, component: @FlovatarComponent.NFT){ 
			let ref = self.borrowWalletContainer(address: address)
			emit WalletDepositComponent(address: address, componentId: component.id)
			ref.insertComponent(component: <-component)
		}
		
		access(all)
		fun getFlovatarDustBalance(id: UInt64): UFix64{ 
			let ref = self.borrowFlovatarContainer(id: id)
			return ref.dustVault.balance
		}
		
		access(all)
		fun getWalletDustBalance(address: Address): UFix64{ 
			let ref = self.borrowWalletContainer(address: address)
			return ref.dustVault.balance
		}
		
		access(all)
		fun getFlovatarComponentIDs(id: UInt64): [UInt64]{ 
			let ref = self.borrowFlovatarContainer(id: id)
			return *ref.flovatarComponents.keys
		}
		
		access(all)
		fun getWalletComponentIDs(address: Address): [UInt64]{ 
			let ref = self.borrowWalletContainer(address: address)
			return *ref.flovatarComponents.keys
		}
		
		access(all)
		fun getLastClaimedDust(id: UInt64): UFix64{ 
			if self.lastClaimedDust[id] == nil{ 
				self.lastClaimedDust[id] = FlovatarInbox.dustDistributionStart
			}
			return self.lastClaimedDust[id]!
		}
		
		access(contract)
		fun setLastClaimedDust(id: UInt64, value: UFix64){ 
			self.lastClaimedDust[id] = value
		}
		
		access(Withdraw)
		fun withdrawFlovatarComponent(id: UInt64, withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let ref = self.borrowFlovatarContainer(id: id)
			return <-ref.withdrawComponent(id: withdrawID)
		}
		
		access(Withdraw)
		fun withdrawWalletComponent(address: Address, withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let ref = self.borrowWalletContainer(address: address)
			return <-ref.withdrawComponent(id: withdrawID)
		}
		
		access(Withdraw)
		fun withdrawFlovatarDust(id: UInt64): @{FungibleToken.Vault}{ 
			let ref = self.borrowFlovatarContainer(id: id)
			return <-ref.withdrawDust(amount: ref.dustVault.balance)
		}
		
		access(Withdraw)
		fun withdrawWalletDust(address: Address): @{FungibleToken.Vault}{ 
			let ref = self.borrowWalletContainer(address: address)
			return <-ref.withdrawDust(amount: ref.dustVault.balance)
		}
	}
	
	// This function can only be called by the account owner to create an empty Collection
	access(account)
	fun createEmptyCollection(): @FlovatarInbox.Collection{ 
		return <-create Collection()
	}
	
	// Returns the amount of DUST received by the Flovatar for additional rewards or activities (not coming from the Community pool)
	access(all)
	fun getFlovatarDustBalance(id: UInt64): UFix64{ 
		if let inboxCollection = self.account.capabilities.borrow<&FlovatarInbox.Collection>(FlovatarInbox.CollectionPublicPath){ 
			return inboxCollection.getFlovatarDustBalance(id: id)
		}
		 
		return 0.0
	}
	
	// Returns the amount of DUST received by the Flovatar Owner for additional rewards or activities (not coming from the Community pool)
	access(all)
	fun getWalletDustBalance(address: Address): UFix64{ 
		
		if let inboxCollection = self.account.capabilities.borrow<&FlovatarInbox.Collection>(FlovatarInbox.CollectionPublicPath){ 
			return inboxCollection.getWalletDustBalance(address: address)
		}
		
		return 0.0
	}
	
	// Returns the IDs of the Components (Flobits) received by the Flovatar
	access(all)
	fun getFlovatarComponentIDs(id: UInt64): [UInt64]{ 
		
		if let inboxCollection = self.account.capabilities.borrow<auth(Withdraw) &FlovatarInbox.Collection>(FlovatarInbox.CollectionPublicPath){ 
			return inboxCollection.getFlovatarComponentIDs(id: id)
		}
		
		return []
	}
	
	// Returns the IDs of the Components (Flobits) received by the Flovatar Owner
	access(all)
	fun getWalletComponentIDs(address: Address): [UInt64]{ 
		
		if let inboxCollection = self.account.capabilities.borrow<&FlovatarInbox.Collection>(FlovatarInbox.CollectionPublicPath){ 
			return inboxCollection.getWalletComponentIDs(address: address)
		}
		
		return []
	}
	
	// This function withdraws all the Components assigned to a Flovatar and sends them to the Owner's address
	access(all)
	fun withdrawFlovatarComponent(id: UInt64, address: Address){ 
		pre{ 
			self.withdrawEnabled:
				"Withdrawal is not enabled!"
		}
		if let inboxCollection =
			self.account.storage.borrow<auth(Withdraw) &FlovatarInbox.Collection>(
				from: self.CollectionStoragePath
			){ 
			if let flovatar = Flovatar.getFlovatar(address: address, flovatarId: id){ 
				let receiverAccount = getAccount(address)
				let flovatarComponentReceiverCollection = receiverAccount.capabilities.get<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath)
				var i: UInt32 = 0
				let componentIds = self.getFlovatarComponentIDs(id: id)
				
				//set a max of 50 Components to be withdrawn to avoid gas limits
				while i < UInt32(componentIds.length) && i < UInt32(50){ 
					let component <- inboxCollection.withdrawFlovatarComponent(id: id, withdrawID: componentIds[i])
					if component == nil{ 
						panic("Component not found!")
					}
					(flovatarComponentReceiverCollection.borrow()!).deposit(token: <-component)
					emit FlovatarWithdrawComponent(flovatarId: id, componentId: componentIds[i], to: address)
					i = i + UInt32(1)
				}
			}
		}
	}
	
	// This function withdraws all the Components assigned to a Flovatar Owner and sends them to his address
	access(all)
	fun withdrawWalletComponent(address: Address){ 
		pre{ 
			self.withdrawEnabled:
				"Withdrawal is not enabled!"
		}
		if let inboxCollection =
			self.account.storage.borrow<auth(Withdraw) &FlovatarInbox.Collection>(
				from: self.CollectionStoragePath
			){ 
			let receiverAccount = getAccount(address)
			let flovatarComponentReceiverCollection =
				receiverAccount.capabilities.get<&{FlovatarComponent.CollectionPublic}>(
					FlovatarComponent.CollectionPublicPath
				)
			var i: UInt32 = 0
			let componentIds = self.getWalletComponentIDs(address: address)
			
			//set a max of 50 Components to be withdrawn to avoid gas limits
			while i < UInt32(componentIds.length) && i < UInt32(50){ 
				let component <- inboxCollection.withdrawWalletComponent(address: address, withdrawID: componentIds[i])
				if component == nil{ 
					panic("Component not found!")
				}
				(flovatarComponentReceiverCollection.borrow()!).deposit(token: <-component)
				emit WalletWithdrawComponent(address: address, componentId: componentIds[i])
				i = i + UInt32(1)
			}
		}
	}
	
	// This function withdraws all the DUST assigned to a Flovatar (not from general community pool) and sends it to the Owner's vault
	access(all)
	fun withdrawFlovatarDust(id: UInt64, address: Address){ 
		pre{ 
			self.withdrawEnabled:
				"Withdrawal is not enabled!"
		}
		if let inboxCollection =
			self.account.storage.borrow<auth(Withdraw) &FlovatarInbox.Collection>(
				from: self.CollectionStoragePath
			){ 
			if let flovatar = Flovatar.getFlovatar(address: address, flovatarId: id){ 
				let receiverAccount = getAccount(address)
				let receiverRef = (receiverAccount.capabilities.get<&{FungibleToken.Receiver}>(FlovatarDustToken.VaultReceiverPath)!).borrow() ?? panic("Could not borrow receiver reference to the recipient's Vault")
				let vault <- inboxCollection.withdrawFlovatarDust(id: id)
				emit FlovatarWithdrawDust(id: id, amount: vault.balance, to: address)
				receiverRef.deposit(from: <-vault)
			}
		}
	}
	
	// This function withdraws all the DUST assigned to a Flovatar Owner (not from general community pool) and sends it to his vault
	access(all)
	fun withdrawWalletDust(address: Address){ 
		pre{ 
			self.withdrawEnabled:
				"Withdrawal is not enabled!"
		}
		if let inboxCollection =
			self.account.storage.borrow<auth(Withdraw) &FlovatarInbox.Collection>(
				from: self.CollectionStoragePath
			){ 
			let receiverAccount = getAccount(address)
			let receiverRef =
				(
					receiverAccount.capabilities.get<&{FungibleToken.Receiver}>(
						FlovatarDustToken.VaultReceiverPath
					)!
				).borrow()
				?? panic("Could not borrow receiver reference to the recipient's Vault")
			let vault <- inboxCollection.withdrawWalletDust(address: address)
			emit WalletWithdrawDust(address: address, amount: vault.balance)
			receiverRef.deposit(from: <-vault)
		}
	}
	
	// Returns the amount of DUST available and yet to be distributed to the community
	access(all)
	fun getCommunityDustBalance(): UFix64{ 
		return self.communityVault.balance
	}
	
	// Calculates how much DUST a Flovatar should be able to claim based on
	// his rarity score and on the amount of days passed since the last completed claim
	access(all)
	fun getClaimableFlovatarCommunityDust(id: UInt64, address: Address): ClaimableDust?{ 

		if let flovatarScore: UFix64 =
			Flovatar.getFlovatarRarityScore(address: address, flovatarId: id){ 
			
			if let inboxCollection = self.account.capabilities.borrow<&FlovatarInbox.Collection>(FlovatarInbox.CollectionPublicPath){ 
				let lastClaimed: UFix64 = inboxCollection.getLastClaimedDust(id: id)
				let currentTime: UFix64 = getCurrentBlock().timestamp
				let timeDiff: UFix64 = currentTime - lastClaimed
				let dayLength: UFix64 = 86400.0
				if timeDiff > dayLength{ 
					let daysDiff: UInt64 = UInt64(timeDiff / dayLength)
					return ClaimableDust(amount: UFix64(daysDiff) * (3.0 + flovatarScore) * FlovatarInbox.dustPerDayPerScore, days: daysDiff, rarityScore: flovatarScore, flovatarId: id, wallet: address)
				}
			}
		}
		return nil
	}
	
	// Internal function to update the timestamp of the last time DUST were claimed for a specific Flovatar
	access(self)
	fun setLastClaimedDust(id: UInt64, days: UInt64){ 
		if let inboxCollection =
			self.account.storage.borrow<&FlovatarInbox.Collection>(
				from: self.CollectionStoragePath
			){ 
			let lastClaimed: UFix64 = inboxCollection.getLastClaimedDust(id: id)
			inboxCollection.setLastClaimedDust(id: id, value: lastClaimed + UFix64(days * 86400))
		}
	}
	
	// This function will allow any Flovatar to claim his share of the daily distribution of DUST from the community pool
	access(all)
	fun claimFlovatarCommunityDust(id: UInt64, address: Address){ 
		pre{ 
			self.withdrawEnabled:
				"Withdrawal is not enabled!"
		}
		if let claimableDust: ClaimableDust =
			self.getClaimableFlovatarCommunityDust(id: id, address: address){ 
			if claimableDust.amount > self.communityVault.balance{ 
				panic("Not enough community DUST left to be claimed")
			}
			if claimableDust.amount > UFix64(0.0){ 
				let receiverAccount = getAccount(address)
				let receiverRef = (receiverAccount.capabilities.get<&{FungibleToken.Receiver}>(FlovatarDustToken.VaultReceiverPath)!).borrow() ?? panic("Could not borrow receiver reference to the recipient's Vault")
				let vault <- self.communityVault.withdraw(amount: claimableDust.amount)
				self.setLastClaimedDust(id: id, days: claimableDust.days)
				emit FlovatarClaimedCommunityDust(id: id, amount: vault.balance, to: address)
				receiverRef.deposit(from: <-vault)
			}
		}
	}
	
	access(all)
	fun claimFlovatarCommunityDustFromChild(id: UInt64, parent: Address, child: Address){ 

		pre{ 
			self.withdrawEnabled:
				"Withdrawal is not enabled!"
		}
		if parent == child{ 
			self.claimFlovatarCommunityDust(id: id, address: parent)
			return
		}
		let manager =
			getAccount(parent).capabilities.get<&HybridCustody.Manager>(
				HybridCustody.ManagerPublicPath
			).borrow()
			?? panic("parent account does not have a hybrid custody manager")
		assert(
			manager.borrowAccountPublic(addr: child) != nil,
			message: "parent does not have supplied child account"
		)
		if let claimableDust: ClaimableDust =
			self.getClaimableFlovatarCommunityDust(id: id, address: child){ 
			if claimableDust.amount > self.communityVault.balance{ 
				panic("Not enough community DUST left to be claimed")
			}
			if claimableDust.amount > 0.0{ 
				let receiverAccount = getAccount(parent)
				let receiverRef = (receiverAccount.capabilities.get<&{FungibleToken.Receiver}>(FlovatarDustToken.VaultReceiverPath)!).borrow() ?? panic("Could not borrow receiver reference to the recipient's Vault")
				let vault <- self.communityVault.withdraw(amount: claimableDust.amount)
				self.setLastClaimedDust(id: id, days: claimableDust.days)
				
				// TODO: not sure who the `to` address should be, here.
				emit FlovatarClaimedCommunityDust(id: id, amount: vault.balance, to: parent)
				receiverRef.deposit(from: <-vault)
			}
		}
		
	}
	
	// Admin function to temporarly enable or disable the airdrop and reward withdraw so that
	// we can distribute them to everyone at the same time
	access(account)
	fun setWithdrawEnable(enabled: Bool){ 
		self.withdrawEnabled = enabled
	}
	
	// Admin function to deposit DUST into the community pool
	access(all)
	fun depositCommunityDust(vault: @{FungibleToken.Vault}){ 
		pre{ 
			vault.isInstance(Type<@FlovatarDustToken.Vault>()):
				"Vault not of the right Token Type"
		}
		self.communityVault.deposit(from: <-vault)
	}
	
	// Returns the multiplier used to calculate the amount of DUST to distribute for each Rarity Score point per day for each Flovatar
	access(all)
	fun getDustPerDayPerScore(): UFix64{ 
		return self.dustPerDayPerScore
	}
	
	// Admin function to allow potential adjustments for the distribution speed of the community DUST
	access(account)
	fun setDustPerDayPerScore(value: UFix64){ 
		self.dustPerDayPerScore = value
	}
	
	// This is the main Admin resource that will allow the owner
	// to manage the Inbox
	access(all)
	resource Admin{ 
		access(all)
		fun setDustPerDayPerScore(value: UFix64){ 
			FlovatarInbox.setDustPerDayPerScore(value: value)
		}
		
		access(all)
		fun setWithdrawEnable(enabled: Bool){ 
			FlovatarInbox.setWithdrawEnable(enabled: enabled)
		}
		
		// With this function you can generate a new Admin resource
		// and pass it to another user if needed
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	init(){ 
		self.withdrawEnabled = true
		self.communityVault <- FlovatarDustToken.createEmptyDustVault()
			
		self.dustDistributionStart = getCurrentBlock().timestamp - UFix64(86400)
		self.dustPerDayPerScore = 0.91447
		self.CollectionPublicPath = /public/FlovatarInboxCollection
		self.CollectionStoragePath = /storage/FlovatarInboxCollection
		self.account.storage.save<@FlovatarInbox.Collection>(
			<-FlovatarInbox.createEmptyCollection(),
			to: FlovatarInbox.CollectionStoragePath
		)
		var capability_1 =
			self.account.capabilities.storage.issue<&{FlovatarInbox.CollectionPublic}>(
				FlovatarInbox.CollectionStoragePath
			)
		self.account.capabilities.publish(capability_1, at: FlovatarInbox.CollectionPublicPath)
		
		// Put the Admin resource in storage
		self.account.storage.save<@Admin>(<-create Admin(), to: /storage/FlovatarInboxAdmin)
		emit ContractInitialized()
	}
}
