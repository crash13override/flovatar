
//import FungibleToken from 0xee82856bf20e2aa6
//import FungibleToken from "../../contracts/FungibleToken.cdc"
//import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
//import FUSD from "../../contracts/FUSD.cdc"
import Flovatar from "../../contracts/Flovatar.cdc"
import FlovatarComponent from "../../contracts/FlovatarComponent.cdc"
import FlovatarComponentTemplate from "../../contracts/FlovatarComponentTemplate.cdc"
import FlovatarPack from "../../contracts/FlovatarPack.cdc"


//this transaction will create a new Webshot and create and auction for it
transaction(
    name: String,
    category: String,
    color: String,
    description: String,
    svg: String,
    series: UInt32,
    maxMintableComponents: UInt64) {

    let flovatarComponentTemplateCollection: &FlovatarComponentTemplate.Collection
    let flovatarAdmin: &Flovatar.Admin

    prepare(account: AuthAccount) {
        self.flovatarComponentTemplateCollection = account.borrow<&FlovatarComponentTemplate.Collection>(from: FlovatarComponentTemplate.CollectionStoragePath)!

        self.flovatarAdmin = account.borrow<&Flovatar.Admin>(from: Flovatar.AdminStoragePath)!
    }

    execute {
        let flovatarComponentTemplate <- self.flovatarAdmin.createComponentTemplate(
            name: name,
            category: category,
            color: color,
            description: description,
            svg: svg,
            series: series,
            maxMintableComponents: maxMintableComponents
            ) as! @FlovatarComponentTemplate.ComponentTemplate


        self.flovatarComponentTemplateCollection.deposit(componentTemplate: <-flovatarComponentTemplate)

    }
}
