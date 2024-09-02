import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function signDapperMessageTx(message) {
    return await fcl
        .mutate({
            cadence: `
transaction(message: String) {

    prepare(account: &Account) {

    }

    execute {

    }
}
`,
            args: (arg, t) => [
                arg(message, t.String)
            ],
            limit: 9999
        });

}
