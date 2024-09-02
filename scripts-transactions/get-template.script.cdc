
import "FlovatarComponentTemplate"

access(all) fun main(templateId: UInt64) : FlovatarComponentTemplate.ComponentTemplateData? {
    return FlovatarComponentTemplate.getComponentTemplate(id: templateId)
}