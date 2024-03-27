#!/bin/bash
# This script is used to generate the import statements for the resources on BTP into terraform code and terraform state.
# It`s necessary to btp-cli installed and configured to use this script.
# Author: Danilo Bovo <bovodanilo@gmail.com>
# Version: 1.2

VERSION="Version: 1.2"

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
. $BASEDIR/btp_environment_tf_export.sh
. $BASEDIR/btp_rc_assignment_tf_export.sh
. $BASEDIR/btp_role_collection_tf_export.sh
. $BASEDIR/btp_service_instance_tf_export.sh
. $BASEDIR/btp_subaccount_tf_export.sh
. $BASEDIR/btp_subscription_tf_export.sh

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
        _generate_tf_code_for_service_instance $2
        _generate_tf_code_for_role_collection_subaccount $2
        _generate_tf_code_for_user_rc $2
        _generate_tf_code_for_role_collection_assignment_subaccount $2
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
        _generate_tf_code_for_all_subaccounts
        ;;
    *)
        _usage
        ;;
esac

