import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function packOpenTx(packId) {
    return await fcl
        .mutate({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace from 0xFlovatar
import FungibleToken from 0xFungible
import NonFungibleToken from 0xNonFungible
import FlowToken from 0xFlowToken

transaction(packId: UInt64) {

    let flovatarPackCollection: auth(FlovatarPack.WithdrawEnt) &FlovatarPack.Collection

    prepare(account: auth(Storage) &Account) {
        self.flovatarPackCollection = account.storage.borrow<auth(FlovatarPack.WithdrawEnt) &FlovatarPack.Collection>(from: FlovatarPack.CollectionStoragePath)!
    }

    execute {
        self.flovatarPackCollection.openPack(id: packId)
    }

}
`,
            args: (arg, t) => [
                arg(''+packId, t.UInt64)
            ],
            limit: 9999
        });

}
