import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function flovatarSendGiftTx(flovatarId, address) {
    return await fcl
        .mutate({
            cadence: `
import FungibleToken from 0xFungible
import NonFungibleToken from 0xNonFungible
import Flovatar, FlovatarComponent from 0xFlovatar

transaction(
    flovatarId: UInt64,
    address: Address) {

    let flovatarCollection: &Flovatar.Collection
    let flovatarReceiverCollection: Capability<&{Flovatar.CollectionPublic}>

    prepare(account: AuthAccount) {
        self.flovatarCollection = account.borrow<&Flovatar.Collection>(from: Flovatar.CollectionStoragePath)!


        let receiverAccount = getAccount(address)
        self.flovatarReceiverCollection = receiverAccount.getCapability<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath)
    }

    execute {
        let flovatar <- self.flovatarCollection.withdraw(withdrawID: flovatarId)
        if(flovatar == nil){
            panic("Flovatar not found!")
        }
        self.flovatarReceiverCollection.borrow()!.deposit(token: <-flovatar)
    }
}
`,
            args: (arg, t) => [
                arg(''+flovatarId, t.UInt64),
                arg(address, t.Address)
            ],
            limit: 9999
        });

}
