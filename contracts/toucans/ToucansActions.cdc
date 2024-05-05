import FungibleToken from "./utility/FungibleToken.cdc"
import NonFungibleToken from "./utility/NonFungibleToken.cdc"
import ToucansUtils from "./ToucansUtils.cdc"

pub contract ToucansActions {

  pub struct interface Action {
    pub fun getIntent(): String
    pub fun getTitle(): String
  }


  //                _   _                 
  //      /\       | | (_)                
  //     /  \   ___| |_ _  ___  _ __  ___ 
  //    / /\ \ / __| __| |/ _ \| '_ \/ __|
  //   / ____ \ (__| |_| | (_) | | | \__ \
  //  /_/    \_\___|\__|_|\___/|_| |_|___/   


  // Transfers `amount` tokens from the treasury to `recipientVault`
  pub struct WithdrawToken: Action {
    pub let vaultType: Type
    pub let recipientVault: Capability<&{FungibleToken.Receiver}>
    pub let amount: UFix64
    pub let tokenSymbol: String
    pub let readableAmount: String

    pub fun getIntent(): String {
      return "Withdraw ".concat(self.readableAmount).concat(" ").concat(self.tokenSymbol).concat(" tokens from the treasury to ").concat(ToucansUtils.getFind(self.recipientVault.borrow()!.owner!.address))
    }

    pub fun getTitle(): String {
      return "Withdraw"
    }

    init(_ vaultType: Type, _ recipientVault: Capability<&{FungibleToken.Receiver}>, _ amount: UFix64, _ tokenSymbol: String) {
      pre {
        recipientVault.check(): "Invalid recipient capability."
      }
      self.vaultType = vaultType
      self.recipientVault = recipientVault
      self.amount = amount
      self.tokenSymbol = tokenSymbol
      self.readableAmount = ToucansUtils.fixToReadableString(num: amount)
    }
  }

  pub struct BatchWithdrawToken: Action {
    pub let vaultType: Type
    pub let recipientVaults: {Address: Capability<&{FungibleToken.Receiver}>}
    pub let amounts: {Address: UFix64}
    pub let tokenSymbol: String
    pub let totalReadableAmount: String

    pub fun getIntent(): String {
      return "Withdraw a total of ".concat(self.totalReadableAmount).concat(" ").concat(self.tokenSymbol).concat(" tokens from the treasury to ").concat(self.amounts.keys.length.toString()).concat(" total wallets")
    }

    pub fun getTitle(): String {
      return "BatchWithdraw"
    }

    init(_ vaultType: Type, _ recipientVaults: {Address: Capability<&{FungibleToken.Receiver}>}, _ amounts: {Address: UFix64}, _ tokenSymbol: String) {
      self.vaultType = vaultType
      self.recipientVaults = recipientVaults
      self.amounts = amounts
      self.tokenSymbol = tokenSymbol

      var totalAmount: UFix64 = 0.0
      for amount in amounts.values {
        totalAmount = totalAmount + amount
      }
      self.totalReadableAmount = ToucansUtils.fixToReadableString(num: totalAmount)
    }
  }

  // Withdraws NFTs from the treasury to 1 address
  pub struct WithdrawNFTs: Action {
    pub let collectionType: Type
    pub let recipientCollection: Capability<&{NonFungibleToken.Receiver}>
    pub let nftIDs: [UInt64]
    pub let contractAddress: Address
    pub let contractName: String

    pub fun getIntent(): String {
      return "Withdraw ".concat(self.nftIDs.length.toString()).concat(" ").concat(self.contractName).concat(" NFTs from the treasury to ").concat(ToucansUtils.getFind(self.recipientCollection.borrow()!.owner!.address))
    }

    pub fun getTitle(): String {
      return "WithdrawNFTs"
    }

    init(_ collectionType: Type, _ nftIDs: [UInt64], _ recipientCollection: Capability<&{NonFungibleToken.Receiver}>) {
      pre {
        recipientCollection.check(): "Invalid recipient capability."
      }
      self.collectionType = collectionType
      self.recipientCollection = recipientCollection
      self.nftIDs = nftIDs
      let nameAndAddress: [AnyStruct] = ToucansUtils.getAddressAndContractNameFromCollectionIdentifier(identifier: collectionType.identifier)
      self.contractAddress = nameAndAddress[0] as! Address
      self.contractName = nameAndAddress[1] as! String
    }
  }

  // Mint `amount` tokens to `recipientVault`
  pub struct MintTokens: Action {
    pub let recipientVault: Capability<&{FungibleToken.Receiver}>
    pub let amount: UFix64
    pub let tokenSymbol: String
    pub let readableAmount: String

    pub fun getIntent(): String {
      return "Mint ".concat(self.readableAmount).concat(" ").concat(self.tokenSymbol).concat(" tokens to ").concat(ToucansUtils.getFind(self.recipientVault.borrow()!.owner!.address))
    }

    pub fun getTitle(): String {
      return "Mint"
    }

    init(_ recipientVault: Capability<&{FungibleToken.Receiver}>, _ amount: UFix64, _ tokenSymbol: String) {
      self.recipientVault = recipientVault
      assert(self.recipientVault.check(), message: "Invalid recipient capability.")
      self.amount = amount
      self.tokenSymbol = tokenSymbol
      self.readableAmount = ToucansUtils.fixToReadableString(num: amount)
    }
  }

  pub struct BatchMintTokens: Action {
    pub let recipientVaults: {Address: Capability<&{FungibleToken.Receiver}>}
    pub let amounts: {Address: UFix64}
    pub let tokenSymbol: String
    pub let totalReadableAmount: String

    pub fun getIntent(): String {
      return "Mint a total of ".concat(self.totalReadableAmount).concat(" ").concat(self.tokenSymbol).concat(" tokens to ").concat(self.amounts.keys.length.toString()).concat(" total wallets")
    }

    pub fun getTitle(): String {
      return "BatchMint"
    }

    init(_ recipientVaults: {Address: Capability<&{FungibleToken.Receiver}>}, _ amounts: {Address: UFix64}, _ tokenSymbol: String) {
      self.recipientVaults = recipientVaults
      self.amounts = amounts
      self.tokenSymbol = tokenSymbol

      var totalAmount: UFix64 = 0.0
      for amount in amounts.values {
        totalAmount = totalAmount + amount
      }
      self.totalReadableAmount = ToucansUtils.fixToReadableString(num: totalAmount)
    }
  }

  // Mint `amount` tokens to the treasury directly
  pub struct MintTokensToTreasury: Action {
    pub let amount: UFix64
    pub let tokenSymbol: String
    pub let readableAmount: String

    pub fun getIntent(): String {
      return "Mint ".concat(self.readableAmount).concat(" ").concat(self.tokenSymbol).concat(" tokens to the Treasury")
    }

    pub fun getTitle(): String {
      return "MintToTreasury"
    }

    init(_ amount: UFix64, _ tokenSymbol: String) {
      self.amount = amount
      self.tokenSymbol = tokenSymbol
      self.readableAmount = ToucansUtils.fixToReadableString(num: amount)
    }
  }

  // Add a new signer to the treasury
  pub struct AddOneSigner: Action {
    pub let signer: Address

    pub fun getIntent(): String {
      return "Add ".concat(ToucansUtils.getFind(self.signer)).concat(" as a signer to the Treasury")
    }

    pub fun getTitle(): String {
      return "AddSigner"
    }

    init(_ signer: Address) {
      self.signer = signer
    }
  }

  // Remove a signer from the treasury
  // NOTE: If this reduces the # of signers to 
  // below the threshold, this will automatically
  // reduce the threshold to the # of signers
  pub struct RemoveOneSigner: Action {
    pub let signer: Address

    pub fun getIntent(): String {
      return "Remove ".concat(ToucansUtils.getFind(self.signer)).concat(" as a signer from the Treasury")
    }

    pub fun getTitle(): String {
      return "RemoveSigner"
    }

    init(_ signer: Address) {
      self.signer = signer
    }
  }

  // Update the threshold of signers
  pub struct UpdateTreasuryThreshold: Action {
    pub let threshold: UInt64

    pub fun getIntent(): String {
      return "Update the threshold of signers needed to execute an action in the Treasury to ".concat(self.threshold.toString())
    }

    pub fun getTitle(): String {
      return "UpdateThreshold"
    }

    init(_ threshold: UInt64) {
      self.threshold = threshold
    }
  }

  // burn your DAOs token from the treasury
  pub struct BurnTokens: Action {
    pub let amount: UFix64
    pub let tokenSymbol: String
    pub let readableAmount: String

    pub fun getIntent(): String {
      return "Burn ".concat(self.readableAmount).concat(" ").concat(self.tokenSymbol).concat(" tokens from the Treasury")
    }

    pub fun getTitle(): String {
      return "Burn"
    }

    init(_ amount: UFix64, _ tokenSymbol: String) {
      self.amount = amount
      self.tokenSymbol = tokenSymbol
      self.readableAmount = ToucansUtils.fixToReadableString(num: amount)
    }
  }

  // burn your DAOs token from the treasury
  pub struct LockTokens: Action {
    pub let recipient: Address
    pub let amount: UFix64
    pub let tokenSymbol: String
    pub let readableAmount: String
    pub let unlockTime: UFix64

    pub fun getIntent(): String {
      return "Lock ".concat(self.readableAmount).concat(" ").concat(self.tokenSymbol).concat(" tokens for ").concat(ToucansUtils.getFind(self.recipient)).concat(" until ").concat(self.unlockTime.toString())
    }

    pub fun getTitle(): String {
      return "LockTokens"
    }

    init(_ recipient: Address, _ amount: UFix64, _ tokenSymbol: String, _ unlockTime: UFix64) {
      self.amount = amount
      self.tokenSymbol = tokenSymbol
      self.readableAmount = ToucansUtils.fixToReadableString(num: amount)
      self.unlockTime = unlockTime
      self.recipient = recipient
    }
  }
}
 