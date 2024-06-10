import "FungibleToken"

access(all)
contract Toucans { 
	
	access(all)
	resource interface Minter{ 
		access(all)
		fun mint(amount: UFix64): @{FungibleToken.Vault}{ 
			post{ 
				result.balance == amount:
					"Did not mint correct number of tokens."
			}
		}
	}
  
}