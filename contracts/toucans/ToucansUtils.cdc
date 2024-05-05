import Crypto
import FungibleToken from "./utility/FungibleToken.cdc"
import NFTCatalog from "./utility/NFTCatalog.cdc"
import NonFungibleToken from "./utility/NonFungibleToken.cdc"
import FIND from "./utility/FIND.cdc"
import EmeraldIdentity from "./utility/EmeraldIdentity.cdc"

pub contract ToucansUtils {
  pub fun ownsNFTFromCatalogCollectionIdentifier(collectionIdentifier: String, user: Address): Bool {
    if let entry: NFTCatalog.NFTCatalogMetadata = NFTCatalog.getCatalogEntry(collectionIdentifier: collectionIdentifier) {
      let publicPath: PublicPath = entry.collectionData.publicPath
      let contractAddressToString: String = entry.contractAddress.toString()
      let constructedIdentifier: String = "A.".concat(contractAddressToString.slice(from: 2, upTo: contractAddressToString.length)).concat(".").concat(entry.contractName).concat(".Collection")

      var addresses: [Address] = [user]
      if let discordID: String = EmeraldIdentity.getDiscordFromAccount(account: user) {
        addresses = EmeraldIdentity.getEmeraldIDs(discordID: discordID).values
      }
      assert(addresses.contains(user), message: "Should always be true. Just making sure so the user doesn't get punished accidentally ;)")
      for address in addresses {
        if let collection: &{NonFungibleToken.CollectionPublic} = getAccount(address).getCapability(publicPath).borrow<&{NonFungibleToken.CollectionPublic}>() {
          let identifier: String = collection.getType().identifier
          if identifier == constructedIdentifier && collection.getIDs().length > 0 {
            return true
          }
        }
      }
    }
    
    return false
  }

  pub fun depositTokensToAccount(funds: @FungibleToken.Vault, to: Address, publicPath: PublicPath) {
    let vault = getAccount(to).getCapability(publicPath).borrow<&{FungibleToken.Receiver}>() 
              ?? panic("Account does not have a proper Vault set up.")
    vault.deposit(from: <- funds)
  }

  pub fun rangeFunc(_ start: Int, _ end: Int, _ f : ((Int):Void) ) {
    var current = start
    while current < end{
        f(current)
        current = current + 1
    }
  } 

  pub fun range(_ start: Int, _ end: Int): [Int]{
    var res:[Int] = []
    self.rangeFunc(start, end, fun (i:Int){
        res.append(i)
    })
    return res
  }

  pub fun index(_ s : String, _ substr : String, _ startIndex: Int): Int?{
    for i in self.range(startIndex,s.length-substr.length+1){
        if s[i]==substr[0] && s.slice(from:i, upTo:i+substr.length) == substr{
            return i
        }
    }
    return nil
  }

  pub fun getFind(_ address: Address): String {
    if let name = FIND.reverseLookup(address) {
      return name.concat(".find")
    }
    return address.toString()
  }

  pub fun fixToReadableString(num: UFix64): String {
    let numToString: String = num.toString()
    let indexOfDot: Int = ToucansUtils.index(numToString, ".", 1)!
    return numToString.slice(from: 0, upTo: indexOfDot + 3)
  }

  // stringAddress DOES NOT include the `0x`
  pub fun stringToAddress(stringAddress: String): Address {
    var r: UInt64 = 0
    var bytes: [UInt8] = stringAddress.decodeHex()

    while bytes.length > 0 {
      r = r + (UInt64(bytes.removeFirst()) << UInt64(bytes.length * 8))
    }

    return Address(r)
  }

  // returns:
  // [address, contractname]
  pub fun getAddressAndContractNameFromCollectionIdentifier(identifier: String): [AnyStruct] {
    let address: Address = self.stringToAddress(stringAddress: identifier.slice(from: 2, upTo: 18))
    let contractName: String = identifier.slice(from: 19, upTo: identifier.length - 11)
    return [address, contractName]
  }
}