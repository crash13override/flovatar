import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function claimFlovatarAirdropTx(id) {
    return await fcl
        .mutate({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace, FlovatarDustToken, FlovatarInbox from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

//this transaction will claim all content of the Inbox
transaction(id: UInt64) {

    let flovatarCollection: &Flovatar.Collection
    let address: Address

    prepare(account: auth(Storage) &Account) {
        self.flovatarCollection = account.storage.borrow<&Flovatar.Collection>(from: Flovatar.CollectionStoragePath)!
        self.address = account.address

    }

    execute {

        FlovatarInbox.withdrawFlovatarComponent(id: id, address: self.address)
        FlovatarInbox.withdrawFlovatarDust(id: id, address: self.address)

    }
}
`,
            args: (arg, t) => [
                arg(''+id, t.UInt64)
            ],
            limit: 9999
        });

}
