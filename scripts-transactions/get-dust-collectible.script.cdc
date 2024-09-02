
import "FlovatarDustCollectible"

access(all) fun main(address:Address, collectibleId:UInt64) : FlovatarDustCollectible.FlovatarDustCollectibleData? {
    return FlovatarDustCollectible.getCollectible(address: address, collectibleId: collectibleId)
}