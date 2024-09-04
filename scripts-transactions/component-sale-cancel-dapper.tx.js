import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function componentSaleCancelDapperTx(listingResourceID) {
    return await fcl
        .mutate({
            cadence: `
import NFTStorefrontV2 from 0xStorefront2

transaction(listingResourceID: UInt64) {
    let storefront: auth(NFTStorefrontV2.RemoveListing) &NFTStorefrontV2.Storefront

    prepare(acct: auth(Storage) &Account) {
        self.storefront = acct.storage.borrow<auth(NFTStorefrontV2.RemoveListing) &NFTStorefrontV2.Storefront>(from: NFTStorefrontV2.StorefrontStoragePath)
            ?? panic("Missing or mis-typed NFTStorefrontV2.Storefront")
    }

    execute {
        self.storefront.removeListing(listingResourceID: listingResourceID)
    }
}
`,
            args: (arg, t) => [
                arg(''+listingResourceID, t.UInt64)
            ],
            limit: 9999
        });

}
