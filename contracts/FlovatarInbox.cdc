import FungibleToken from 0xf233dcee88fe0abe
import NonFungibleToken from 0x1d7e57aa55817448
import FlowToken from 0x1654653399040a61
import FlovatarComponentTemplate from 0x921ea449dffec68a
import FlovatarComponent from 0x921ea449dffec68a
import FlovatarPack from 0x921ea449dffec68a
import FlovatarDustToken from 0x921ea449dffec68a

/*

 This contract defines the Inbox for Flovatar owners where they can claim their airdrops and rewards

 This contract contains also the Admin resource that can be used to manage the different inboxes.

 */

pub contract FlovatarInbox {

    access(account) var withdrawEnabled: Bool

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath

    // Event to notify about the Inbox creation
    pub event ContractInitialized()

    pub event FlovatarDepositComponent(flovatarId: UInt64, componentId: UInt64)
    pub event FlovatarDepositDust(id: UInt64, amount: UFix64)
    pub event FlovatarWithdrawComponent(flovatarId: UInt64, componentId: UInt64, to: Address)
    pub event FlovatarWithdrawDust(id: UInt64, amount: UFix64, to: Address)
    pub event WalletDepositComponent(address: Address, componentId: UInt64)
    pub event WalletDepositDust(address: Address, amount: UFix64)
    pub event WalletWithdrawComponent(address: Address, componentId: UInt64)
    pub event WalletWithdrawDust(address: Address, amount: UFix64)

    // The Container resounce holds both the FlovatarComponent and the Dust for each Flovatar minted
    pub resource Container {
        access(contract) let dustVault: @FlovatarDustToken.Vault
        access(contract) let flovatarComponents: @{UInt64: FlovatarComponent.NFT}

        // Initialize a Template with all the necessary data
        init() {
            self.dustVault <- FlovatarDustToken.createEmptyVault()
            self.flovatarComponents <- {}
        }
    }


    // The main Collection that manages the Containers
    pub resource Collection {
        // Dictionary of Component Templates
        pub var flovatarContainers: @{UInt64: FlovatarInbox.Container}
        pub var walletContainers: @{Address: FlovatarInbox.Container}

        init () {
            self.flovatarContainers <- {}
            self.walletContainers <- {}
        }

        pub fun borrowFlovatarContainer(id: UInt64) &{FlovatarInbox.Container} {
            if self.containers[id] == nil {
                let oldContainer <- self.flovatarContainers[id] <- create Container()
                destroy oldContainer
            }
            return &self.flovatarContainers[id] as auth &FlovatarInbox.Container
        }
        pub fun borrowWalletContainer(address: Address) &{FlovatarInbox.Container} {
            if self.containers[address] == nil {
                let oldContainer <- self.walletContainers[address] <- create Container()
                destroy oldContainer
            }
            return &self.walletContainers[id] as auth &FlovatarInbox.Container
        }

        pub fun depositDustToFlovatar(id: UInt64, vault: @FlovatarDustToken.Vault) {
            let ref = self.borrowFlovatarContainer(id: id)
            ref.dustVault.deposit(vault: <- vault)
        }

        pub fun depositDustToWallet(address: Address, vault: @FlovatarDustToken.Vault) {
            let ref = self.borrowWalletContainer(address: address)
            ref.dustVault.deposit(vault: <- vault)
        }

        pub fun depositComponentToFlovatar(id: UInt64, component: @FlovatarComponent.NFT) {
            let ref = self.borrowFlovatarContainer(id: id)
            let oldComponent <- ref.flovatarComponents[id] <- component
            destroy oldComponent
        }
        pub fun depositComponentToWallet(address: Address, component: @FlovatarComponent.NFT) {
            let ref = self.borrowWalletContainer(address: address)
            let oldComponent <- ref.flovatarComponents[address] <- component
            destroy oldComponent
        }

        pub fun getFlovatarDustBalance(id: UInt64) UFix64 {
            let ref = self.borrowFlovatarContainer(id: id)
            return ref.dustVault.balance
        }

        pub fun getWalletDustBalance(address: Address) UFix64 {
            let ref = self.borrowWalletContainer(address: address)
            return ref.dustVault.balance
        }

        pub fun getFlovatarComponentIDs(id: UInt64): [UInt64] {
            let ref = self.borrowFlovatarContainer(id: id)
            return ref.dustVault.flovatarComponents.keys
        }
        pub fun getWalletComponentIDs(address: Address): [UInt64] {
            let ref = self.borrowWalletContainer(address: address)
            return ref.dustVault.flovatarComponents.keys
        }

        pub fun getFlovatarIDs(): [UInt64] {
            return self.flovatarContainers.keys
        }
        pub fun getWalletAddresses(): [Address] {
            return self.walletContainers.keys
        }

        pub fun withdrawFlovatarComponent(id: UInt64, withdrawID: UInt64): @NonFungibleToken.NFT {
            let ref = self.borrowFlovatarContainer(id: id)
            let token <- ref.flovatarComponents.remove(key: withdrawID) ?? panic("missing NFT")
            return <- token
        }
        pub fun withdrawWalletComponent(address: Address, withdrawID: UInt64): @NonFungibleToken.NFT {
            let ref = self.borrowWalletContainer(address: address)
            let token <- ref.flovatarComponents.remove(key: withdrawID) ?? panic("missing NFT")
            return <- token
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




    pub fun getFlovatarDustBalance(id: UInt64) : UFix64 {
        if let inboxCollection = self.account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarInbox.CollectionPublic}>()  {
            return inboxCollection.getFlovatarDustBalance(id: id);
        }
        return 0.0
    }
    pub fun getWalletDustBalance(address: Address) : UFix64 {
        if let inboxCollection = self.account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarInbox.CollectionPublic}>()  {
            return inboxCollection.getWalletDustBalance(address: address);
        }
        return 0.0
    }
    pub fun getFlovatarComponentIDs(id: UInt64): [UInt64] {
        if let inboxCollection = self.account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarInbox.CollectionPublic}>()  {
            return inboxCollection.getFlovatarComponentIDs(id: id);
        }
        return []
    }
    pub fun getWalletComponentIDs(address: Address): [UInt64] {
        if let inboxCollection = self.account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarInbox.CollectionPublic}>()  {
            return inboxCollection.getWalletComponentIDs(address: address);
        }
        return []
    }

    pub fun withdrawFlovatarComponent(id: UInt64, address: Address) {
        if let inboxCollection = self.account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarInbox.CollectionPublic}>()  {
            if let flovatar = Flovatar.getFlovatar(address: address, id: id){
                let receiverAccount = getAccount(address)
                let flovatarComponentReceiverCollection = receiverAccount.getCapability<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath)

                var i: UInt32 = 0
                let componentIds = self.getFlovatarComponentIDs(id: id)

                while i < UInt32(componentIds.length) {
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

    pub fun withdrawWalletComponent(address: Address) {
        if let inboxCollection = self.account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarInbox.CollectionPublic}>()  {
            let receiverAccount = getAccount(address)
            let flovatarComponentReceiverCollection = receiverAccount.getCapability<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath)

            var i: UInt32 = 0
            let componentIds = self.getWalletComponentIDs(address: address)

            while i < UInt32(componentIds.length) {
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




	init() {
	    self.withdrawEnabled = true

        self.CollectionPublicPath=/public/FlovatarInboxCollection
        self.CollectionStoragePath=/storage/FlovatarInboxCollection

        self.account.save<@FlovatarInbox.Collection>(<- FlovatarInbox.createEmptyCollection(), to: FlovatarInbox.CollectionStoragePath)
        self.account.link<&{FlovatarInbox.CollectionPublic}>(FlovatarInbox.CollectionPublicPath, target: FlovatarInbox.CollectionStoragePath)

        emit ContractInitialized()
	}
}
