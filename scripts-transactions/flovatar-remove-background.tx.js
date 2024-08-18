import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function flovatarRemoveBackgroundTx(flovatarId) {

    return await fcl
        .mutate({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

//this transaction will remove the Background from an existing Flovatar
transaction(
    flovatarId: UInt64
    ) {

    let flovatarCollection: &Flovatar.Collection
    let flovatarComponentCollection: &FlovatarComponent.Collection


    prepare(account: AuthAccount) {
        self.flovatarCollection = account.borrow<&Flovatar.Collection>(from: Flovatar.CollectionStoragePath)!

        self.flovatarComponentCollection = account.borrow<&FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!
    }

    execute {

        let flovatar: &{Flovatar.Private} = self.flovatarCollection.borrowFlovatarPrivate(id: flovatarId)!

        let background <-flovatar.removeBackground()
        if(background != nil){
            self.flovatarComponentCollection.deposit(token: <-background!)
        } else {
            destroy background
        }
    }
}
`,
            args: (arg, t) => [
                arg(''+flovatarId, t.UInt64)
            ],
            limit: 9999
        });

}
