import NonFungibleToken from "./NonFungibleToken.cdc"
import FungibleToken from "./FungibleToken.cdc"

/*

 The contract that defines the Flovatar NFT and a Collection to manage them


10 head shapes
15 hairs
10 eyeglasses
5 facial hair
10 clothes
10 eyes
10 eyebrows
10 mouth
15 accessories

 */

pub contract FlovatarComponent: NonFungibleToken {

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath

    pub var totalSupply: UInt64

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Created(id: UInt64, metadata: Metadata)

    //The public interface can show metadata and the content for the Webshot
    pub resource interface Public {
        pub let id: UInt64
        pub let metadata: Metadata

        //these three are added because I think they will be in the standard. At least Dieter thinks it will be needed
        pub let name: String
        pub let description: String
        pub let schema: String?

        pub let content: String

        access(contract) let royalty: {String: Royalty}
    }

    //content is embedded in the NFT both as content and as URL pointing to an IPFS
    pub struct Metadata {
        pub let websiteAddress: Address
        pub let websiteId: UInt64
        pub let mint: UInt64
        pub let name: String
        pub let url: String
        pub let owner: String
        pub let ownerAddress: Address
        pub let description: String
        pub let date: UFix64
        pub let ipfs: {String: String}
        pub let imgUrl: String

        init(
            websiteAddress: Address,
            websiteId: UInt64,
            mint: UInt64
            name: String,
            url: String,
            owner: String,
            ownerAddress:Address,
            description: String,
            date: UFix64,
            ipfs: {String: String},
            imgUrl: String
        ) {
                self.websiteAddress = websiteAddress
                self.websiteId = websiteId
                self.mint = mint
                self.name = name
                self.url = url
                self.owner = owner
                self.ownerAddress = ownerAddress
                self.description = description
                self.date = date
                self.ipfs = ipfs
                self.imgUrl = imgUrl
        }
    }

    pub struct Royalty{
        pub let wallet: Capability<&{FungibleToken.Receiver}>
        pub let cut: UFix64

        init(wallet: Capability<&{FungibleToken.Receiver}>, cut: UFix64 ){
           self.wallet = wallet
           self.cut = cut
        }
    }

    pub resource NFT: NonFungibleToken.INFT, Public {
        pub let id: UInt64
        pub let name: String
        pub let description: String
        pub let schema: String?
        pub let content: String
        pub let metadata: Metadata
        access(contract) let royalty: {String: Royalty}

        init(
            content: String,
            metadata: Metadata,
            royalty: {String: Royalty}) {

            Webshot.totalSupply = Webshot.totalSupply + UInt64(1)
            Website.setTotalMintedWebshots(id: metadata.websiteId, value: Website.getTotalMintedWebshots(id: metadata.websiteId)! + UInt64(1))
            Website.setLastWebshotMintedAt(id: metadata.websiteId, value: metadata.date)

            self.id = Webshot.totalSupply
            self.content = content
            self.metadata = metadata
            self.royalty = royalty
            self.schema = nil
            self.name = metadata.name
            self.description = metadata.description
        }

        pub fun getID(): UInt64 {
            return self.id
        }

        pub fun getMetadata(): Metadata {
            return self.metadata
        }

        pub fun getRoyalty(): {String: Royalty} {
            return self.royalty
        }
    }

    //Standard NFT collectionPublic interface that can also borrowWebshot as the correct type
    pub resource interface CollectionPublic {

        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowWebshot(id: UInt64): &{Webshot.Public}?
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

            return <- token
        }

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @Webshot.NFT

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

        // borrowWebshot returns a borrowed reference to a Webshot
        // so that the caller can read data and call methods from it.
        //
        // Parameters: id: The ID of the NFT to get the reference for
        //
        // Returns: A reference to the NFT
        pub fun borrowWebshot(id: UInt64): &{Webshot.Public}? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &Webshot.NFT
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

    pub struct WebshotData {
        pub let id: UInt64
        pub let metadata: Webshot.Metadata
        init(id: UInt64, metadata: Webshot.Metadata) {
            self.id = id
            self.metadata = metadata
        }
    }

    pub fun getContentForWebshot(address: Address, webshotId: UInt64) : String? {
        let account = getAccount(address)
        if let webshotCollection= account.getCapability(self.CollectionPublicPath).borrow<&{Webshot.CollectionPublic}>()  {
            return webshotCollection.borrowWebshot(id: webshotId)!.content
        }
        return nil
    }

    // We cannot return the content here since it will be too big to run in a script
    pub fun getWebshot(address: Address, webshotId: UInt64) : WebshotData? {

        let account = getAccount(address)

        if let webshotCollection = account.getCapability(self.CollectionPublicPath).borrow<&{Webshot.CollectionPublic}>()  {
            if let webshot = webshotCollection.borrowWebshot(id: webshotId) {
                return WebshotData(
                    id: webshotId,
                    metadata: webshot!.metadata
                )
            }
        }
        return nil
    }

    // We cannot return the content here since it will be too big to run in a script
        pub fun getWebshots(address: Address) : [WebshotData] {

            var webshotData: [WebshotData] = []
            let account = getAccount(address)

            if let webshotCollection = account.getCapability(self.CollectionPublicPath).borrow<&{Webshot.CollectionPublic}>()  {
                for id in webshotCollection.getIDs() {
                    var webshot = webshotCollection.borrowWebshot(id: id)
                    webshotData.append(WebshotData(
                        id: id,
                        metadata: webshot!.metadata
                        ))
                }
            }
            return webshotData
        }

    //This method can only be called from another contract in the same account. In Webshot case it is called from the AuctionAdmin that is used to administer the solution
    access(account) fun createWebshot(
        websiteAddress: Address,
        websiteId: UInt64,
        name: String,
        url: String,
        owner:String,
        ownerAddress:Address,
        description: String,
        date: UFix64,
        ipfs: {String: String},
        content: String,
        imgUrl: String,
        royalty: {String: Royalty}) : @Webshot.NFT {

        let mint = Website.getTotalMintedWebshots(id: websiteId)! + UInt64(1)

        var newNFT <- create NFT(
            content: content,
            metadata: Metadata(
                websiteAddress: websiteAddress,
                websiteId: websiteId,
                mint: mint,
                name: name,
                url: url,
                owner: owner,
                ownerAddress: ownerAddress,
                description: description,
                date: date,
                ipfs: ipfs,
                imgUrl: imgUrl
            ),
            royalty: royalty
        )
        emit Created(id: Webshot.totalSupply, metadata: newNFT.metadata)

        return <- newNFT
    }

	init() {
        self.CollectionPublicPath = /public/WebshotCollection
        self.CollectionStoragePath = /storage/WebshotCollection

        // Initialize the total supply
        self.totalSupply = UInt64(0)

        self.account.save<@NonFungibleToken.Collection>(<- Webshot.createEmptyCollection(), to: Webshot.CollectionStoragePath)
        self.account.link<&{Webshot.CollectionPublic}>(Webshot.CollectionPublicPath, target: Webshot.CollectionStoragePath)

        emit ContractInitialized()
	}
}

