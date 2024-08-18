import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function flovatarAddEyeglassesTx(flovatarId, eyeglasses) {

    return await fcl
        .mutate({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

//this transaction will add a new pair of Eyeglasses to an existing Flovatar
transaction(
    flovatarId: UInt64,
    eyeglasses: UInt64
    ) {

    let flovatarCollection: &Flovatar.Collection
    let flovatarComponentCollection: &FlovatarComponent.Collection

    let eyeglassesNFT: @FlovatarComponent.NFT

    prepare(account: AuthAccount) {
        self.flovatarCollection = account.borrow<&Flovatar.Collection>(from: Flovatar.CollectionStoragePath)!

        self.flovatarComponentCollection = account.borrow<&FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!

        self.eyeglassesNFT <- self.flovatarComponentCollection.withdraw(withdrawID: eyeglasses) as! @FlovatarComponent.NFT
    }

    execute {

        let flovatar: &{Flovatar.Private} = self.flovatarCollection.borrowFlovatarPrivate(id: flovatarId)!

        let eyeglasses <-flovatar.setEyeglasses(component: <-self.eyeglassesNFT)
        if(eyeglasses != nil){
            self.flovatarComponentCollection.deposit(token: <-eyeglasses!)
        } else {
            destroy eyeglasses
        }
    }
}
`,
            args: (arg, t) => [
                arg(''+flovatarId, t.UInt64),
                arg(''+eyeglasses, t.UInt64)
            ],
            limit: 9999
        });

}
