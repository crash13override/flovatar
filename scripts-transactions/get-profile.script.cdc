
import "FungibleToken"
import "FlowToken"
import "FIND"
import "Profile"
//import FlovatarDustToken from 0xFlovatar


access(all) struct AddressStatus {

  access(all) var address: Address
  access(all) var name: String?
  access(all) var balance: UFix64
  access(all) var dustBalance: UFix64
  init (_ address:Address,_ name: String?, _ balance: UFix64, _ dustBalance: UFix64) {
    self.address = address
    self.balance = balance
    self.dustBalance = dustBalance
    self.name = name
  }
}

// This script checks that the accounts are set up correctly for the marketplace tutorial.

access(all) fun main(address:Address) : AddressStatus {
    // get the accounts' public address objects
    let account = getAccount(address)
    var balance = 0.0
    var name: String? = nil
    var dustBalance = 0.0

    if let vault = account.capabilities.borrow<&FlowToken.Vault>(/public/flowTokenBalance) {
       balance = vault.balance
    }
    //if let dustVault = account.capabilities.get(FlovatarDustToken.VaultReceiverPath).borrow<&FlovatarDustToken.Vault{FungibleToken.Balance}>() {
    //   status.dustBalance = dustVault.balance
    //}

    let leaseCap = account.capabilities.get<&FIND.LeaseCollection>(FIND.LeasePublicPath)

    //we do have leases
    if leaseCap.check() {
        let profile= Profile.find(address).asProfile()
        let leases = leaseCap.borrow()!.getLeaseInformation()
        var time : UFix64? = nil
        var name :String? = nil
        var profileName :String? = nil

        for lease in leases {

            //filter out all leases that are FREE or LOCKED since they are not actice
            if lease.status != "TAKEN" {
                continue
            }

            //if we have not set a findName in profile we find the one that has the least validUntil, first registerd
            if profile.findName == "" {
                if time == nil || lease.validUntil < time! {
                    time = lease.validUntil
                    name = lease.name
                }
            } else if profile.findName == lease.name {
                profileName = lease.name
            }
        }

        if(profileName != nil){
            name = profileName
        } else if(name != nil) {
            name = name
        }

    }


    return AddressStatus(address, name, balance, dustBalance)

}