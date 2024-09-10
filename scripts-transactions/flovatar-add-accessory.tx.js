import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function flovatarAddAccessoryTx(flovatarId, accessory) {

    return await fcl
        .mutate({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

//this transaction will add a new Accessory to an existing Flovatar
transaction(
    flovatarId: UInt64,
    accessory: UInt64
    ) {

    let flovatarCollection: auth(Flovatar.PrivateEnt) &Flovatar.Collection
    let flovatarComponentCollection: &FlovatarComponent.Collection

    let accessoryNFT: @FlovatarComponent.NFT

    prepare(account: auth(Storage) &Account) {
        self.flovatarCollection = account.storage.borrow<auth(Flovatar.PrivateEnt) &Flovatar.Collection>(from: Flovatar.CollectionStoragePath)!

        self.flovatarComponentCollection = account.storage.borrow<auth(NonFungibleToken.Withdraw) &FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!

        self.accessoryNFT <- self.flovatarComponentCollection.withdraw(withdrawID: accessory) as! @FlovatarComponent.NFT
    }

    execute {

        let flovatar = self.flovatarCollection.borrowFlovatar(id: flovatarId)! as! auth(Flovatar.PrivateEnt) &Flovatar.NFT

        let accessory <-flovatar.setAccessory(component: <-self.accessoryNFT)
        if(accessory != nil){
            self.flovatarComponentCollection.deposit(token: <-accessory!)
        } else {
            destroy accessory
        }
    }
}
`,
            args: (arg, t) => [
                arg(''+flovatarId, t.UInt64),
                arg(''+accessory, t.UInt64)
            ],
            limit: 9999
        });

}
