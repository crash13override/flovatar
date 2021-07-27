import NonFungibleToken from "./NonFungibleToken.cdc"
import FungibleToken from "./FungibleToken.cdc"
//import FlowToken from "./FlowToken.cdc"
//import FUSD from "./FUSD.cdc"

/*

 The contract that defines the Website NFT and a Collection to manage them

 This contract based on the following git repo

 - The Versus Auction contract created by Bjartek and Alchemist
 https://github.com/versus-flow/auction-flow-contract

 Each Website defines the name, URL, drop frequency, minting number for all the webshots created from it

 */

pub contract FlovatarPack: NonFungibleToken {

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath

    pub var totalSupply: UInt64
    access(contract) let totalMintedWebshots: { UInt64: UInt64 }
    access(contract) let lastWebshotMintedAt: { UInt64: UFix64 }

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Created(id: UInt64, name: String, url: String)

    pub resource interface Public {
        pub let id: UInt64
        pub let name: String
        pub let url: String
        pub let ownerName: String
        pub let ownerAddress: Address
        pub let description: String
        pub let webshotMinInterval: UInt64
        pub let isRecurring: Bool
    }

    pub resource NFT: NonFungibleToken.INFT, Public {
        pub let id: UInt64
        pub let name: String
        pub let url: String
        pub let ownerName: String
        pub let ownerAddress: Address
        pub let description: String
        pub let webshotMinInterval: UInt64
        pub let isRecurring: Bool

        init(
            name: String,
            url: String,
            ownerName: String,
            ownerAddress: Address,
            description: String,
            webshotMinInterval: UInt64,
            isRecurring: Bool
        ) {

            Website.totalSupply = Website.totalSupply + UInt64(1)
            self.id = Website.totalSupply
            self.name = name
            self.url = url
            self.ownerName = ownerName
            self.ownerAddress = ownerAddress
            self.description = description
            self.webshotMinInterval = webshotMinInterval
            self.isRecurring = isRecurring
        }
    }

    //Standard NFT CollectionPublic interface that can also borrowWebsite as the correct type
    pub resource interface CollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowWebsite(id: UInt64): &{Website.Public}?
    }

    pub resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
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

            return <-token
        }

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @Website.NFT

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
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT
        }

        // borrowWebsite returns a borrowed reference to a Website
        // so that the caller can read data and call methods from it.
        //
        // Parameters: id: The ID of the NFT to get the reference for
        //
        // Returns: A reference to the NFT
        pub fun borrowWebsite(id: UInt64): &{Website.Public}? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &Website.NFT
            } else {
                return nil
            }
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    pub struct WebsiteData {
        pub let id: UInt64
        pub let name: String
        pub let url: String
        pub let ownerName: String
        pub let ownerAddress: Address
        pub let description: String
        pub let webshotMinInterval: UInt64
        pub let isRecurring: Bool
        pub let totalMintedWebshots: UInt64
        pub let lastWebshotMintedAt: UFix64

        init(
            id: UInt64,
            name: String,
            url: String,
            ownerName: String,
            ownerAddress: Address,
            description: String,
            webshotMinInterval: UInt64,
            isRecurring: Bool) {
            self.id = id
            self.name = name
            self.url = url
            self.ownerName = ownerName
            self.ownerAddress = ownerAddress
            self.description = description
            self.webshotMinInterval = webshotMinInterval
            self.isRecurring = isRecurring
            self.totalMintedWebshots = Website.getTotalMintedWebshots(id: id)!
            self.lastWebshotMintedAt = Website.getLastWebshotMintedAt(id: id)!
        }
    }

    pub fun getWebsites(address: Address) : [WebsiteData] {
        var websiteData: [WebsiteData] = []
        let account = getAccount(address)

        if let websiteCollection = account.getCapability(self.CollectionPublicPath).borrow<&{Website.CollectionPublic}>()  {
            for id in websiteCollection.getIDs() {
                var website = websiteCollection.borrowWebsite(id: id)
                websiteData.append(WebsiteData(
                    id: id,
                    name: website!.name,
                    url: website!.url,
                    ownerName: website!.ownerName,
                    ownerAddress: website!.ownerAddress,
                    description: website!.description,
                    webshotMinInterval: website!.webshotMinInterval,
                    isRecurring: website!.isRecurring
                    ))
            }
        }
        return websiteData
    }

    pub fun getWebsite(address: Address, id: UInt64) : WebsiteData? {
        var websiteData: [WebsiteData] = []
        let account = getAccount(address)

        if let websiteCollection = account.getCapability(self.CollectionPublicPath).borrow<&{Website.CollectionPublic}>()  {
            if let website = websiteCollection.borrowWebsite(id: id) {
                return WebsiteData(
                    id: id,
                    name: website.name,
                    url: website.url,
                    ownerName: website.ownerName,
                    ownerAddress: website.ownerAddress,
                    description: website.description,
                    webshotMinInterval: website.webshotMinInterval,
                    isRecurring: website.isRecurring
                )
            }
        }
        return nil
    }


    pub fun getTotalMintedWebshots(id: UInt64) : UInt64? {
        return Website.totalMintedWebshots[id]
    }
    pub fun getLastWebshotMintedAt(id: UInt64) : UFix64? {
        return Website.lastWebshotMintedAt[id]
    }

    access(account) fun setTotalMintedWebshots(id: UInt64, value: UInt64) {
        Website.totalMintedWebshots[id] = value
    }
    access(account) fun setLastWebshotMintedAt(id: UInt64, value: UFix64) {
        Website.lastWebshotMintedAt[id] = value
    }

    //This method can only be called from another contract in the same account. In Website case it is called from the AuctionAdmin that is used to administer the solution
    access(account) fun createWebsite(
        name: String,
        url: String,
        ownerName: String,
        ownerAddress: Address,
        description: String,
        webshotMinInterval: UInt64,
        isRecurring: Bool) : @Website.NFT {

        var newNFT <- create NFT(
            name: name,
            url: url,
            ownerName: ownerName,
            ownerAddress: ownerAddress,
            description: description,
            webshotMinInterval: webshotMinInterval,
            isRecurring: isRecurring
        )
        emit Created(id: newNFT.id, name: newNFT.name, url: newNFT.url)

        Website.setTotalMintedWebshots(id: newNFT.id, value: UInt64(0))
        Website.setLastWebshotMintedAt(id: newNFT.id, value: UFix64(0))

        return <- newNFT
    }

	init() {
        self.CollectionPublicPath=/public/WebsiteCollection
        self.CollectionStoragePath=/storage/WebsiteCollection

        // Initialize the total supply
        self.totalSupply = 0
        self.totalMintedWebshots = {}
        self.lastWebshotMintedAt = {}

        self.account.save<@NonFungibleToken.Collection>(<- Website.createEmptyCollection(), to: Website.CollectionStoragePath)
        self.account.link<&{Website.CollectionPublic}>(Website.CollectionPublicPath, target: Website.CollectionStoragePath)

        emit ContractInitialized()
	}
}

