/// CapabilityFilter defines `Filter`, an interface to sit on top of a ChildAccount's capabilities. Requested
/// capabilities will only return if the filter's `allowed` method returns true.
///
/// Along with the `Filter` interface are three implementations:
/// - `DenylistFilter`  - A filter which contains a mapping of denied Types
/// - `AllowlistFilter` - A filter which contains a mapping of allowed Types
/// - `AllowAllFilter`  - A passthrough, all requested capabilities are allowed
/// 
access(all) contract CapabilityFilter {
    
    /* --- Canonical Paths --- */
    //
    access(all) let StoragePath: StoragePath
    access(all) let PublicPath: PublicPath

    access(all) entitlement Add
    access(all) entitlement Delete

    /* --- Events --- */
    //
    access(all) event FilterUpdated(id: UInt64, filterType: Type, type: Type, active: Bool)

    /// `Filter` is a simple interface with methods to determine if a Capability is allowed and retrieve details about
    /// the Filter itself
    ///
    access(all) resource interface Filter {
        access(all) view fun allowed(cap: Capability): Bool
        access(all) view fun getDetails(): AnyStruct
    }

    /// `DenylistFilter` is a `Filter` which contains a mapping of denied Types
    ///
    access(all) resource DenylistFilter: Filter {

        /// Represents the underlying types which should not ever be returned by a RestrictedChildAccount. The filter
        /// will borrow a requested capability, and make sure that the type it gets back is not in the list of denied
        /// types
        access(self) let deniedTypes: {Type: Bool}

        /// Adds a type to the mapping of denied types with a value of true
        /// 
        /// @param type: The type to add to the denied types mapping
        ///
        access(Add) fun addType(_ type: Type) {
            self.deniedTypes.insert(key: type, true)
            emit FilterUpdated(id: self.uuid, filterType: self.getType(), type: type, active: true)
        }

        /// Removes a type from the mapping of denied types
        ///
        /// @param type: The type to remove from the denied types mapping
        ///
        access(Delete) fun removeType(_ type: Type) {
            if let removed = self.deniedTypes.remove(key: type) {
                emit FilterUpdated(id: self.uuid, filterType: self.getType(), type: type, active: false)
            }
        }

        /// Removes all types from the mapping of denied types
        ///
        access(Delete) fun removeAllTypes() {
            for type in self.deniedTypes.keys {
                self.removeType(type)
            }
        }

        /// Determines if a requested capability is allowed by this `Filter`
        ///
        /// @param cap: The capability to check
        /// @return: true if the capability is allowed, false otherwise
        ///
        access(all) view fun allowed(cap: Capability): Bool {
            if let item = cap.borrow<&AnyResource>() {
                return !self.deniedTypes.containsKey(item.getType())
            }

            return false
        }

        /// Returns details about this filter
        ///
        /// @return A struct containing details about this filter including this Filter's Type indexed on the `type`
        ///         key as well as types denied indexed on the `deniedTypes` key
        ///
        access(all) view fun getDetails(): AnyStruct {
            return {
                "type": self.getType(),
                "deniedTypes": self.deniedTypes.keys
            }
        }

        init() {
            self.deniedTypes = {}
        }
    }

    /// `AllowlistFilter` is a `Filter` which contains a mapping of allowed Types
    ///
    access(all) resource AllowlistFilter: Filter {
        // allowedTypes
        // Represents the set of underlying types which are allowed to be 
        // returned by a RestrictedChildAccount. The filter will borrow
        // a requested capability, and make sure that the type it gets back is
        // in the list of allowed types
        access(self) let allowedTypes: {Type: Bool}

        /// Adds a type to the mapping of allowed types with a value of true
        /// 
        /// @param type: The type to add to the allowed types mapping
        ///
        access(Add) fun addType(_ type: Type) {
            self.allowedTypes.insert(key: type, true)
            emit FilterUpdated(id: self.uuid, filterType: self.getType(), type: type, active: true)
        }

        /// Removes a type from the mapping of allowed types
        ///
        /// @param type: The type to remove from the denied types mapping
        ///
        access(Delete) fun removeType(_ type: Type) {
            if let removed = self.allowedTypes.remove(key: type) {
                emit FilterUpdated(id: self.uuid, filterType: self.getType(), type: type, active: false)
            }
        }

        /// Removes all types from the mapping of denied types
        ///
        access(Delete) fun removeAllTypes() {
            for type in self.allowedTypes.keys {
                self.removeType(type)
            }
        }
        
        /// Determines if a requested capability is allowed by this `Filter`
        ///
        /// @param cap: The capability to check
        /// @return: true if the capability is allowed, false otherwise
        ///
        access(all) view fun allowed(cap: Capability): Bool {
            if let item = cap.borrow<&AnyResource>() {
                return self.allowedTypes.containsKey(item.getType())
            }

            return false
        }

        /// Returns details about this filter
        ///
        /// @return A struct containing details about this filter including this Filter's Type indexed on the `type`
        ///         key as well as types allowed indexed on the `allowedTypes` key
        ///
        access(all) view fun getDetails(): AnyStruct {
            return {
                "type": self.getType(),
                "allowedTypes": self.allowedTypes.keys
            }
        }

        init() {
            self.allowedTypes = {}
        }
    }

    /// AllowAllFilter is a passthrough, all requested capabilities are allowed
    ///
    access(all) resource AllowAllFilter: Filter {
        /// Determines if a requested capability is allowed by this `Filter`
        ///
        /// @param cap: The capability to check
        /// @return: true since this filter is a passthrough
        ///
        access(all) view fun allowed(cap: Capability): Bool {
            return true
        }
        
        /// Returns details about this filter
        ///
        /// @return A struct containing details about this filter including this Filter's Type indexed on the `type`
        ///         key
        ///
        access(all) view fun getDetails(): AnyStruct {
            return {
                "type": self.getType()
            }
        }
    }

    /// Creates a new `Filter` of the given type
    ///
    /// @param t: The type of `Filter` to create
    /// @return: A new instance of the given `Filter` type
    ///
    access(all) fun createFilter(_ t: Type): @{Filter} {
        post {
            result.getType() == t
        }

        switch t {
            case Type<@AllowAllFilter>():
                return <- create AllowAllFilter()
            case Type<@AllowlistFilter>():
                return <- create AllowlistFilter()
            case Type<@DenylistFilter>():
                return <- create DenylistFilter()
        }

        panic("unsupported type requested: ".concat(t.identifier))
    }

    init() {
        let identifier = "CapabilityFilter_".concat(self.account.address.toString())
        
        self.StoragePath = StoragePath(identifier: identifier)!
        self.PublicPath = PublicPath(identifier: identifier)!
    }
}
