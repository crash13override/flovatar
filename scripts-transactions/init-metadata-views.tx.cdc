
import "Flovatar"
import "FlovatarComponent"

transaction {
  // We want the account's address for later so we can verify if the account was initialized properly
  let address: Address

  prepare(account: auth(Capabilities) &Account) {
    // save the address for the post check
    self.address = account.address

    let flovatarCapMeta = account.capabilities.get<&Flovatar.Collection>(Flovatar.CollectionPublicPath)
    if(!flovatarCapMeta.check()) {
        account.capabilities.unpublish(Flovatar.CollectionPublicPath)
        account.capabilities.publish(
            account.capabilities.storage.issue<&Flovatar.Collection>(Flovatar.CollectionStoragePath),
            at: Flovatar.CollectionPublicPath
        )
    }

    let flovatarComponentCapMeta = account.capabilities.get<&FlovatarComponent.Collection>(FlovatarComponent.CollectionPublicPath)
    if(!flovatarComponentCapMeta.check()) {
        account.capabilities.unpublish(FlovatarComponent.CollectionPublicPath)
        account.capabilities.publish(
            account.capabilities.storage.issue<&FlovatarComponent.Collection>(FlovatarComponent.CollectionStoragePath),
            at: FlovatarComponent.CollectionPublicPath
        )
    }


  }

}