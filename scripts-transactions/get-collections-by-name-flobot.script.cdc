
import "Flobot"
import "FIND"

access(all) struct Collections {

  access(all) var address: Address
  access(all) var flobots: [Flobot.FlobotData]
  init (_ address:Address, _ flobots: [Flobot.FlobotData]) {
    self.address = address
    self.flobots = flobots
  }
}

access(all) fun main(name: String) :Collections? {

    let address = FIND.lookupAddress(name)

    if (address != nil) {

        let flobots = Flobot.getFlobots(address: address!)

        return Collections(address!, flobots)
    } else {
        return nil
    }

}