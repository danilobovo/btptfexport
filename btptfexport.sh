#!/bin/bash
# This script is used to generate the import statements for the resources on BTP into terraform code and terraform state.
# It`s necessary to btp-cli installed and configured to use this script.
# Author: Danilo Bovo <bovodanilo@gmail.com>
# Version: 1.2
#set -x
VERSION="Version: 1.2"

BASEDIR=$(dirname $0)
source $BASEDIR/scripts/utils.sh

# Check if the btp-cli is installed and configured
_check_btp_cli

source $BASEDIR/scripts/btp_subaccount_tf_export.sh
source $BASEDIR/scripts/btp_subscription_tf_export.sh
source $BASEDIR/scripts/btp_environment_tf_export.sh
source $BASEDIR/scripts/btp_role_collection_tf_export.sh
source $BASEDIR/scripts/btp_rc_assignment_tf_export.sh
source $BASEDIR/scripts/btp_service_instance_tf_export.sh

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
        _generate_tf_code_for_subscription $2
        _generate_tf_code_for_environment $2
        _generate_tf_code_for_role_collection_subaccount $2
        _generate_tf_code_for_role_collection_assignment_subaccount $2
        _generate_tf_code_for_service_instance $2
    ;;
    -ga | --global-account)
        if [ -z $2 ]; then
            echo "The global account subdomain is missing."
            exit 1
        fi
        _generate_tf_code_for_role_collection_global_account $2
        _generate_tf_code_for_role_collection_assignment_global_account $2
    ;;
    -all)
        for subaccount in $(btp --format json list accounts/subaccounts | jq -r '.subaccounts[] | @base64'); do
            sa_id=$(_jq $subaccount '.guid')
            _generate_tf_code_for_subaccount $sa_id
            _generate_tf_code_for_subscription $sa_id
            _generate_tf_code_for_environment $sa_id
            _generate_tf_code_for_role_collection_subaccount $sa_id
            _generate_tf_code_for_role_collection_assignment_subaccount $sa_id
            _generate_tf_code_for_service_instance $sa_id
        done
    ;;
    *)
        _usage
    ;;
esac

