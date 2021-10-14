import Crypto

pub fun main(
  address: Address,
  message: String,
  signature: String
): Bool {


    // Gets the Crypto.KeyList and the public key of the collection's owner
    let keyList = Crypto.KeyList()

    var i = 0;
    var accountKey  = getAccount(address).keys.get(keyIndex: i)
    while(accountKey != nil) {
        //We have to skip the first signature with i!=0 because FCL is not using it to sign the message for some reason!
        if(!accountKey!.isRevoked && i != 0){
        keyList.add(
                PublicKey(
                    publicKey: accountKey!.publicKey.publicKey,
                    signatureAlgorithm: accountKey!.publicKey.signatureAlgorithm
                ),
                hashAlgorithm: HashAlgorithm.SHA3_256,
                weight: accountKey!.weight
            )
        }
        i = i + 1
        accountKey = getAccount(address).keys.get(keyIndex: i)
    }


    let signatureSet: [Crypto.KeyListSignature] = []
    signatureSet.append(
        Crypto.KeyListSignature(
            keyIndex: 0,
            signature: signature.decodeHex()
        )
    )

    return keyList.verify(signatureSet: signatureSet, signedData: message.decodeHex())
}
