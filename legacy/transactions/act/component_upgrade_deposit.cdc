import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"
import Flovatar from "../../contracts/Flovatar.cdc"
import FlovatarComponent from "../../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../../contracts/FlovatarPack.cdc"
import FlovatarMarketplace from "../../contracts/FlovatarMarketplace.cdc"
import FlovatarDustCollectible from "../../contracts/FlovatarDustCollectible.cdc"
import FlovatarDustCollectibleTemplate from "../../contracts/FlovatarDustCollectibleTemplate.cdc"
import FlovatarDustToken from "../../contracts/FlovatarDustToken.cdc"
import FlovatarComponentUpgrader from "../../contracts/FlovatarComponentUpgrader.cdc"


transaction(
    componentIds: [UInt64]
    ) {

    let componentCollection: &FlovatarComponent.Collection
    let upgraderCollection: &FlovatarComponentUpgrader.Collection

    prepare(account: AuthAccount) {

        self.componentCollection = account.borrow<&FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!
        self.upgraderCollection = account.borrow<&FlovatarComponentUpgrader.Collection>(from: FlovatarComponentUpgrader.CollectionStoragePath)!
    }

    execute {

        for componentId in componentIds {
            let tempNFT <-self.componentCollection.withdraw(withdrawID: componentId) as! @FlovatarComponent.NFT
            self.upgraderCollection.depositComponent(component: <- tempNFT)
        }
    }
}