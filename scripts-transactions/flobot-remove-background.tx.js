import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function flobotRemoveBackgroundTx(flobotId) {

    return await fcl
        .mutate({
            cadence: `
import Flovatar, Flobot, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

//this transaction will remove the Background from an existing Flobot
transaction(
    flobotId: UInt64
    ) {

    let flobotCollection: &Flobot.Collection
    let flovatarComponentCollection: &FlovatarComponent.Collection


    prepare(account: auth(Storage) &Account) {
        self.flobotCollection = account.storage.borrow<&Flobot.Collection>(from: Flobot.CollectionStoragePath)!

        self.flovatarComponentCollection = account.storage.borrow<&FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!
    }

    execute {

        let flobot = self.flobotCollection.borrowFlobot(id: flobotId)! as! auth(Flobot.PrivateEnt) &Flobot.NFT

        let background <-flobot.removeBackground()
        if(background != nil){
            self.flovatarComponentCollection.deposit(token: <-background!)
        } else {
            destroy background
        }
    }
}
`,
            args: (arg, t) => [
                arg(''+flobotId, t.UInt64)
            ],
            limit: 9999
        });

}
