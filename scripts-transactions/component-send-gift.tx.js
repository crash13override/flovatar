import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function componentSendGiftTx(componentId, address) {
    return await fcl
        .mutate({
            cadence: `
import FungibleToken from 0xFungible
import NonFungibleToken from 0xNonFungible
import Flovatar, FlovatarComponent from 0xFlovatar

transaction(
    componentId: UInt64,
    address: Address) {

    let flovatarComponentCollection: auth(NonFungibleToken.Withdraw) &FlovatarComponent.Collection
    let flovatarComponentReceiverCollection: Capability<&{FlovatarComponent.CollectionPublic}>

    prepare(account: auth(Storage) &Account) {
        self.flovatarComponentCollection = account.storage.borrow<auth(NonFungibleToken.Withdraw) &FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!

        let receiverAccount = getAccount(address)
        self.flovatarComponentReceiverCollection = receiverAccount.capabilities.get<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath)
    }

    execute {
        let component <- self.flovatarComponentCollection.withdraw(withdrawID: componentId)
        if(component == nil){
            panic("Component not found!")
        }
        self.flovatarComponentReceiverCollection.borrow()!.deposit(token: <-component)
    }
}
`,
            args: (arg, t) => [
                arg(''+componentId, t.UInt64),
                arg(address, t.Address)
            ],
            limit: 9999
        });

}
