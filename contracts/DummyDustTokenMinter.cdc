import FungibleToken from "./FungibleToken.cdc"
import Toucans from "./toucans/Toucans.cdc"
import FlovatarDustToken from "./FlovatarDustToken.cdc"

pub contract DummyDustTokenMinter {

    pub resource DummyMinter: Toucans.Minter {
       pub fun mint(amount: UFix64): @FlovatarDustToken.Vault {
        return <- FlovatarDustToken.createEmptyVault()
       }
    }

    pub fun createMinter(): @DummyMinter {
       return <- create DummyMinter()
    }

    init() {

    }
}
