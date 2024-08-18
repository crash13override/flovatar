import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function flobotSendGiftTx(flobotId, address) {
    return await fcl
        .mutate({
            cadence: `
import FungibleToken from 0xFungible
import NonFungibleToken from 0xNonFungible
import Flovatar, FlovatarComponent, Flobot from 0xFlovatar

transaction(
    flobotId: UInt64,
    address: Address) {

    let flobotCollection: &Flobot.Collection
    let flobotReceiverCollection: Capability<&{Flobot.CollectionPublic}>

    prepare(account: AuthAccount) {
        self.flobotCollection = account.borrow<&Flobot.Collection>(from: Flobot.CollectionStoragePath)!


        let receiverAccount = getAccount(address)
        self.flobotReceiverCollection = receiverAccount.getCapability<&{Flobot.CollectionPublic}>(Flobot.CollectionPublicPath)
    }

    execute {
        let flobot <- self.flobotCollection.withdraw(withdrawID: flobotId)
        if(flobot == nil){
            panic("Flobot not found!")
        }
        self.flobotReceiverCollection.borrow()!.deposit(token: <-flobot)
    }
}
`,
            args: (arg, t) => [
                arg(''+flobotId, t.UInt64),
                arg(address, t.Address)
            ],
            limit: 9999
        });

}
