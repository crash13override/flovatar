import NonFungibleToken from "./NonFungibleToken.cdc"
import FungibleToken from "./FungibleToken.cdc"
import FlovatarComponentType from "./FlovatarComponentType.cdc"

/*

 The contract that defines the Flovatar Component NFT and a Collection to manage them

 */

pub contract FlovatarComponent: NonFungibleToken {

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath

    pub var totalSupply: UInt64

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Created(id: UInt64, type_id: UInt64)

    //The public interface can show metadata and the content for the Webshot
    pub resource interface Public {
        pub let id: UInt64
        pub let type_id: UInt64
        pub let mint: UInt64
        pub fun getSvg(): String
        pub fun getType(): FlovatarComponentType.ComponentTypeData

        //these three are added because I think they will be in the standard. At least Dieter thinks it will be needed
        pub let name: String
        pub let description: String
        pub let schema: String?
    }

    

    pub resource NFT: NonFungibleToken.INFT, Public {
        pub let id: UInt64
        pub let type_id: UInt64
        pub let mint: UInt64
        pub let name: String
        pub let description: String
        pub let schema: String?

        init(type_id: UInt64) {

            FlovatarComponent.totalSupply = FlovatarComponent.totalSupply + UInt64(1)

            let componentType = FlovatarComponentType.getComponentType(self.type_id)!

            self.id = FlovatarComponent.totalSupply
            self.type_id = type_id
            self.mint = FlovatarComponentType.getTotalMintedComponents(id: type_id)! + UInt64(1)
            self.name = componentType.name
            self.description = componentType.description

            FlovatarComponentType.setTotalMintedComponents(id: type_id, value: self.mint)
            FlovatarComponentType.setLastComponentMintedAt(id: type_id, value: getCurrentBlock().timestamp)
        }

        pub fun getID(): UInt64 {
            return self.id
        }

        pub fun getType(): FlovatarComponentType.ComponentTypeData {
            return FlovatarComponentType.getComponentType(self.type_id)!
        }

        pub fun getSvg(): String {
            return self.getType().svg
        }
    }

    //Standard NFT collectionPublic interface that can also borrowComponent as the correct type
    pub resource interface CollectionPublic {

        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowComponent(id: UInt64): &{FlovatarComponent.Public}?
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
            let token <- token as! @FlovatarComponent.NFT

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

        // borrowComponent returns a borrowed reference to a FlovatarComponent
        // so that the caller can read data and call methods from it.
        //
        // Parameters: id: The ID of the NFT to get the reference for
        //
        // Returns: A reference to the NFT
        pub fun borrowComponent(id: UInt64): &{FlovatarComponent.Public}? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &FlovatarComponent.NFT
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

    pub struct ComponentData {
        pub let id: UInt64
        pub let type_id: UInt64
        pub let mint: UInt64
        pub let name: String
        pub let description: String
        pub let type: String
        pub let color: String
        //pub let svg: String?

        init(id: UInt64, type_id: UInt64, mint: UInt64) {
            self.id = id
            self.type_id = type_id
            self.mint = mint
            let componentType = FlovatarComponentType.getComponentType(type_id)!
            self.name = componentType.name
            self.description = componentType.description
            self.type = componentType.type
            self.color = componentType.color
            //self.svg = componentType.svg
        }
    }

    pub fun getSvgForComponent(address: Address, component_id: UInt64) : String? {
        let account = getAccount(address)
        if let componentCollection= account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarComponent.CollectionPublic}>()  {
            return componentCollection.borrowComponent(id: component_id)!.getSvg()
        }
        return nil
    }

    pub fun getComponent(address: Address, component_id: UInt64) : ComponentData? {
        let account = getAccount(address)
        if let componentCollection = account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarComponent.CollectionPublic}>()  {
            if let component = componentCollection.borrowComponent(id: component_id) {
                return ComponentData(
                    id: component_id,
                    type_id: component!.type_id,
                    mint: component!.mint
                )
            }
        }
        return nil
    }

    // We cannot return the svg here since it will be too big to run in a script
        pub fun getComponents(address: Address) : [ComponentData] {

            var componentData: [ComponentData] = []
            let account = getAccount(address)

            if let componentCollection = account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarComponent.CollectionPublic}>()  {
                for id in componentCollection.getIDs() {
                    var component = componentCollection.borrowComponent(id: id)
                    componentData.append(ComponentData(
                        id: id,
                        type_id: component!.type_id,
                        mint: component!.mint
                        ))
                }
            }
            return componentData
        }

    //This method can only be called from another contract in the same account. In FlovatarComponent case it is called from the Admin that is used to administer the components
    access(account) fun createComponent(type_id: UInt64) : @FlovatarComponent.NFT {


        var newNFT <- create NFT(type_id: type_id)
        emit Created(id: newNFT.id, type_id: type_id)

        return <- newNFT
    }

	init() {
        //TODO: remove before deploying to mainnet!!!
        self.CollectionPublicPath = /public/FlovatarComponentCollection001
        self.CollectionStoragePath = /storage/FlovatarComponentCollection001

        // Initialize the total supply
        self.totalSupply = UInt64(0)

        self.account.save<@NonFungibleToken.Collection>(<- FlovatarComponent.createEmptyCollection(), to: FlovatarComponent.CollectionStoragePath)
        self.account.link<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath, target: FlovatarComponent.CollectionStoragePath)

        emit ContractInitialized()
	}
}

