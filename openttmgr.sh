#!/usr/bin/env bash
if [[ "$DEBUG" != "" ]]; then
    set -x
fi
set -eo pipefail

if [[ "$FAKE_MOUNT" != "" ]]; then
    MOUNT_POINT="$FAKE_MOUNT"
else
    MOUNT_POINT=""
fi

DOWNLOAD_PATH=""

check_connectivity() {
    if [[ $(lsusb | grep "Mentor Graphics") ]]; then
        echo "TipToi is connected via USB"
    else
        echo "TipToi is not connected."
    fi
}

check_mount() {
    if [[ $(mount | grep tiptoi) ]]; then
        _mount_point=$(mount | grep tiptoi | cut -d " " -f3)
        echo "TipToi is mounted at $_mount_point"
        MOUNT_POINT=$_mount_point
    else
        read -r -p "TipToi is not mounted. Mount now? [y/N] " response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
                mount_tiptoi
        fi
    fi
}

mount_tiptoi() {
    #TODO: mount via diskutil to userspace
    echo "Not implemented"
}

list_local_tiptoi_files() {
    if [[ "$MOUNT_POINT" != "" ]]; then
        find "$MOUNT_POINT" -iname "*.gme"  -printf "%f\n" | sort
    else
        check_connectivity
        check_mount
    fi
}

move_downloaded_files_to_tiptoi() {
    if [[ "$MOUNT_POINT" != "" ]] && [[ "$DOWNLOAD_PATH" != "" ]]; then
      find "$DOWNLOAD_PATH" -iname "*.gme" -exec mv {} "$MOUNT_POINT" \;
    fi
}

download_tiptoi_file() {
    eval _file_url="$1"
    readarray -t _gme_files <<<$(curl --silent "$_file_url" | grep --only-matching --perl-regexp "(\"https:\/\/ravensburger\.cloud\/rvwebsite\/rvDE\/db\/applications\/[[:alnum:]].*\.gme\")"  | cut -d " " -f1 | tr -d '"')

    if [[ "$DOWNLOAD_PATH" == "" ]]; then
      DOWNLOAD_PATH=$(mktemp)
    fi
    
    for _file in "${_gme_files[@]}"; do
        wget -P "$DOWNLOAD_PATH" "$_file"
    done
    check_connectivity
    check_mount
    move_downloaded_files_to_tiptoi 
}

lookup_by_ean() {
    eval _ean="$1"
    _result_html="https://www.ravensburger.de/de-DE/suche?query=$_ean&productCategories=Ravensburger"
    #TODO: grep/sed with regex and match 2nd group: (<div class="card-product-name">[[:cntrl:]][[:blank:]].*)(tiptoi®[[:blank:]][[:alnum:]].*[[:blank:]].*)([[:cntrl:]][[:blank:]].*<\/div>)

}

lookup_tiptoi_title() {
    # takes article number, ISBN or product name
    eval _query="$1"
    # url encode all whitespaces passed as arguments
    _query_encoded=$(echo "$_query" | jq -sRr @uri)

    # build a new json with title and uri but only consider Audiofiles
    _result_json=$(curl --silent "https://service.ravensburger.de/@api/deki/site/query?dream.out.format=json&q=$_query_encoded&types=wiki&sortBy=-rank&parser=bestguess"\
     | jq '.result[] as $books | select($books.page.path | contains("Audiodateien")) | { title: $books.title, uri: $books.uri }' ) || true # don't fail if result is empty

    mapfile -t _result < <( echo "$_result_json" | jq -r '.title' )

    # create selection menu out of results and download selected file
    if [[ ${#_result[@]} != 0 ]]; then
        PS3="Select file to download to tiptoi: "
        select book in "${_result[@]}"; do
            _product_number=$(echo "$book" | grep --only-matching --perl-regexp "[0-9]{5}" | head -1) #only select first match if there are multiple ids per product
            _selected_uri=$(echo "$_result_json" | jq -r 'select(.title | contains("'"$_product_number"'")) | .uri')
            download_tiptoi_file "$_selected_uri"
            break # abort after one file
        done
    else
        echo "No product found with title $_query"
    fi
}

main(){

    lookup_tiptoi_title "$@"
}

main "$@"