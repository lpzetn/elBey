#!/bin/bash

# grep -Fvx -f old sites.txt > temp && mv temp sites.txt
# Define regex for email addresses
sed -i 's/\r$//; s/^[[:space:]]*//; s/[[:space:]]*$//' sites.txt
email_regex="[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"

# Function to search for email addresses on a website
fetch_website() {
    website=$1
    echo -e "*** FETCHING --> $website"
    # Fetch the homepage HTML content
    html_content=$(curl -s -L --max-time 20 --connect-timeout 5 "http://$website" -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' -H 'accept-language: en-US,en;q=0.9' -H 'priority: u=0, i' -H 'sec-ch-ua: "Chromium";v="134", "Not:A-Brand";v="24", "Google Chrome";v="134"' -H 'sec-ch-ua-mobile: ?0' -H 'sec-ch-ua-platform: "Linux"' -H 'sec-fetch-dest: document' -H 'sec-fetch-mode: navigate' -H 'sec-fetch-site: none' -H 'sec-fetch-user: ?1' -H 'upgrade-insecure-requests: 1' -H 'user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36')


    # Search for email address regex using grep
    email_found=$(echo "$html_content" | grep -oP '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.(?!png|jpg|jpeg|webp|svg|gif\b)[a-zA-Z]{2,}' | sort -u)
    
    if [[ -n "$email_found" ]]; then
        echo -e "$email_found" >> output.txt
        echo -e "$website : $email_found \n"
        return
    fi

    # Try contact-related URLs if no email found on homepage
    for contact_page in "/contact" "/contact-us" "/contactus" "/contact.php"; do
        contact_url="https://${website%/}${contact_page}"
        contact_html=$(curl -s -o /dev/null -w "%{http_code}" --max-time 20 --connect-timeout 5 "$contact_url" -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' -H 'accept-language: en-US,en;q=0.9' -H 'priority: u=0, i' -H 'sec-ch-ua: "Chromium";v="134", "Not:A-Brand";v="24", "Google Chrome";v="134"' -H 'sec-ch-ua-mobile: ?0' -H 'sec-ch-ua-platform: "Linux"' -H 'sec-fetch-dest: document' -H 'sec-fetch-mode: navigate' -H 'sec-fetch-site: none' -H 'sec-fetch-user: ?1' -H 'upgrade-insecure-requests: 1' -H 'user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36')


        if [[ "$contact_html" == "200" ]]; then
            html_content=$(curl -s --max-time 20 --connect-timeout 5 "$contact_url" -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' -H 'accept-language: en-US,en;q=0.9' -H 'priority: u=0, i' -H 'sec-ch-ua: "Chromium";v="134", "Not:A-Brand";v="24", "Google Chrome";v="134"' -H 'sec-ch-ua-mobile: ?0' -H 'sec-ch-ua-platform: "Linux"' -H 'sec-fetch-dest: document' -H 'sec-fetch-mode: navigate' -H 'sec-fetch-site: none' -H 'sec-fetch-user: ?1' -H 'upgrade-insecure-requests: 1' -H 'user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36')
            email_found=$(echo "$html_content" | grep -oP "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.(?!png|jpg|jpeg|webp|svg|gif\b)[a-zA-Z]{2,}" | sort -u)
            if [[ -n "$email_found" ]]; then
                echo -e "$email_found" >> output.txt
                echo -e "$website : $email_found \n"
                return
            fi
        fi
    done
}

# Export the function to make it accessible to subshells
export -f fetch_website

# Read websites from the input file and run the script with threading
cat sites.txt | xargs -n 1 -P 18 bash -c 'fetch_website "$0"'
curl -k -X POST -F "file=@output.txt" https://www.searchenginegenie.com/m/das.php

# total=$(grep -c "" sites.txt)

# for (( i=1; i<=$total; i++ )); do
#     site=$(sed -i -e '1 w /dev/stdout' -e '1d' sites.txt)
#     fetch_website "$site"
# done
