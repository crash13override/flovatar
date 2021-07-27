
//import FungibleToken from 0xee82856bf20e2aa6
import FungibleToken from "../contracts/FungibleToken.cdc"
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import Website from "../contracts/Website.cdc"
import Webshot from "../contracts/Webshot.cdc"
import Marketplace from "../contracts/Marketplace.cdc"
import Drop from "../contracts/Drop.cdc"



// This script returns the available websites

pub fun main(id: UInt64) : Drop.AuctionStatus? {

    return Drop.getAuction(id)

}
