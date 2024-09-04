/// CapabilityDelegator is a contract used to share Capabiltities to other accounts. It is used by the
/// HybridCustody contract to allow more flexible sharing of Capabilities when an app wants to share things
/// that aren't the NFT-standard interface types.
/// 
/// Inside of CapabilityDelegator is a resource called `Delegator` which maintains a mapping of public and private
/// Capabilities. They cannot and should not be mixed. A public `Delegator` is able to be borrowed by anyone, whereas a
/// private `Delegator` can only be borrowed from the child account when you have access to the full `ChildAccount` 
/// resource.
///
access(all) contract CapabilityDelegator {

    /* --- Canonical Paths --- */
    //
    access(all) let StoragePath: StoragePath
    access(all) let PublicPath: PublicPath

    access(all) entitlement Get
    access(all) entitlement Add
    access(all) entitlement Delete
    
    /* --- Events --- */
    //
    access(all) event DelegatorCreated(id: UInt64)
    access(all) event DelegatorUpdated(id: UInt64, capabilityType: Type, isPublic: Bool, active: Bool)

    /// Private interface for Capability retrieval
    ///
    access(all) resource interface GetterPrivate {
        access(Get) view fun getPrivateCapability(_ type: Type): Capability? {
            post {
                result == nil || type.isSubtype(of: result.getType()): "incorrect returned capability type"
            }
        }
        access(all) view fun findFirstPrivateType(_ type: Type): Type?
        access(Get) fun getAllPrivate(): [Capability]
    }

    /// Exposes public Capability retrieval
    ///
    access(all) resource interface GetterPublic {
        access(all) view fun getPublicCapability(_ type: Type): Capability? {
            post {
                result == nil || type.isSubtype(of: result.getType()): "incorrect returned capability type"
            }
        }

        access(all) view fun findFirstPublicType(_ type: Type): Type?
        access(all) view fun getAllPublic(): [Capability]
    }

    /// This Delegator is used to store Capabilities, partitioned by public and private access with corresponding
    /// GetterPublic and GetterPrivate conformances.AccountCapabilityController
    ///
    access(all) resource Delegator: GetterPublic, GetterPrivate {
        access(self) let privateCapabilities: {Type: Capability}
        access(self) let publicCapabilities: {Type: Capability}

        // ------ Begin Getter methods
        //
        /// Returns the public Capability of the given Type if it exists
        ///
        access(all) view fun getPublicCapability(_ type: Type): Capability? {
            return self.publicCapabilities[type]
        }

        /// Returns the private Capability of the given Type if it exists
        ///
        ///
        /// @param type: Type of the Capability to retrieve
        /// @return Capability of the given Type if it exists, nil otherwise
        ///
        access(Get) view fun getPrivateCapability(_ type: Type): Capability? {
            return self.privateCapabilities[type]
        }

        /// Returns all public Capabilities
        ///
        /// @return List of all public Capabilities
        ///
        access(all) view fun getAllPublic(): [Capability] {
            return self.publicCapabilities.values
        }

        /// Returns all private Capabilities
        ///
        /// @return List of all private Capabilities
        ///
        access(Get) fun getAllPrivate(): [Capability] {
            return self.privateCapabilities.values
        }

        /// Returns the first public Type that is a subtype of the given Type
        ///
        /// @param type: Type to check for subtypes
        /// @return First public Type that is a subtype of the given Type, nil otherwise
        ///
        access(all) view fun findFirstPublicType(_ type: Type): Type? {
            for t in self.publicCapabilities.keys {
                if t.isSubtype(of: type) {
                    return t
                }
            }

            return nil
        }

        /// Returns the first private Type that is a subtype of the given Type
        ///
        /// @param type: Type to check for subtypes
        /// @return First private Type that is a subtype of the given Type, nil otherwise
        ///
        access(all) view fun findFirstPrivateType(_ type: Type): Type? {
            for t in self.privateCapabilities.keys {
                if t.isSubtype(of: type) {
                    return t
                }
            }

            return nil
        }
        // ------- End Getter methods

        /// Adds a Capability to the Delegator
        ///
        /// @param cap: Capability to add
        /// @param isPublic: Whether the Capability should be public or private
        ///
        access(Add) fun addCapability(cap: Capability, isPublic: Bool) {
            pre {
                cap.check<&AnyResource>(): "Invalid Capability provided"
            }
            if isPublic {
                self.publicCapabilities.insert(key: cap.getType(), cap)
            } else {
                self.privateCapabilities.insert(key: cap.getType(), cap)
            }
            emit DelegatorUpdated(id: self.uuid, capabilityType: cap.getType(), isPublic: isPublic, active: true)
        }

        /// Removes a Capability from the Delegator
        ///
        /// @param cap: Capability to remove
        ///
        access(Delete) fun removeCapability(cap: Capability) {
            if let removedPublic = self.publicCapabilities.remove(key: cap.getType()) {
                emit DelegatorUpdated(id: self.uuid, capabilityType: cap.getType(), isPublic: true, active: false)
            }
            
            if let removedPrivate = self.privateCapabilities.remove(key: cap.getType()) {
                emit DelegatorUpdated(id: self.uuid, capabilityType: cap.getType(), isPublic: false, active: false)
            }
        }

        init() {
            self.privateCapabilities = {}
            self.publicCapabilities = {}
        }
    }

    /// Creates a new Delegator and returns it
    /// 
    /// @return Newly created Delegator
    ///
    access(all) fun createDelegator(): @Delegator {
        let delegator <- create Delegator()
        emit DelegatorCreated(id: delegator.uuid)
        return <- delegator
    }
    
    init() {
        let identifier = "CapabilityDelegator_".concat(self.account.address.toString())
        self.StoragePath = StoragePath(identifier: identifier)!
        self.PublicPath = PublicPath(identifier: identifier)!
    }
}
 