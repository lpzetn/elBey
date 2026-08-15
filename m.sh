#!/bin/bash

#ELBEY

sed -i 's/\r$//; s/^[[:space:]]*//; s/[[:space:]]*$//' ttt4

# Initialize / clear output text file
> output.txt

fetch_website() {
    website=$1
    # Log progress to stderr so it doesn't pollute standard output
    echo "*** FETCHING --> $website" >&2

    html_content=$(curl -s -L --max-time 20 --connect-timeout 5 "http://$website" \
        -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
        -H 'accept-language: en-US,en;q=0.9' \
        -H 'priority: u=0, i' \
        -H 'sec-ch-ua: "Chromium";v="134", "Not:A-Brand";v="24", "Google Chrome";v="134"' \
        -H 'sec-ch-ua-mobile: ?0' \
        -H 'sec-ch-ua-platform: "Linux"' \
        -H 'sec-fetch-dest: document' \
        -H 'sec-fetch-mode: navigate' \
        -H 'sec-fetch-site: none' \
        -H 'sec-fetch-user: ?1' \
        -H 'upgrade-insecure-requests: 1' \
        -H 'user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36')

    email_found=$(echo "$html_content" | grep -oP '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.(?!png|jpg|jpeg|webp|svg|gif\b)[a-zA-Z]{2,}' | sort -u)
    
    if [[ -n "$email_found" ]]; then
        # Print a website,email line for each extracted email
        echo "$email_found" | awk -v site="$website" '{print site "," $0}'
        return
    fi

    for contact_page in "/contact" "/contact-us" "/contactus" "/contact.php"; do
        contact_url="https://${website%/}${contact_page}"
        contact_html=$(curl -s -o /dev/null -w "%{http_code}" --max-time 20 --connect-timeout 5 "$contact_url" \
            -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
            -H 'accept-language: en-US,en;q=0.9' \
            -H 'priority: u=0, i' \
            -H 'sec-ch-ua: "Chromium";v="134", "Not:A-Brand";v="24", "Google Chrome";v="134"' \
            -H 'sec-ch-ua-mobile: ?0' \
            -H 'sec-ch-ua-platform: "Linux"' \
            -H 'sec-fetch-dest: document' \
            -H 'sec-fetch-mode: navigate' \
            -H 'sec-fetch-site: none' \
            -H 'sec-fetch-user: ?1' \
            -H 'upgrade-insecure-requests: 1' \
            -H 'user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36')

        if [[ "$contact_html" == "200" ]]; then
            html_content=$(curl -s --max-time 20 --connect-timeout 5 "$contact_url" \
                -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
                -H 'accept-language: en-US,en;q=0.9' \
                -H 'priority: u=0, i' \
                -H 'sec-ch-ua: "Chromium";v="134", "Not:A-Brand";v="24", "Google Chrome";v="134"' \
                -H 'sec-ch-ua-mobile: ?0' \
                -H 'sec-ch-ua-platform: "Linux"' \
                -H 'sec-fetch-dest: document' \
                -H 'sec-fetch-mode: navigate' \
                -H 'sec-fetch-site: none' \
                -H 'sec-fetch-user: ?1' \
                -H 'upgrade-insecure-requests: 1' \
                -H 'user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36')
            
            email_found=$(echo "$html_content" | grep -oP "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.(?!png|jpg|jpeg|webp|svg|gif\b)[a-zA-Z]{2,}" | sort -u)
            
            if [[ -n "$email_found" ]]; then
                # Print a website,email line for each extracted email
                echo "$email_found" | awk -v site="$website" '{print site "," $0}'
                return
            fi
        fi
    done
}

export -f fetch_website

# Stream all extracted pairs to output.txt
cat ttt4 | xargs -n 1 -P 42 bash -c 'fetch_website "$0"' >> output.txt
