import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

export async function getTemplatesScript() {
    if (address == null) return null

    return await fcl
        .query({
            cadence: `
import Flovatar, FlovatarComponent, FlovatarComponentTemplate, FlovatarPack, FlovatarMarketplace from 0xFlovatar
import NonFungibleToken from 0xNonFungible
import FungibleToken from 0xFungible
import FlowToken from 0xFlowToken

pub fun main() : [FlovatarComponentTemplate.ComponentTemplateData] {
    return FlovatarComponentTemplate.getComponentTemplates()
}
`,
            args: (arg, t) => [
            ],
        });

}

