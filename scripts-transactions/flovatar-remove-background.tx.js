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

    let flovatarCollection: auth(Flovatar.PrivateEnt) &Flovatar.Collection
    let flovatarComponentCollection: &FlovatarComponent.Collection


    prepare(account: auth(Storage) &Account) {
        self.flovatarCollection = account.storage.borrow<auth(Flovatar.PrivateEnt) &Flovatar.Collection>(from: Flovatar.CollectionStoragePath)!

        self.flovatarComponentCollection = account.storage.borrow<&FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!
    }

    execute {

        let flovatar = self.flovatarCollection.borrowFlovatar(id: flovatarId)! as! auth(Flovatar.PrivateEnt) &Flovatar.NFT

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
