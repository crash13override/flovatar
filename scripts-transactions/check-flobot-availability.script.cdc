import "Flobot"

access(all) fun main(
    body: UInt64,
    head: UInt64,
    arms: UInt64,
    legs: UInt64,
    face: UInt64) : Bool {

    return Flobot.checkCombinationAvailable(body: body, head: head, arms: arms, legs: legs, face: face)

}