#!/bin/bash
# This script is used to generate the import statements for the resources on BTP into terraform code and terraform state.
# It`s necessary to btp-cli installed and configured to use this script.
# Author: Danilo Bovo <bovodanilo@gmail.com>
# Version: 1.2
VERSION="Version: 1.2"

BASEDIR=$(dirname $0)
if ! command -v _jq &> /dev/null; then
    source $BASEDIR/utils.sh
fi

# Check if the btp-cli is installed and configured
_check_btp_cli

_print_subaccount_tf_code() {
    # Code to generate the terraform code for the subaccount
    sa_name=$(_jq $1 '.displayName')
    sa_id=$(_jq $1 '.guid')
    echo "data \"btp_subaccount\" \"$sa_name\" {"
    echo "  id = \"$sa_id\""
    echo "}"
    echo ""
    echo "# ------------------------------------------------------------------------------------------------------"
    echo "# Creation of subaccount"
    echo "# ------------------------------------------------------------------------------------------------------"
    echo "# terraform code for $sa_name subaccount"
    echo "resource \"btp_subaccount\" \"$sa_name\" {"
    echo "  name         = \"$sa_name\""
    echo "  subdomain    = \"$(_jq $1 '.subdomain')\""
    echo "  region       = \"$(_jq $1 '.region')\""
    echo "  parent_id    = \"$(_jq $1 '.parentGUID')\""
    echo "  beta_enabled = \"$(_jq $1 '.betaEnabled')\""
    description=$(_jq $1 '.description')
    [ "$description" != "null" ] && echo "  description  = \"$description\""
    echo "  usage        = \"$(_jq $1 '.usedForProduction')\""
    echo "}"
    echo ""
    echo "# Command to import the state of $sa_name subaccount"
    echo "# terraform import btp_subaccount.$sa_name $(_jq $1 '.guid')"
    echo ""
    # Code to generate the terraform code for the entitlements for the subaccount above
    echo "# ------------------------------------------------------------------------------------------------------"
    echo "# Creation of subaccount entitlements"
    echo "# ------------------------------------------------------------------------------------------------------"
    echo "module \"sap-btp-entitlements-$sa_name\" {"
    echo "  source       = \"aydin-ozcan/sap-btp-entitlements/btp\""
    echo "  version      = \"1.0.1\""
    echo ""
    echo "  subaccount   = btp_subaccount.$sa_name.id"
    echo ""
    echo "  entitlements = {"
    btp --format json list accounts/entitlement --subaccount $(_jq $1 '.guid') | jq -c '.quotas | group_by(.service) | map({key: .[0].service,value: map(.plan)})' | sed 's/\[{//;s/}\]//;s/},{/\n/g;s/","value"/":"value"/g' | awk -F: '{print "    "$2" = "$4}'
    echo "  }"
    echo "}"
    echo ""
    echo "# Command to import $sa_name entitlements"
    for ent in $(btp --format json list accounts/entitlement --subaccount $(_jq $1 '.guid') | jq -r '.quotas[] | @base64'); do
        echo "# terraform import module.sap-btp-entitlements-$sa_name.btp_subaccount_entitlement.entitlement[\\\"$(_jq $ent '.service')-$(_jq $ent '.plan')\\\"] $(_jq $1 '.guid'),$(_jq $ent '.service'),$(_jq $ent '.plan')"
        # terraform import module.sap-btp-entitlements.btp_subaccount_entitlement.entitlement[\"application-logs-lite\"] 6673841d-0558-44fb-8fab-fcba02852479,application-logs,lite
    done
    echo ""
}

_generate_tf_code_for_subaccount() {
    # Generate the terraform code for the subaccount with the given GUID
    row=$(btp --format json get accounts/subaccounts $1 | jq -r '. | @base64')
    _print_subaccount_tf_code $row
}

_generate_tf_code_for_all_subaccounts() {
    # Generate the terraform code for all subaccounts
    for row in $(btp --format json list accounts/subaccounts | jq -r '.value[] | @base64'); do
        _print_subaccount_tf_code $row
    done
}

if [ "$0" != "$BASH_SOURCE" ]; then
    return 0
fi

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
        _generate_tf_code_for_subaccount $2
        ;;
    -ga | --global-account)
        if [ -z $2 ]; then
            echo "The global account subdomain is missing."
            exit 1
        fi
        echo "Not implemented yet."
        exit 0
        ;;
    -all)
        _generate_tf_code_for_all_subaccounts
        ;;
    *)
        _usage
        ;;
esac

