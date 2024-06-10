import "FungibleToken"
import "MetadataViews"
import "FungibleTokenMetadataViews"

access(all) contract FlowUtilityToken: FungibleToken {

    // Total supply of FlowUtilityTokens in existence
    access(all) var totalSupply: UFix64

    // Event that is emitted when the contract is created
    access(all) event TokensInitialized(initialSupply: UFix64)

    // Event that is emitted when tokens are withdrawn from a Vault
    access(all) event TokensWithdrawn(amount: UFix64, from: Address?)

    // Event that is emitted when tokens are deposited to a Vault
    access(all) event TokensDeposited(amount: UFix64, to: Address?)

    // Event that is emitted when new tokens are minted
    access(all) event TokensMinted(amount: UFix64)

    // Event that is emitted when tokens are destroyed
    access(all) event TokensBurned(amount: UFix64)

    // Event that is emitted when a new minter resource is created
    access(all) event MinterCreated(allowedAmount: UFix64)

    // Event that is emitted when a new burner resource is created
    access(all) event BurnerCreated()

    // Vault
    //
    // Each user stores an instance of only the Vault in their storage
    // The functions in the Vault and governed by the pre and post conditions
    // in FungibleToken when they are called.
    // The checks happen at runtime whenever a function is called.
    //
    // Resources can only be created in the context of the contract that they
    // are defined in, so there is no way for a malicious user to create Vaults
    // out of thin air. A special Minter resource needs to be defined to mint
    // new tokens.
    //
    access(all) resource Vault: FungibleToken.Vault {

        // holds the balance of a users tokens
        access(all) var balance: UFix64

        // initialize the balance at resource creation time
        init(balance: UFix64) {
            self.balance = balance
        }

        // withdraw
        //
        // Function that takes an integer amount as an argument
        // and withdraws that amount from the Vault.
        // It creates a new temporary Vault that is used to hold
        // the money that is being transferred. It returns the newly
        // created Vault to the context that called so it can be deposited
        // elsewhere.
        //
        access(FungibleToken.Withdraw) fun withdraw(amount: UFix64): @{FungibleToken.Vault} {
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault(balance: amount)
        }

        // deposit
        //
        // Function that takes a Vault object as an argument and adds
        // its balance to the balance of the owners Vault.
        // It is allowed to destroy the sent Vault because the Vault
        // was a temporary holder of the tokens. The Vault's balance has
        // been consumed and therefore can be destroyed.
        access(all) fun deposit(from: @{FungibleToken.Vault}) {
            let vault <- from as! @FlowUtilityToken.Vault
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0
            destroy vault
        }
        
        access(all) view fun isAvailableToWithdraw(amount: UFix64): Bool {
            return self.balance >= amount
        }

        access(all) view fun getSupportedVaultTypes(): {Type: Bool} {
            return {Type<@Vault>(): true}
        }

        access(all) view fun isSupportedVaultType(type: Type): Bool {
            return type == Type<@Vault>()
        }

        access(contract) fun burnCallback() {
            FlowUtilityToken.totalSupply = FlowUtilityToken.totalSupply - self.balance
        }

        access(all) fun createEmptyVault(): @{FungibleToken.Vault} {
            return <- create Vault(balance: 0.0)
        }

        access(all) view fun getViews(): [Type]{
            return FlowUtilityToken.getContractViews(resourceType: nil)
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            return FlowUtilityToken.resolveContractView(resourceType: nil, viewType: view)
        }
    }

    // createEmptyVault
    //
    // Function that creates a new Vault with a balance of zero
    // and returns it to the calling context. A user must call this function
    // and store the returned Vault in their storage in order to allow their
    // account to be able to receive deposits of this token type.
    //
    access(all) fun createEmptyVault(vaultType: Type): @{FungibleToken.Vault} {
        return <-create Vault(balance: 0.0)
    }

    access(all) resource Administrator {
        // createNewMinter
        //
        // Function that creates and returns a new minter resource
        //
        access(all) fun createNewMinter(allowedAmount: UFix64): @Minter {
            emit MinterCreated(allowedAmount: allowedAmount)
            return <-create Minter(allowedAmount: allowedAmount)
        }

        // createNewBurner
        //
        // Function that creates and returns a new burner resource
        //
        access(all) fun createNewBurner(): @Burner {
            emit BurnerCreated()
            return <-create Burner()
        }
    }

    // Minter
    //
    // Resource object that token admin accounts can hold to mint new tokens.
    //
    access(all) resource Minter {

        // the amount of tokens that the minter is allowed to mint
        access(all) var allowedAmount: UFix64

        // mintTokens
        //
        // Function that mints new tokens, adds them to the total supply,
        // and returns them to the calling context.
        //
        access(all) fun mintTokens(amount: UFix64): @FlowUtilityToken.Vault {
            pre {
                amount > 0.0: "Amount minted must be greater than zero"
                amount <= self.allowedAmount: "Amount minted must be less than the allowed amount"
            }
            FlowUtilityToken.totalSupply = FlowUtilityToken.totalSupply + amount
            self.allowedAmount = self.allowedAmount - amount
            emit TokensMinted(amount: amount)
            return <-create Vault(balance: amount)
        }

        init(allowedAmount: UFix64) {
            self.allowedAmount = allowedAmount
        }
    }

    // Burner
    //
    // Resource object that token admin accounts can hold to burn tokens.
    //
    access(all) resource Burner {

        // burnTokens
        //
        // Function that destroys a Vault instance, effectively burning the tokens.
        //
        // Note: the burned tokens are automatically subtracted from the
        // total supply in the Vault destructor.
        //
        access(all) fun burnTokens(from: @{FungibleToken.Vault}) {
            let vault <- from as! @FlowUtilityToken.Vault
            let amount = vault.balance
            destroy vault
            emit TokensBurned(amount: amount)
        }
    }

    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [Type<FungibleTokenMetadataViews.FTView>(),
                Type<FungibleTokenMetadataViews.FTDisplay>(),
                Type<FungibleTokenMetadataViews.FTVaultData>(),
                Type<FungibleTokenMetadataViews.TotalSupply>()]
    }

    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        switch viewType {
            case Type<FungibleTokenMetadataViews.FTView>():
                return FungibleTokenMetadataViews.FTView(
                    ftDisplay: self.resolveContractView(resourceType: nil, viewType: Type<FungibleTokenMetadataViews.FTDisplay>()) as! FungibleTokenMetadataViews.FTDisplay?,
                    ftVaultData: self.resolveContractView(resourceType: nil, viewType: Type<FungibleTokenMetadataViews.FTVaultData>()) as! FungibleTokenMetadataViews.FTVaultData?
                )
            case Type<FungibleTokenMetadataViews.FTDisplay>():
                let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                        url: "https://meetdapper.com/"
                    ),
                    mediaType: "image/svg+xml"
                )
                let medias = MetadataViews.Medias([media])
                return FungibleTokenMetadataViews.FTDisplay(
                    name: "Dapper Utility Coin",
                    symbol: "DUC",
                    description: "",
                    externalURL: MetadataViews.ExternalURL("https://meetdapper.com/"),
                    logos: medias,
                    socials: {
                        "twitter": MetadataViews.ExternalURL("https://twitter.com/hellodapper")
                    }
                )
            case Type<FungibleTokenMetadataViews.FTVaultData>():
                let vaultRef = FlowUtilityToken.account.storage.borrow<auth(FungibleToken.Withdraw) &FlowUtilityToken.Vault>(from: /storage/flowUtilityTokenVault)
			        ?? panic("Could not borrow reference to the contract's Vault!")
                return FungibleTokenMetadataViews.FTVaultData(
                    storagePath: /storage/flowUtilityTokenVault,
                    receiverPath: /public/exampleTokenReceiver,
                    metadataPath: /public/flowUtilityTokenBalance,
                    receiverLinkedType: Type<&{FungibleToken.Receiver, FungibleToken.Vault}>(),
                    metadataLinkedType: Type<&{FungibleToken.Balance, FungibleToken.Vault}>(),
                    createEmptyVaultFunction: (fun (): @{FungibleToken.Vault} {
                        return <-vaultRef.createEmptyVault()
                    })
                )
            case Type<FungibleTokenMetadataViews.TotalSupply>():
                return FungibleTokenMetadataViews.TotalSupply(totalSupply: FlowUtilityToken.totalSupply)
        }
        return nil
    }

    init() {
        // we're using a high value as the balance here to make it look like we've got a ton of money,
        // just in case some contract manually checks that our balance is sufficient to pay for stuff
        self.totalSupply = 999999999.0

        let admin <- create Administrator()
        let minter <- admin.createNewMinter(allowedAmount: self.totalSupply)
        self.account.storage.save(<-admin, to: /storage/flowUtilityTokenAdmin)

        // mint tokens
        let tokenVault <- minter.mintTokens(amount: self.totalSupply)
        self.account.storage.save(<-tokenVault, to: /storage/flowUtilityTokenVault)
        destroy minter

        let cap = self.account.capabilities.storage.issue<&FlowUtilityToken.Vault>(/storage/flowUtilityTokenVault)
        self.account.capabilities.publish(cap, at: /public/flowUtilityTokenBalance)
        self.account.capabilities.publish(cap, at: /public/flowUtilityTokenReceiver)

        // Emit an event that shows that the contract was initialized
        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}