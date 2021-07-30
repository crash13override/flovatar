/*

 The contract that defines the Flovatar Component Types and a Collection to manage them

 */

pub contract FlovatarComponentType {

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath

    pub var totalSupply: UInt64
    access(contract) let totalMintedComponents: { UInt64: UInt64 }
    access(contract) let lastComponentMintedAt: { UInt64: UFix64 }

    pub event ContractInitialized()
    pub event Created(id: UInt64, name: String, type: String, color: String, maxMintableComponents: UInt64)

    pub resource interface Public {
        pub let id: UInt64
        pub let name: String
        pub let type: String
        pub let color: String
        pub let description: String
        pub let svg: String
        pub let maxMintableComponents: UInt64
    }

    pub resource ComponentType: Public {
        pub let id: UInt64
        pub let name: String
        pub let type: String
        pub let color: String
        pub let description: String
        pub let svg: String
        pub let maxMintableComponents: UInt64

        init(
            name: String,
            type: String,
            color: String,
            description: String,
            svg: String,
            maxMintableComponents: UInt64
        ) {

            FlovatarComponentType.totalSupply = FlovatarComponentType.totalSupply + UInt64(1)
            self.id = FlovatarComponentType.totalSupply
            self.name = name
            self.type = type
            self.color = color
            self.description = description
            self.svg = svg
            self.maxMintableComponents = maxMintableComponents
        }
    }

    //Standard CollectionPublic interface that can also borrow Component Types
    pub resource interface CollectionPublic {
        pub fun getIDs(): [UInt64]
        pub fun borrowComponentType(id: UInt64): &{FlovatarComponentType.Public}?
    }

    pub resource Collection: CollectionPublic {
        // dictionary of Component Types
        // Type is a resource type with an `UInt64` ID field
        pub var ownedComponentTypes: @{UInt64: FlovatarComponentType.ComponentType}

        init () {
            self.ownedComponentTypes <- {}
        }

        

        // deposit takes a Component Type and adds it to the collections dictionary
        // and adds the ID to the id array
        access(account) fun deposit(componentType: @FlovatarComponentType.ComponentType) {

            let id: UInt64 = componentType.id

            // add the new Component Type to the dictionary which removes the old one
            let oldComponentType <- self.ownedComponentTypes[id] <- componentType

            destroy oldToken
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedComponentTypes.keys
        }

        // borrowComponentType returns a borrowed reference to a Component Type
        // so that the caller can read data and call methods from it.
        //
        // Parameters: id: The ID of the Component Type to get the reference for
        //
        // Returns: A reference to the Component Type
        pub fun borrowComponentType(id: UInt64): &{FlovatarComponentType.Public}? {
            if self.ownedComponentTypes[id] != nil {
                let ref = &self.ownedComponentTypes[id] as auth &FlovatarComponentType.ComponentType
                return ref as! &FlovatarComponentType.ComponentType
            } else {
                return nil
            }
        }

        destroy() {
            destroy self.ownedComponentTypes
        }
    }

    access(account) fun createEmptyCollection(): @FlovatarComponentType.Collection {
        return <- create Collection()
    }

    pub struct ComponentTypeData {
        pub let id: UInt64
        pub let name: String
        pub let type: String
        pub let color: String
        pub let description: String
        pub let svg: String?
        pub let maxMintableComponents: UInt64
        pub let totalMintedComponents: UInt64
        pub let lastComponentMintedAt: UFix64

        init(
            id: UInt64,
            name: String,
            type: String,
            color: String,
            description: String,
            svg: String?,
            maxMintableComponents: UInt64
        ) {
            self.id = id
            self.name = name
            self.type = type
            self.color = color
            self.description = description
            self.svg = svg
            self.maxMintableComponents = maxMintableComponents
            self.totalMintedComponents = FlovatarComponentType.getTotalMintedComponents(id: id)!
            self.lastWebshotMintedAt = FlovatarComponentType.getLastComponentMintedAt(id: id)!
        }
    }

    // Get all the Component Types from the account. We hide the SVG field because it might be too big to execute in a script
    pub fun getComponentTypes() : [ComponentTypeData] {
        var componentTypeData: [ComponentTypeData] = []

        if let componentTypeCollection = self.account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarComponentType.CollectionPublic}>()  {
            for id in componentTypeCollection.getIDs() {
                var componentType = componentTypeCollection.borrowComponentType(id: id)
                componentTypeData.append(ComponentTypeData(
                    id: id,
                    name: componentType!.name,
                    type: componentType!.type,
                    color: componentType!.color,
                    description: componentType!.description,
                    svg: nil,
                    maxMintableComponents: componentType!.maxMintableComponents
                    ))
            }
        }
        return componentTypeData
    }

    pub fun getComponentType(id: UInt64) : ComponentTypeData? {

        if let componentTypeCollection = self.account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarComponentType.CollectionPublic}>()  {
            if let componentType = componentTypeCollection.borrowComponentType(id: id) {
                return ComponentTypeData(
                    id: id,
                    name: componentType!.name,
                    type: componentType!.type,
                    color: componentType!.color,
                    description: componentType!.description,
                    svg: componentType!.svg,
                    maxMintableComponents: componentType!.maxMintableComponents
                    )
            }
        }
        return nil
    }


    pub fun getTotalMintedComponents(id: UInt64) : UInt64? {
        return FlovatarComponentType.totalMintedComponents[id]
    }
    pub fun getLastComponentMintedAt(id: UInt64) : UFix64? {
        return FlovatarComponentType.lastComponentMintedAt[id]
    }

    access(account) fun setTotalMintedComponents(id: UInt64, value: UInt64) {
        FlovatarComponentType.totalMintedComponents[id] = value
    }
    access(account) fun setLastComponentMintedAt(id: UInt64, value: UFix64) {
        FlovatarComponentType.lastComponentMintedAt[id] = value
    }

    access(account) fun createComponentType(
        name: String,
        type: String,
        color: String,
        description: String,
        svg: String,
        maxMintableComponents: UInt64
    ) : @FlovatarComponentType.ComponentType {

        var newComponentType <- create ComponentType(
            name: name,
            type: type,
            color: color,
            description: description,
            svg: svg,
            maxMintableComponents: maxMintableComponents
        )
        emit Created(id: newComponentType.id, name: newComponentType.name, type: newComponentType.type, color: newComponentType.color, maxMintableComponents: newComponentType.maxMintableComponents)

        FlovatarComponentType.setTotalMintedComponents(id: newComponentType.id, value: UInt64(0))
        FlovatarComponentType.setLastComponentMintedAt(id: newComponentType.id, value: UFix64(0))

        return <- newComponentType
    }

	init() {
        //TODO: remove before deploying to mainnet!!!
        self.CollectionPublicPath=/public/FlovatarComponentTypeCollection001
        self.CollectionStoragePath=/storage/FlovatarComponentTypeCollection001

        // Initialize the total supply
        self.totalSupply = 0
        self.totalMintedComponents = {}
        self.lastComponentMintedAt = {}

        self.account.save<@FlovatarComponentType.Collection>(<- FlovatarComponentType.createEmptyCollection(), to: FlovatarComponentType.CollectionStoragePath)
        self.account.link<&{FlovatarComponentType.CollectionPublic}>(FlovatarComponentType.CollectionPublicPath, target: FlovatarComponentType.CollectionStoragePath)

        emit ContractInitialized()
	}
}

