/*

 The contract that defines the Flovatar Component Templates and a Collection to manage them

 */

pub contract FlovatarComponentTemplate {

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath

    pub var totalSupply: UInt64
    access(contract) let totalMintedComponents: { UInt64: UInt64 }
    access(contract) let lastComponentMintedAt: { UInt64: UFix64 }

    pub event ContractInitialized()
    pub event Created(id: UInt64, name: String, category: String, color: String, maxMintableComponents: UInt64)

    pub resource interface Public {
        pub let id: UInt64
        pub let name: String
        pub let category: String
        pub let color: String
        pub let description: String
        pub let svg: String
        pub let maxMintableComponents: UInt64
    }

    pub resource ComponentTemplate: Public {
        pub let id: UInt64
        pub let name: String
        pub let category: String
        pub let color: String
        pub let description: String
        pub let svg: String
        pub let maxMintableComponents: UInt64

        init(
            name: String,
            category: String,
            color: String,
            description: String,
            svg: String,
            maxMintableComponents: UInt64
        ) {

            FlovatarComponentTemplate.totalSupply = FlovatarComponentTemplate.totalSupply + UInt64(1)
            self.id = FlovatarComponentTemplate.totalSupply
            self.name = name
            self.category = category
            self.color = color
            self.description = description
            self.svg = svg
            self.maxMintableComponents = maxMintableComponents
        }
    }

    //Standard CollectionPublic interface that can also borrow Component Templates
    pub resource interface CollectionPublic {
        pub fun getIDs(): [UInt64]
        pub fun borrowComponentTemplate(id: UInt64): &{FlovatarComponentTemplate.Public}?
    }

    pub resource Collection: CollectionPublic {
        // dictionary of Component Templates
        pub var ownedComponentTemplates: @{UInt64: FlovatarComponentTemplate.ComponentTemplate}

        init () {
            self.ownedComponentTemplates <- {}
        }

        

        // deposit takes a Component Template and adds it to the collections dictionary
        // and adds the ID to the id array
        access(account) fun deposit(componentTemplate: @FlovatarComponentTemplate.ComponentTemplate) {

            let id: UInt64 = componentTemplate.id

            // add the new Component Template to the dictionary which removes the old one
            let oldComponentTemplate <- self.ownedComponentTemplates[id] <- componentTemplate

            destroy oldToken
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedComponentTemplates.keys
        }

        // borrowComponentTemplate returns a borrowed reference to a Component Template
        // so that the caller can read data and call methods from it.
        //
        // Parameters: id: The ID of the Component Template to get the reference for
        //
        // Returns: A reference to the Component Template
        pub fun borrowComponentTemplate(id: UInt64): &{FlovatarComponentTemplate.Public}? {
            if self.ownedComponentTemplates[id] != nil {
                let ref = &self.ownedComponentTemplates[id] as auth &FlovatarComponentTemplate.ComponentTemplate
                return ref as! &FlovatarComponentTemplate.ComponentTemplate
            } else {
                return nil
            }
        }

        destroy() {
            destroy self.ownedComponentTemplates
        }
    }

    access(account) fun createEmptyCollection(): @FlovatarComponentTemplate.Collection {
        return <- create Collection()
    }

    pub struct ComponentTemplateData {
        pub let id: UInt64
        pub let name: String
        pub let category: String
        pub let color: String
        pub let description: String
        pub let svg: String?
        pub let maxMintableComponents: UInt64
        pub let totalMintedComponents: UInt64
        pub let lastComponentMintedAt: UFix64

        init(
            id: UInt64,
            name: String,
            category: String,
            color: String,
            description: String,
            svg: String?,
            maxMintableComponents: UInt64
        ) {
            self.id = id
            self.name = name
            self.category = category
            self.color = color
            self.description = description
            self.svg = svg
            self.maxMintableComponents = maxMintableComponents
            self.totalMintedComponents = FlovatarComponentTemplate.getTotalMintedComponents(id: id)!
            self.lastWebshotMintedAt = FlovatarComponentTemplate.getLastComponentMintedAt(id: id)!
        }
    }

    // Get all the Component Templates from the account. We hide the SVG field because it might be too big to execute in a script
    pub fun getComponentTemplates() : [ComponentTemplateData] {
        var componentTemplateData: [ComponentTemplateData] = []

        if let componentTemplateCollection = self.account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarComponentTemplate.CollectionPublic}>()  {
            for id in componentTemplateCollection.getIDs() {
                var componentTemplate = componentTemplateCollection.borrowComponentTemplate(id: id)
                componentTemplateData.append(ComponentTemplateData(
                    id: id,
                    name: componentTemplate!.name,
                    category: componentTemplate!.category,
                    color: componentTemplate!.color,
                    description: componentTemplate!.description,
                    svg: nil,
                    maxMintableComponents: componentTemplate!.maxMintableComponents
                    ))
            }
        }
        return componentTemplateData
    }

    pub fun getComponentTemplate(id: UInt64) : ComponentTemplateData? {

        if let componentTemplateCollection = self.account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarComponentTemplate.CollectionPublic}>()  {
            if let componentTemplate = componentTemplateCollection.borrowComponentTemplate(id: id) {
                return ComponentTemplateData(
                    id: id,
                    name: componentTemplate!.name,
                    category: componentTemplate!.category,
                    color: componentTemplate!.color,
                    description: componentTemplate!.description,
                    svg: componentTemplate!.svg,
                    maxMintableComponents: componentTemplate!.maxMintableComponents
                    )
            }
        }
        return nil
    }


    pub fun getTotalMintedComponents(id: UInt64) : UInt64? {
        return FlovatarComponentTemplate.totalMintedComponents[id]
    }
    pub fun getLastComponentMintedAt(id: UInt64) : UFix64? {
        return FlovatarComponentTemplate.lastComponentMintedAt[id]
    }

    access(account) fun setTotalMintedComponents(id: UInt64, value: UInt64) {
        FlovatarComponentTemplate.totalMintedComponents[id] = value
    }
    access(account) fun setLastComponentMintedAt(id: UInt64, value: UFix64) {
        FlovatarComponentTemplate.lastComponentMintedAt[id] = value
    }

    access(account) fun createComponentTemplate(
        name: String,
        category: String,
        color: String,
        description: String,
        svg: String,
        maxMintableComponents: UInt64
    ) : @FlovatarComponentTemplate.ComponentTemplate {

        var newComponentTemplate <- create ComponentTemplate(
            name: name,
            category: category,
            color: color,
            description: description,
            svg: svg,
            maxMintableComponents: maxMintableComponents
        )
        emit Created(id: newComponentTemplate.id, name: newComponentTemplate.name, category: newComponentTemplate.category, color: newComponentTemplate.color, maxMintableComponents: newComponentTemplate.maxMintableComponents)

        FlovatarComponentTemplate.setTotalMintedComponents(id: newComponentTemplate.id, value: UInt64(0))
        FlovatarComponentTemplate.setLastComponentMintedAt(id: newComponentTemplate.id, value: UFix64(0))

        return <- newComponentTemplate
    }

	init() {
        //TODO: remove before deploying to mainnet!!!
        self.CollectionPublicPath=/public/FlovatarComponentTemplateCollection001
        self.CollectionStoragePath=/storage/FlovatarComponentTemplateCollection001

        // Initialize the total supply
        self.totalSupply = 0
        self.totalMintedComponents = {}
        self.lastComponentMintedAt = {}

        self.account.save<@FlovatarComponentTemplate.Collection>(<- FlovatarComponentTemplate.createEmptyCollection(), to: FlovatarComponentTemplate.CollectionStoragePath)
        self.account.link<&{FlovatarComponentTemplate.CollectionPublic}>(FlovatarComponentTemplate.CollectionPublicPath, target: FlovatarComponentTemplate.CollectionStoragePath)

        emit ContractInitialized()
	}
}

