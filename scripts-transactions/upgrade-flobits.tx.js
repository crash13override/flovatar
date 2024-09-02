import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function upgradeFlobitsTx(componentIds) {

    return await fcl
        .mutate({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace, FlovatarDustToken, FlovatarDustCollectible, FlovatarDustCollectibleAccessory, FlovatarDustCollectibleTemplate, FlovatarComponentUpgrader from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

transaction(
    componentIds: [UInt64]
    ) {

    let componentCollection: auth(NonFungibleToken.Withdraw) &FlovatarComponent.Collection
    let upgradeNFT: @[FlovatarComponent.NFT]
    let vaultCap: Capability<&FlovatarDustToken.Vault>
    let temporaryVault: @{FungibleToken.Vault}
    let address: Address

    prepare(account: auth(Storage) &Account) {

        self.componentCollection = account.storage.borrow<auth(NonFungibleToken.Withdraw) &FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!

        self.upgradeNFT <-[]
        for componentId in componentIds {
            let tempNFT <-self.componentCollection.withdraw(withdrawID: componentId) as! @FlovatarComponent.NFT
            self.upgradeNFT.append(<-tempNFT)
        }

        self.vaultCap = account.capabilities.get<&FlovatarDustToken.Vault>(FlovatarDustToken.VaultReceiverPath)

        let vaultRef = account.storage.borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Provider}>(from: FlovatarDustToken.VaultStoragePath) ?? panic("Could not borrow owner's Vault reference")

        // withdraw tokens from the buyer's Vault
        self.temporaryVault <- vaultRef.withdraw(amount: 20.0)

        self.address = account.address
    }

    execute {
        FlovatarComponentUpgrader.upgradeFlovatarComponent(components: <- self.upgradeNFT, vault: <- self.temporaryVault, address: self.address)
    }
}
`,
            args: (arg, t) => [
                arg(componentIds, t.Array(t.UInt64))
            ],
            limit: 9999
        });

}
