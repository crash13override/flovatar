
import "Flobot"

access(all) struct Collections {

  access(all) var address: Address
  access(all) var flobots: [Flobot.FlobotData]
  init (_ address:Address, _ flobots: [Flobot.FlobotData]) {
    self.address = address
    self.flobots = flobots
  }
}

access(all) fun main(address:Address) : Collections {
    let flobots = Flobot.getFlobots(address: address)

    return Collections(address, flobots)
}