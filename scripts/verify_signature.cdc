import Crypto

pub fun main(
  address: Address,
  message: String,
  signature: String
): Bool {


    // Gets the Crypto.KeyList and the public key of the collection's owner
    let keyList = Crypto.KeyList()
    let accountKey = getAccount(address).keys.get(keyIndex: 0)!.publicKey

    // Adds the public key to the keyList
    keyList.add(
        PublicKey(
            publicKey: accountKey.publicKey,
            signatureAlgorithm: accountKey.signatureAlgorithm
        ),
        hashAlgorithm: HashAlgorithm.SHA3_256,
        weight: 1.0
    )

    let signatureSet: [Crypto.KeyListSignature] = []
    signatureSet.append(
        Crypto.KeyListSignature(
            keyIndex: 0,
            signature: signature.decodeHex()
        )
    )

    return keyList.verify(signatureSet: signatureSet, signedData: message.utf8)
}
