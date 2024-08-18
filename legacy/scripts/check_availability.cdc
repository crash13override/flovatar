import FungibleToken from "../contracts/FungibleToken.cdc"
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import FlowToken from "../contracts/FlowToken.cdc"
import Flovatar from "../contracts/Flovatar.cdc"
import FlovatarComponent from "../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../contracts/FlovatarPack.cdc"
import FlovatarMarketplace from "../contracts/FlovatarMarketplace.cdc"


pub fun main(
    name: String,
    body: UInt64,
    hair: UInt64,
    facialHair: UInt64?,
    eyes: UInt64,
    nose: UInt64,
    mouth: UInt64,
    clothing: UInt64) : {String: Bool} {

    //return Flovatar.checkCombinationAvailable(body: body, hair: hair, facialHair: facialHair, eyes: eyes, nose: nose, mouth: mouth, clothing: clothing) && Flovatar.checkNameAvailable(name: name)

    let boolCombination = Flovatar.checkCombinationAvailable(body: body, hair: hair, facialHair: facialHair, eyes: eyes, nose: nose, mouth: mouth, clothing: clothing)
    let boolName = Flovatar.checkNameAvailable(name: name)
    let status:{String:Bool} = {}
    status["combination"] = boolCombination
    status["name"] = boolName
    status["available"] = boolCombination && boolName
    return status

}