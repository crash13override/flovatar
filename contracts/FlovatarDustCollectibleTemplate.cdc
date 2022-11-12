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
    pub var totalSeriesSupply: UInt64
    //These counters will keep track of how many Components were minted for each Template
    access(contract) let totalMintedComponents: { UInt64: UInt64 }
    access(contract) let totalMintedCollectibles: { UInt64: UInt64 }
    access(contract) let templatesCurrentPrice: { UInt64: UFix64 }
    access(contract) let lastComponentMintedAt: { UInt64: UFix64 }

    // Event to notify about the Template creation
    pub event ContractInitialized()
    pub event Created(id: UInt64, name: String, series: UInt64, layer: UInt32, maxMintableComponents: UInt64)
    pub event CreatedSeries(id: UInt64, name: String, maxMintable: UInt64)

    pub struct Layer{
        pub let id: UInt32
        pub let name: String
        pub let isAccessory: Bool

        init(id: UInt32, name: String, isAccessory: Bool){
            self.id = id
            self.name = name
            self.isAccessory = isAccessory
        }
    }

    pub resource interface PublicSeries {
        pub let id: UInt64
        pub let name: String
        pub let description: String
        pub let svgPrefix: String
        pub let svgSuffix: String
        pub let priceIncrease: UFix64
        access(contract) let layers: {UInt32: Layer}
        access(contract) let colors: {UInt32: String}
        access(contract) let metadata: {String: String}
        pub let maxMintable: UInt64
        pub fun getLayers(): {UInt32: Layer}
        pub fun getColors(): {UInt32: String}
        pub fun getMetadata(): {String: String}
    }

    // The Series resource implementing the public interface as well
    pub resource CollectibleSeries: PublicSeries {
        pub let id: UInt64
        pub let name: String
        pub let description: String
        pub let svgPrefix: String
        pub let svgSuffix: String
        pub let priceIncrease: UFix64
        access(contract) let layers: {UInt32: Layer}
        access(contract) let colors: {UInt32: String}
        access(contract) let metadata: {String: String}
        pub let maxMintable: UInt64

        pub fun getLayers(): {UInt32: Layer} {
            return self.layers
        }
        pub fun getColors(): {UInt32: String} {
            return self.colors
        }
        pub fun getMetadata(): {String: String} {
            return self.metadata
        }

        init(
            name: String,
            description: String,
            svgPrefix: String,
            svgSuffix: String,
            priceIncrease: UFix64,
            layers: {UInt32: Layer},
            colors: {UInt32: String},
            metadata: {String: String},
            maxMintable: UInt64
        ) {
            // increments the counter and stores it as the ID
            FlovatarDustCollectibleTemplate.totalSeriesSupply = FlovatarDustCollectibleTemplate.totalSeriesSupply + UInt64(1)
            self.id = FlovatarDustCollectibleTemplate.totalSeriesSupply
            self.name = name
            self.description = description
            self.svgPrefix = svgPrefix
            self.svgSuffix = svgSuffix
            self.priceIncrease = priceIncrease
            self.layers = layers
            self.colors = colors
            self.metadata = metadata
            self.maxMintable = maxMintable
        }
   }

    // The public interface providing the SVG and all the other 
    // metadata like name, series, layer, etc.
    pub resource interface Public {
        pub let id: UInt64
        pub let name: String
        pub let description: String
        pub let series: UInt64
        pub let layer: UInt32
        access(contract) let metadata: {String: String}
        pub let rarity: String
        pub let basePrice: UFix64
        pub let svg: String
        pub let maxMintableComponents: UInt64

        pub fun getMetadata(): {String: String} {
            return self.metadata
        }
    }

    // The Template resource implementing the public interface as well
    pub resource CollectibleTemplate: Public {
        pub let id: UInt64
        pub let name: String
        pub let description: String
        pub let series: UInt64
        pub let layer: UInt32
        access(contract) let metadata: {String: String}
        pub let rarity: String
        pub let basePrice: UFix64
        pub let svg: String
        pub let maxMintableComponents: UInt64

        // Initialize a Template with all the necessary data
        init(
            name: String,
            description: String,
            series: UInt64,
            layer: UInt32,
            metadata: {String: String},
            rarity: String,
            basePrice: UFix64,
            svg: String,
            maxMintableComponents: UInt64
        ) {
            // increments the counter and stores it as the ID
            FlovatarDustCollectibleTemplate.totalSupply = FlovatarDustCollectibleTemplate.totalSupply + UInt64(1)
            self.id = FlovatarDustCollectibleTemplate.totalSupply
            self.name = name
            self.description = description
            self.series = series
            self.layer = layer
            self.metadata = metadata
            self.rarity = rarity
            self.basePrice = basePrice
            self.svg = svg
            self.maxMintableComponents = maxMintableComponents
        }
    }

    // Standard CollectionPublic interface that can also borrow Component Templates
    pub resource interface CollectionPublic {
        pub fun getIDs(): [UInt64]
        pub fun getSeriesIDs(): [UInt64]
        pub fun borrowCollectibleTemplate(id: UInt64): &{FlovatarDustCollectibleTemplate.Public}?
        pub fun borrowCollectibleSeries(id: UInt64): &{FlovatarDustCollectibleTemplate.PublicSeries}?
    }

    // The main Collection that manages the Templates and that implements also the Public interface
    pub resource Collection: CollectionPublic {
        // Dictionary of Component Templates
        pub var ownedCollectibleTemplates: @{UInt64: FlovatarDustCollectibleTemplate.CollectibleTemplate}
        pub var ownedCollectibleSeries: @{UInt64: FlovatarDustCollectibleTemplate.CollectibleSeries}

        init () {
            self.ownedCollectibleTemplates <- {}
            self.ownedCollectibleSeries <- {}
        }

        

        // deposit takes a Component Template and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(collectibleTemplate: @FlovatarDustCollectibleTemplate.CollectibleTemplate) {

            let id: UInt64 = collectibleTemplate.id

            // add the new Component Template to the dictionary which removes the old one
            let oldCollectibleTemplate <- self.ownedCollectibleTemplates[id] <- collectibleTemplate

            destroy oldCollectibleTemplate
        }

        // deposit takes a Series and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun depositSeries(collectibleSeries: @FlovatarDustCollectibleTemplate.CollectibleSeries) {

            let id: UInt64 = collectibleSeries.id

            // add the new Component Template to the dictionary which removes the old one
            let oldCollectibleTemplate <- self.ownedCollectibleSeries[id] <- collectibleSeries

            destroy oldCollectibleTemplate
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedCollectibleTemplates.keys
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getSeriesIDs(): [UInt64] {
            return self.ownedCollectibleSeries.keys
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

        // borrowCollectibleTemplate returns a borrowed reference to a Component Template
        // so that the caller can read data and call methods from it.
        pub fun borrowCollectibleSeries(id: UInt64): &{FlovatarDustCollectibleTemplate.PublicSeries}? {
            if self.ownedCollectibleSeries[id] != nil {
                let ref = (&self.ownedCollectibleSeries[id] as auth &FlovatarDustCollectibleTemplate.CollectibleSeries?)!
                return ref as! &FlovatarDustCollectibleTemplate.CollectibleSeries
            } else {
                return nil
            }
        }

        destroy() {
            destroy self.ownedCollectibleTemplates
            destroy self.ownedCollectibleSeries
        }
    }

    // This function can only be called by the account owner to create an empty Collection
    access(account) fun createEmptyCollection(): @FlovatarDustCollectibleTemplate.Collection {
        return <- create Collection()
    }




    // This struct is used to send a data representation of the Templates
    // when retrieved using the contract helper methods outside the collection.
    pub struct CollectibleSeriesData {
        pub let id: UInt64
        pub let name: String
        pub let description: String
        pub let svgPrefix: String
        pub let svgSuffix: String
        pub let priceIncrease: UFix64
        pub let layers: {UInt32: Layer}
        pub let colors: {UInt32: String}
        pub let metadata: {String: String}
        pub let maxMintable: UInt64

        init(
            id: UInt64,
            name: String,
            description: String,
            svgPrefix: String,
            svgSuffix: String,
            priceIncrease: UFix64,
            layers: {UInt32: Layer},
            colors: {UInt32: String},
            metadata: {String: String},
            maxMintable: UInt64
        ) {
            self.id = id
            self.name = name
            self.description = description
            self.svgPrefix = svgPrefix
            self.svgSuffix = svgSuffix
            self.priceIncrease = priceIncrease
            self.layers = layers
            self.colors = colors
            self.metadata = metadata
            self.maxMintable = maxMintable
        }
    }

    // This struct is used to send a data representation of the Templates 
    // when retrieved using the contract helper methods outside the collection.
    pub struct CollectibleTemplateData {
        pub let id: UInt64
        pub let name: String
        pub let description: String
        pub let series: UInt64
        pub let layer: UInt32
        pub let metadata: {String: String}
        pub let rarity: String
        pub let basePrice: UFix64
        pub let svg: String?
        pub let maxMintableComponents: UInt64
        pub let totalMintedComponents: UInt64
        pub let totalMintedCollectibles: UInt64
        pub let currentPrice: UFix64
        pub let lastComponentMintedAt: UFix64

        init(
            id: UInt64,
            name: String,
            description: String,
            series: UInt64,
            layer: UInt32,
            metadata: {String: String},
            rarity: String,
            basePrice: UFix64,
            svg: String?,
            maxMintableComponents: UInt64
        ) {
            self.id = id
            self.name = name
            self.description = description
            self.series = series
            self.layer = layer
            self.metadata = metadata
            self.rarity = rarity
            self.basePrice = basePrice
            self.svg = svg
            self.maxMintableComponents = maxMintableComponents
            self.totalMintedComponents = FlovatarDustCollectibleTemplate.getTotalMintedComponents(id: id)!
            self.totalMintedCollectibles = FlovatarDustCollectibleTemplate.getTotalMintedCollectibles(series: series)!
            self.currentPrice = FlovatarDustCollectibleTemplate.getTemplateCurrentPrice(id: id)!
            self.lastComponentMintedAt = FlovatarDustCollectibleTemplate.getLastComponentMintedAt(id: id)!
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
                    description: collectibleTemplate!.description,
                    series: collectibleTemplate!.series,
                    layer: collectibleTemplate!.layer,
                    metadata: collectibleTemplate!.metadata,
                    rarity: collectibleTemplate!.rarity,
                    basePrice: collectibleTemplate!.basePrice,
                    svg: nil,
                    maxMintableComponents: collectibleTemplate!.maxMintableComponents
                    ))
            }
        }
        return collectibleTemplateData
    }


    // Get all the Series from the account.
    // We hide the SVG field because it might be too big to execute in a script
    pub fun getCollectibleSeriesAll() : [CollectibleSeriesData] {
        var collectibleSeriesData: [CollectibleSeriesData] = []

        if let collectibleTemplateCollection = self.account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarDustCollectibleTemplate.CollectionPublic}>()  {
            for id in collectibleTemplateCollection.getSeriesIDs() {
                var collectibleSeries = collectibleTemplateCollection.borrowCollectibleSeries(id: id)
                collectibleSeriesData.append(CollectibleSeriesData(
                    id: id,
                    name: collectibleSeries!.name,
                    description: collectibleSeries!.description,
                    svgPrefix: collectibleSeries!.svgPrefix,
                    svgSuffix: collectibleSeries!.svgSuffix,
                    priceIncrease: collectibleSeries!.priceIncrease,
                    layers: collectibleSeries!.layers,
                    colors: collectibleSeries!.colors,
                    metadata: collectibleSeries!.metadata,
                    maxMintable: collectibleSeries!.maxMintable
                    ))
            }
        }
        return collectibleSeriesData
    }

    // Gets a specific Template from its ID
    pub fun getCollectibleTemplate(id: UInt64) : CollectibleTemplateData? {
        if let collectibleTemplateCollection = self.account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarDustCollectibleTemplate.CollectionPublic}>()  {
            if let collectibleTemplate = collectibleTemplateCollection.borrowCollectibleTemplate(id: id) {
                return CollectibleTemplateData(
                    id: id,
                    name: collectibleTemplate!.name,
                    description: collectibleTemplate!.description,
                    series: collectibleTemplate!.series,
                    layer: collectibleTemplate!.layer,
                    metadata: collectibleTemplate!.metadata,
                    rarity: collectibleTemplate!.rarity,
                    basePrice: collectibleTemplate!.basePrice,
                    svg: collectibleTemplate!.svg,
                    maxMintableComponents: collectibleTemplate!.maxMintableComponents
                    )
            }
        }
        return nil
    }

    // Gets the SVG of a specific Template from its ID
    pub fun getCollectibleTemplateSvg(id: UInt64) : String? {
        if let collectibleTemplateCollection = self.account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarDustCollectibleTemplate.CollectionPublic}>()  {
            if let collectibleTemplate = collectibleTemplateCollection.borrowCollectibleTemplate(id: id) {
                return collectibleTemplate!.svg
            }
        }
        return nil
    }


    // Gets a specific Series from its ID
    pub fun getCollectibleSeries(id: UInt64) : CollectibleSeriesData? {
        if let collectibleTemplateCollection = self.account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarDustCollectibleTemplate.CollectionPublic}>()  {
            if let collectibleSeries = collectibleTemplateCollection.borrowCollectibleSeries(id: id) {
                return CollectibleSeriesData(
                    id: id,
                    name: collectibleSeries!.name,
                    description: collectibleSeries!.description,
                    svgPrefix: collectibleSeries!.svgPrefix,
                    svgSuffix: collectibleSeries!.svgSuffix,
                    priceIncrease: collectibleSeries!.priceIncrease,
                    layers: collectibleSeries!.layers,
                    colors: collectibleSeries!.colors,
                    metadata: collectibleSeries!.metadata,
                    maxMintable: collectibleSeries!.maxMintable
                    )
            }
        }
        return nil
    }

    pub fun isCollectibleLayerAccessory(layer: UInt32, series: UInt64): Bool {
        let series = FlovatarDustCollectibleTemplate.getCollectibleSeries(id: series)!
        if let layer = series.layers[layer] {
            if(layer.isAccessory){
                return true
            }
        }
        return false
    }

    // Returns the amount of minted Components for a specific Template
    pub fun getTotalMintedComponents(id: UInt64) : UInt64? {
        return FlovatarDustCollectibleTemplate.totalMintedComponents[id]
    }
    // Returns the amount of minted Collectibles for a specific Series
    pub fun getTotalMintedCollectibles(series: UInt64) : UInt64? {
        return FlovatarDustCollectibleTemplate.totalMintedCollectibles[series]
    }
    // Returns the current price for a specific Template
    pub fun getTemplateCurrentPrice(id: UInt64) : UFix64? {
        return FlovatarDustCollectibleTemplate.templatesCurrentPrice[id]
    }

    // Returns the timestamp of the last time a Component for a specific Template was minted
    pub fun getLastComponentMintedAt(id: UInt64) : UFix64? {
        return FlovatarDustCollectibleTemplate.lastComponentMintedAt[id]
    }

    // This function is used within the contract to set the new counter for each Template
    access(account) fun setTotalMintedComponents(id: UInt64, value: UInt64) {
        FlovatarDustCollectibleTemplate.totalMintedComponents[id] = value
    }
    // This function is used within the contract to set the new counter for each Template
    access(account) fun increaseTotalMintedComponents(id: UInt64) {
        let totMintedComponents: UInt64? = FlovatarDustCollectibleTemplate.totalMintedComponents[id]
        if(totMintedComponents != nil){
            FlovatarDustCollectibleTemplate.totalMintedComponents[id] = totMintedComponents! + UInt64(1)
        }
    }
    // This function is used within the contract to set the new counter for each Series
    access(account) fun setTotalMintedCollectibles(series: UInt64, value: UInt64) {
        FlovatarDustCollectibleTemplate.totalMintedCollectibles[series] = value
    }
    // This function is used within the contract to set the new counter for each Template
    access(account) fun increaseTotalMintedCollectibles(series: UInt64) {
        let totMintedCollectibles: UInt64? = FlovatarDustCollectibleTemplate.totalMintedCollectibles[series]
        if(totMintedCollectibles != nil){
            FlovatarDustCollectibleTemplate.totalMintedCollectibles[series] = totMintedCollectibles! + UInt64(1)
        }
    }
    // This function is used within the contract to set the new counter for each Template
    access(account) fun setTemplatesCurrentPrice(id: UInt64, value: UFix64) {
        FlovatarDustCollectibleTemplate.templatesCurrentPrice[id] = value
    }
    // This function is used within the contract to set the new counter for each Template
    access(account) fun increaseTemplatesCurrentPrice(id: UInt64) {
        let currentPrice: UFix64? = FlovatarDustCollectibleTemplate.templatesCurrentPrice[id]
        if(currentPrice != nil){
            let template = FlovatarDustCollectibleTemplate.getCollectibleTemplate(id: id)
            let series = FlovatarDustCollectibleTemplate.getCollectibleSeries(id: template!.series)
            FlovatarDustCollectibleTemplate.templatesCurrentPrice[id] = currentPrice! * (UFix64(1.0) + series!.priceIncrease)
        }
    }
    // This function is used within the contract to set the timestamp 
    // when a Component for a specific Template was minted
    access(account) fun setLastComponentMintedAt(id: UInt64, value: UFix64) {
        FlovatarDustCollectibleTemplate.lastComponentMintedAt[id] = value
    }


    access(account) fun createCollectibleTemplate(
        name: String,
        description: String,
        series: UInt64,
        layer: UInt32,
        metadata: {String: String},
        rarity: String,
        basePrice: UFix64,
        svg: String,
        maxMintableComponents: UInt64
    ) : @FlovatarDustCollectibleTemplate.CollectibleTemplate {

        var newCollectibleTemplate <- create CollectibleTemplate(
            name: name,
            description: description,
            series: series,
            layer: layer,
            metadata: metadata,
            rarity: rarity,
            basePrice: basePrice,
            svg: svg,
            maxMintableComponents: maxMintableComponents
        )

        // Emits the Created event to notify about the new Template
        emit Created(id: newCollectibleTemplate.id, name: newCollectibleTemplate.name, series: newCollectibleTemplate.series, layer: newCollectibleTemplate.layer, maxMintableComponents: newCollectibleTemplate.maxMintableComponents)

        // Set the counter for the minted Components of this Template to 0
        FlovatarDustCollectibleTemplate.setTotalMintedComponents(id: newCollectibleTemplate.id, value: UInt64(0))
        FlovatarDustCollectibleTemplate.setTemplatesCurrentPrice(id: newCollectibleTemplate.id, value: basePrice)
        FlovatarDustCollectibleTemplate.setLastComponentMintedAt(id: newCollectibleTemplate.id, value: UFix64(0))

        return <- newCollectibleTemplate
    }

    access(account) fun createCollectibleSeries(
        name: String,
        description: String,
        svgPrefix: String,
        svgSuffix: String,
        priceIncrease: UFix64,
        layers: {UInt32: Layer},
        colors: {UInt32: String},
        metadata: {String: String},
        maxMintable: UInt64
    ) : @FlovatarDustCollectibleTemplate.CollectibleSeries {

        var newCollectibleSeries <- create CollectibleSeries(
            name: name,
            description: description,
            svgPrefix: svgPrefix,
            svgSuffix: svgSuffix,
            priceIncrease: priceIncrease,
            layers: layers,
            colors: colors,
            metadata: metadata,
            maxMintable: maxMintable
        )

        // Emits the Created event to notify about the new Template
        emit CreatedSeries(id: newCollectibleSeries.id, name: newCollectibleSeries.name, maxMintable: newCollectibleSeries.maxMintable)

        return <- newCollectibleSeries
    }
	init() {
        self.CollectionPublicPath=/public/FlovatarDustCollectibleTemplateCollection
        self.CollectionStoragePath=/storage/FlovatarDustCollectibleTemplateCollection

        // Initialize the total supply
        self.totalSupply = 0
        self.totalSeriesSupply = 0
        self.totalMintedComponents = {}
        self.totalMintedCollectibles = {}
        self.templatesCurrentPrice = {}
        self.lastComponentMintedAt = {}

        self.account.save<@FlovatarDustCollectibleTemplate.Collection>(<- FlovatarDustCollectibleTemplate.createEmptyCollection(), to: FlovatarDustCollectibleTemplate.CollectionStoragePath)
        self.account.link<&{FlovatarDustCollectibleTemplate.CollectionPublic}>(FlovatarDustCollectibleTemplate.CollectionPublicPath, target: FlovatarDustCollectibleTemplate.CollectionStoragePath)

        emit ContractInitialized()
	}
}
