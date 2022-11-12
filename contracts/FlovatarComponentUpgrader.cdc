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

 This contract provides the ability for users to upgrade their Flobits

 */

pub contract FlovatarComponentUpgrader {

    // The withdrawEnabled will allow to put all withdraws on hold while the distribution of new airdrops is happening
    // So that everyone will be then be able to access his rewards at the same time
    access(account) var upgradeEnabled: Bool


    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath

    // Event to notify about the Inbox creation
    pub event ContractInitialized()

    // Events to notify when Dust or Components are deposited or withdrawn
    pub event FlovatarComponentUpgraded(newId: UInt64, rarity: String, category: String, burnedIds: [UInt64])


    pub resource interface CollectionPublic {
        pub fun depositComponent(component: @FlovatarComponent.NFT)
        pub fun withdrawComponent(id: UInt64) : @FlovatarComponent.NFT
    }

    // The main Collection that manages the Containers
    pub resource Collection: CollectionPublic {

        access(contract) let flovatarComponents: @{UInt64: FlovatarComponent.NFT}


        init () {
            self.flovatarComponents <- {}
        }

        pub fun depositComponent(component: @FlovatarComponent.NFT) {
            let oldComponent <- self.flovatarComponents[component.id] <- component
            destroy oldComponent
        }

        pub fun withdrawComponent(id: UInt64) : @FlovatarComponent.NFT {
            let token <- self.flovatarComponents.remove(key: id) ?? panic("missing NFT")
            return <- token
        }
        pub fun withdrawRandomComponent(series: UInt32, rarity: String) : @FlovatarComponent.NFT {
            //TODO FILTER BY SERIES AND RARITY AND THEN RANDOMIZE AND PICK ONE
            let token <- self.flovatarComponents.remove(key: 0) ?? panic("missing NFT")
            return <- token
        }

        pub fun getComponentIDs(): [UInt64] {
            return self.flovatarComponents.keys
        }

        destroy() {
            destroy self.flovatarComponents
        }
    }



    // This function can only be called by the account owner to create an empty Collection
    access(account) fun createEmptyCollection(): @FlovatarComponentUpgrader.Collection {
        return <- create Collection()
    }



    // This function withdraws all the Components assigned to a Flovatar and sends them to the Owner's address
    pub fun upgradeFlovatarComponent(components: @[FlovatarComponent.NFT], vault: @FungibleToken.Vault) : @FlovatarComponent.NFT {
        pre {
        	self.upgradeEnabled : "Upgrade is not enabled!"
            vault.balance == 20.0 : "The amount of $DUST is not correct"
            vault.isInstance(Type<@FlovatarDustToken.Vault>()) : "Vault not of the right Token Type"
            components.length == 20 : "You need to provide exactly 10 Flobits for the upgrade"
        }
        if let inboxCollection = self.account.borrow<&FlovatarComponentUpgrader.Collection>(from: self.CollectionStoragePath) {

            var componentSeries: UInt32 = 0
            var checkCategory: Bool = true
            var componentCategory: String = ""
            var componentRarity: String = ""
            var outputRarity: String = ""

            var i: UInt32 = 0

            while (i < UInt32(components.length)) {

                let template = FlovatarComponentTemplate.getComponentTemplate(id: components[i]!.templateId)!

                if(i == UInt32(0)){
                    componentSeries = template.series
                    componentCategory = template.category
                    componentRarity = template.rarity
                }

                if(componentSeries != template.series){
                    panic("All the Flovatar Components need to be belong to the same Series")
                }
                if(componentRarity != template.rarity){
                    panic("All the Flovatar Components need to be belong to the same Rarity Level")
                }
                if(componentCategory != template.category){
                    checkCategory = false
                }

                i = i + UInt32(1)
            }

            if(componentRarity == "common"){
                outputRarity = "rare"
            } else if(componentRarity == "rare"){
                outputRarity = "epic"
            } else if(componentRarity == "epic"){
                outputRarity = "legendary"
            } else {
                panic("Rarity needs to be Common, Rare or Epic")
            }

            let component <- inboxCollection.withdrawRandomComponent(series: componentSeries, rarity: outputRarity)

            destroy components

        }
    }


    // Admin function to temporarly enable or disable the airdrop and reward withdraw so that
    // we can distribute them to everyone at the same time
    access(account) fun setUpgradeEnable(enabled: Bool) {
        self.upgradeEnabled = enabled
    }

	init() {
	    self.upgradeEnabled = true

        self.CollectionPublicPath=/public/FlovatarComponentUpgraderCollection
        self.CollectionStoragePath=/storage/FlovatarComponentUpgraderCollection

        self.account.save<@FlovatarComponentUpgrader.Collection>(<- FlovatarComponentUpgrader.createEmptyCollection(), to: FlovatarComponentUpgrader.CollectionStoragePath)
        self.account.link<&{FlovatarComponentUpgrader.CollectionPublic}>(FlovatarComponentUpgrader.CollectionPublicPath, target: FlovatarComponentUpgrader.CollectionStoragePath)

        emit ContractInitialized()
	}
}
