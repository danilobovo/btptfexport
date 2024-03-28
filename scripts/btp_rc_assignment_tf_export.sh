#!/bin/bash
# This script is used to generate the import statements for the resources on BTP into terraform code and terraform state.
# It`s necessary to btp-cli installed and configured to use this script.
# Author: Danilo Bovo <bovodanilo@gmail.com>
# Version: 1.2
#set -x
VERSION="Version: 1.0"

BASEDIR=$(dirname $0)
if ! command -v _jq &> /dev/null; then
    source $BASEDIR/utils.sh
fi

# Check if the btp-cli is installed and configured
_check_btp_cli

_generate_tf_code_for_role_collection_assignment_subaccount(){
    # Generate the terraform code for the subaccount with the given GUID
    sa_name=$(btp --format json get accounts/subaccounts $1 | jq -r '.displayName')
    echo "# ------------------------------------------------------------------------------------------------------"
    echo "# Creation of role collection assigment for subaccount $sa_name"
    echo "# ------------------------------------------------------------------------------------------------------"
    for user in $(btp --format json list security/user -sa $1 | jq -r '.[]'); do
        for rolecollection in $(btp --format json get security/user "$user" -sa $1 | jq -r '.roleCollections[] | @base64'); do
            name=$(echo $user | cut -d@ -f1)
            rc=$(_jq $rolecollection)
            echo ""
            echo "# terraform code for $user and role collection $rc assignment"
            echo "resource \"btp_subaccount_role_collection_assignment\" \"$(_slugify $name)-$(_slugify "$rc")\" {"
            echo "    subaccount_id        = btp_subaccount.$sa_name.id"
            echo "    role_collection_name = \"$rc\""
            echo "    user_name            = \"$user\""
            echo "}"
            echo ""
        done
    done
}

_generate_tf_code_for_role_collection_assignment_global_account(){
    echo "# ------------------------------------------------------------------------------------------------------"
    echo "# Creation of role collection assigment for global account $1"
    echo "# ------------------------------------------------------------------------------------------------------"
    for user in $(btp --format json list security/user -ga $1 | jq -r '.[]'); do
        for rolecollection in $(btp --format json get security/user "$user" -ga $1 | jq -r '.roleCollections[] | @base64'); do
            name=$(echo $user | cut -d@ -f1)
            rc=$(_jq $rolecollection)
            echo ""
            echo "# terraform code for $user and role collection $rc assignment"
            echo "resource \"btp_globalaccount_role_collection_assignment\" \"$(_slugify $name)-$(_slugify "$rc")\" {"
            echo "    role_collection_name = \"$rc\""
            echo "    user_name            = \"$user\""
            echo "}"
            echo ""
        done
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
        _generate_tf_code_for_role_collection_assignment_subaccount $2
        ;;
    -ga | --global-account)
        if [ -z $2 ]; then
            echo "The global account subdomain is missing."
            exit 1
        fi
        _generate_tf_code_for_role_collection_assignment_global_account $2
        ;;
    -all)
        for subaccount in $(btp --format json list accounts/subaccounts | jq -r '.value[] | @base64'); do
            sa_id=$(_jq $subaccount '.guid')
            _generate_tf_code_for_role_collection_assignment_subaccount $sa_id
        done
        ;;
    *)
        _usage
        ;;
esac
