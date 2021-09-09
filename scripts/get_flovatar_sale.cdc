import FungibleToken from "../contracts/FungibleToken.cdc"
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import FUSD from "../contracts/FUSD.cdc"
import Flovatar from "../contracts/Flovatar.cdc"
import FlovatarComponent from "../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../contracts/FlovatarPack.cdc"
import Marketplace from "../contracts/Marketplace.cdc"


// This script returns a specific Flovatar sale

pub fun main(address:Address, id: UInt64) : Marketplace.FlovatarSaleData? {

    return Marketplace.getFlovatarSale(address: address, id: id)

}
