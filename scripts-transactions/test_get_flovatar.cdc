import Flovatar from "Flovatar"




// This script returns the available webshots

access(all) fun main(address:Address, flovatarId: UInt64) : Flovatar.FlovatarData? {

    return Flovatar.getFlovatar(address: address, flovatarId: flovatarId)

}
