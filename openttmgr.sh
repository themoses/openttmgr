#!/usr/bin/env bash
if [[ "$DEBUG" != "" ]]; then
    set -x
fi
set -eo pipefail

MOUNT_POINT=""
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
    #TODO: mount via fuse
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
    if [[ "$MOUNT_POINT" != "" && "$DOWNLOAD_PATH" != "" ]]; then
      find "$DOWNLOAD_PATH" -iname "*.gme" -exec mv "$MOUNT_POINT" {} \;
    fi
}

download_tiptoi_file() {
    eval _file_url="$1"
    _gme_file=$(curl --silent "$_file_url" | grep --only-matching --perl-regexp "(\"https:\/\/ravensburger\.cloud\/rvwebsite\/rvDE\/db\/applications\/[[:alnum:]].*\.gme\")" | head -1 | cut -d " " -f1 | tr -d '"')
    echo "$_gme_file"
    #TODO: Support donwnload of both files (old and RL). Currently only first match will get downloaded
    if [[ "$DOWNLOAD_PATH" == "" ]]; then
      DOWNLOAD_PATH=$(mktemp)
    fi

    wget -P "$DOWNLOAD_PATH" "$_gme_file"
}

lookup_by_ean() {
    eval _ean="$1"
    _result_html="https://www.ravensburger.de/de-DE/suche?query=$_ean&productCategories=Ravensburger"
    #TODO: grep/sed with regex and match 2nd group: (<div class="card-product-name">[[:cntrl:]][[:blank:]].*)(tiptoi®[[:blank:]][[:alnum:]].*[[:blank:]].*)([[:cntrl:]][[:blank:]].*<\/div>)

}

lookup_tiptoi_title() {
    # takes article number, ISBN or product name
    eval _query="$1"
    # url encode all whitespaces
    _query_encoded=$(echo "$_query"|jq -sRr @uri)

    # build a new json with title and uri
    #TODO: dont fail if result is empty
    _result_json=$(curl --silent "https://service.ravensburger.de/@api/deki/site/query?dream.out.format=json&q=$_query_encoded&types=wiki&sortBy=-rank&parser=bestguess"\
     | jq '.result[] as $books | select($books.preview | contains("Audiodatei")) | { title: $books.title, uri: $books.uri }' )

    #echo "$_result_json"; exit 0
    mapfile -t _result < <( echo "$_result_json" | jq -r '.title' )

    # create selection menu out of results and download selected file
    if [[ ${#_result[@]} != 0 ]]; then
        select book in "${_result[@]}"; do
            _product_number=$(echo "$book" | grep --only-matching --perl-regexp "[0-9]{5}" | head -1) #only select first match if there are multiple ids per product
            _selected_uri=$(echo "$_result_json" | jq -r 'select(.title | contains("'"$_product_number"'")) | .uri')
            download_tiptoi_file "$_selected_uri"
            #break
        done
    fi
}

main(){
    check_connectivity
    check_mount
    list_local_tiptoi_files
    lookup_tiptoi_title "\"asdf\""
}

main