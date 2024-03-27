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

_generate_tf_code_for_subscription() {
    # Generate the terraform code for the subaccount with the given GUID
    sa_name=$(btp --format json get accounts/subaccounts $1 | jq -r '.displayName')
    echo "# ------------------------------------------------------------------------------------------------------"
    echo "# Creation of subaccount subscription"
    echo "# ------------------------------------------------------------------------------------------------------"
    for subscription in $(btp --format json list accounts/subscription -sa $1 | jq -r '.applications[] | @base64'); do
        name=$(_jq $subscription '.displayName')
        name_slug=$(_slugify "$(_jq $subscription '.displayName')")
        state=$(_jq $subscription '.state')
        if [ "$state" != "SUBSCRIBED" ]; then
            continue
        fi
        echo "# terraform code for $(_jq $subscription '.displayName') subscription"
        echo "resource \"btp_subaccount_subscription\" \"$name_slug\" {"
        echo "  subaccount_id   = btp_subaccount.$sa_name.id"
        echo "  app_name        = \"$(_jq $subscription '.appName')\""
        echo "  plan_name       = \"$(_jq $subscription '.planName')\""
        parameters=$(_jq $subscription '.parameters')
        [ "$parameters" != "null" ] && echo "  parameters      = \"$parameters\""
        echo "}"
        echo ""
        echo "# Command to import the state of $(_jq $subscription '.displayName') subscription"
        echo "# terraform import btp_subaccount_subscription.$name_slug $1,$(_jq $subscription '.appName'),$(_jq $subscription '.planName')"
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
        _generate_tf_code_for_subscription $2
        ;;
    -all)
        exit
        ;;
    *)
        _usage
        ;;
esac


