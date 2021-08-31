
//import FungibleToken from 0xee82856bf20e2aa6
//import FungibleToken from "../contracts/FungibleToken.cdc"
//import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
//import FUSD from "../contracts/FUSD.cdc"
import Flovatar from "../contracts/Flovatar.cdc"
import FlovatarComponent from "../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../contracts/FlovatarPack.cdc"



// This script returns the available components

pub fun main(address:Address) : [Flovatar.FlovatarData] {

    return Flovatar.getFlovatars(address: address)

}
