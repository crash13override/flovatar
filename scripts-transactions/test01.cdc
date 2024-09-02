import FlovatarComponent from 0x9392a4a7c3f49a0b


access(all) fun main(address: Address): Bool {

  let account = getAccount(address)

  let flovatarComponentCap = account.capabilities.get<&FlovatarComponent.Collection>(FlovatarComponent.CollectionPublicPath)


  return (flovatarComponentCap.check())
}