//import FungibleToken from 0xf233dcee88fe0abe
//import NonFungibleToken from 0x1d7e57aa55817448
//import FlowToken from 0x1654653399040a61
//import FlovatarComponentTemplate from 0x921ea449dffec68a
//import FlovatarComponent from 0x921ea449dffec68a
//import FlovatarPack from 0x921ea449dffec68a
//import FlovatarDustToken from 0x921ea449dffec68a
//import Flovatar from 0x921ea449dffec68a
import FungibleToken from "./FungibleToken.cdc"
import NonFungibleToken from "./NonFungibleToken.cdc"
import FlowToken from "./FlowToken.cdc"
import FlovatarComponentTemplate from "./FlovatarComponentTemplate.cdc"
import FlovatarComponent from "./FlovatarComponent.cdc"
import FlovatarPack from "./FlovatarPack.cdc"
import FlovatarDustToken from "./FlovatarDustToken.cdc"
import Flovatar from "./Flovatar.cdc"

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

pub contract FlovatarInbox {

    // The withdrawEnabled will allow to put all withdraws on hold while the distribution of new airdrops is happening
    // So that everyone will be then be able to access his rewards at the same time
    access(account) var withdrawEnabled: Bool

    //The communityVault holds the total of the DUST assigned to the community distribution over a period of 10 years
    access(account) let communityVault: @FlovatarDustToken.Vault

    //Stores the timestamp when Dust was first release and when the community distribution should start
    pub let dustDistributionStart: UFix64

    //Defines the amount of Dust to distribute to each Flovatar for each Rarity Score point
    pub var dustPerDayPerScore: UFix64

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath

    // Event to notify about the Inbox creation
    pub event ContractInitialized()

    // Events to notify when Dust or Components are deposited or withdrawn
    pub event FlovatarDepositComponent(flovatarId: UInt64, componentId: UInt64)
    pub event FlovatarDepositDust(id: UInt64, amount: UFix64)
    pub event FlovatarWithdrawComponent(flovatarId: UInt64, componentId: UInt64, to: Address)
    pub event FlovatarWithdrawDust(id: UInt64, amount: UFix64, to: Address)
    pub event WalletDepositComponent(address: Address, componentId: UInt64)
    pub event WalletDepositDust(address: Address, amount: UFix64)
    pub event WalletWithdrawComponent(address: Address, componentId: UInt64)
    pub event WalletWithdrawDust(address: Address, amount: UFix64)
    pub event FlovatarClaimedCommunityDust(id: UInt64, amount: UFix64, to: Address)

    // This struct contains all the information about the Dust the be claimed for each Flovatar by the user
    pub struct ClaimableDust{
        pub let amount: UFix64
        pub let days: UInt64
        pub let rarityScore: UFix64
        pub let flovatarId: UInt64
        pub let wallet: Address


        init(amount: UFix64, days: UInt64, rarityScore: UFix64, flovatarId: UInt64, wallet: Address){
            self.amount = amount
            self.days = days
            self.rarityScore = rarityScore
            self.flovatarId = flovatarId
            self.wallet = wallet
        }
    }

    // The Container resounce holds both the FlovatarComponent Dictionary and the DUST Vault
    pub resource Container {
        access(contract) let dustVault: @FlovatarDustToken.Vault
        access(contract) let flovatarComponents: @{UInt64: FlovatarComponent.NFT}
        access(self) var blockHeight : UInt64

        // Initialize a Template with all the necessary data
        init() {
            self.dustVault <- FlovatarDustToken.createEmptyVault()
            self.flovatarComponents <- {}
            self.blockHeight = getCurrentBlock().height
        }

        pub fun insertComponent(component: @FlovatarComponent.NFT) {
            let oldComponent <- self.flovatarComponents[component.id] <- component
            destroy oldComponent
            self.blockHeight = getCurrentBlock().height
        }

        pub fun withdrawComponent(id: UInt64) : @FlovatarComponent.NFT{
            pre{
                self.blockHeight <= getCurrentBlock().height : "You need to wait at least one Block to withdraw the NFT"
            }
            let token <- self.flovatarComponents.remove(key: id) ?? panic("missing NFT")
            return <- token
        }

        destroy(){
            destroy self.dustVault
            destroy self.flovatarComponents
        }
    }


    pub resource interface CollectionPublic {
        pub fun depositDustToFlovatar(id: UInt64, vault: @FlovatarDustToken.Vault)
        pub fun depositDustToWallet(address: Address, vault: @FlovatarDustToken.Vault)
        pub fun depositComponentToFlovatar(id: UInt64, component: @FlovatarComponent.NFT)
        pub fun depositComponentToWallet(address: Address, component: @FlovatarComponent.NFT)
        pub fun getFlovatarDustBalance(id: UInt64): UFix64
        pub fun getWalletDustBalance(address: Address): UFix64
        pub fun getFlovatarComponentIDs(id: UInt64): [UInt64]
        pub fun getWalletComponentIDs(address: Address): [UInt64]
        pub fun getLastClaimedDust(id: UInt64): UFix64
    }

    // The main Collection that manages the Containers
    pub resource Collection: CollectionPublic {

        // Dictionary of Containers for the Flovatars and the Flovatar Owners Wallets
        pub var flovatarContainers: @{UInt64: FlovatarInbox.Container}
        pub var walletContainers: @{Address: FlovatarInbox.Container}

        // Dictionary to remember the last time that DUST was claimed by each Flovatar
        // so that it can calculate the right amount to be claimable
        pub var lastClaimedDust: {UInt64: UFix64}

        init () {
            self.flovatarContainers <- {}
            self.walletContainers <- {}
            self.lastClaimedDust = {}
        }

        // Borrows the Container Collection for the Flovatar and if not present it initializes it
        pub fun borrowFlovatarContainer(id: UInt64): &FlovatarInbox.Container {
            if self.flovatarContainers[id] == nil {
                let oldContainer <- self.flovatarContainers[id] <- create Container()
                destroy oldContainer
            }
            return (&self.flovatarContainers[id] as auth &FlovatarInbox.Container?)!
        }

        // Borrows the Container Collection for the Flovatar Owner Wallet and if not present it initializes it
        pub fun borrowWalletContainer(address: Address): &FlovatarInbox.Container {
            if self.walletContainers[address] == nil {
                let oldContainer <- self.walletContainers[address] <- create Container()
                destroy oldContainer
            }
            return (&self.walletContainers[address] as auth &FlovatarInbox.Container?)!
        }

        pub fun depositDustToFlovatar(id: UInt64, vault: @FlovatarDustToken.Vault) {
            let ref = self.borrowFlovatarContainer(id: id)
            emit FlovatarDepositDust(id: id, amount: vault.balance)
            ref.dustVault.deposit(from: <- vault)
        }

        pub fun depositDustToWallet(address: Address, vault: @FlovatarDustToken.Vault) {
            let ref = self.borrowWalletContainer(address: address)
            emit WalletDepositDust(address: address, amount: vault.balance)
            ref.dustVault.deposit(from: <- vault)
        }

        pub fun depositComponentToFlovatar(id: UInt64, component: @FlovatarComponent.NFT) {
            let ref = self.borrowFlovatarContainer(id: id)
            emit FlovatarDepositComponent(flovatarId: id, componentId: component.id)
            ref.insertComponent(component: <- component)
        }

        pub fun depositComponentToWallet(address: Address, component: @FlovatarComponent.NFT) {
            let ref = self.borrowWalletContainer(address: address)
            emit WalletDepositComponent(address: address, componentId: component.id)
            ref.insertComponent(component: <- component)
        }

        pub fun getFlovatarDustBalance(id: UInt64): UFix64 {
            let ref = self.borrowFlovatarContainer(id: id)
            return ref.dustVault.balance
        }

        pub fun getWalletDustBalance(address: Address): UFix64 {
            let ref = self.borrowWalletContainer(address: address)
            return ref.dustVault.balance
        }

        pub fun getFlovatarComponentIDs(id: UInt64): [UInt64] {
            let ref = self.borrowFlovatarContainer(id: id)
            return ref.flovatarComponents.keys
        }
        pub fun getWalletComponentIDs(address: Address): [UInt64] {
            let ref = self.borrowWalletContainer(address: address)
            return ref.flovatarComponents.keys
        }

        pub fun getLastClaimedDust(id: UInt64): UFix64{
            if self.lastClaimedDust[id] == nil {
                self.lastClaimedDust[id] = FlovatarInbox.dustDistributionStart
            }
            return self.lastClaimedDust[id]!
        }

        access(contract) fun setLastClaimedDust(id: UInt64, value: UFix64){
            self.lastClaimedDust[id] = value
        }

        pub fun withdrawFlovatarComponent(id: UInt64, withdrawID: UInt64): @NonFungibleToken.NFT {
            let ref = self.borrowFlovatarContainer(id: id)
            return <- ref.withdrawComponent(id: withdrawID)
        }
        pub fun withdrawWalletComponent(address: Address, withdrawID: UInt64): @NonFungibleToken.NFT {
            let ref = self.borrowWalletContainer(address: address)
            return <- ref.withdrawComponent(id: withdrawID)
        }

        pub fun withdrawFlovatarDust(id: UInt64): @FungibleToken.Vault {
            let ref = self.borrowFlovatarContainer(id: id)
            return <- ref.dustVault.withdraw(amount: ref.dustVault.balance)
        }
        pub fun withdrawWalletDust(address: Address): @FungibleToken.Vault {
            let ref = self.borrowWalletContainer(address: address)
            return <- ref.dustVault.withdraw(amount: ref.dustVault.balance)
        }

        destroy() {
            destroy self.flovatarContainers
            destroy self.walletContainers
        }
    }



    // This function can only be called by the account owner to create an empty Collection
    access(account) fun createEmptyCollection(): @FlovatarInbox.Collection {
        return <- create Collection()
    }



    // Returns the amount of DUST received by the Flovatar for additional rewards or activities (not coming from the Community pool)
    pub fun getFlovatarDustBalance(id: UInt64): UFix64 {
        if let inboxCollection = self.account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarInbox.CollectionPublic}>()  {
            return inboxCollection.getFlovatarDustBalance(id: id)
        }
        return 0.0
    }
    // Returns the amount of DUST received by the Flovatar Owner for additional rewards or activities (not coming from the Community pool)
    pub fun getWalletDustBalance(address: Address): UFix64 {
        if let inboxCollection = self.account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarInbox.CollectionPublic}>()  {
            return inboxCollection.getWalletDustBalance(address: address)
        }
        return 0.0
    }
    // Returns the IDs of the Components (Flobits) received by the Flovatar
    pub fun getFlovatarComponentIDs(id: UInt64): [UInt64] {
        if let inboxCollection = self.account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarInbox.CollectionPublic}>()  {
            return inboxCollection.getFlovatarComponentIDs(id: id)
        }
        return []
    }
    // Returns the IDs of the Components (Flobits) received by the Flovatar Owner
    pub fun getWalletComponentIDs(address: Address): [UInt64] {
        if let inboxCollection = self.account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarInbox.CollectionPublic}>()  {
            return inboxCollection.getWalletComponentIDs(address: address)
        }
        return []
    }

    // This function withdraws all the Components assigned to a Flovatar and sends them to the Owner's address
    pub fun withdrawFlovatarComponent(id: UInt64, address: Address) {
        pre {
        	self.withdrawEnabled : "Withdrawal is not enabled!"
        }
        if let inboxCollection = self.account.borrow<&FlovatarInbox.Collection>(from: self.CollectionStoragePath) {
            if let flovatar = Flovatar.getFlovatar(address: address, flovatarId: id){
                let receiverAccount = getAccount(address)
                let flovatarComponentReceiverCollection = receiverAccount.getCapability<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath)

                var i: UInt32 = 0
                let componentIds = self.getFlovatarComponentIDs(id: id)

                //set a max of 50 Components to be withdrawn to avoid gas limits
                while (i < UInt32(componentIds.length) && i < UInt32(50)) {
                    let component <- inboxCollection.withdrawFlovatarComponent(id: id, withdrawID: componentIds[i])

                    if(component == nil){
                        panic("Component not found!")
                    }
                    flovatarComponentReceiverCollection.borrow()!.deposit(token: <-component)

                    emit FlovatarWithdrawComponent(flovatarId: id, componentId: componentIds[i], to: address)

                    i = i + UInt32(1)
                }
            }
        }
    }

    // This function withdraws all the Components assigned to a Flovatar Owner and sends them to his address
    pub fun withdrawWalletComponent(address: Address) {
        pre {
        	self.withdrawEnabled : "Withdrawal is not enabled!"
        }
        if let inboxCollection = self.account.borrow<&FlovatarInbox.Collection>(from: self.CollectionStoragePath) {
            let receiverAccount = getAccount(address)
            let flovatarComponentReceiverCollection = receiverAccount.getCapability<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath)

            var i: UInt32 = 0
            let componentIds = self.getWalletComponentIDs(address: address)

            //set a max of 50 Components to be withdrawn to avoid gas limits
            while (i < UInt32(componentIds.length) && i < UInt32(50)) {
                let component <- inboxCollection.withdrawWalletComponent(address: address, withdrawID: componentIds[i])

                if(component == nil){
                    panic("Component not found!")
                }
                flovatarComponentReceiverCollection.borrow()!.deposit(token: <-component)

                emit WalletWithdrawComponent(address: address, componentId: componentIds[i])

                i = i + UInt32(1)
            }
        }
    }

    // This function withdraws all the DUST assigned to a Flovatar (not from general community pool) and sends it to the Owner's vault
    pub fun withdrawFlovatarDust(id: UInt64, address: Address) {
        pre {
            self.withdrawEnabled : "Withdrawal is not enabled!"
        }
        if let inboxCollection = self.account.borrow<&FlovatarInbox.Collection>(from: self.CollectionStoragePath) {
            if let flovatar = Flovatar.getFlovatar(address: address, flovatarId: id){
                let receiverAccount = getAccount(address)
                let receiverRef = receiverAccount.getCapability(FlovatarDustToken.VaultReceiverPath)!.borrow<&{FungibleToken.Receiver}>()
                          ?? panic("Could not borrow receiver reference to the recipient's Vault")

                let vault <- inboxCollection.withdrawFlovatarDust(id: id)

                emit FlovatarWithdrawDust(id: id, amount: vault.balance, to: address)

                receiverRef.deposit(from: <- vault)

            }
        }
    }

    // This function withdraws all the DUST assigned to a Flovatar Owner (not from general community pool) and sends it to his vault
    pub fun withdrawWalletDust(address: Address) {
        pre {
            self.withdrawEnabled : "Withdrawal is not enabled!"
        }
        if let inboxCollection = self.account.borrow<&FlovatarInbox.Collection>(from: self.CollectionStoragePath) {
            let receiverAccount = getAccount(address)
            let receiverRef = receiverAccount.getCapability(FlovatarDustToken.VaultReceiverPath)!.borrow<&{FungibleToken.Receiver}>()
                      ?? panic("Could not borrow receiver reference to the recipient's Vault")

            let vault <- inboxCollection.withdrawWalletDust(address: address)

            emit WalletWithdrawDust(address: address, amount: vault.balance)

            receiverRef.deposit(from: <- vault)
        }
    }


    // Returns the amount of DUST available and yet to be distributed to the community
    pub fun getCommunityDustBalance(): UFix64 {
        return self.communityVault.balance
    }

    // Calculates how much DUST a Flovatar should be able to claim based on
    // his rarity score and on the amount of days passed since the last completed claim
    pub fun getClaimableFlovatarCommunityDust(id: UInt64, address: Address): ClaimableDust? {
        if let flovatarScore: UFix64 = Flovatar.getFlovatarRarityScore(address: address, flovatarId: id){
            if let inboxCollection = self.account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarInbox.CollectionPublic}>() {
                let lastClaimed: UFix64 = inboxCollection.getLastClaimedDust(id: id)
                let currentTime: UFix64 = getCurrentBlock().timestamp
                let timeDiff: UFix64 = currentTime - lastClaimed
                let dayLength: UFix64 = 86400.0
                if(timeDiff > dayLength){
                    let daysDiff: UInt64 = UInt64(timeDiff / dayLength)
                    return ClaimableDust(
                        amount: UFix64(daysDiff) * (3.0 + flovatarScore) * FlovatarInbox.dustPerDayPerScore,
                        days: daysDiff,
                        rarityScore: flovatarScore,
                        flovatarId: id,
                        wallet: address
                    )
                }
            }
        }
        return nil
    }

    // Internal function to update the timestamp of the last time DUST were claimed for a specific Flovatar
    access(self) fun setLastClaimedDust(id: UInt64, days: UInt64){
        if let inboxCollection = self.account.borrow<&FlovatarInbox.Collection>(from: self.CollectionStoragePath) {
            let lastClaimed: UFix64 = inboxCollection.getLastClaimedDust(id: id)
            inboxCollection.setLastClaimedDust(id: id, value: lastClaimed + UFix64(days * 86400))
        }
    }

    // This function will allow any Flovatar to claim his share of the daily distribution of DUST from the community pool
    pub fun claimFlovatarCommunityDust(id: UInt64, address: Address) {
        pre {
            self.withdrawEnabled : "Withdrawal is not enabled!"
        }
        if let claimableDust: ClaimableDust = self.getClaimableFlovatarCommunityDust(id: id, address: address){
            if(claimableDust.amount > self.communityVault.balance){
                panic("Not enough community DUST left to be claimed")
            }
            if(claimableDust.amount > UFix64(0.0)){

                let receiverAccount = getAccount(address)
                let receiverRef = receiverAccount.getCapability(FlovatarDustToken.VaultReceiverPath)!.borrow<&{FungibleToken.Receiver}>()
                          ?? panic("Could not borrow receiver reference to the recipient's Vault")

                let vault <- self.communityVault.withdraw(amount: claimableDust.amount)
                self.setLastClaimedDust(id: id, days: claimableDust.days)


                emit FlovatarClaimedCommunityDust(id: id, amount: vault.balance, to: address)

                receiverRef.deposit(from: <- vault)
            }
        }
    }

    // Admin function to temporarly enable or disable the airdrop and reward withdraw so that
    // we can distribute them to everyone at the same time
    access(account) fun setWithdrawEnable(enabled: Bool) {
        self.withdrawEnabled = enabled
    }
    // Admin function to deposit DUST into the community pool
    pub fun depositCommunityDust(vault: @FungibleToken.Vault) {
        pre {
            vault.isInstance(Type<@FlovatarDustToken.Vault>()) : "Vault not of the right Token Type"
        }
        self.communityVault.deposit(from: <- vault)
    }

    // Returns the multiplier used to calculate the amount of DUST to distribute for each Rarity Score point per day for each Flovatar
    pub fun getDustPerDayPerScore(): UFix64 {
        return self.dustPerDayPerScore
    }

    // Admin function to allow potential adjustments for the distribution speed of the community DUST
    access(account) fun setDustPerDayPerScore(value: UFix64) {
        self.dustPerDayPerScore = value
    }


    // This is the main Admin resource that will allow the owner
    // to manage the Inbox
    pub resource Admin {

        pub fun setDustPerDayPerScore(value: UFix64) {
            FlovatarInbox.setDustPerDayPerScore(value: value)
        }
        pub fun setWithdrawEnable(enabled: Bool) {
            FlovatarInbox.setWithdrawEnable(enabled: enabled)
        }


        // With this function you can generate a new Admin resource
        // and pass it to another user if needed
        pub fun createNewAdmin(): @Admin {
            return <-create Admin()
        }

    }


	init() {
	    self.withdrawEnabled = true
	    self.communityVault <- FlovatarDustToken.createEmptyVault()

	    self.dustDistributionStart = getCurrentBlock().timestamp

	    self.dustPerDayPerScore = 0.91447

        self.CollectionPublicPath=/public/FlovatarInboxCollection
        self.CollectionStoragePath=/storage/FlovatarInboxCollection

        self.account.save<@FlovatarInbox.Collection>(<- FlovatarInbox.createEmptyCollection(), to: FlovatarInbox.CollectionStoragePath)
        self.account.link<&{FlovatarInbox.CollectionPublic}>(FlovatarInbox.CollectionPublicPath, target: FlovatarInbox.CollectionStoragePath)

        // Put the Admin resource in storage
        self.account.save<@Admin>(<- create Admin(), to: /storage/FlovatarInboxAdmin)

        emit ContractInitialized()
	}
}
