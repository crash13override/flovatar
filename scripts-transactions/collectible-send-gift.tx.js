import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function collectibleSendGiftTx(collectibleId, address) {
    return await fcl
        .mutate({
            cadence: `
import FungibleToken from 0xFungible
import NonFungibleToken from 0xNonFungible
import Flovatar, FlovatarComponent, FlovatarDustToken, FlovatarDustCollectible, FlovatarDustCollectibleAccessory, FlovatarDustCollectibleTemplate from 0xFlovatar

transaction(
    collectibleId: UInt64,
    address: Address) {

    let collectibleCollection: auth(NonFungibleToken.Withdraw) &FlovatarDustCollectible.Collection
    let collectibleReceiverCollection: Capability<&{FlovatarDustCollectible.CollectionPublic}>

    prepare(account: auth(Storage) &Account) {
        self.collectibleCollection = account.storage.borrow<auth(NonFungibleToken.Withdraw) &FlovatarDustCollectible.Collection>(from: FlovatarDustCollectible.CollectionStoragePath)!


        let receiverAccount = getAccount(address)
        self.collectibleReceiverCollection = receiverAccount.capabilities.get<&{FlovatarDustCollectible.CollectionPublic}>(FlovatarDustCollectible.CollectionPublicPath)
    }

    execute {
        let collectible <- self.collectibleCollection.withdraw(withdrawID: collectibleId)
        if(collectible == nil){
            panic("Collectible not found!")
        }
        self.collectibleReceiverCollection.borrow()!.deposit(token: <-collectible)
    }
}
`,
            args: (arg, t) => [
                arg(''+collectibleId, t.UInt64),
                arg(address, t.Address)
            ],
            limit: 9999
        });

}
