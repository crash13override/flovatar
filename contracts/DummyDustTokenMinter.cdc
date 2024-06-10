import "FungibleToken"
import "Toucans"
import "FlovatarDustToken"

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
