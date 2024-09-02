
import "Flobot"

access(all) fun main(address:Address, flobotId: UInt64) : Flobot.FlobotData? {

    return Flobot.getFlobot(address: address, flobotId: flobotId)

}