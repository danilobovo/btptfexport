# SAP BTP Exporter for Terraform Code

This is a collection of shell scripts based on [btp cli](https://developers.sap.com/tutorials/cp-sapcp-getstarted.html) and [Terraform provider for BTP](https://registry.terraform.io/providers/SAP/btp/latest), to get SAP BTP resources information and generate the respective terraform code and the terraform import command to administer this resources in terraform code.

> [!WARNING]
> This script is not maintained or supported by SAP.

At this moment the script is working for:

- [BTP Subaccount](https://registry.terraform.io/providers/SAP/btp/latest/docs/resources/subaccount)

- [BTP Subaccount Entitlements](https://registry.terraform.io/providers/SAP/btp/latest/docs/resources/subaccount_entitlement) using the [sap btp entitlement](https://registry.terraform.io/modules/aydin-ozcan/sap-btp-entitlements/btp/latest) module by [Aydin Ozcan](https://registry.terraform.io/namespaces/aydin-ozcan).

- [BTP Subaccount Subcription](https://registry.terraform.io/providers/SAP/btp/latest/docs/resources/subaccount_subscription)

- [BTP Subaccount Subcription](https://registry.terraform.io/providers/SAP/btp/latest/docs/resources/subaccount_subscription)

- [BTP Subaccount Environment Instance](https://registry.terraform.io/providers/SAP/btp/latest/docs/resources/subaccount_environment_instance)

- [BTP Subaccount Role Collection](https://registry.terraform.io/providers/SAP/btp/latest/docs/resources/subaccount_role_collection)

- [BTP Subaccount Role Collection Assigment](https://registry.terraform.io/providers/SAP/btp/latest/docs/resources/subaccount_role_collection_assignment)

- [BTP Glocal Account Role Collection](https://registry.terraform.io/providers/SAP/btp/latest/docs/resources/globalaccount_role_collection)

- [BTP Glocal Account Role Collection Assigment](https://registry.terraform.io/providers/SAP/btp/latest/docs/resources/globalaccount_role_collection_assignment)

> [!NOTE]
> The scripts is getting the information for [Subaccount Service Instance](https://registry.terraform.io/providers/SAP/btp/latest/docs/resources/subaccount_service_instance), but I`m not able to import it in the terraform state due to restrictions stated in [Documentation](https://registry.terraform.io/providers/SAP/btp/latest/docs/resources/subaccount_service_instance#restriction).

## Usage

### Step 1: [btp cli](https://developers.sap.com/tutorials/cp-sapcp-getstarted.html)

btp command installed and configured, as configured I mean authenticated.

[Download and start using btp cli](https://help.sap.com/docs/btp/sap-business-technology-platform/download-and-start-using-btp-cli-client)
[Getting started with btp cli](https://developers.sap.com/tutorials/cp-sapcp-getstarted.html)

To login and check.

```bash
btp login
btp --info
```

### Step 2: Download the scripts

Download the root script for all resources

### Step 3: Run the script

Just run the command btptfexport.sh or any of the other subscripts.
You can redirect the output to a tf file and organize the as your preference.

