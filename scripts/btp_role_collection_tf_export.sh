#!/bin/bash
# This script is used to generate the import statements for the resources on BTP into terraform code and terraform state.
# It`s necessary to btp-cli installed and configured to use this script.
# Author: Danilo Bovo <bovodanilo@gmail.com>
# Version: 1.2
#set -x
VERSION="Version: 1.0"

# Check if the btp-cli is installed
if ! command -v btp &> /dev/null; then
    echo "btp-cli could not be found. Please install it and configure it to use this script."
    exit 1
fi

# Check if the btp-cli is configured
if [ -z "$(btp --format json list accounts/subaccounts)" ]; then
    echo "btp-cli is not configured. Please configure it to use this script."
    exit 1
fi

BASEDIR=$(dirname $0)
. $BASEDIR/utils.sh

_generate_tf_code_for_role_collection_subaccount() {
    # Generate the terraform code for the subaccount with the given GUID
    sa_name=$(btp --format json get accounts/subaccounts $1 | jq -r '.displayName')
    for rolecollection in $(btp --format json list security/role-collection -sa $1 | jq -r '.[] | @base64'); do
        # Code to generate the terraform code for the role
        name=$(_jq $rolecollection '.name')
        name_slug=$(_slugify "$(_jq $rolecollection '.name')")
        echo ""
        echo "# terraform code for $name role collection"
        echo "resource \"btp_subaccount_role_collection\" \"$name_slug\" {"
        echo "  subaccount_id = btp_subaccount.$sa_name.id"
        echo "  name          = \"$name\""
        echo "  description   = \"$(_jq $rolecollection '.description')\""
        echo ""
        echo "  roles         = ["
        for role in $(_jq $rolecollection '.roleReferences'| jq -r '.[] | @base64'); do
            echo "    {"
            echo "      name                 = \"$(_jq $role '.name')\""
            echo "      role_template_app_id = \"$(_jq $role '.roleTemplateAppId')\""
            echo "      role_template_name   = \"$(_jq $role '.roleTemplateName')\""
            echo "    },"
        done
        echo "  ]"
        echo "}"
        echo ""
        echo "# Command to import the state of $name role"
        echo "# terraform import btp_subaccount_role_collection.$name_slug $1,\"$name\""
        echo ""
    done
}

_generate_tf_code_for_role_collection_global_account() {
    # Generate the terraform code for the subaccount with the given GUID
    for rolecollection in $(btp --format json list security/role-collection -ga $1 | jq -r '.[] | @base64'); do
        # Code to generate the terraform code for the role
        name=$(_jq $rolecollection '.name')
        name_slug=$(_slugify "$(_jq $rolecollection '.name')")
        echo ""
        echo "# terraform code for $name role collection"
        echo "resource \"btp_globalaccount_role_collection\" \"$name_slug\" {"
        echo "  name     = \"$name\""
        echo "  description = \"$(_jq $rolecollection '.description')\""
        echo ""
        echo "  roles = ["
        for role in $(_jq $rolecollection '.roleReferences'| jq -r '.[] | @base64'); do
            echo "    {"
            echo "      name                 = \"$(_jq $role '.name')\""
            echo "      role_template_app_id = \"$(_jq $role '.roleTemplateAppId')\""
            echo "      role_template_name   = \"$(_jq $role '.roleTemplateName')\""
            echo "    },"
        done
        echo "  ]"
        echo "}"
        echo ""
        echo "# Command to import the state of $name role"
        echo "# terraform import btp_globalaccount_role_collection.$name_slug \"$name\""
        echo ""
    done
}

case $1 in
    -h | --help)
        _usage
        ;;
    -v | --version)
        _version
        ;;
    -sa | --subaccount)
        if [ -z $2 ]; then
            echo "The subaccount GUID is missing."
            exit 1
        fi
        _generate_tf_code_for_role_collection_subaccount $2
        ;;
    -ga | --global-account)
        if [ -z $2 ]; then
            echo "The global account subdomain is missing."
            exit 1
        fi
        _generate_tf_code_for_role_collection_global_account $2
        ;;
    -all)
        exit
        ;;
    *)
        _usage
        ;;
esac


