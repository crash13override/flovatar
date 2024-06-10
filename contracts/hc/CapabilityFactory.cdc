/// # Capability Factory
///
/// This contract defines a Factory interface and a Manager resource to contain Factory implementations, as well as a
/// Getter interface for retrieval of contained Factories.
/// 
/// A Factory is defines a method getCapability() which defines the retrieval pattern of a Capability from a given
/// account at the specified path. This pattern arose out of a need to retrieve arbitrary & castable Capabilities from
/// an account under the static typing constraints inherent to Cadence.
///
/// The Manager resource is a container for Factories, and implements the Getter interface.
///
/// **Note:** It's generally an anti-pattern to pass around AuthAccount references; however, the need for castable
/// Capabilities is critical to the use case of Hybrid Custody. It's advised to use Factories sparingly and only for
/// cases where Capabilities must be castable by the caller.
///
access(all) contract CapabilityFactory {
    
    access(all) let StoragePath: StoragePath
    access(all) let PublicPath: PublicPath

    access(all) entitlement Add
    access(all) entitlement Delete
    
    /// Factory structures a common interface for Capability retrieval from a given account at a specified path
    ///
    access(all) struct interface Factory {
        access(all) view fun getCapability(acct: auth(Capabilities) &Account, controllerID: UInt64): Capability?
        access(all) view fun getPublicCapability(acct: &Account, path: PublicPath): Capability?
    }

    /// Getter defines an interface for retrieval of a Factory if contained within the implementing resource
    ///
    access(all) resource interface Getter {
        access(all) view fun getSupportedTypes(): [Type]
        access(all) view fun getFactory(_ t: Type): {CapabilityFactory.Factory}?
    }

    /// Manager is a resource that contains Factories and implements the Getter interface for retrieval of contained
    /// Factories
    ///
    access(all) resource Manager: Getter {
        /// Mapping of Factories indexed on Type of Capability they retrieve
        access(all) let factories: {Type: {CapabilityFactory.Factory}}

        /// Retrieves a list of Types supported by contained Factories
        ///
        /// @return List of Types supported by the Manager
        ///
        access(all) view fun getSupportedTypes(): [Type] {
            return self.factories.keys
        }

        /// Retrieves a Factory from the Manager, returning it or nil if it doesn't exist
        ///
        /// @param t: Type the Factory is indexed on
        ///
        access(all) view fun getFactory(_ t: Type): {CapabilityFactory.Factory}? {
            return self.factories[t]
        }

        /// Adds a Factory to the Manager, conditioned on the Factory not already existing
        ///
        /// @param t: Type of Capability the Factory retrieves
        /// @param f: Factory to add
        ///
        access(Add) fun addFactory(_ t: Type, _ f: {CapabilityFactory.Factory}) {
            pre {
                !self.factories.containsKey(t): "Factory of given type already exists"
            }
            self.factories[t] = f
        }

        /// Updates a Factory in the Manager, adding if it didn't already exist
        ///
        /// @param t: Type of Capability the Factory retrieves
        /// @param f: Factory to replace existing Factory
        ///
        access(Add) fun updateFactory(_ t: Type, _ f: {CapabilityFactory.Factory}) {
            self.factories[t] = f
        }

        /// Removes a Factory from the Manager, returning it or nil if it didn't exist
        ///
        /// @param t: Type the Factory is indexed on
        ///
        access(Delete) fun removeFactory(_ t: Type): {CapabilityFactory.Factory}? {
            return self.factories.remove(key: t)
        }

        init () {
            self.factories = {}
        }
    }

    /// Creates a Manager resource
    ///
    /// @return Manager resource
    access(all) fun createFactoryManager(): @Manager {
        return <- create Manager()
    }

    init() {
        let identifier = "CapabilityFactory_".concat(self.account.address.toString())
        self.StoragePath = StoragePath(identifier: identifier)!
        self.PublicPath = PublicPath(identifier: identifier)!
    }
}