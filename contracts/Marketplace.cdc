import FungibleToken from "./FungibleToken.cdc"
import NonFungibleToken from "./NonFungibleToken.cdc"
//import FlowToken from "./FlowToken.cdc"
import FUSD from "./FUSD.cdc"
import Flovatar from "./Flovatar.cdc"
import FlovatarComponent from "./FlovatarComponent.cdc"

/*
// A standard marketplace contract only hardcoded against Flovatar and Components with Royalties management

 This contract based on the following git repo

 - The Versus Auction contract created by Bjartek and Alchemist
 https://github.com/versus-flow/auction-flow-contract
*/

pub contract Marketplace {

    pub let CollectionPublicPath: PublicPath
    pub let CollectionStoragePath: StoragePath

    pub let marketplaceWallet: Capability<&FUSD.Vault{FungibleToken.Receiver}>

    // Event that is emitted when a new NFT is put up for sale
    pub event FlovatarForSale(id: UInt64, price: UFix64, address: Address)
    pub event FlovatarComponentForSale(id: UInt64, price: UFix64, address: Address)

    // Event that is emitted when the price of an NFT changes
    pub event FlovatarPriceChanged(id: UInt64, newPrice: UFix64, address: Address)
    pub event FlovatarComponentPriceChanged(id: UInt64, newPrice: UFix64, address: Address)

    // Event that is emitted when a token is purchased
    pub event FlovatarPurchased(id: UInt64, price: UFix64, from: Address, to: Address)
    pub event FlovatarComponentPurchased(id: UInt64, price: UFix64, from: Address, to: Address)

    pub event RoyaltyPaid(id: UInt64, amount: UFix64, to: Address, name: String)

    // Event that is emitted when a seller withdraws their NFT from the sale
    pub event FlovatarSaleWithdrawn(tokenId: UInt64, address: Address)
    pub event FlovatarComponentSaleWithdrawn(tokenId: UInt64, address: Address)

    // Interface that users will publish for their Sale collection
    // that only exposes the methods that are supposed to be public
    //
    pub resource interface SalePublic {
        pub fun purchaseFlovatar(tokenId: UInt64, recipientCap: Capability<&{Flovatar.CollectionPublic}>, buyTokens: @FungibleToken.Vault)
        pub fun purchaseFlovatarComponent(tokenId: UInt64, recipientCap: Capability<&{FlovatarComponent.CollectionPublic}>, buyTokens: @FungibleToken.Vault)
        pub fun getFlovatarPrice(tokenId: UInt64): UFix64?
        pub fun getFlovatarComponentPrice(tokenId: UInt64): UFix64?
        pub fun getFlovatarIDs(): [UInt64]
        pub fun getFlovatarComponentIDs(): [UInt64]
        pub fun getFlovatar(tokenId: UInt64): &{Flovatar.Public}?
        pub fun getFlovatarComponent(tokenId: UInt64): &{FlovatarComponent.Public}?
    }

    // SaleCollection
    //
    // NFT Collection object that allows a user to put their NFT up for sale
    // where others can send fungible tokens to purchase it
    //
    pub resource SaleCollection: SalePublic {

        // Dictionary of the NFTs that the user is putting up for sale
        access(contract) let flovatarForSale: @{UInt64: Flovatar.NFT}
        access(contract) let flovatarComponentForSale: @{UInt64: FlovatarComponent.NFT}

        // Dictionary of the prices for each NFT by ID
        access(contract) let flovatarPrices: {UInt64: UFix64}
        access(contract) let flovatarComponentPrices: {UInt64: UFix64}

        // The fungible token vault of the owner of this sale.
        // When someone buys a token, this resource can deposit
        // tokens into their account.
        access(account) let ownerVault: Capability<&AnyResource{FungibleToken.Receiver}>

        init (vault: Capability<&AnyResource{FungibleToken.Receiver}>) {
            self.flovatarForSale <- {}
            self.flovatarComponentForSale <- {}
            self.ownerVault = vault
            self.flovatarPrices = {}
            self.flovatarComponentPrices = {}
        }

        // withdraw gives the owner the opportunity to remove a sale from the collection
        pub fun withdrawFlovatar(tokenId: UInt64): @Flovatar.NFT {
            // remove the price
            self.flovatarPrices.remove(key: tokenId)
            // remove and return the token
            let token <- self.flovatarForSale.remove(key: tokenId) ?? panic("missing NFT")

            let vaultRef = self.ownerVault.borrow()
                ?? panic("Could not borrow reference to owner token vault")
            emit FlovatarSaleWithdrawn(tokenId: tokenId, address: vaultRef.owner!.address)
            return <-token
        }

        // withdraw gives the owner the opportunity to remove a sale from the collection
        pub fun withdrawFlovatarComponent(tokenId: UInt64): @FlovatarComponent.NFT {
            // remove the price
            self.flovatarComponentPrices.remove(key: tokenId)
            // remove and return the token
            let token <- self.flovatarComponentForSale.remove(key: tokenId) ?? panic("missing NFT")

            let vaultRef = self.ownerVault.borrow()
                ?? panic("Could not borrow reference to owner token vault")
            emit FlovatarComponentSaleWithdrawn(tokenId: tokenId, address: vaultRef.owner!.address)
            return <-token
        }

        // listForSale lists an NFT for sale in this collection
        pub fun listFlovatarForSale(token: @Flovatar.NFT, price: UFix64) {
            let id = token.id

            // store the price in the price array
            self.flovatarPrices[id] = price

            // put the NFT into the the forSale dictionary
            let oldToken <- self.flovatarForSale[id] <- token
            destroy oldToken

            let vaultRef = self.ownerVault.borrow()
                ?? panic("Could not borrow reference to owner token vault")
            emit FlovatarForSale(id: id, price: price, address: vaultRef.owner!.address)
        }

        // listForSale lists an NFT for sale in this collection
        pub fun listFlovatarComponentForSale(token: @FlovatarComponent.NFT, price: UFix64) {
            let id = token.id

            // store the price in the price array
            self.flovatarComponentPrices[id] = price

            // put the NFT into the the forSale dictionary
            let oldToken <- self.flovatarComponentForSale[id] <- token
            destroy oldToken

            let vaultRef = self.ownerVault.borrow()
                ?? panic("Could not borrow reference to owner token vault")
            emit FlovatarComponentForSale(id: id, price: price, address: vaultRef.owner!.address)
        }

        // changePrice changes the price of a token that is currently for sale
        pub fun changeFlovatarPrice(tokenId: UInt64, newPrice: UFix64) {
            self.flovatarPrices[tokenId] = newPrice

            let vaultRef = self.ownerVault.borrow()
                ?? panic("Could not borrow reference to owner token vault")
            emit FlovatarPriceChanged(id: tokenId, newPrice: newPrice, address: vaultRef.owner!.address)
        }
        // changePrice changes the price of a token that is currently for sale
        pub fun changeFlovatarComponentPrice(tokenId: UInt64, newPrice: UFix64) {
            self.flovatarComponentPrices[tokenId] = newPrice

            let vaultRef = self.ownerVault.borrow()
                ?? panic("Could not borrow reference to owner token vault")
            emit FlovatarComponentPriceChanged(id: tokenId, newPrice: newPrice, address: vaultRef.owner!.address)
        }

        // purchase lets a user send tokens to purchase an NFT that is for sale
        pub fun purchaseFlovatar(tokenId: UInt64, recipientCap: Capability<&{Flovatar.CollectionPublic}>, buyTokens: @FungibleToken.Vault) {
            pre {
                self.flovatarForSale[tokenId] != nil && self.flovatarPrices[tokenId] != nil:
                    "No token matching this ID for sale!"
                buyTokens.balance >= (self.flovatarPrices[tokenId] ?? 0.0):
                    "Not enough tokens to buy the NFT!"
            }

            let recipient = recipientCap.borrow()!

            // get the value out of the optional
            let price = self.flovatarPrices[tokenId]!

            self.flovatarPrices[tokenId] = nil

            let vaultRef = self.ownerVault.borrow() ?? panic("Could not borrow reference to owner token vault")

            let token <-self.withdrawFlovatar(tokenId: tokenId)

            let creatorAccount = getAccount(token.metadata.creatorAddress)
            let creatorWallet = creatorAccount.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver).borrow()!
            let creatorAmount = price * Flovatar.getRoyaltyCut()
            let tempCreatorWallet <- buyTokens.withdraw(amount: creatorAmount)
            creatorWallet.deposit(from: <-tempCreatorWallet)
            

            let marketplaceWallet = Marketplace.marketplaceWallet.borrow()!
            let marketplaceAmount = price * Flovatar.getMarketplaceCut()
            let tempMarketplaceWallet <- buyTokens.withdraw(amount: marketplaceAmount)
            marketplaceWallet.deposit(from: <-tempMarketplaceWallet)

            // deposit the purchasing tokens into the owners vault
            vaultRef.deposit(from: <-buyTokens)

            // deposit the NFT into the buyers collection
            recipient.deposit(token: <- token)

            emit FlovatarPurchased(id: tokenId, price: price, from: vaultRef.owner!.address, to: recipient.owner!.address)
        }

        // purchase lets a user send tokens to purchase an NFT that is for sale
        pub fun purchaseFlovatarComponent(tokenId: UInt64, recipientCap: Capability<&{FlovatarComponent.CollectionPublic}>, buyTokens: @FungibleToken.Vault) {
            pre {
                self.flovatarComponentForSale[tokenId] != nil && self.flovatarComponentPrices[tokenId] != nil:
                    "No token matching this ID for sale!"
                buyTokens.balance >= (self.flovatarComponentPrices[tokenId] ?? 0.0):
                    "Not enough tokens to buy the NFT!"
            }

            let recipient = recipientCap.borrow()!

            // get the value out of the optional
            let price = self.flovatarComponentPrices[tokenId]!

            self.flovatarComponentPrices[tokenId] = nil

            let vaultRef = self.ownerVault.borrow() ?? panic("Could not borrow reference to owner token vault")

            let token <-self.withdrawFlovatarComponent(tokenId: tokenId)


            let marketplaceWallet = Marketplace.marketplaceWallet.borrow()!
            let marketplaceAmount = price * Flovatar.getMarketplaceCut()
            let tempMarketplaceWallet <- buyTokens.withdraw(amount: marketplaceAmount)
            marketplaceWallet.deposit(from: <-tempMarketplaceWallet)

            // deposit the purchasing tokens into the owners vault
            vaultRef.deposit(from: <-buyTokens)

            // deposit the NFT into the buyers collection
            recipient.deposit(token: <- token)

            emit FlovatarComponentPurchased(id: tokenId, price: price, from: vaultRef.owner!.address, to: recipient.owner!.address)
        }

        // idPrice returns the price of a specific token in the sale
        pub fun getFlovatarPrice(tokenId: UInt64): UFix64? {
            return self.flovatarPrices[tokenId]
        }
        // idPrice returns the price of a specific token in the sale
        pub fun getFlovatarComponentPrice(tokenId: UInt64): UFix64? {
            return self.flovatarComponentPrices[tokenId]
        }

        // getIDs returns an array of token IDs that are for sale
        pub fun getFlovatarIDs(): [UInt64] {
            return self.flovatarForSale.keys
        }
        // getIDs returns an array of token IDs that are for sale
        pub fun getFlovatarComponentIDs(): [UInt64] {
            return self.flovatarComponentForSale.keys
        }
        // borrowSale returns a borrowed reference to a Sale
        // so that the caller can read data and call methods from it.
        //
        // Parameters: id: The ID of the Sale NFT to get the reference for
        //
        // Returns: A reference to the NFT
        pub fun getFlovatar(tokenId: UInt64): &{Flovatar.Public}? {
            if self.flovatarForSale[tokenId] != nil {
                let ref = &self.flovatarForSale[tokenId] as auth &NonFungibleToken.NFT
                return ref as! &Flovatar.NFT
            } else {
                return nil
            }
        }
        pub fun getFlovatarComponent(tokenId: UInt64): &{FlovatarComponent.Public}? {
            if self.flovatarComponentForSale[tokenId] != nil {
                let ref = &self.flovatarComponentForSale[tokenId] as auth &NonFungibleToken.NFT
                return ref as! &FlovatarComponent.NFT
            } else {
                return nil
            }
        }

        destroy() {
            destroy self.flovatarForSale
            destroy self.flovatarComponentForSale
        }
    }

    pub struct FlovatarSaleData {
        pub let id: UInt64
        pub let price: UFix64
        pub let metadata: Flovatar.Metadata
        pub let accessoryId: UInt64?
        pub let hatId: UInt64?
        pub let eyeglassesId: UInt64?
        pub let backgroundId: UInt64?

        init(
            id: UInt64,
            price: UFix64,
            metadata: Flovatar.Metadata,
            accessoryId: UInt64?,
            hatId: UInt64?,
            eyeglassesId: UInt64?,
            backgroundId: UInt64?
            ){

            self.id = id
            self.price = price
            self.metadata = metadata
            self.accessoryId = accessoryId
            self.hatId = hatId
            self.eyeglassesId = eyeglassesId
            self.backgroundId = backgroundId
        }
    }
    pub struct FlovatarComponentSaleData {
        pub let id: UInt64
        pub let price: UFix64
        pub let metadata: FlovatarComponent.ComponentData

        init(
            id: UInt64,
            price: UFix64,
            metadata: FlovatarComponent.ComponentData){

            self.id = id
            self.price = price
            self.metadata = metadata
        }
    }

    pub fun getFlovatarSales(address: Address) : [FlovatarSaleData] {
        var saleData: [FlovatarSaleData] = []
        let account = getAccount(address)

        if let saleCollection = account.getCapability(self.CollectionPublicPath).borrow<&{Marketplace.SalePublic}>()  {
            for id in saleCollection.getFlovatarIDs() {
                let price = saleCollection.getFlovatarPrice(tokenId: id)
                let flovatar = saleCollection.getFlovatar(tokenId: id)
                saleData.append(FlovatarSaleData(
                    id: id,
                    price: price!,
                    metadata: flovatar!.metadata,
                    accessoryId: flovatar!.getAccessory(),
                    hatId: flovatar!.getHat(),
                    eyeglassesId: flovatar!.getEyeglasses(),
                    backgroundId: flovatar!.getBackground()
                    ))
            }
        }
        return saleData
    }

    pub fun getFlovatarComponentSales(address: Address) : [FlovatarComponentSaleData] {
        var saleData: [FlovatarComponentSaleData] = []
        let account = getAccount(address)

        if let saleCollection = account.getCapability(self.CollectionPublicPath).borrow<&{Marketplace.SalePublic}>()  {
            for id in saleCollection.getFlovatarComponentIDs() {
                let price = saleCollection.getFlovatarComponentPrice(tokenId: id)
                let flovatarComponent = saleCollection.getFlovatarComponent(tokenId: id)
                saleData.append(FlovatarComponentSaleData(
                    id: id,
                    price: price!,
                    metadata: FlovatarComponent.ComponentData(
                        id: id,
                        templateId: flovatarComponent!.templateId,
                        mint: flovatarComponent!.mint
                        )
                    ))
            }
        }
        return saleData
    }

    pub fun getFlovatarSale(address: Address, id: UInt64) : FlovatarSaleData? {

        let account = getAccount(address)

        if let saleCollection = account.getCapability(self.CollectionPublicPath).borrow<&{Marketplace.SalePublic}>()  {
            if let flovatar = saleCollection.getFlovatar(tokenId: id) {
                let price = saleCollection.getFlovatarPrice(tokenId: id)
                return FlovatarSaleData(
                           id: id,
                            price: price!,
                            metadata: flovatar.metadata,
                            accessoryId: flovatar.getAccessory(),
                            hatId: flovatar.getHat(),
                            eyeglassesId: flovatar.getEyeglasses(),
                            backgroundId: flovatar!.getBackground()
                           )
            }
        }
        return nil
    }

    pub fun getFlovatarComponentSale(address: Address, id: UInt64) : FlovatarComponentSaleData? {

        let account = getAccount(address)

        if let saleCollection = account.getCapability(self.CollectionPublicPath).borrow<&{Marketplace.SalePublic}>()  {
            if let flovatarComponent = saleCollection.getFlovatarComponent(tokenId: id) {
                let price = saleCollection.getFlovatarComponentPrice(tokenId: id)
                return FlovatarComponentSaleData(
                           id: id,
                            price: price!,
                            metadata: FlovatarComponent.ComponentData(
                                id: id,
                                templateId: flovatarComponent!.templateId,
                                mint: flovatarComponent!.mint
                                )
                           )
            }
        }
        return nil
    }



    // createCollection returns a new collection resource to the caller
    pub fun createSaleCollection(ownerVault: Capability<&{FungibleToken.Receiver}>): @SaleCollection {
        return <- create SaleCollection(vault: ownerVault)
    }

    pub init() {
        //TODO: remove suffix before deploying to mainnet!!!
        self.CollectionPublicPath= /public/FlovatarMarketplace005
        self.CollectionStoragePath= /storage/FlovatarMarketplace005


        if(self.account.borrow<&FUSD.Vault>(from: /storage/fusdVault) == nil) {
          self.account.save(<-FUSD.createEmptyVault(), to: /storage/fusdVault)
          self.account.link<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver, target: /storage/fusdVault)
          self.account.link<&FUSD.Vault{FungibleToken.Balance}>(/public/fusdBalance, target: /storage/fusdVault)
        }

        self.marketplaceWallet = self.account.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver)

    }
}
