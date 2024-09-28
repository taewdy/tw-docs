#!/bin/bash

# Check if a JSON file is provided
if [ $# -lt 1 ]; then
  echo "Usage: $0 input.json"
  exit 1
fi

# Assign the first argument as the JSON file
json_file="$1"

# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: 'jq' is required but not installed. Please install jq to proceed."
  exit 1
fi

# Extract values from the JSON file using jq
login_url=$(jq -r '.login_url // empty' "$json_file")
login_token=$(jq -r '.login_token // empty' "$json_file")
method=$(jq -r '.method // empty' "$json_file")
content_type=$(jq -r '.["content-type"] // empty' "$json_file")
body=$(jq -c '.body // empty' "$json_file")
url=$(jq -r '.url // empty' "$json_file")

# Verify that the URL is provided
if [ -z "$url" ]; then
  echo "Error: URL is missing in the JSON file."
  exit 1
fi

curl_login_cmd=("curl" "-i", "-X", "POST", "-H", "Content-Type: application/json", "--data", "{\"Token\":\"$login_token\"}", "$login_url")

# Execute the curl command and extract returned values using jq, it's under resources.token
token=$("${curl_login_cmd[@]}") | jq -r '.resources.token // empty'

# Build the curl command using an array to handle spaces and special characters
curl_cmd=("curl" "-i")

# Add the HTTP method if specified
if [ -n "$method" ]; then
  curl_cmd+=("-X" "$method")
fi

# Add the Content-Type header if specified
if [ -n "$content_type" ]; then
  curl_cmd+=("-H" "Content-Type: $content_type")
fi

# Add the Authorization header if specified
if [ -n "$token" ]; then
  curl_cmd+=("-H" "Authorization: Bearer $token")
fi

# Add the JSON body if specified
if [ -n "$body" ] && [ "$body" != "null" ]; then
  curl_cmd+=("--data" "$body")
fi

# Add the URL
curl_cmd+=("$url")

# Execute the curl command
"${curl_cmd[@]}"
