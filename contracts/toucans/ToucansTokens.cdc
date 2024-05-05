import FlowToken from "./utility/FlowToken.cdc"
import FiatToken from "./utility/FiatToken.cdc"
import FungibleToken from "./utility/FungibleToken.cdc"

pub contract ToucansTokens {

  access(self) let tokens: {Type: TokenInfo}

  pub struct TokenInfo {
    pub let contractName: String
    pub let contractAddress: Address
    pub let tokenType: Type
    pub let symbol: String
    pub let receiverPath: PublicPath
    pub let publicPath: PublicPath
    pub let storagePath: StoragePath

    init(_ cn: String, _ ca: Address, _ s: String, _ rp: PublicPath, _ pp: PublicPath, _ sp: StoragePath) {
      self.contractName = cn
      self.contractAddress = ca
      let caToString: String = ca.toString()
      self.tokenType = CompositeType("A.".concat(caToString.slice(from: 2, upTo: caToString.length)).concat(".".concat(cn)).concat(".Vault"))!
      self.symbol = s
      self.receiverPath = rp
      self.publicPath = pp
      self.storagePath = sp
    }
  }

  pub resource Admin {
    pub fun addToken(tokenInfo: TokenInfo) {
      ToucansTokens.tokens[tokenInfo.tokenType] = tokenInfo
    }

    pub fun removeToken(tokenType: Type) {
      ToucansTokens.tokens.remove(key: tokenType)
    }
  }

  pub fun getTokenInfo(tokenType: Type): TokenInfo? {
    return self.tokens[tokenType]
  }

  pub fun getTokenSymbol(tokenType: Type): String? {
    return self.tokens[tokenType]?.symbol
  }

  pub fun getTokenInfoFromSymbol(symbol: String): TokenInfo? {
    for info in self.tokens.values {
      if info.symbol == symbol {
        return info
      }
    }
    return nil
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

  init() {
    self.tokens = {
      Type<@FlowToken.Vault>(): TokenInfo("FlowToken", self.stringToAddress(stringAddress: FlowToken.getType().identifier.slice(from: 2, upTo: 18)), "FLOW", /public/flowTokenReceiver, /public/flowTokenBalance, /storage/flowTokenVault),
      Type<@FiatToken.Vault>(): TokenInfo("FiatToken", self.stringToAddress(stringAddress: FiatToken.getType().identifier.slice(from: 2, upTo: 18)), "USDC", /public/USDCVaultReceiver, /public/USDCVaultBalance, /storage/USDCVault)
    }
    self.account.save(<- create Admin(), to: /storage/ToucansTokensAdmin)
  }

}