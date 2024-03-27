_jq() {
    if [ -z $2 ]; then
        echo ${1} | base64 --decode
    else
        echo ${1} | base64 --decode | jq -r ${2}
    fi
}

_slugify() {
    echo "$1" | iconv -t ascii//TRANSLIT | sed -r s/[^a-zA-Z0-9]+/-/g | sed -r s/^-+\|-+$//g | tr A-Z a-z
}

_version() {
    echo "$VERSION"
    exit 0
}

_usage() {
    echo "Usage: $0"
    echo "  -h, --help"
    echo "  -v, --version"
    echo ""
    echo "  This script is used to generate the import statements for the resources on BTP into terraform code and terraform state."
    echo "  It\`s necessary to btp-cli installed and configured to use this script."
    echo ""
    echo "  -h, --help"
    echo "    Print this help message."
    echo ""
    echo "  -v, --version"
    echo "    Print the version of this script."
    echo ""
    echo "  -sa, --subaccount <subaccount_guid>"
    echo "    Generate the terraform code for the subaccount with the given GUID."
    echo ""
    echo "  -ga, --global-account <global_account_subdomain>"
    echo "    Generate the terraform code for the global account with the given subdomain."
    echo ""
    echo "  -all"
    echo "    Generate the terraform code for all subaccounts."
    echo ""
    exit 0
}
