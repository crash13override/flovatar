import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function flobotAddBackgroundTx(flobotId, background) {

    return await fcl
        .mutate({
            cadence: `
import Flovatar, Flobot, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

//this transaction will add a new Background to an existing Flobot
transaction(
    flobotId: UInt64,
    background: UInt64
    ) {

    let flobotCollection: auth(Flobot.PrivateEnt) &Flobot.Collection
    let flovatarComponentCollection: &FlovatarComponent.Collection

    let backgroundNFT: @FlovatarComponent.NFT


    prepare(account: auth(Storage) &Account) {
        self.flobotCollection = account.storage.borrow<auth(Flobot.PrivateEnt) &Flobot.Collection>(from: Flobot.CollectionStoragePath)!

        self.flovatarComponentCollection = account.storage.borrow<auth(NonFungibleToken.Withdraw) &FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!

        self.backgroundNFT <- self.flovatarComponentCollection.withdraw(withdrawID: background) as! @FlovatarComponent.NFT
    }

    execute {

        let flobot= self.flobotCollection.borrowFlobot(id: flobotId)! as! auth(Flobot.PrivateEnt) &Flobot.NFT

        let background <-flobot.setBackground(component: <-self.backgroundNFT)
        if(background != nil){
            self.flovatarComponentCollection.deposit(token: <-background!)
        } else {
            destroy background
        }
    }
}
`,
            args: (arg, t) => [
                arg(''+flobotId, t.UInt64),
                arg(''+background, t.UInt64)
            ],
            limit: 9999
        });

}
