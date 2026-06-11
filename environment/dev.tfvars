subscription_id        = "7a6d2623-b7d9-467b-ab2f-d71d7bf6d45d"
location               = "centralus"
location_code_override = "eus"
subscription           = "corit"
app_name               = "app"
instance               = "01"

admin_username = "azureadmin"
admin_password = "ChangeThisPassword123!"

vm_size     = "Standard_D4s_v2"
storage_sku = "Standard_LRS"

vnet_address_prefix            = "10.3.0.0/16"
logic_app_subnet_prefix        = "10.3.0.0/24"
vm_subnet_prefix               = "10.3.1.0/24"
private_endpoint_subnet_prefix = "10.3.2.0/24"

lock_level = "CanNotDelete"

project    = "vm-ss-automation"
department = "corporate IT"
created_by = "kishore avula"
environment = "dev"

redis_sku_size = "Balanced_B0"