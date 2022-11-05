import FlovatarInbox from "../contracts/FlovatarInbox.cdc"

pub fun main() : UFix64 {

    return FlovatarInbox.getCommunityDustBalance()
}