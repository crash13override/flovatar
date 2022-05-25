# Flovatar
## Pre-made is so last month, now you can become the creator!
Instead of collecting pre-generated assets, with Flovatar you can unleash your creativity - no more trade-off between rarity and your own individuality.

You can decide if you want to build a Flovatar that looks just like you, or even better, something that speaks to you with the rarest traits combination! With 11 components, there are over 100 billion unique variations!

Check https://flovatar.com/! 💪

# Contribute
This repository contains code for contracts, scripts and transaction associated with [Flovatar](https://flovatar.com/) project. Take a look around and if you have ideas how to make it better - we welcome it with open heart! :hearts:

# Intergation
Our contracts are deployed to both networks:
- `Mainnet` - **0x921ea449dffec68a** - [Flow View Source - Flovatar Account](https://flow-view-source.com/mainnet/account/0x921ea449dffec68a)
- `Testnet` - **0x0cf264811b95d465** - [Flow View Source - Flovatar Account](https://flow-view-source.com/testnet/account/0x0cf264811b95d465)

## Basic Example
You can use code in [get_flovatars.cdc](/scripts/get_flovatars.cdc) file to get a list of Flovatars living in account's storage. 
```cadence
/// Fetch a List of Flovatars on address - Mainnet
import Flovatar from 0x921ea449dffec68a

pub fun main(address:Address) : [Flovatar.FlovatarData] {
  return Flovatar.getFlovatars(address: address)
}
```
```js
import { query, config } from "@onflow/fcl";

config().put("accessNode.api", "https://rest-mainnet.onflow.org");

(async()=>{
  const getFlovatars = async (address) => {
    // We will inline code from above here
    const cadence = `
      import Flovatar from 0x921ea449dffec68a

      pub fun main(address:Address) : [Flovatar.FlovatarData] {
        return Flovatar.getFlovatars(address: address)
      }
    `;
    
    // script expects single argument of type Address
    const args = (arg, t) => [arg(address, t.Address)];
    
    // ...and we are ready to query the network! :)
    const flovatars = await query({ cadence, args });
    
    console.log({ flovatars })
  }
  
  const user = "0x2a0eccae942667be"
  await getFlovatars(user)
})()
```

Example code on how it could be used together with [FCL-JS](https://github.com/onflow/fcl-js) library can be found on [CodeSandbox](https://codesandbox.io/s/dev-to-fcl-05-list-flovatars-at-address-0bibcd)
