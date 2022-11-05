/*

 This contract defines the Dust Collectible Templates and the Collection to manage them.
 Dust Collectible Templates are the building blocks (lego bricks) of the final Dust Collectible,

 Templates are NOT using the NFT standard and will be always linked only to the contract's owner account.

 Templates are organized in Series, Layers and have maximum mint number along with some other variables.

 */

pub contract FlovatarDustCollectibleTemplate {

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath


    // Counter for all the Templates ever minted
    pub var totalSupply: UInt64
    //These counters will keep track of how many Components were minted for each Template
    access(contract) let totalMintedComponents: { UInt64: UInt64 }
    access(contract) let lastComponentMintedAt: { UInt64: UFix64 }

    // Event to notify about the Template creation
    pub event ContractInitialized()
    pub event Created(id: UInt64, name: String, category: String, color: String, maxMintableComponents: UInt64)

    // The public interface providing the SVG and all the other 
    // metadata like name, category, color, series, description and 
    // the maximum mintable Components
    pub resource interface Public {
        pub let id: UInt64
        pub let name: String
        pub let layer: UInt32
        pub let category: String
        pub let color: String
        pub let description: String
        pub let svg: String
        pub let series: UInt32
        pub let maxMintableComponents: UInt64
        pub let rarity: String
    }

    // The Component resource implementing the public interface as well
    pub resource CollectibleTemplate: Public {
        pub let id: UInt64
        pub let name: String
        pub let layer: UInt32
        pub let category: String
        pub let color: String
        pub let description: String
        pub let svg: String
        pub let series: UInt32
        pub let maxMintableComponents: UInt64
        pub let rarity: String

        // Initialize a Template with all the necessary data
        init(
            name: String,
            layer: UInt32,
            category: String,
            color: String,
            description: String,
            svg: String,
            series: UInt32,
            maxMintableComponents: UInt64,
            rarity: String
        ) {
            // increments the counter and stores it as the ID
            FlovatarDustCollectibleTemplate.totalSupply = FlovatarDustCollectibleTemplate.totalSupply + UInt64(1)
            self.id = FlovatarDustCollectibleTemplate.totalSupply
            self.name = name
            self.layer = layer
            self.category = category
            self.color = color
            self.description = description
            self.svg = svg
            self.series = series
            self.maxMintableComponents = maxMintableComponents
            self.rarity = rarity
        }
    }

    // Standard CollectionPublic interface that can also borrow Component Templates
    pub resource interface CollectionPublic {
        pub fun getIDs(): [UInt64]
        pub fun borrowCollectibleTemplate(id: UInt64): &{FlovatarDustCollectibleTemplate.Public}?
    }

    // The main Collection that manages the Templates and that implements also the Public interface
    pub resource Collection: CollectionPublic {
        // Dictionary of Component Templates
        pub var ownedCollectibleTemplates: @{UInt64: FlovatarDustCollectibleTemplate.CollectibleTemplate}

        init () {
            self.ownedCollectibleTemplates <- {}
        }

        

        // deposit takes a Component Template and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(collectibleTemplate: @FlovatarDustCollectibleTemplate.CollectibleTemplate) {

            let id: UInt64 = collectibleTemplate.id

            // add the new Component Template to the dictionary which removes the old one
            let oldCollectibleTemplate <- self.ownedCollectibleTemplates[id] <- collectibleTemplate

            destroy oldCollectibleTemplate
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedCollectibleTemplates.keys
        }

        // borrowCollectibleTemplate returns a borrowed reference to a Component Template
        // so that the caller can read data and call methods from it.
        pub fun borrowCollectibleTemplate(id: UInt64): &{FlovatarDustCollectibleTemplate.Public}? {
            if self.ownedCollectibleTemplates[id] != nil {
                let ref = (&self.ownedCollectibleTemplates[id] as auth &FlovatarDustCollectibleTemplate.CollectibleTemplate?)!
                return ref as! &FlovatarDustCollectibleTemplate.CollectibleTemplate
            } else {
                return nil
            }
        }

        destroy() {
            destroy self.ownedCollectibleTemplates
        }
    }

    // This function can only be called by the account owner to create an empty Collection
    access(account) fun createEmptyCollection(): @FlovatarDustCollectibleTemplate.Collection {
        return <- create Collection()
    }


    // This struct is used to send a data representation of the Templates 
    // when retrieved using the contract helper methods outside the collection.
    pub struct CollectibleTemplateData {
        pub let id: UInt64
        pub let name: String
        pub let layer: UInt32
        pub let category: String
        pub let color: String
        pub let description: String
        pub let svg: String?
        pub let series: UInt32
        pub let maxMintableComponents: UInt64
        pub let totalMintedComponents: UInt64
        pub let lastComponentMintedAt: UFix64
        pub let rarity: String

        init(
            id: UInt64,
            name: String,
            layer: UInt32,
            category: String,
            color: String,
            description: String,
            svg: String?,
            series: UInt32,
            maxMintableComponents: UInt64,
            rarity: String
        ) {
            self.id = id
            self.name = name
            self.layer = layer
            self.category = category
            self.color = color
            self.description = description
            self.svg = svg
            self.series = series
            self.maxMintableComponents = maxMintableComponents
            self.totalMintedComponents = FlovatarDustCollectibleTemplate.getTotalMintedComponents(id: id)!
            self.lastComponentMintedAt = FlovatarDustCollectibleTemplate.getLastComponentMintedAt(id: id)!
            self.rarity = rarity
        }
    }

    // Get all the Component Templates from the account. 
    // We hide the SVG field because it might be too big to execute in a script
    pub fun getCollectibleTemplates() : [CollectibleTemplateData] {
        var collectibleTemplateData: [CollectibleTemplateData] = []

        if let collectibleTemplateCollection = self.account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarDustCollectibleTemplate.CollectionPublic}>()  {
            for id in collectibleTemplateCollection.getIDs() {
                var collectibleTemplate = collectibleTemplateCollection.borrowCollectibleTemplate(id: id)
                collectibleTemplateData.append(CollectibleTemplateData(
                    id: id,
                    name: collectibleTemplate!.name,
                    layer: collectibleTemplate!.layer,
                    category: collectibleTemplate!.category,
                    color: collectibleTemplate!.color,
                    description: collectibleTemplate!.description,
                    svg: nil,
                    series: collectibleTemplate!.series,
                    maxMintableComponents: collectibleTemplate!.maxMintableComponents,
                    rarity: collectibleTemplate!.rarity
                    ))
            }
        }
        return collectibleTemplateData
    }

    // Gets a specific Template from its ID
    pub fun getCollectibleTemplate(id: UInt64) : CollectibleTemplateData? {
        if let collectibleTemplateCollection = self.account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarDustCollectibleTemplate.CollectionPublic}>()  {
            if let collectibleTemplate = collectibleTemplateCollection.borrowCollectibleTemplate(id: id) {
                return CollectibleTemplateData(
                    id: id,
                    name: collectibleTemplate!.name,
                    layer: collectibleTemplate!.layer,
                    category: collectibleTemplate!.category,
                    color: collectibleTemplate!.color,
                    description: collectibleTemplate!.description,
                    svg: collectibleTemplate!.svg,
                    series: collectibleTemplate!.series,
                    maxMintableComponents: collectibleTemplate!.maxMintableComponents,
                    rarity: collectibleTemplate!.rarity
                    )
            }
        }
        return nil
    }

    // Returns the amount of minted Components for a specific Template
    pub fun getTotalMintedComponents(id: UInt64) : UInt64? {
        return FlovatarDustCollectibleTemplate.totalMintedComponents[id]
    }
    // Returns the timestamp of the last time a Component for a specific Template was minted
    pub fun getLastComponentMintedAt(id: UInt64) : UFix64? {
        return FlovatarDustCollectibleTemplate.lastComponentMintedAt[id]
    }

    // This function is used within the contract to set the new counter for each Template
    access(account) fun setTotalMintedComponents(id: UInt64, value: UInt64) {
        FlovatarDustCollectibleTemplate.totalMintedComponents[id] = value
    }
    // This function is used within the contract to set the timestamp 
    // when a Component for a specific Template was minted
    access(account) fun setLastComponentMintedAt(id: UInt64, value: UFix64) {
        FlovatarDustCollectibleTemplate.lastComponentMintedAt[id] = value
    }

    // It creates a new Template with the data provided.
    // This is used from the Flovatar Admin resource
    access(account) fun createCollectibleTemplate(
        name: String,
        category: String,
        color: String,
        description: String,
        svg: String,
        series: UInt32,
        maxMintableComponents: UInt64,
        rarity: String
    ) : @FlovatarDustCollectibleTemplate.CollectibleTemplate {

        var newCollectibleTemplate <- create CollectibleTemplate(
            name: name,
            category: category,
            color: color,
            description: description,
            svg: svg,
            series: series,
            maxMintableComponents: maxMintableComponents,
            rarity: rarity
        )

        // Emits the Created event to notify about the new Template
        emit Created(id: newCollectibleTemplate.id, name: newCollectibleTemplate.name, category: newCollectibleTemplate.category, color: newCollectibleTemplate.color, maxMintableComponents: newCollectibleTemplate.maxMintableComponents)

        // Set the counter for the minted Components of this Template to 0
        FlovatarDustCollectibleTemplate.setTotalMintedComponents(id: newCollectibleTemplate.id, value: UInt64(0))
        FlovatarDustCollectibleTemplate.setLastComponentMintedAt(id: newCollectibleTemplate.id, value: UFix64(0))

        return <- newCollectibleTemplate
    }

	init() {
        self.CollectionPublicPath=/public/FlovatarDustCollectibleTemplateCollection
        self.CollectionStoragePath=/storage/FlovatarDustCollectibleTemplateCollection

        // Initialize the total supply
        self.totalSupply = 0
        self.totalMintedComponents = {}
        self.lastComponentMintedAt = {}

        self.account.save<@FlovatarDustCollectibleTemplate.Collection>(<- FlovatarDustCollectibleTemplate.createEmptyCollection(), to: FlovatarDustCollectibleTemplate.CollectionStoragePath)
        self.account.link<&{FlovatarDustCollectibleTemplate.CollectionPublic}>(FlovatarDustCollectibleTemplate.CollectionPublicPath, target: FlovatarDustCollectibleTemplate.CollectionStoragePath)

        emit ContractInitialized()
	}
}
