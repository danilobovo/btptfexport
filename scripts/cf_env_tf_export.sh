#!/bin/bash
# This script is used to generate the import statements for the resources on BTP into terraform code and terraform state.
# It`s necessary to btp-cli installed and configured to use this script.
# Author: Danilo Bovo <bovodanilo@gmail.com>
# Version: 1.1
#set -x
VERSION="Version: 1.1"

# Check if the btp-cli is installed
if ! command -v cf &> /dev/null; then
    echo "cf-cli could not be found. Please install it and configure it to use this script."
    exit 1
fi

# Check if the btp-cli is configured
if [ ! "$(cf target)" ]; then
    echo "cf-cli is not configured. Please configure it to use this script."
    exit 1
fi

BASEDIR=$(dirname $0)
. $BASEDIR/utils.sh

_generate_tf_code_for_cloudfoundry() {
    org_name=$1
    name_slug=$(_slugify "$org_name")
    echo ""
    echo "# ------------------------------------------------------------------------------------------------------"
    echo "# Creation of cloudfoundry org $org_name"
    echo "# ------------------------------------------------------------------------------------------------------"
    echo "# terraform code for $org_name cloud foundry organization"
    echo "resource \"cloudfoundry_org\" \"$name_slug\" {"
    echo "  name                     = \"$org_name\""
    echo "  delete_recursive_allowed = false"
    echo "}"
    echo "# terraform import cloudfoundry_org.$name_slug $(cf org $org_name --guid)"
    echo ""

    org_managers=$(cf org-users "$org_name" | sed -n '/ORG MANAGER/,/^$/p' | sed '1 d;$ d' | sed -n 's/  \([^@]\+@[^[:space:]]*\).*/\"\1\"/p' | paste -sd ',')
    bil_managers=$(cf org-users "$org_name" | sed -n '/BILLING MAN/,/^$/p' | sed '1 d;$ d' | sed -n 's/  \([^@]\+@[^[:space:]]*\).*/\"\1\"/p' | paste -sd ',')
    org_auditors=$(cf org-users "$org_name" | sed -n '/ORG AUDITOR/,/^$/p' | sed '1 d;$ d' | sed -n 's/  \([^@]\+@[^[:space:]]*\).*/\"\1\"/p' | paste -sd ',')

    echo "# terraform code for $org_name cloud foundry organization users"
    echo "resource \"cloudfoundry_org_users\" \"$name_slug-users\" {"
    echo "  org              = cloudfoundry_org.$name_slug.id"
    echo "  managers         = [ $org_managers ]"
    echo "  billing_managers = [ $bil_managers ]"
    echo "  auditors         = [ $org_auditors ]"
    echo "}"

    cf target -o $org_name > /dev/null
    echo "# ------------------------------------------------------------------------------------------------------"
    echo "# Creation of cloudfoundry spaces on $org_name"
    echo "# ------------------------------------------------------------------------------------------------------"
    for space_name in $(cf spaces | awk 'f;/name/{f=1}'); do
        space_name_slug=$(_slugify "$space_name")
        echo "# terraform code for $space_name space on $org_name cloud foundry organization"
        echo "resource \"cloudfoundry_space\" \"$space_name_slug\" {"
        echo "  name                     = \"$space_name\""
        echo "  org                      = cloudfoundry_org.$name_slug.id"
        echo "  delete_recursive_allowed = false"
        echo "}"
        echo "# terraform import cloudfoundry_space.$space_name_slug $(cf space $space_name --guid)"
        echo ""
    done

    dev=$(cf space-users "$org_name" "$space_name" | sed -n '/DEVELOP/,/^$/p' | sed '1 d;$ d' | sed -n 's/  \([^@]\+@[^[:space:]]*\).*/\"\1\"/p' | paste -sd ',')
    aud=$(cf space-users "$org_name" "$space_name" | sed -n '/AUDITOR/,/^$/p' | sed '1 d;$ d' | sed -n 's/  \([^@]\+@[^[:space:]]*\).*/\"\1\"/p' | paste -sd ',')
    man=$(cf space-users "$org_name" "$space_name" | sed -n '/MANAGER/,/^$/p' | sed '1 d;$ d' | sed -n 's/  \([^@]\+@[^[:space:]]*\).*/\"\1\"/p' | paste -sd ',')

    echo "# terraform code for $space_name space users"
    echo "resource \"cloudfoundry_space_users\" \"$space_name_slug-users\" {"
    echo "  space      = cloudfoundry_space.$space_name_slug.id"
    echo "  managers   = [ $man ]"
    echo "  developers = [ $dev ]"
    echo "  auditors   = [ $aud ]"
    echo "}"
}


_generate_tf_code_for_cloudfoundry_all() {
    export IFS=$'\n'
    # Generate the terraform code for the subaccount with the given GUID
    for org_name in $(cf orgs | awk 'f;/name/{f=1}'); do
        _generate_tf_code_for_cloudfoundry "$org_name"
    done
}



_usage() {
    echo "Usage: $0 [option]"
    echo "Options:"
    echo "  -h, --help          Show this help message and exit"
    echo "  -v, --version       Show the version of the script"
    echo "  -a, -all            Generate the terraform code for all orgs on cloudfoundry"
    echo "  -o, -org <org_name> Generate the terraform code for the org on cloudfoundry"
}

case $1 in
    -h | --help)
        _usage
        ;;
    -v | --version)
        _version
        ;;
    -a | -all)
        _generate_tf_code_for_cloudfoundry_all
        ;;
    -o | -org)
        if [ -z "$2" ]; then
            echo "You must provide the org name"
            exit 1
        fi
        if [ ! $(cf orgs | grep $2) ]; then
            echo "The org $2 does not exist"
            exit 1
        fi
        _generate_tf_code_for_cloudfoundry $2
        ;;
    *)
        _usage
        ;;
esac


