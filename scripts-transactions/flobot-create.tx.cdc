import "Flobot"
import "FlovatarComponent"
import "NonFungibleToken"
import "FungibleToken"
import "FlowToken"
import "MetadataViews"

// This transaction will create a new Flobot by burning a Flobot Kit of the necessary rarity
transaction(
    flobotkit: [UInt64],
    body: UInt64,
    head: UInt64,
    arms: UInt64,
    legs: UInt64,
    face: UInt64,
    background: UInt64?
    ) {


    let flobotCollection: &Flobot.Collection
    let flobotComponentCollection: auth(NonFungibleToken.Withdraw) &FlovatarComponent.Collection

    let flobotkitNFT: @[FlovatarComponent.NFT]
    let backgroundNFT: @FlovatarComponent.NFT?
    let accountAddress: Address

    prepare(account: auth(Storage, Capabilities) &Account) {

        let flobotCap = account.capabilities.get<&Flobot.Collection>(Flobot.CollectionPublicPath)
        if(!flobotCap.check()) {
            account.storage.save<@{NonFungibleToken.Collection}>(<- Flobot.createEmptyCollection(nftType: Type<@Flobot.NFT>()), to: Flobot.CollectionStoragePath)
            account.capabilities.unpublish(Flobot.CollectionPublicPath)
            account.capabilities.publish(
                account.capabilities.storage.issue<&Flobot.Collection>(Flobot.CollectionStoragePath),
                at: Flobot.CollectionPublicPath)
        }

        self.flobotCollection = account.storage.borrow<&Flobot.Collection>(from: Flobot.CollectionStoragePath)!
        self.flobotComponentCollection = account.storage.borrow<auth(NonFungibleToken.Withdraw) &FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!


        if(background != nil){
            self.backgroundNFT <- self.flobotComponentCollection.withdraw(withdrawID: background!) as! @FlovatarComponent.NFT
        } else {
            self.backgroundNFT <- nil
        }

        self.flobotkitNFT <-[]
        for componentId in flobotkit {
            let tempNFT <-self.flobotComponentCollection.withdraw(withdrawID: componentId) as! @FlovatarComponent.NFT
            self.flobotkitNFT.append(<-tempNFT)
        }

        self.accountAddress = account.address

    }

    execute {

        let flobot <- Flobot.createFlobot(
            flobotkit: <-self.flobotkitNFT,
            body: body,
            head: head,
            arms: arms,
            legs: legs,
            face: face,
            background: <-self.backgroundNFT,
            address: self.accountAddress
        )

        self.flobotCollection.deposit(token: <-flobot)
    }

}