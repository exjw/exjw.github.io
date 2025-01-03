#!/usr/bin/env bash
# Author https://github.com/Lirt/markdown-toc-bash

FILE=${1}

if [ -z "${FILE}" ]; then
	echo "No file specified as input"
	exit 1
elif [ ! -f "${FILE}" ]; then
	echo "Invalid file: ${FILE}"
	exit 1
fi

declare -a TOC
declare -A TOC_MAP
CODE_BLOCK=0
CODE_BLOCK_REGEX='^```'
HEADING_REGEX='^#{1,}'

while read -r LINE; do
    # Treat code blocks
    if [[ "${LINE}" =~ $CODE_BLOCK_REGEX ]]; then
        # Ignore things until we see code block ending
        CODE_BLOCK=$((CODE_BLOCK + 1))
        if [[ "${CODE_BLOCK}" -eq 2 ]]; then
            # We hit the closing code block
            CODE_BLOCK=0
        fi
        continue
    fi

    # Treat normal line
    if [[ "${CODE_BLOCK}" == 0 ]]; then
        # If we see heading, we save it to ToC map
        if [[ "${LINE}" =~ ${HEADING_REGEX} ]]; then
            TOC+=("${LINE}")
        fi
    fi
done < <(grep -v '## Table of Contents' "${FILE}")

echo -e "## Table of Contents\n"
for LINE in "${TOC[@]}"; do
    case "${LINE}" in
        '#####'*)
          echo -n "        - "
          ;;
        '####'*)
          echo -n "      - "
          ;;
        '###'*)
          echo -n "    - "
          ;;
        '##'*)
          echo -n "  - "
          ;;
        '#'*)
          echo -n "- "
          ;;
    esac

    LINK=${LINE}
    # Detect markdown links in heading and remove link part from them
    if grep -qE "\[.*\]\(.*\)" <<< "${LINK}"; then
        LINK=$(sed 's/\(\]\)\((.*)\)/\1/' <<< "${LINK}")
    fi
    # Special characters (besides '-') in page links in markdown
    # are deleted and spaces are converted to dashes
    LINK=$(tr -dc "[:alnum:] _-" <<< "${LINK}")
    LINK=${LINK/ /}
    LINK=${LINK// /-}
    LINK=${LINK,,}
    LINK=$(tr -s "-" <<< "${LINK}")

    # Print in format [Very Special Heading](#very-special-heading)
    # Make sure to add "-X" suffix with correct increment for headings that are repeated
    INDEX=${TOC_MAP[${LINE}]}
    if [[ "${INDEX}" != "" ]]; then
        INDEX=$(( INDEX + 1 ))
        TOC_MAP[${LINE}]=${INDEX}
        echo "[${LINE#\#* }](#${LINK}-${INDEX})"
    else
        TOC_MAP[${LINE}]=0
        echo "[${LINE#\#* }](#${LINK})"
    fi
done
