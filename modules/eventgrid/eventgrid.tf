variable "tf_lbl_cost_center" {}
variable "tf_lbl_product" {}
variable "tf_lbl_deployment_name" {}
variable "tf_lbl_owner" {}
variable "tf_lbl_environment" {}
variable "tf_lbl_provisioned_by" {}
variable "tf_lbl_source_repo" {}
variable "tf_lbl_releaseid" {}
variable "tf_lbl_buildid" {}
variable "resource_group" {}
variable "location" {}
variable "eventgrid" {}
variable "eventgridsubscription" {}
variable "storageaccount" {}
variable "subscriptionkey" {}



resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group}"
  location = "${var.location}"
}

data "azurerm_resource_group" "storageaccount" {
  name = "${var.storageaccount}"
}

resource "azurerm_eventgrid_topic" "eventgridtopic" {
  count               = "${length(var.eventgrid)}"
  name                = "${lookup(var.eventgrid[count.index], "name")}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  tags = {
    CostCenter          = "${var.tf_lbl_cost_center}"
    Product             = "${var.tf_lbl_product}"
    DeploymentName      = "${var.tf_lbl_deployment_name}"
    Owner               = "${var.tf_lbl_owner}"
    Environment         = "${var.tf_lbl_environment}"
    ProvisionedBy       = "${var.tf_lbl_provisioned_by}"
    SourceRepo          = "${var.tf_lbl_source_repo}"
    ReleaseId           = "${var.tf_lbl_releaseid}"
    BuildId             = "${var.tf_lbl_buildid}"    
  }
}

resource "azurerm_eventgrid_event_subscription" "eventgridsubscription" {
    depends_on = [azurerm_eventgrid_topic.eventgridtopic]
    count = "${length(var.eventgridsubscription)}"
    name  = "${lookup(var.eventgridsubscription[count.index], "name")}"
    scope = "${azurerm_resource_group.rg.id}/providers/Microsoft.EventGrid/topics/${lookup(var.eventgridsubscription[count.index], "scope")}"
    included_event_types  = list("${lookup(var.eventgridsubscription[count.index], "included_event_types")}")
    storage_blob_dead_letter_destination {
      storage_account_id = "${data.azurerm_resource_group.storageaccount.id}/providers/Microsoft.Storage/storageAccounts/${lookup(var.eventgridsubscription[count.index], "storage_account_id")}"
      storage_blob_container_name = "${lookup(var.eventgridsubscription[count.index], "storage_blob_container_name")}"
    }
    retry_policy {
      max_delivery_attempts = "${lookup(var.eventgridsubscription[count.index], "max_delivery_attempts")}"
      event_time_to_live = "${lookup(var.eventgridsubscription[count.index], "event_time_to_live")}"
    }
    dynamic "webhook_endpoint" {
      for_each = "${lookup(var.eventgridsubscription[count.index], "webhook_endpoint")}" == null ? [] : list(var.eventgridsubscription[count.index])
      content {
        url = "${webhook_endpoint.value.webhook_endpoint}${var.subscriptionkey}"
      }
    }

}
