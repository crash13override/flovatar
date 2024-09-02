
import "Flovatar"

access(all) fun main(address:Address) : [Flovatar.FlovatarData] {

    return Flovatar.getFlovatars(address: address)

}
