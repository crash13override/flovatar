import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function flobotCreateTx(flobotkit, body, head, arms, legs, face, background) {

    return await fcl
        .mutate({
            cadence: `
import Flobot, Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken
import MetadataViews from 0xMetadataViews

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
    let flobotComponentCollection: &FlovatarComponent.Collection

    let flobotkitNFT: @[FlovatarComponent.NFT]
    let backgroundNFT: @FlovatarComponent.NFT?
    let accountAddress: Address

    prepare(account: AuthAccount) {

        let flobotCap = account.getCapability<&{Flobot.CollectionPublic}>(Flobot.CollectionPublicPath)
        if(!flobotCap.check()) {
            account.save<@NonFungibleToken.Collection>(<- Flobot.createEmptyCollection(), to: Flobot.CollectionStoragePath)
            account.link<&Flobot.Collection{Flobot.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(Flobot.CollectionPublicPath, target: Flobot.CollectionStoragePath)
        }

        self.flobotCollection = account.borrow<&Flobot.Collection>(from: Flobot.CollectionStoragePath)!
        self.flobotComponentCollection = account.borrow<&FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!


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
`,
            args: (arg, t) => [
                arg(flobotkit, t.Array(t.UInt64)),
                arg(''+body, t.UInt64),
                arg(''+head, t.UInt64),
                arg(''+arms, t.UInt64),
                arg(''+legs, t.UInt64),
                arg(''+face, t.UInt64),
                arg(background ? ''+background : background, t.Optional(t.UInt64))
            ],
            limit: 9999
        });

}
