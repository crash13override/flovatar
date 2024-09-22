import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function flovatarAddBackgroundTx(flovatarId, background) {

    return await fcl
        .mutate({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

//this transaction will add a new Background to an existing Flovatar
transaction(
    flovatarId: UInt64,
    background: UInt64
    ) {

    let flovatarCollection: auth(Flovatar.PrivateEnt) &Flovatar.Collection
    let flovatarComponentCollection: auth(NonFungibleToken.Withdraw) &FlovatarComponent.Collection

    let backgroundNFT: @FlovatarComponent.NFT

    prepare(account: auth(Storage) &Account) {
        self.flovatarCollection = account.storage.borrow<auth(Flovatar.PrivateEnt) &Flovatar.Collection>(from: Flovatar.CollectionStoragePath)!

        self.flovatarComponentCollection = account.storage.borrow<auth(NonFungibleToken.Withdraw) &FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!

        self.backgroundNFT <- self.flovatarComponentCollection.withdraw(withdrawID: background) as! @FlovatarComponent.NFT
    }

    execute {

        let flovatar = self.flovatarCollection.borrowFlovatarPrivate(id: flovatarId)!

        let background <-flovatar.setBackground(component: <-self.backgroundNFT)
        if(background != nil){
            self.flovatarComponentCollection.deposit(token: <-background!)
        } else {
            destroy background
        }
    }
}
`,
            args: (arg, t) => [
                arg(''+flovatarId, t.UInt64),
                arg(''+background, t.UInt64)
            ],
            limit: 9999
        });

}
