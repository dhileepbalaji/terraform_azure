resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group}"
  location = "${var.location}"
}

resource "azurerm_eventgrid_topic" "eventgridtopic" {
  count               = "${length(var.flasheventgrid)}"
  name                = "${lookup(var.flasheventgrid[count.index], "name")}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  tags = {
    CostCenter          = "${var.mrc_lbl_cost_center}"
    Product             = "${var.mrc_lbl_product}"
    DeploymentName      = "${var.mrc_lbl_deployment_name}"
    Owner               = "${var.mrc_lbl_owner}"
    Environment         = "${var.mrc_lbl_environment}"
    ProvisionedBy       = "${var.mrc_lbl_provisioned_by}"
    SourceRepo          = "${var.mrc_lbl_source_repo}"
    ReleaseId           = "${var.mrc_lbl_releaseid}"
    BuildId             = "${var.mrc_lbl_buildid}"    
  }
}

resource "azurerm_eventgrid_event_subscription" "eventgridsubscription" {
    depends_on = [azurerm_eventgrid_topic.eventgridtopic]
    count = "${length(var.flasheventgridsubscription)}"
    name  = "${lookup(var.flasheventgridsubscription[count.index], "name")}"
    scope = "${azurerm_resource_group.rg.id}/providers/Microsoft.EventGrid/topics/${lookup(var.flasheventgridsubscription[count.index], "scope")}"
    included_event_types  = list("${lookup(var.flasheventgridsubscription[count.index], "included_event_types")}")
    storage_blob_dead_letter_destination {
      storage_account_id = "${data.azurerm_resource_group.storageaccount.id}/providers/Microsoft.Storage/storageAccounts/${lookup(var.flasheventgridsubscription[count.index], "storage_account_id")}"
      storage_blob_container_name = "${lookup(var.flasheventgridsubscription[count.index], "storage_blob_container_name")}"
    }
    retry_policy {
      max_delivery_attempts = "${lookup(var.flasheventgridsubscription[count.index], "max_delivery_attempts")}"
      event_time_to_live = "${lookup(var.flasheventgridsubscription[count.index], "event_time_to_live")}"
    }
    dynamic "webhook_endpoint" {
      for_each = "${lookup(var.flasheventgridsubscription[count.index], "webhook_endpoint")}" == null ? [] : list(var.flasheventgridsubscription[count.index])
      content {
        url = "${webhook_endpoint.value.webhook_endpoint}${var.subscriptionkey}"
      }
    }

}
