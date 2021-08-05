import NonFungibleToken from "./NonFungibleToken.cdc"
import FungibleToken from "./FungibleToken.cdc"

/*

 The contract that defines the Flovatar NFT and a Collection to manage them

Base components that will be used to generate the unique combination of the Flovatar
'head', 'hair', 'facialhair', 'eyes', 'nose', 'mouth', 'clothing'

Extra components that can be added in a second moment
'hat', eyeglass', 'accessory'

 */

pub contract Flovatar: NonFungibleToken {

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath

    pub var totalSupply: UInt64
    access(contract) let mintedCombinations: [String]
    access(contract) let mintedNames: [String]

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Created(id: UInt64, metadata: Metadata)


    //content is embedded in the NFT both as content and as URL pointing to an IPFS
    pub struct Metadata {
        pub let name: String
        pub let mint: UInt64
        pub let svg: String
        pub let combination: String
        pub let creatorAddress: Address
        pub let components: {String: UInt64}


        init(
            name: String,
            mint: UInt64
            svg: String,
            combination: String,
            creatorAddress: Address,
            components: {String: UInt64},
        ) {
                self.name = name
                self.mint = mint
                self.svg = svg
                self.combination = combination
                self.creatorAddress = creatorAddress
                self.components = components
        }
    }

    //The public interface can show metadata and the content for the Flovatar
    pub resource interface Public {
        pub let id: UInt64
        pub let metadata: Metadata
        access(contract) let additionalComponents: {String: UInt64}

        //these three are added because I think they will be in the standard. At least Dieter thinks it will be needed
        pub let name: String
        pub let description: String
        pub let schema: String?

        pub fun getAdditionalComponents(): {String: UInt64}
        pub fun appendAdditionalComponents(component: @FlovatarComponent.NFT): {String: UInt64}

    }

    pub resource NFT: NonFungibleToken.INFT, Public {
        pub let id: UInt64
        pub let metadata: Metadata
        access(contract) let additionalComponents: {String: UInt64}

        pub let name: String
        pub let description: String
        pub let schema: String?

        init(metadata: Metadata) {

            Flovatar.totalSupply = Flovatar.totalSupply + UInt64(1)

            self.id = Flovatar.totalSupply
            self.metadata = metadata
            self.additionalComponents = {}

            self.schema = nil
            self.name = metadata.name
            self.description = metadata.name
        }

        pub fun getID(): UInt64 {
            return self.id
        }

        pub fun getMetadata(): Metadata {
            return self.metadata
        }

        pub fun getAdditionalComponents(): {String: UInt64} {
            return self.additionalComponents
        }
        pub fun appendAdditionalComponents(component: @FlovatarComponent.NFT): {String: UInt64} {
            //TODO check limitations for each type
            let componentType = component.getType()
            self.additionalComponents.insert(key: componentType.type, component.typeId)
            //TODO burn the additional component NFT
            return self.additionalComponents
        }
    }

    //Standard NFT collectionPublic interface that can also borrowFlovatar as the correct type
    pub resource interface CollectionPublic {

        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowFlovatar(id: UInt64): &{Flovatar.Public}?
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
            let token <- token as! @Flovatar.NFT

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

        // borrowFlovatar returns a borrowed reference to a Flovatar
        // so that the caller can read data and call methods from it.
        //
        // Parameters: id: The ID of the NFT to get the reference for
        //
        // Returns: A reference to the NFT
        pub fun borrowFlovatar(id: UInt64): &{Flovatar.Public}? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &Flovatar.NFT
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

    pub struct FlovatarData {
        pub let id: UInt64
        pub let metadata: Flovatar.Metadata
        init(id: UInt64, metadata: Flovatar.Metadata) {
            self.id = id
            self.metadata = metadata
        }
    }


    pub fun getFlovatar(address: Address, FlovatarId: UInt64) : FlovatarData? {

        let account = getAccount(address)

        if let FlovatarCollection = account.getCapability(self.CollectionPublicPath).borrow<&{Flovatar.CollectionPublic}>()  {
            if let Flovatar = FlovatarCollection.borrowFlovatar(id: FlovatarId) {
                return FlovatarData(
                    id: FlovatarId,
                    metadata: Flovatar!.metadata
                )
            }
        }
        return nil
    }

    pub fun getFlovatars(address: Address) : [FlovatarData] {

        var FlovatarData: [FlovatarData] = []
        let account = getAccount(address)

        if let FlovatarCollection = account.getCapability(self.CollectionPublicPath).borrow<&{Flovatar.CollectionPublic}>()  {
            for id in FlovatarCollection.getIDs() {
                var Flovatar = FlovatarCollection.borrowFlovatar(id: id)
                FlovatarData.append(FlovatarData(
                    id: id,
                    metadata: Flovatar!.metadata
                    ))
            }
        }
        return FlovatarData
    }


    pub fun getMintedCombinations() : [String] {
        return Flovatar.mintedCombinations
    }
    pub fun getMintedNames() : [String] {
        return Flovatar.mintedNames
    }

    pub fun checkMintedCombination(combination: String) : Bool {
        return Flovatar.mintedCombinations.contains(combination)
    }
    pub fun checkMintedName(name: String) : [String] {
        return Flovatar.mintedNames.contains(name)
    }

    access(account) fun addMintedCombination(combination: String) {
        Flovatar.mintedCombinations.append(combination)
    }
    access(account) fun addMintedName(name: String) {
        Flovatar.mintedNames.append(name)
    }

    pub fun getCombinationString(
        head: UInt64,
        hair: UInt64,
        facialHair: UInt64?,
        eyes: UInt64,
        nose: UInt64,
        mouth: UInt64,
        clothing: UInt64
    ) : String {
        return String("Head").concat(String(head)).concat("-Hair").concat(String(hair)).concat("-FacialHair").concat(String(facialHair ?? "x")).concat("-Eyes").concat(String(eyes)).concat("-Nose").concat(String(nose)).concat("-Mouth").concat(String(mouth)).concat("-Clothing").concat(String(clothing))
    }

    pub fun checkCombinationAvailable(
        head: UInt64,
        hair: UInt64,
        facialHair: UInt64?,
        eyes: UInt64,
        nose: UInt64,
        mouth: UInt64,
        clothing: UInt64
    ) : Bool {
        let combinationString = Flovatar.getCombinationString(
            head: head,
            hair: hair,
            facialHair: facialHair,
            eyes: eyes,
            nose: nose,
            mouth: mouth,
            clothing: clothing
        )
        return Flovatar.checkMintedCombination(combinationString)
    }

    //'head', 'hair', 'facialhair', 'eyes', 'nose', 'mouth', 'clothing'
    pub fun createFlovatar(
        name: String,
        head: @FlovatarComponent.NFT,
        hair: @FlovatarComponent.NFT,
        facialHair: @FlovatarComponent.NFT?,
        eyes: @FlovatarComponent.NFT,
        nose: @FlovatarComponent.NFT,
        mouth: @FlovatarComponent.NFT,
        clothing: @FlovatarComponent.NFT
    ) : @Flovatar.NFT {


        pre {
            let combinationString = Flovatar.getCombinationString(
                head: head.typeId, 
                hair: hair.typeId, 
                facialHair: facialHair ? facialHair.typeId : nil, 
                eyes: eyes.typeId, 
                nose: nose.typeId, 
                mouth: mouth.typeId, 
                clothing: clothing.typeId)

                Flovatar.checkMintedCombination(combinationString) == false : "This combination has already been minted"

                Flovatar.checkMintedName(combinationString) == false : "This name has already been minted"
        }

        let metadata = Metadata(
            name: name,
            mint: Flovatar.totalSupply + UInt64(1),
            svg: "" //TODO implement createSVG function
            combination: combinationString,
            creatorAddress: self.account.address //TODO check and implement via parameter?
            components: {
                "head": head.typeId, 
                "hair": hair.typeId, 
                "facialHair": facialHair ? facialHair.typeId : nil, 
                "eyes": eyes.typeId, 
                "nose": nose.typeId, 
                "mouth": mouth.typeId, 
                "clothing": clothing.typeId
            }
        )

        var newNFT <- create NFT(metadata: metadata)
        emit Created(id: Flovatar.totalSupply, metadata: metadata)

        //TODO burn all the components

        return <- newNFT
    }

	init() {
        self.CollectionPublicPath = /public/FlovatarCollection
        self.CollectionStoragePath = /storage/FlovatarCollection

        // Initialize the total supply
        self.totalSupply = UInt64(0)
        self.mintedCombinations = []
        self.mintedNames = []
        self.account.save<@NonFungibleToken.Collection>(<- Flovatar.createEmptyCollection(), to: Flovatar.CollectionStoragePath)
        self.account.link<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath, target: Flovatar.CollectionStoragePath)

        emit ContractInitialized()
	}
}

