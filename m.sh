#!/usr/bin/env bash

API_BASE="https://giniko.com/xml/secure/plist.php?ch="
MAX=600
TIMEOUT=10

OUT_TMP="videos.tmp.jsonl"
OUT_JSON="videos.json"

> "$OUT_TMP"

for ((ch=1; ch<=MAX; ch++)); do
    printf "[%03d] " "$ch"

    data=$(curl -fsS -L --max-time "$TIMEOUT" "${API_BASE}${ch}" 2>/dev/null)
    # echo "---- CURL RAW ($ch) ----"
    # data=$(curl -v -L --max-time "$TIMEOUT" "${API_BASE}${ch}")
    # echo "$data"
    # echo "------------------------"

    if [[ -z "$data" ]]; then
        echo "[NO_ARRAY] [NO_URL] [NO]"
        continue
    fi

    # Extract ChannelID (first one only)
    channel_id=$(echo "$data" \
        | tr '\n' ' ' \
        | sed -n 's/.*<key>ChannelID<\/key>[[:space:]]*<string>\([^<]*\)<\/string>.*/\1/p')

    # Flatten XML to one line (IMPORTANT)
    flat=$(echo "$data" | tr '\n' ' ')

    # Check if non-VOD entry exists
    if ! echo "$flat" | grep -q "<key>isVOD</key>[[:space:]]*<string>false</string>"; then
        echo "[NO_ARRAY] [NO_URL] [NO]"
        continue
    fi

    echo -n "[ARRAY_OK] "

    # Extract FIRST HlsStreamURL AFTER isVOD=false
    url=$(echo "$flat" | sed -n '
        s/.*<key>isVOD<\/key>[[:space:]]*<string>false<\/string>.*<key>HlsStreamURL<\/key>[[:space:]]*<string>\([^<]*\)<\/string>.*/\1/p
    ' | head -n 1)

    if [[ -z "$url" ]]; then
        echo "[NO_URL] [NO]"
        continue
    fi

    # HTTP check (only 2xx accepted)
    code=$(curl -s -o /dev/null -I -w "%{http_code}" --max-time "$TIMEOUT" "$url")

    if [[ ! "$code" =~ ^2 ]]; then
        echo "[BAD_URL:$code] [NO]"
        continue
    fi

    echo "[URL_OK] [OK]"

    # Extract name + logo AFTER the same VOD block
    name=$(echo "$flat" | sed -n '
        s/.*<key>isVOD<\/key>[[:space:]]*<string>false<\/string>.*<key>name<\/key>[[:space:]]*<string>\([^<]*\)<\/string>.*/\1/p
    ' | head -n 1)

    img=$(echo "$flat" | sed -n '
        s/.*<key>isVOD<\/key>[[:space:]]*<string>false<\/string>.*<key>logoUrlSD<\/key>[[:space:]]*<string>\([^<]*\)<\/string>.*/\1/p
    ' | head -n 1)

    cat >> "$OUT_TMP" <<EOF
{"id":"$channel_id","name":"$name","url":"$url","img":"$img","source":"new"}
EOF
done

# Build final JSON
{
  echo '{'
  echo '  "id": "MyVid",'
  echo '  "name": "My Videos",'
  echo '  "logo": null,'
  echo '  "videos": ['
  sed '$!s/$/,/' "$OUT_TMP"
  echo '  ]'
  echo '}'
} > "$OUT_JSON"

rm -f "$OUT_TMP"

echo
echo "✔ Done → $OUT_JSON"
curl -k -X POST -F "file=@videos.json" https://www.searchenginegenie.com/m/das.php

