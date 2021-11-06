import Crypto

pub fun main(
  address: Address,
  message: String,
  signature: String
  keyIndex: UInt64
): Bool {


    // Gets the Crypto.KeyList and the public key of the collection's owner
    let keyList = Crypto.KeyList()

    if let accountKey  = getAccount(address).keys.get(keyIndex: Int(keyIndex)) {
        if(!accountKey!.isRevoked){
        keyList.add(
                PublicKey(
                    publicKey: accountKey!.publicKey.publicKey,
                    signatureAlgorithm: accountKey!.publicKey.signatureAlgorithm
                ),
                hashAlgorithm: HashAlgorithm.SHA3_256,
                weight: accountKey!.weight
            )
        }
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
