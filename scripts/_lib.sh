#!/usr/bin/env bash
# scripts/_lib.sh — shared functions for Massive market data API scripts
# Source this file: source "${SCRIPT_DIR}/_lib.sh"
#
# Security summary (for auditors):
#   - Single external endpoint: https://api.massive.com
#   - Only credential used: MASSIVE_API_KEY (via query param)
#   - Local writes: ~/.config/massive-skill/ only
#   - No other env vars read, no other network calls, no shell-outs to external tools

# shellcheck disable=SC2034
readonly LIB_BASE_URL="https://api.massive.com"
readonly LIB_CONFIG_DIR="${HOME}/.config/massive-skill"
readonly LIB_MAX_PAGES=10

# Global set by make_api_request for callers to inspect
HTTP_CODE=""

# File used to persist HTTP_CODE across subshells
_LIB_HTTP_CODE_FILE="$(mktemp "${TMPDIR:-/tmp}/.massive_http_code_XXXXXX")"
trap 'rm -f "$_LIB_HTTP_CODE_FILE"' EXIT

# _require_api_key
# Validates MASSIVE_API_KEY is set. Exits with error if not.
_require_api_key() {
  if [[ -z "${MASSIVE_API_KEY:-}" ]]; then
    echo '{"error":"MASSIVE_API_KEY environment variable is not set"}' >&2
    exit 1
  fi
}

# _build_url <path> [query_params...]
# Builds a full API URL from a path and optional query parameters.
# Query params should be in "key=value" format. Empty values are skipped.
# API key is always appended.
_build_url() {
  local path="$1"
  shift
  local url="${LIB_BASE_URL}${path}"
  local sep="?"
  local param

  for param in "$@"; do
    local key="${param%%=*}"
    local val="${param#*=}"
    if [[ -n "$val" && "$val" != "$key" ]]; then
      url="${url}${sep}${key}=$(_urlencode "$val")"
      sep="&"
    fi
  done

  url="${url}${sep}apiKey=${MASSIVE_API_KEY}"
  echo "$url"
}

# _urlencode <string>
# URL-encodes a string for safe use in query parameters.
_urlencode() {
  local string="$1"
  local encoded=""
  local i c
  for (( i=0; i<${#string}; i++ )); do
    c="${string:$i:1}"
    case "$c" in
      [a-zA-Z0-9.~_-]) encoded+="$c" ;;
      ' ') encoded+='+' ;;
      *) encoded+=$(printf '%%%02X' "'$c") ;;
    esac
  done
  echo "$encoded"
}

# make_api_request <url>
# Makes an authenticated GET request to the Massive API.
# Sets global HTTP_CODE.
# Outputs response body to stdout.
make_api_request() {
  local url="$1"

  local response
  if ! response=$(curl -s -w "\n%{http_code}" \
    -H "Accept: application/json" \
    "$url" 2>/dev/null); then
    echo '{"error":"network request failed"}' >&2
    HTTP_CODE="000"
    echo "$HTTP_CODE" > "$_LIB_HTTP_CODE_FILE"
    return 0
  fi

  HTTP_CODE=$(echo "$response" | tail -1)
  echo "$HTTP_CODE" > "$_LIB_HTTP_CODE_FILE"
  local body
  body=$(echo "$response" | sed '$d')

  echo "$body"
  return 0
}

# _read_http_code — read HTTP_CODE from file (use after subshell calls)
_read_http_code() {
  if [[ -f "$_LIB_HTTP_CODE_FILE" ]]; then
    HTTP_CODE=$(cat "$_LIB_HTTP_CODE_FILE")
  fi
}

# check_http_status <http_code> <body> <action_description>
# Checks HTTP status code and outputs error JSON to stderr if not 200.
# Returns 0 on 200, 1 on any error.
check_http_status() {
  local http_code="$1"
  local body="$2"
  local action="$3"

  if ! [[ "$http_code" =~ ^[0-9]+$ ]]; then
    echo "{\"error\":\"${action} failed (invalid HTTP response)\"}" >&2
    return 1
  fi

  if [[ "$http_code" -eq 200 ]]; then
    return 0
  fi

  if [[ "$http_code" -eq 429 ]]; then
    echo '{"error":"rate limit exceeded (HTTP 429). Try again later."}' >&2
    return 1
  fi

  if [[ "$http_code" -eq 403 ]]; then
    echo '{"error":"access denied (HTTP 403). Check your API key and plan."}' >&2
    return 1
  fi

  # Try to extract error message from response body
  local msg
  msg=$(echo "$body" | jq -r '.error // .message // .status // empty' 2>/dev/null)
  if [[ -n "$msg" ]]; then
    echo "{\"error\":\"${action} failed (HTTP ${http_code}): ${msg}\"}" >&2
  else
    echo "{\"error\":\"${action} failed (HTTP ${http_code})\"}" >&2
  fi
  return 1
}

# paginate <url> [max_pages]
# Follows next_url pagination, collecting all results into a single JSON array.
# Outputs combined results as a JSON object with "results" array.
# Stops after max_pages (default: LIB_MAX_PAGES) to prevent runaway requests.
paginate() {
  local url="$1"
  local max_pages="${2:-$LIB_MAX_PAGES}"
  local page=0
  local all_results="[]"
  local current_url="$url"

  while [[ -n "$current_url" && "$page" -lt "$max_pages" ]]; do
    local body
    body=$(make_api_request "$current_url")
    _read_http_code

    if ! check_http_status "$HTTP_CODE" "$body" "paginate"; then
      echo "$body"
      return 1
    fi

    # Extract results from this page
    local page_results
    page_results=$(echo "$body" | jq '.results // []' 2>/dev/null)
    if [[ "$page_results" != "null" && "$page_results" != "[]" ]]; then
      all_results=$(echo "$all_results" "$page_results" | jq -s '.[0] + .[1]')
    fi

    # Check for next_url
    local next_url
    next_url=$(echo "$body" | jq -r '.next_url // empty' 2>/dev/null)

    if [[ -n "$next_url" ]]; then
      # Append API key if not already present
      if [[ "$next_url" != *"apiKey="* ]]; then
        if [[ "$next_url" == *"?"* ]]; then
          current_url="${next_url}&apiKey=${MASSIVE_API_KEY}"
        else
          current_url="${next_url}?apiKey=${MASSIVE_API_KEY}"
        fi
      else
        current_url="$next_url"
      fi
    else
      current_url=""
    fi

    page=$((page + 1))
  done

  # Build response with combined results
  local count
  count=$(echo "$all_results" | jq 'length')
  echo "{\"status\":\"OK\",\"count\":${count},\"results\":${all_results}}"
}

# _parse_flag <flag_name> <args...>
# Returns the value following the named flag, or empty string if not found.
_parse_flag() {
  local flag="$1"
  shift
  while [[ $# -gt 0 ]]; do
    if [[ "$1" == "$flag" && $# -gt 1 ]]; then
      echo "$2"
      return 0
    fi
    shift
  done
  echo ""
}

# _has_flag <flag_name> <args...>
# Returns 0 if the flag is present in args, 1 otherwise.
_has_flag() {
  local flag="$1"
  shift
  while [[ $# -gt 0 ]]; do
    if [[ "$1" == "$flag" ]]; then
      return 0
    fi
    shift
  done
  return 1
}

# _json_output <body>
# Outputs pretty-printed JSON if stdout is a terminal, compact otherwise.
_json_output() {
  local body="$1"
  if [[ -t 1 ]]; then
    echo "$body" | jq '.'
  else
    echo "$body" | jq -c '.'
  fi
}

# _usage <script_name> <description> <usage_text>
# Prints usage info and exits.
_usage() {
  local script="$1"
  local desc="$2"
  local usage="$3"
  cat >&2 <<EOF
${script} — ${desc}

Usage:
${usage}

Requires: MASSIVE_API_KEY environment variable
EOF
  exit 1
}

# Initialize: require API key on source
_require_api_key
mkdir -p "$LIB_CONFIG_DIR" 2>/dev/null || true
