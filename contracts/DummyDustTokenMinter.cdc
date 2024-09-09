import "FungibleToken"
import "Toucans"
import "FlovatarDustToken"
/*
    This is a Dummy Token Minter for Toucans to allow the use of DUST within the DAO tools.
*/
access(all)
contract DummyDustTokenMinter{ 
	access(all)
	resource DummyMinter: Toucans.Minter{ 
		access(all)
		fun mint(amount: UFix64): @FlovatarDustToken.Vault{ 
			return <-FlovatarDustToken.createEmptyDustVault()
		}
	}
	
	access(all)
	fun createMinter(): @DummyMinter{ 
		return <-create DummyMinter()
	}
	
	init(){} 
}
