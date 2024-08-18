import FungibleToken from "../contracts/FungibleToken.cdc"
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import FlowToken from "../contracts/FlowToken.cdc"
import Flovatar from "../contracts/Flovatar.cdc"
import FlovatarComponent from "../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../contracts/FlovatarPack.cdc"
import FlovatarMarketplace from "../contracts/FlovatarMarketplace.cdc"



// This script returns the available webshots

pub fun main(address:Address, flovatarId: UInt64) : Flovatar.FlovatarData? {

    return Flovatar.getFlovatar(address: address, flovatarId: flovatarId)

}
