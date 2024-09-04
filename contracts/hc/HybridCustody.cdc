// Third-party imports
import "MetadataViews"
import "ViewResolver"
import "Burner"

// HC-owned imports
import "CapabilityFactory"
import "CapabilityDelegator"
import "CapabilityFilter"

/// HybridCustody defines a framework for sharing accounts via account linking.
/// In the contract, there are three main resources:
///
/// 1. OwnedAccount - A resource which maintains an AuthAccount Capability, and handles publishing and revoking access
///    of that account via another resource called a ChildAccount
/// 2. ChildAccount - A second resource which exists on the same account as the OwnedAccount and contains the filters
///    and retrieval patterns governing the scope of parent account access. A Capability on this resource is shared to
///    the parent account, enabling Hybrid Custody access to the underlying account.
/// 3. Manager - A resource setup by the parent which manages all child accounts shared with it. The Manager resource
///    also maintains a set of accounts that it "owns", meaning it has a capability to the full OwnedAccount resource
///    and would then also be able to manage the child account's links as it sees fit.
/// 
/// Contributors (please add to this list if you contribute!):
/// - Austin Kline - https://twitter.com/austin_flowty
/// - Deniz Edincik - https://twitter.com/bluesign
/// - Giovanni Sanchez - https://twitter.com/gio_incognito
/// - Ashley Daffin - https://twitter.com/web3ashlee
/// - Felipe Ribeiro - https://twitter.com/Frlabs33
///
/// Repo reference: https://github.com/onflow/hybrid-custody
///
access(all) contract HybridCustody {
    access(all) entitlement Owner
    access(all) entitlement Child
    access(all) entitlement Manage

    /* --- Canonical Paths --- */
    //
    // Note: Paths for ChildAccount & Delegator are derived from the parent's address
    //
    access(all) let OwnedAccountStoragePath: StoragePath
    access(all) let OwnedAccountPublicPath: PublicPath

    access(all) let ManagerStoragePath: StoragePath
    access(all) let ManagerPublicPath: PublicPath

    /* --- Events --- */
    //
    /// Manager creation event
    access(all) event CreatedManager(id: UInt64)
    /// OwnedAccount creation event
    access(all) event CreatedOwnedAccount(id: UInt64, child: Address)
    /// ChildAccount added/removed from Manager
    ///     active  : added to Manager
    ///     !active : removed from Manager
    access(all) event AccountUpdated(id: UInt64?, child: Address, parent: Address?, active: Bool)
    /// OwnedAccount added/removed or sealed
    ///     active && owner != nil  : added to Manager 
    ///     !active && owner == nil : removed from Manager
    access(all) event OwnershipUpdated(id: UInt64, child: Address, previousOwner: Address?, owner: Address?, active: Bool)
    /// ChildAccount ready to be redeemed by emitted pendingParent
    access(all) event ChildAccountPublished(
        ownedAcctID: UInt64,
        childAcctID: UInt64,
        capDelegatorID: UInt64,
        factoryID: UInt64,
        filterID: UInt64,
        filterType: Type,
        child: Address,
        pendingParent: Address
    )
    /// OwnedAccount granted ownership to a new address, publishing a Capability for the pendingOwner
    access(all) event OwnershipGranted(ownedAcctID: UInt64, child: Address, previousOwner: Address?, pendingOwner: Address)
    /// Account has been sealed - keys revoked, new AuthAccount Capability generated
    access(all) event AccountSealed(id: UInt64, address: Address, parents: [Address])

    /// An OwnedAccount shares the BorrowableAccount capability to itelf with ChildAccount resources
    ///
    access(all) resource interface BorrowableAccount {
        access(contract) view fun _borrowAccount(): auth(Storage, Contracts, Keys, Inbox, Capabilities) &Account
        access(all) view fun check(): Bool
    }

    /// Public methods anyone can call on an OwnedAccount
    ///
    access(all) resource interface OwnedAccountPublic {
        /// Returns the addresses of all parent accounts
        access(all) view fun getParentAddresses(): [Address]

        /// Returns associated parent addresses and their redeemed status - true if redeemed, false if pending
        access(all) view fun getParentStatuses(): {Address: Bool}

        /// Returns true if the given address is a parent of this child and has redeemed it. Returns false if the given
        /// address is a parent of this child and has NOT redeemed it. Returns nil if the given address it not a parent
        /// of this child account.
        access(all) view fun getRedeemedStatus(addr: Address): Bool?

        /// A callback function to mark a parent as redeemed on the child account.
        access(contract) fun setRedeemed(_ addr: Address)

        /// A helper function to find what controller Id to ask for if you are looking for a specific type of capability
        access(all) view fun getControllerIDForType(type: Type, forPath: StoragePath): UInt64?
    }

    /// Private interface accessible to the owner of the OwnedAccount
    ///
    access(all) resource interface OwnedAccountPrivate {
        /// Deletes the ChildAccount resource being used to share access to this OwnedAccount with the supplied parent
        /// address, and unlinks the paths it was using to reach the underlying account.
        access(Owner) fun removeParent(parent: Address): Bool

        /// Sets up a new ChildAccount resource for the given parentAddress to redeem. This child account uses the
        /// supplied factory and filter to manage what can be obtained from the child account, and a new
        /// CapabilityDelegator resource is created for the sharing of one-off capabilities. Each of these pieces of
        /// access control are managed through the child account.
        access(Owner) fun publishToParent(
            parentAddress: Address,
            factory: Capability<&CapabilityFactory.Manager>,
            filter: Capability<&{CapabilityFilter.Filter}>
        ) {
            pre {
                factory.check(): "Invalid CapabilityFactory.Getter Capability provided"
                filter.check(): "Invalid CapabilityFilter Capability provided"
            }
        }

        /// Passes ownership of this child account to the given address. Once executed, all active keys on the child
        /// account will be revoked, and the active AuthAccount Capability being used by to obtain capabilities will be
        /// rotated, preventing anyone without the newly generated Capability from gaining access to the account.
        access(Owner) fun giveOwnership(to: Address)

        /// Revokes all keys on an account, unlinks all currently active AuthAccount capabilities, then makes a new one
        /// and replaces the OwnedAccount's underlying AuthAccount Capability with the new one to ensure that all
        /// parent accounts can still operate normally.
        /// Unless this method is executed via the giveOwnership function, this will leave an account **without** an
        /// owner.
        /// USE WITH EXTREME CAUTION.
        access(Owner) fun seal()

        // setCapabilityFactoryForParent
        // Override the existing CapabilityFactory Capability for a given parent. This will allow the owner of the
        // account to start managing their own factory of capabilities to be able to retrieve
        access(Owner) fun setCapabilityFactoryForParent(parent: Address, cap: Capability<&CapabilityFactory.Manager>) {
            pre {
                cap.check(): "Invalid CapabilityFactory.Getter Capability provided"
            }
        }

        /// Override the existing CapabilityFilter Capability for a given parent. This will allow the owner of the
        /// account to start managing their own filter for retrieving Capabilities
        access(Owner) fun setCapabilityFilterForParent(parent: Address, cap: Capability<&{CapabilityFilter.Filter}>) {
            pre {
                cap.check(): "Invalid CapabilityFilter Capability provided"
            }
        }

        /// Adds a capability to a parent's managed @ChildAccount resource. The Capability can be made public,
        /// permitting anyone to borrow it.
        access(Owner) fun addCapabilityToDelegator(parent: Address, cap: Capability, isPublic: Bool) {
            pre {
                cap.check<&AnyResource>(): "Invalid Capability provided"
            }
        }

        /// Removes a Capability from the CapabilityDelegator used by the specified parent address
        access(Owner) fun removeCapabilityFromDelegator(parent: Address, cap: Capability)

        /// Returns the address of this OwnedAccount
        access(all) view fun getAddress(): Address
        
        /// Checks if this OwnedAccount is a child of the specified address
        access(all) view fun isChildOf(_ addr: Address): Bool

        /// Returns all addresses which are parents of this OwnedAccount
        access(all) view fun getParentAddresses(): [Address]

        /// Borrows this OwnedAccount's AuthAccount Capability
        access(Owner) view fun borrowAccount(): auth(Storage, Contracts, Keys, Inbox, Capabilities) &Account

        /// Returns the current owner of this account, if there is one
        access(all) view fun getOwner(): Address?

        /// Returns the pending owner of this account, if there is one
        access(all) view fun getPendingOwner(): Address?

        /// A callback which is invoked when a parent redeems an owned account
        access(contract) fun setOwnerCallback(_ addr: Address)
        
        /// Destroys all outstanding AuthAccount capabilities on this owned account, and creates a new one for the
        /// OwnedAccount to use
        access(Owner) fun rotateAuthAccount()

        /// Revokes all keys on this account
        access(Owner) fun revokeAllKeys()
    }

    /// Public methods exposed on a ChildAccount resource. OwnedAccountPublic will share some methods here, but isn't
    /// necessarily the same.
    ///
    access(all) resource interface AccountPublic {
        access(all) view fun getPublicCapability(path: PublicPath, type: Type): Capability?
        access(all) view fun getPublicCapFromDelegator(type: Type): Capability?
        access(all) view fun getAddress(): Address
        access(all) view fun getCapabilityFactoryManager(): &{CapabilityFactory.Getter}?
        access(all) view fun getCapabilityFilter(): &{CapabilityFilter.Filter}?
        access(all) view fun getControllerIDForType(type: Type, forPath: StoragePath): UInt64?
    }

    /// Methods accessible to the designated parent of a ChildAccount
    ///
    access(all) resource interface AccountPrivate {
        access(Child) view fun getCapability(controllerID: UInt64, type: Type): Capability? {
            post {
                result == nil || [true, nil].contains(self.getManagerCapabilityFilter()?.allowed(cap: result!)):
                    "Capability is not allowed by this account's Parent"
            }
        }
        access(all) view fun getManagerCapabilityFilter():  &{CapabilityFilter.Filter}?
        access(Child) view fun getPrivateCapFromDelegator(type: Type): Capability? {
            post {
                result == nil || [true, nil].contains(self.getManagerCapabilityFilter()?.allowed(cap: result!)):
                    "Capability is not allowed by this account's Parent"
            }
        }
        access(contract) fun redeemedCallback(_ addr: Address)
        access(contract) fun setManagerCapabilityFilter(_ managerCapabilityFilter: Capability<&{CapabilityFilter.Filter}>?) {
            pre {
                managerCapabilityFilter == nil || managerCapabilityFilter!.check(): "Invalid Manager Capability Filter"
            }
        }
        access(contract) fun parentRemoveChildCallback(parent: Address)
    }

    /// Entry point for a parent to obtain, maintain and access Capabilities or perform other actions on child accounts
    ///
    access(all) resource interface ManagerPrivate {
        access(Manage) fun addAccount(cap: Capability<auth(Child) &{AccountPrivate, AccountPublic, ViewResolver.Resolver}>)
        access(Manage) fun borrowAccount(addr: Address): auth(Child) &{AccountPrivate, AccountPublic, ViewResolver.Resolver}?
        access(Manage) fun removeChild(addr: Address)
        access(Manage) fun addOwnedAccount(cap: Capability<auth(Owner) &{OwnedAccountPrivate, OwnedAccountPublic, ViewResolver.Resolver}>)
        access(Manage) fun borrowOwnedAccount(addr: Address): auth(Owner) &{OwnedAccountPrivate, OwnedAccountPublic, ViewResolver.Resolver}?
        access(Manage) fun removeOwned(addr: Address)
        access(Manage) fun setManagerCapabilityFilter(cap: Capability<&{CapabilityFilter.Filter}>?, childAddress: Address) {
            pre {
                cap == nil || cap!.check(): "Invalid Manager Capability Filter"
            }
        }
    }

    /// Functions anyone can call on a manager to get information about an account such as What child accounts it has
    /// Functions anyone can call on a manager to get information about an account such as what child accounts it has
    access(all) resource interface ManagerPublic {
        access(all) view fun borrowAccountPublic(addr: Address): &{AccountPublic, ViewResolver.Resolver}?
        access(all) view fun getChildAddresses(): [Address]
        access(all) view fun getOwnedAddresses(): [Address]
        access(all) view fun getChildAccountDisplay(address: Address): MetadataViews.Display?
        access(contract) fun removeParentCallback(child: Address)
    }

    /// A resource for an account which fills the Parent role of the Child-Parent account management Model. A Manager
    /// can redeem or remove child accounts, and obtain any capabilities exposed by the child account to them.
    ///
    access(all) resource Manager: ManagerPrivate, ManagerPublic, ViewResolver.Resolver, Burner.Burnable {
        access(all) event ResourceDestroyed(uuid: UInt64 = self.uuid)

        /// Mapping of restricted access child account Capabilities indexed by their address
        access(self) let childAccounts: {Address: Capability<auth(Child) &{AccountPrivate, AccountPublic, ViewResolver.Resolver}>}
        /// Mapping of unrestricted owned account Capabilities indexed by their address
        access(self) let ownedAccounts: {Address: Capability<auth(Owner) &{OwnedAccountPrivate, OwnedAccountPublic, ViewResolver.Resolver}>}

        /// A bucket of structs so that the Manager resource can be easily extended with new functionality.
        access(self) let data: {String: AnyStruct}
        /// A bucket of resources so that the Manager resource can be easily extended with new functionality.
        access(self) let resources: @{String: AnyResource}

        /// An optional filter to gate what capabilities are permitted to be returned from a child account For example,
        /// Dapper Wallet parent account's should not be able to retrieve any FungibleToken Provider capabilities.
        access(self) var filter: Capability<&{CapabilityFilter.Filter}>?

        // display metadata for a child account exists on its parent
        access(self) let childAccountDisplays: {Address: MetadataViews.Display}

        /// Sets the Display on the ChildAccount. If nil, the display is removed.
        ///
        access(Manage) fun setChildAccountDisplay(address: Address, _ d: MetadataViews.Display?) {
            pre {
                self.childAccounts[address] != nil: "There is no child account with this address"
            }

            if d == nil {
                self.childAccountDisplays.remove(key: address)
                return
            }

            self.childAccountDisplays[address] = d
        }

        /// Adds a ChildAccount Capability to this Manager. If a default Filter is set in the manager, it will also be
        /// added to the ChildAccount
        ///
        access(Manage) fun addAccount(cap: Capability<auth(Child) &{AccountPrivate, AccountPublic, ViewResolver.Resolver}>) {
            pre {
                self.childAccounts[cap.address] == nil: "There is already a child account with this address"
            }

            let acct = cap.borrow()
                ?? panic("child account capability could not be borrowed")

            self.childAccounts[cap.address] = cap
            
            emit AccountUpdated(id: acct.uuid, child: cap.address, parent: self.owner!.address, active: true)

            acct.redeemedCallback(self.owner!.address)
            acct.setManagerCapabilityFilter(self.filter)
        }

        /// Sets the default Filter Capability for this Manager. Does not propagate to child accounts.
        ///
        access(Manage) fun setDefaultManagerCapabilityFilter(cap: Capability<&{CapabilityFilter.Filter}>?) {
            pre {
                cap == nil || cap!.check(): "supplied capability must be nil or check must pass"
            }

            self.filter = cap
        }

        /// Sets the Filter Capability for this Manager, propagating to the specified child account
        ///
        access(Manage) fun setManagerCapabilityFilter(cap: Capability<&{CapabilityFilter.Filter}>?, childAddress: Address) {
            let acct = self.borrowAccount(addr: childAddress) 
                ?? panic("child account not found")

            acct.setManagerCapabilityFilter(cap)
        }

        /// Removes specified child account from the Manager's child accounts. Callbacks to the child account remove
        /// any associated resources and Capabilities
        ///
        access(Manage) fun removeChild(addr: Address) {
            let cap = self.childAccounts.remove(key: addr)
                ?? panic("child account not found")

            self.childAccountDisplays.remove(key: addr)
            
            if !cap.check() {
                // Emit event if invalid capability
                emit AccountUpdated(id: nil, child: cap.address, parent: self.owner!.address, active: false)
                return
            }

            let acct = cap.borrow()!
            // Get the child account id before removing capability
            let id: UInt64 = acct.uuid

            if self.owner != nil {
                acct.parentRemoveChildCallback(parent: self.owner!.address) 
            }

            emit AccountUpdated(id: id, child: cap.address, parent: self.owner?.address, active: false)
        }

        /// Contract callback that removes a child account from the Manager's child accounts in the event a child
        /// account initiates unlinking parent from child
        ///
        access(contract) fun removeParentCallback(child: Address) {
            self.childAccounts.remove(key: child)
            self.childAccountDisplays.remove(key: child)
        }

        /// Adds an owned account to the Manager's list of owned accounts, setting the Manager account as the owner of
        /// the given account
        ///
        access(Manage) fun addOwnedAccount(cap: Capability<auth(Owner) &{OwnedAccountPrivate, OwnedAccountPublic, ViewResolver.Resolver}>) {
            pre {
                self.ownedAccounts[cap.address] == nil: "There is already an owned account with this address"
            }

            let acct = cap.borrow()
                ?? panic("owned account capability could not be borrowed")

            // for safety, rotate the auth account capability to prevent any outstanding capabilities from the previous owner
            // and revoke all outstanding keys.
            acct.rotateAuthAccount()
            acct.revokeAllKeys()

            self.ownedAccounts[cap.address] = cap

            emit OwnershipUpdated(id: acct.uuid, child: cap.address, previousOwner: acct.getOwner(), owner: self.owner!.address, active: true)
            acct.setOwnerCallback(self.owner!.address)
        }

        /// Returns a reference to a child account
        ///
        access(Manage) fun borrowAccount(addr: Address): auth(Child) &{AccountPrivate, AccountPublic, ViewResolver.Resolver}? {
            let cap = self.childAccounts[addr]
            if cap == nil {
                return nil
            }

            return cap!.borrow()
        }

        /// Returns a reference to a child account's public AccountPublic interface
        ///
        access(all) view fun borrowAccountPublic(addr: Address): &{AccountPublic, ViewResolver.Resolver}? {
            let cap = self.childAccounts[addr]
            if cap == nil {
                return nil
            }

            return cap!.borrow()
        }

        /// Returns a reference to an owned account
        ///
        access(Manage) view fun borrowOwnedAccount(addr: Address): auth(Owner) &{OwnedAccountPrivate, OwnedAccountPublic, ViewResolver.Resolver}? {
            if let cap = self.ownedAccounts[addr] {
                return cap.borrow()
            }

            return nil
        }

        /// Removes specified child account from the Manager's child accounts. Callbacks to the child account remove
        /// any associated resources and Capabilities
        ///
        access(Manage) fun removeOwned(addr: Address) {
            if let acct = self.ownedAccounts.remove(key: addr) {
                if acct.check() {
                    acct.borrow()!.seal()
                }
                let id: UInt64? = acct.borrow()?.uuid ?? nil

                emit OwnershipUpdated(id: id!, child: addr, previousOwner: self.owner!.address, owner: nil, active: false)
            }
            // Don't emit an event if nothing was removed
        }

        /// Removes the owned Capabilty on the specified account, relinquishing access to the account and publishes a
        /// Capability for the specified account. See `OwnedAccount.giveOwnership()` for more details on this method.
        /// 
        /// **NOTE:** The existence of this method does not imply that it is the only way to receive access to a
        /// OwnedAccount Capability or that only the labeled `to` account has said access. Rather, this is a convenient
        /// mechanism intended to easily transfer 'root' access on this account to another account and an attempt to
        /// minimize access vectors.
        ///
        access(Manage) fun giveOwnership(addr: Address, to: Address) {
            let acct = self.ownedAccounts.remove(key: addr)
                ?? panic("account not found")

            acct.borrow()!.giveOwnership(to: to)
        }

        /// Returns an array of child account addresses
        ///
        access(all) view fun getChildAddresses(): [Address] {
            return self.childAccounts.keys
        }

        /// Returns an array of owned account addresses
        ///
        access(all) view fun getOwnedAddresses(): [Address] {
            return self.ownedAccounts.keys
        }

        /// Retrieves the parent-defined display for the given child account
        ///
        access(all) view fun getChildAccountDisplay(address: Address): MetadataViews.Display? {
            return self.childAccountDisplays[address]
        }

        /// Returns the types of supported views - none at this time
        ///
        access(all) view fun getViews(): [Type] {
            return []
        }

        /// Resolves the given view if supported - none at this time
        ///
        access(all) view fun resolveView(_ view: Type): AnyStruct? {
            return nil
        }

        init(filter: Capability<&{CapabilityFilter.Filter}>?) {
            pre {
                filter == nil || filter!.check(): "Invalid CapabilityFilter Filter capability provided"
            }
            self.childAccounts = {}
            self.ownedAccounts = {}
            self.childAccountDisplays = {}
            self.filter = filter

            self.data = {}
            self.resources <- {}
        }

        // When a manager resource is destroyed, attempt to remove this parent from every
        // child account it currently has
        //
        // Destruction will fail if there are any owned account to prevent loss of access to an account
        access(contract) fun burnCallback() {
            pre {
                // Prevent accidental burning of a resource that has ownership of other accounts
                self.ownedAccounts.length == 0: "cannot destroy a manager with owned accounts"
            }

            for c in self.childAccounts.keys {
                self.removeChild(addr: c)
            }
        }
    }

    /// The ChildAccount resource sits between a child account and a parent and is stored on the same account as the
    /// child account. Once created, a private capability to the child account is shared with the intended parent. The
    /// parent account will accept this child capability into its own manager resource and use it to interact with the
    /// child account.
    /// 
    /// Because the ChildAccount resource exists on the child account itself, whoever owns the child account will be
    /// able to manage all ChildAccount resources it shares, without worrying about whether the upstream parent can do
    /// anything to prevent it.
    /// 
    access(all) resource ChildAccount: AccountPrivate, AccountPublic, ViewResolver.Resolver, Burner.Burnable {
        access(all) event ResourceDestroyed(uuid: UInt64 = self.uuid, address: Address = self.childCap.address, parent: Address = self.parent)

        /// A Capability providing access to the underlying child account
        access(self) let childCap: Capability<&{BorrowableAccount, OwnedAccountPublic, ViewResolver.Resolver}>

        /// The CapabilityFactory Manager is a ChildAccount's way of limiting what types can be asked for by its parent
        /// account. The CapabilityFactory returns Capabilities which can be casted to their appropriate types once
        /// obtained, but only if the child account has configured their factory to allow it. For instance, a
        /// ChildAccount might choose to expose NonFungibleToken.Provider, but not FungibleToken.Provider
        access(self) var factory: Capability<&CapabilityFactory.Manager>

        /// The CapabilityFilter is a restriction put at the front of obtaining any non-public Capability. Some wallets
        /// might want to give access to NonFungibleToken.Provider, but only to **some** of the collections it manages,
        /// not all of them.
        access(self) var filter: Capability<&{CapabilityFilter.Filter}>

        /// The CapabilityDelegator is a way to share one-off capabilities from the child account. These capabilities
        /// can be public OR private and are separate from the factory which returns a capability at a given path as a 
        /// certain type. When using the CapabilityDelegator, you do not have the ability to specify which path a
        /// capability came from. For instance, Dapper Wallet might choose to expose a Capability to their Full TopShot
        /// collection, but only to the path that the collection exists in.
        access(self) let delegator: Capability<auth(CapabilityDelegator.Get) &CapabilityDelegator.Delegator>

        /// managerCapabilityFilter is a component optionally given to a child account when a manager redeems it. If
        /// this filter is not nil, any Capability returned through the `getCapability` function checks that the
        /// manager allows access first.
        access(self) var managerCapabilityFilter: Capability<&{CapabilityFilter.Filter}>?

        /// A bucket of structs so that the ChildAccount resource can be easily extended with new functionality.
        access(self) let data: {String: AnyStruct}

        /// A bucket of resources so that the ChildAccount resource can be easily extended with new functionality.
        access(self) let resources: @{String: AnyResource}

        /// ChildAccount resources have a 1:1 association with parent accounts, the named parent Address here is the 
        /// one with a Capability on this resource.
        access(all) let parent: Address

        /// Returns the Address of the underlying child account
        ///
        access(all) view fun getAddress(): Address {
            return self.childCap.address
        }

        /// Callback setting the child account as redeemed by the provided parent Address
        ///
        access(contract) fun redeemedCallback(_ addr: Address) {
            self.childCap.borrow()!.setRedeemed(addr)
        }

        /// Sets the given filter as the managerCapabilityFilter for this ChildAccount
        ///
        access(contract) fun setManagerCapabilityFilter(
            _ managerCapabilityFilter: Capability<&{CapabilityFilter.Filter}>?
        ) {
            self.managerCapabilityFilter = managerCapabilityFilter
        }

        /// Sets the CapabiltyFactory.Manager Capability
        ///
        access(contract) fun setCapabilityFactory(cap: Capability<&CapabilityFactory.Manager>) {
            self.factory = cap
        }
 
        /// Sets the Filter Capability as the one provided
        ///
        access(contract) fun setCapabilityFilter(cap: Capability<&{CapabilityFilter.Filter}>) {
            self.filter = cap
        }

        /// The main function to a child account's capabilities from a parent account. When getting a capability, the CapabilityFilter will be borrowed and
        /// the Capability being returned will be checked against it to
        /// ensure that borrowing is permitted. If not allowed, nil is returned.
        /// Also know that this method retrieves Capabilities via the CapabilityFactory path. To retrieve arbitrary 
        /// Capabilities, see `getPrivateCapFromDelegator()` and `getPublicCapFromDelegator()` which use the
        /// `Delegator` retrieval path.
        ///
        access(Child) view fun getCapability(controllerID: UInt64, type: Type): Capability? {
            let child = self.childCap.borrow() ?? panic("failed to borrow child account")

            let f = self.factory.borrow()!.getFactory(type)
            if f == nil {
                return nil
            }

            let acct = child._borrowAccount()
            let tmp = f!.getCapability(acct: acct, controllerID: controllerID)
            if tmp == nil {
                return nil
            }

            let cap = tmp!
            // Check that private capabilities are allowed by either internal or manager filter (if assigned)
            // If not allowed, return nil
            if self.filter.borrow()!.allowed(cap: cap) == false || (self.getManagerCapabilityFilter()?.allowed(cap: cap) ?? true) == false {
                return nil
            }

            return cap
        }

        /// Retrieves a private Capability from the Delegator or nil none is found of the given type. Useful for
        /// arbitrary Capability retrieval
        ///
        access(Child) view fun getPrivateCapFromDelegator(type: Type): Capability? {
            if let d = self.delegator.borrow() {
                return d.getPrivateCapability(type)
            }

            return nil
        }

        /// Retrieves a public Capability from the Delegator or nil none is found of the given type. Useful for
        /// arbitrary Capability retrieval
        ///
        access(all) view fun getPublicCapFromDelegator(type: Type): Capability? {
            if let d = self.delegator.borrow() {
                return d.getPublicCapability(type)
            }
            return nil
        }

        /// Enables retrieval of public Capabilities of the given type from the specified path or nil if none is found.
        /// Callers should be aware this method uses the `CapabilityFactory` retrieval path.
        ///
        access(all) view fun getPublicCapability(path: PublicPath, type: Type): Capability? {
            let child = self.childCap.borrow() ?? panic("failed to borrow child account")

            let f = self.factory.borrow()!.getFactory(type)
            if f == nil {
                return nil
            }

            let acct = child._borrowAccount()
            return f!.getPublicCapability(acct: acct, path: path)
        }

        /// Returns a reference to the stored managerCapabilityFilter if one exists
        ///
        access(all) view fun getManagerCapabilityFilter(): &{CapabilityFilter.Filter}? {
            return self.managerCapabilityFilter != nil ? self.managerCapabilityFilter!.borrow() : nil
        }

        /// Sets the child account as redeemed by the given Address
        ///
        access(contract) fun setRedeemed(_ addr: Address) {
            let acct = self.childCap.borrow()!._borrowAccount()
            acct.storage.borrow<&OwnedAccount>(from: HybridCustody.OwnedAccountStoragePath)?.setRedeemed(addr)
        }

        /// Returns a reference to the stored delegator, generally used for arbitrary Capability retrieval
        ///
        access(Owner) fun borrowCapabilityDelegator(): auth(CapabilityDelegator.Get) &CapabilityDelegator.Delegator? {
            let path = HybridCustody.getCapabilityDelegatorIdentifier(self.parent)
            return self.childCap.borrow()!._borrowAccount().storage.borrow<auth(CapabilityDelegator.Get) &CapabilityDelegator.Delegator>(
                from: StoragePath(identifier: path)!
            )
        }

        /// Returns a list of supported metadata views
        ///
        access(all) view fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>()
            ]
        }

        /// Resolves a view of the given type if supported
        ///
        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    let childAddress = self.getAddress()
                    let tmp = getAccount(self.parent).capabilities.get<&{HybridCustody.ManagerPublic}>(HybridCustody.ManagerPublicPath)
                    if tmp == nil {
                        return nil
                    }

                    let manager = tmp!

                    if !manager.check() {
                        return nil
                    }

                    return manager.borrow()!.getChildAccountDisplay(address: childAddress)
            }
            return nil
        }

        /// Callback to enable parent-initiated removal all the child account and its associated resources &
        /// Capabilities
        ///
        access(contract) fun parentRemoveChildCallback(parent: Address) {
            if !self.childCap.check() {
                return
            }

            let child: &{HybridCustody.BorrowableAccount} = self.childCap.borrow()!
            if !child.check() {
                return
            }

            let acct = child._borrowAccount()
            if let ownedAcct = acct.storage.borrow<auth(Owner) &OwnedAccount>(from: HybridCustody.OwnedAccountStoragePath) {
                ownedAcct.removeParent(parent: parent)
            }
        }

        init(
            _ childCap: Capability<&{BorrowableAccount, OwnedAccountPublic, ViewResolver.Resolver}>,
            _ factory: Capability<&CapabilityFactory.Manager>,
            _ filter: Capability<&{CapabilityFilter.Filter}>,
            _ delegator: Capability<auth(CapabilityDelegator.Get) &CapabilityDelegator.Delegator>,
            _ parent: Address
        ) {
            pre {
                childCap.check(): "Provided childCap Capability is invalid"
                factory.check(): "Provided factory Capability is invalid"
                filter.check(): "Provided filter Capability is invalid"
                delegator.check(): "Provided delegator Capability is invalid"
            }
            self.childCap = childCap
            self.factory = factory
            self.filter = filter
            self.delegator = delegator
            self.managerCapabilityFilter = nil // this will get set when a parent account redeems
            self.parent = parent

            self.data = {}
            self.resources <- {}
        }

        /// Returns a capability to this child account's CapabilityFilter
        ///
        access(all) view fun getCapabilityFilter(): &{CapabilityFilter.Filter}? {
            return self.filter.check() ? self.filter.borrow() : nil
        }

        /// Returns a capability to this child account's CapabilityFactory
        ///
        access(all) view fun getCapabilityFactoryManager(): &{CapabilityFactory.Getter}? {
            return self.factory.check() ? self.factory.borrow() : nil
        }

        access(all) view fun getControllerIDForType(type: Type, forPath: StoragePath): UInt64? {
            let child = self.childCap.borrow()
            if child == nil {
                return nil
            }

            return child!.getControllerIDForType(type: type, forPath: forPath)
        }

        // When a ChildAccount is destroyed, attempt to remove it from the parent account as well
        access(contract) fun burnCallback() {
            self.parentRemoveChildCallback(parent: self.parent)
        }
    }

    /// A resource which sits on the account it manages to make it easier for apps to configure the behavior they want 
    /// to permit. An OwnedAccount can be used to create ChildAccount resources and share them, publishing them to
    /// other addresses.
    /// 
    /// The OwnedAccount can also be used to pass ownership of an account off to another address, or to relinquish
    /// ownership entirely, marking the account as owned by no one. Note that even if there isn't an owner, the parent
    /// accounts would still exist, allowing a form of Hybrid Custody which has no true owner over an account, but
    /// shared partial ownership.
    ///
    access(all) resource OwnedAccount: OwnedAccountPrivate, BorrowableAccount, OwnedAccountPublic, ViewResolver.Resolver, Burner.Burnable {
        access(all) event ResourceDestroyed(uuid: UInt64 = self.uuid, addr: Address = self.acct.address)
        /// Capability on the underlying account object
        access(self) var acct: Capability<auth(Storage, Contracts, Keys, Inbox, Capabilities) &Account>

        /// Mapping of current and pending parents, true and false respectively
        access(all) let parents: {Address: Bool}
        /// Address of the pending owner, if one exists
        access(all) var pendingOwner: Address?
        /// Address of the current owner, if one exists
        access(all) var acctOwner: Address?
        /// Owned status of this account
        access(all) var currentlyOwned: Bool

        /// A bucket of structs so that the OwnedAccount resource can be easily extended with new functionality.
        access(self) let data: {String: AnyStruct}

        /// A bucket of resources so that the OwnedAccount resource can be easily extended with new functionality.
        access(self) let resources: @{String: AnyResource}

        /// display is its own field on the OwnedAccount resource because only the owner of the child account should be
        /// able to set this field.
        access(self) var display: MetadataViews.Display?

        /// Callback that sets this OwnedAccount as redeemed by the parent
        ///
        access(contract) fun setRedeemed(_ addr: Address) {
            pre {
                self.parents[addr] != nil: "address is not waiting to be redeemed"
            }

            self.parents[addr] = true
        }

        /// Callback that sets the owner once redeemed
        ///
        access(contract) fun setOwnerCallback(_ addr: Address) {
            pre {
                self.pendingOwner == addr: "Address does not match pending owner!"
            }
            self.pendingOwner = nil
            self.acctOwner = addr
        }


        /// A helper method to make it easier to manage what parents an account has configured. The steps to sharing this
        /// OwnedAccount with a new parent are:
        /// 
        /// 1. Create a new CapabilityDelegator for the ChildAccount resource being created. We make a new one here because
        ///    CapabilityDelegator types are meant to be shared explicitly. Making one shared base-line of capabilities might
        ///    introduce unforseen behavior where an app accidentally shared something to all accounts when it only meant
        ///    to go to one of them. It is better for parent accounts to have less access than they might have anticipated,
        ///    than for a child to have given out access it did not intend to.
        /// 2. Create a new Capability<&{BorrowableAccount}> which has its own unique path for the parent to share this
        ///    child account with. We make new ones each time so that you can revoke access from one parent, without
        ///    destroying them all. A new link is made each time based on the address being shared to allow this
        ///    fine-grained control, but it is all managed by the OwnedAccount resource itself.
        /// 3. A new @ChildAccount resource is created and saved, using the CapabilityDelegator made in step one, and our
        ///    CapabilityFactory and CapabilityFilter Capabilities. Once saved, public and private links are configured for
        ///    the ChildAccount.
        /// 4. Publish the newly made private link to the designated parent's inbox for them to claim on their @Manager
        ///    resource.
        ///
        access(Owner) fun publishToParent(
            parentAddress: Address,
            factory: Capability<&CapabilityFactory.Manager>,
            filter: Capability<&{CapabilityFilter.Filter}>
        ) {
            pre {
                self.parents[parentAddress] == nil: "Address pending or already redeemed as parent"
            }
            let capDelegatorIdentifier = HybridCustody.getCapabilityDelegatorIdentifier(parentAddress)

            let identifier = HybridCustody.getChildAccountIdentifier(parentAddress)
            let childAccountStorage = StoragePath(identifier: identifier)!

            let capDelegatorStorage = StoragePath(identifier: capDelegatorIdentifier)!
            let acct = self.borrowAccount()

            assert(acct.storage.borrow<&AnyResource>(from: capDelegatorStorage) == nil, message: "conflicting resource found in capability delegator storage slot for parentAddress")
            assert(acct.storage.borrow<&AnyResource>(from: childAccountStorage) == nil, message: "conflicting resource found in child account storage slot for parentAddress")

            if acct.storage.borrow<&CapabilityDelegator.Delegator>(from: capDelegatorStorage) == nil {
                let delegator <- CapabilityDelegator.createDelegator()
                acct.storage.save(<-delegator, to: capDelegatorStorage)
            }

            let capDelegatorPublic = PublicPath(identifier: capDelegatorIdentifier)!

            let pubCap = acct.capabilities.storage.issue<&{CapabilityDelegator.GetterPublic}>(capDelegatorStorage)
            acct.capabilities.publish(pubCap, at: capDelegatorPublic)

            let delegator = acct.capabilities.storage.issue<auth(CapabilityDelegator.Get) &CapabilityDelegator.Delegator>(capDelegatorStorage)
            assert(delegator.check(), message: "failed to setup capability delegator for parent address")

            let borrowableCap = self.borrowAccount().capabilities.storage.issue<&{BorrowableAccount, OwnedAccountPublic, ViewResolver.Resolver}>(
                HybridCustody.OwnedAccountStoragePath
            )

            let childAcct <- create ChildAccount(borrowableCap, factory, filter, delegator, parentAddress)

            acct.storage.save(<-childAcct, to: childAccountStorage)            
            let delegatorCap = acct.capabilities.storage.issue<auth(Child) &{AccountPrivate, AccountPublic, ViewResolver.Resolver}>(childAccountStorage)
            assert(delegatorCap.check(), message: "Delegator capability check failed")

            acct.inbox.publish(delegatorCap, name: identifier, recipient: parentAddress)
            self.parents[parentAddress] = false

            emit ChildAccountPublished(
                ownedAcctID: self.uuid,
                childAcctID: delegatorCap.borrow()!.uuid,
                capDelegatorID: delegator.borrow()!.uuid,
                factoryID: factory.borrow()!.uuid,
                filterID: filter.borrow()!.uuid,
                filterType: filter.borrow()!.getType(),
                child: self.getAddress(),
                pendingParent: parentAddress
            )
        }

        /// Checks the validity of the encapsulated account Capability
        ///
        access(all) view fun check(): Bool {
            return self.acct.check()
        }

        /// Returns a reference to the encapsulated account object
        ///
        access(Owner) view fun borrowAccount(): auth(Storage, Contracts, Keys, Inbox, Capabilities) &Account {
            return self.acct.borrow() ?? panic("unable to borrow Account Capability")
        }

        // Used internally so that child account resources are able to borrow their underlying Account reference
        access(contract) view fun _borrowAccount(): auth(Storage, Contracts, Keys, Inbox, Capabilities) &Account {
            return self.borrowAccount()
        }

        /// Returns the addresses of all associated parents pending and active
        ///
        access(all) view fun getParentAddresses(): [Address] {
            return self.parents.keys
        }

        /// Returns whether the given address is a parent of this account
        ///
        access(all) view fun isChildOf(_ addr: Address): Bool {
            return self.parents[addr] != nil
        }

        /// Returns nil if the given address is not a parent, false if the parent has not redeemed the child account
        /// yet, and true if they have
        ///
        access(all) view fun getRedeemedStatus(addr: Address): Bool? {
            return self.parents[addr]
        }

        /// Returns associated parent addresses and their redeemed status
        ///
        access(all) view fun getParentStatuses(): {Address: Bool} {
            return self.parents
        }

        /// Unlinks all paths configured when publishing an account, and destroy's the @ChildAccount resource 
        /// configured for the provided parent address. Once done, the parent will not have any valid capabilities with
        /// which to access the child account.
        ///
        access(Owner) fun removeParent(parent: Address): Bool {
            if self.parents[parent] == nil {
                return false
            }

            let identifier = HybridCustody.getChildAccountIdentifier(parent)
            let capDelegatorIdentifier = HybridCustody.getCapabilityDelegatorIdentifier(parent)

            let acct = self.borrowAccount()

            // get all controllers which target this storage path
            let storagePath = StoragePath(identifier: identifier)!
            let childAccountControllers = acct.capabilities.storage.getControllers(forPath: storagePath)
            for c in childAccountControllers {
                c.delete()
            }
            Burner.burn(<- acct.storage.load<@AnyResource>(from: storagePath))

            let delegatorStoragePath = StoragePath(identifier: capDelegatorIdentifier)!
            let delegatorControllers = acct.capabilities.storage.getControllers(forPath: delegatorStoragePath)
            for c in delegatorControllers {
                c.delete()
            }
            Burner.burn(<- acct.storage.load<@AnyResource>(from: delegatorStoragePath))

            self.parents.remove(key: parent)
            emit AccountUpdated(id: self.uuid, child: self.acct.address, parent: parent, active: false)

            let parentManager = getAccount(parent).capabilities.get<&{ManagerPublic}>(HybridCustody.ManagerPublicPath)
            if parentManager.check() {
                parentManager.borrow()?.removeParentCallback(child: acct.address)
            }

            return true
        }

        /// Returns the address of the encapsulated account
        ///
        access(all) view fun getAddress(): Address {
            return self.acct.address
        }

        /// Returns the address of the pending owner if one is assigned. Pending owners are assigned when ownership has
        /// been granted, but has not yet been redeemed.
        ///
        access(all) view fun getPendingOwner(): Address? {
            return self.pendingOwner
        }

        /// Returns the address of the current owner if one is assigned. Current owners are assigned when ownership has
        /// been redeemed.
        ///
        access(all) view fun getOwner(): Address? {
            if !self.currentlyOwned {
                return nil
            }
            return self.acctOwner != nil ? self.acctOwner! : self.owner!.address
        }

        /// This method is used to transfer ownership of the child account to a new address.
        /// Ownership here means that one has unrestricted access on this OwnedAccount resource, giving them full
        /// access to the account.
        ///
        /// **NOTE:** The existence of this method does not imply that it is the only way to receive access to a
        /// OwnedAccount Capability or that only the labeled 'acctOwner' has said access. Rather, this is a convenient
        /// mechanism intended to easily transfer 'root' access on this account to another account and an attempt to
        /// minimize access vectors.
        ///
        access(Owner) fun giveOwnership(to: Address) {
            self.seal()
            
            let acct = self.borrowAccount()

            // Link a Capability for the new owner, retrieve & publish
            let identifier =  HybridCustody.getOwnerIdentifier(to)
            let cap = acct.capabilities.storage.issue<auth(Owner) &{OwnedAccountPrivate, OwnedAccountPublic, ViewResolver.Resolver}>(HybridCustody.OwnedAccountStoragePath)

            // make sure we can borrow the newly issued owned account
            cap.borrow()?.borrowAccount() ?? panic("can not borrow the Hybrid Custody Owned Account")

            acct.inbox.publish(cap, name: identifier, recipient: to)

            self.pendingOwner = to
            self.currentlyOwned = true

            emit OwnershipGranted(ownedAcctID: self.uuid, child: self.acct.address, previousOwner: self.getOwner(), pendingOwner: to)
        }

        /// Revokes all keys on the underlying account
        ///
        access(Owner) fun revokeAllKeys() {
            let acct = self.borrowAccount()

            // Revoke all keys
            acct.keys.forEach(fun (key: AccountKey): Bool {
                if !key.isRevoked {
                    acct.keys.revoke(keyIndex: key.keyIndex)
                }
                return true
            })
        }

        /// Cancels all existing AuthAccount capabilities, and creates a new one. The newly created capability will 
        /// then be used by the child account for accessing its AuthAccount going forward.
        ///
        /// This is used when altering ownership of an account, and can also be used as a safeguard for anyone who
        /// assumes ownership of an account to guarantee that the previous owner doesn't maintain admin access to the
        /// account via other AuthAccount Capabilities.
        ///
        access(Owner) fun rotateAuthAccount() {
            let acct = self.borrowAccount()

            // Find all active AuthAccount capabilities so they can be removed after we make the new auth account cap
            let controllersToDestroy = acct.capabilities.account.getControllers()

            // Link a new AuthAccount Capability
            let acctCap = acct.capabilities.account.issue<auth(Storage, Contracts, Keys, Inbox, Capabilities) &Account>()

            self.acct = acctCap
            let newAcct = self.acct.borrow()!

            // cleanup, remove all previously found paths. We had to do it in this order because we will be unlinking
            // the existing path which will cause a deference issue with the originally borrowed auth account
            for con in controllersToDestroy {
                newAcct.capabilities.account.getController(byCapabilityID: con.capabilityID)?.delete()
            }

            assert(self.acct.check(), message: "new auth account capability is not valid")
        }

        /// Revokes all keys on an account, unlinks all currently active AuthAccount capabilities, then makes a new one
        /// and replaces the @OwnedAccount's underlying AuthAccount Capability with the new one to ensure that all parent
        /// accounts can still operate normally.
        /// Unless this method is executed via the giveOwnership function, this will leave an account **without** an owner.
        ///
        /// USE WITH EXTREME CAUTION.
        ///
        access(Owner) fun seal() {
            self.rotateAuthAccount()
            self.revokeAllKeys() // There needs to be a path to giving ownership that doesn't revoke keys   
            emit AccountSealed(id: self.uuid, address: self.acct.address, parents: self.parents.keys)
            self.currentlyOwned = false
        }

        /// Retrieves a reference to the ChildAccount associated with the given parent account if one exists.
        ///
        access(Owner) fun borrowChildAccount(parent: Address): auth(Child) &ChildAccount? {
            let identifier = HybridCustody.getChildAccountIdentifier(parent)
            return self.borrowAccount().storage.borrow<auth(Child) &ChildAccount>(from: StoragePath(identifier: identifier)!)
        }

        /// Sets the CapabilityFactory Manager for the specified parent in the associated ChildAccount.
        ///
        access(Owner) fun setCapabilityFactoryForParent(
            parent: Address,
            cap: Capability<&CapabilityFactory.Manager>
        ) {
            let p = self.borrowChildAccount(parent: parent) ?? panic("could not find parent address")
            p.setCapabilityFactory(cap: cap)
        }

        /// Sets the Filter for the specified parent in the associated ChildAccount.
        ///
        access(Owner) fun setCapabilityFilterForParent(parent: Address, cap: Capability<&{CapabilityFilter.Filter}>) {
            let p = self.borrowChildAccount(parent: parent) ?? panic("could not find parent address")
            p.setCapabilityFilter(cap: cap)
        }

        /// Retrieves a reference to the Delegator associated with the given parent account if one exists.
        ///
        access(Owner) fun borrowCapabilityDelegatorForParent(parent: Address): auth(CapabilityDelegator.Get, CapabilityDelegator.Add, CapabilityDelegator.Delete) &CapabilityDelegator.Delegator? {
            let identifier = HybridCustody.getCapabilityDelegatorIdentifier(parent)
            return self.borrowAccount().storage.borrow<auth(CapabilityDelegator.Get, CapabilityDelegator.Add, CapabilityDelegator.Delete) &CapabilityDelegator.Delegator>(from: StoragePath(identifier: identifier)!)
        }

        /// Adds the provided Capability to the Delegator associated with the given parent account.
        ///
        access(Owner) fun addCapabilityToDelegator(parent: Address, cap: Capability, isPublic: Bool) {
            let p = self.borrowChildAccount(parent: parent) ?? panic("could not find parent address")
            let delegator = self.borrowCapabilityDelegatorForParent(parent: parent)
                ?? panic("could not borrow capability delegator resource for parent address")
            delegator.addCapability(cap: cap, isPublic: isPublic)
        }

        /// Removes the provided Capability from the Delegator associated with the given parent account.
        ///
        access(Owner) fun removeCapabilityFromDelegator(parent: Address, cap: Capability) {
            let p = self.borrowChildAccount(parent: parent) ?? panic("could not find parent address")
            let delegator = self.borrowCapabilityDelegatorForParent(parent: parent)
                ?? panic("could not borrow capability delegator resource for parent address")
            delegator.removeCapability(cap: cap)
        }

        access(all) view fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>()
            ]
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return self.display
            }
            return nil
        }

        /// Sets this OwnedAccount's display to the one provided
        ///
        access(Owner) fun setDisplay(_ d: MetadataViews.Display) {
            self.display = d
        }

        access(all) view fun getControllerIDForType(type: Type, forPath: StoragePath): UInt64? {
            let acct = self.acct.borrow()
            if acct == nil {
                return nil
            }

            for c in acct!.capabilities.storage.getControllers(forPath: forPath) {
                if c.borrowType.isSubtype(of: type) {
                    return c.capabilityID
                }
            }

            return nil
        }

        init(
            _ acct: Capability<auth(Storage, Contracts, Keys, Inbox, Capabilities) &Account>
        ) {
            self.acct = acct

            self.parents = {}
            self.pendingOwner = nil
            self.acctOwner = nil
            self.currentlyOwned = true

            self.data = {}
            self.resources <- {}
            self.display = nil
        }

        // When an OwnedAccount is destroyed, remove it from every configured parent account
        access(contract) fun burnCallback() {
            for p in self.parents.keys {
                self.removeParent(parent: p)
            }
        }
    }

    /// Utility function to get the path identifier for a parent address when interacting with a ChildAccount and its
    /// parents
    ///
    access(all) view fun getChildAccountIdentifier(_ addr: Address): String {
        return "ChildAccount_".concat(addr.toString())
    }

    /// Utility function to get the path identifier for a parent address when interacting with a Delegator and its
    /// parents
    ///
    access(all) view fun getCapabilityDelegatorIdentifier(_ addr: Address): String {
        return "ChildCapabilityDelegator_".concat(addr.toString())
    }

    /// Utility function to get the path identifier for a parent address when interacting with an OwnedAccount and its
    /// owners
    ///
    access(all) view fun getOwnerIdentifier(_ addr: Address): String {
        return "HybridCustodyOwnedAccount_".concat(HybridCustody.account.address.toString()).concat(addr.toString())
    }

    /// Returns an OwnedAccount wrapping the provided AuthAccount Capability.
    ///
    access(all) fun createOwnedAccount(
        acct: Capability<auth(Storage, Contracts, Keys, Inbox, Capabilities) &Account>
    ): @OwnedAccount {
        pre {
            acct.check(): "invalid auth account capability"
        }

        let ownedAcct <- create OwnedAccount(acct)
        emit CreatedOwnedAccount(id: ownedAcct.uuid, child: acct.borrow()!.address)
        return <- ownedAcct
    }

    /// Returns a new Manager with the provided Filter as default (if not nil).
    ///
    access(all) fun createManager(filter: Capability<&{CapabilityFilter.Filter}>?): @Manager {
        pre {
            filter == nil || filter!.check(): "Invalid CapabilityFilter Filter capability provided"
        }
        let manager <- create Manager(filter: filter)
        emit CreatedManager(id: manager.uuid)
        return <- manager
    }

    init() {
        let identifier = "HybridCustodyChild_".concat(self.account.address.toString())
        self.OwnedAccountStoragePath = StoragePath(identifier: identifier)!
        self.OwnedAccountPublicPath = PublicPath(identifier: identifier)!

        let managerIdentifier = "HybridCustodyManager_".concat(self.account.address.toString())
        self.ManagerStoragePath = StoragePath(identifier: managerIdentifier)!
        self.ManagerPublicPath = PublicPath(identifier: managerIdentifier)!
    }
}
