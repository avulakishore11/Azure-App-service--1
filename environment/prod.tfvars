subscription_id        = "7a6d2623-b7d9-467b-ab2f-d71d7bf6d45d"
location               = "centralus"
location_code_override = "eus"
subscription           = "corit"
app_name               = "app"
environment            = "prod"
instance               = "01"

admin_username = "azureadmin"
admin_password = "ChangeThisPassword123!"

vm_size     = "Standard_D8s_v5"
storage_sku = "Standard_ZRS"

vnet_address_prefix            = "10.5.0.0/16"
logic_app_subnet_prefix        = "10.5.0.0/24"
vm_subnet_prefix               = "10.5.1.0/24"
private_endpoint_subnet_prefix = "10.5.2.0/24"

lock_level = "CanNotDelete"

project     = "vm-ss-automation"
department  = "corporate IT"
created_by  = "kishore avula"
update_ring = "Ring 3"
