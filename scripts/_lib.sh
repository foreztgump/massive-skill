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

# File used to persist HTTP_CODE across subshells (deterministic path, no mktemp fork)
_LIB_HTTP_CODE_FILE="/tmp/.massive_http_code_$$"
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
    # Skip params with no '=' separator
    [[ "$param" != *"="* ]] && continue
    local key="${param%%=*}"
    local val="${param#*=}"
    if [[ -n "$val" ]]; then
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
  local i c hex
  for (( i=0; i<${#string}; i++ )); do
    c="${string:$i:1}"
    case "$c" in
      [a-zA-Z0-9.~_-]) encoded+="$c" ;;
      ' ') encoded+='+' ;;
      # printf -v avoids forking a subshell per character
      *) printf -v hex '%%%02X' "'$c"; encoded+="$hex" ;;
    esac
  done
  echo "$encoded"
}

# make_api_request <url>
# Makes an authenticated GET request to the Massive API.
# Sets global HTTP_CODE (also written to file for subshell access).
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
    return 1
  fi

  # Extract HTTP code and body using bash string ops (no fork)
  HTTP_CODE="${response##*$'\n'}"
  echo "$HTTP_CODE" > "$_LIB_HTTP_CODE_FILE"
  echo "${response%$'\n'*}"
  return 0
}

# _read_http_code — read HTTP_CODE from file (use after subshell calls)
_read_http_code() {
  if [[ -f "$_LIB_HTTP_CODE_FILE" ]]; then
    read -r HTTP_CODE < "$_LIB_HTTP_CODE_FILE"
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
    local api_msg
    api_msg=$(echo "$body" | jq -r '.message // .error // empty' 2>/dev/null)
    if [[ -n "$api_msg" ]]; then
      jq -n --arg msg "access denied (HTTP 403): $api_msg" '{"error": $msg}' >&2
    else
      echo '{"error":"access denied (HTTP 403). Check your API key and plan at https://massive.com/pricing"}' >&2
    fi
    return 1
  fi

  local msg
  msg=$(echo "$body" | jq -r '.error // .message // .status // empty' 2>/dev/null)
  if [[ -n "$msg" ]]; then
    echo "{\"error\":\"${action} failed (HTTP ${http_code}): ${msg}\"}" >&2
  else
    echo "{\"error\":\"${action} failed (HTTP ${http_code})\"}" >&2
  fi
  return 1
}

# _fetch_and_output <action> <url>
# Makes an API request, checks status, and outputs JSON. Exits 1 on error.
# Replaces the repeated make_api_request + _read_http_code + check_http_status + _json_output pattern.
_fetch_and_output() {
  local action="$1"
  local url="$2"
  local body
  body=$(make_api_request "$url")
  _read_http_code
  check_http_status "$HTTP_CODE" "$body" "$action" || exit 1
  _json_output "$body"
}

# _paginate_and_output <url>
# Paginates an endpoint and outputs combined JSON. Exits 1 on error.
# Replaces the repeated paginate + _json_output pattern.
_paginate_and_output() {
  local url="$1"
  local body
  body=$(paginate "$url") || exit 1
  _json_output "$body"
}

# _require_arg <name> <value> <command>
# Validates that a required argument is present. Exits with error if not.
_require_arg() {
  local name="$1"
  local value="$2"
  local command="$3"
  if [[ -z "$value" ]]; then
    echo "{\"error\":\"${command} requires: <${name}>\"}" >&2
    exit 1
  fi
}

# _resolve_next_url <next_url>
# Appends API key to a pagination URL if not already present.
_resolve_next_url() {
  local next_url="$1"
  if [[ -z "$next_url" ]]; then
    echo ""
    return
  fi
  if [[ "$next_url" == *"apiKey="* ]]; then
    echo "$next_url"
  elif [[ "$next_url" == *"?"* ]]; then
    echo "${next_url}&apiKey=${MASSIVE_API_KEY}"
  else
    echo "${next_url}?apiKey=${MASSIVE_API_KEY}"
  fi
}

# paginate <url> [max_pages]
# Follows next_url pagination, collecting all results into a single JSON array.
# Outputs combined results as a JSON object with "results" array.
# Stops after max_pages (default: LIB_MAX_PAGES) to prevent runaway requests.
paginate() {
  local url="$1"
  local max_pages="${2:-$LIB_MAX_PAGES}"
  local page=0
  local current_url="$url"
  local tmpfile
  tmpfile=$(mktemp)
  # shellcheck disable=SC2064
  trap "rm -f '$tmpfile'" RETURN

  while [[ -n "$current_url" && "$page" -lt "$max_pages" ]]; do
    local body
    body=$(make_api_request "$current_url")
    _read_http_code

    if ! check_http_status "$HTTP_CODE" "$body" "paginate"; then
      echo "$body"
      rm -f "$tmpfile"
      return 1
    fi

    # Single jq call to extract results type, results, and next_url
    local results_type page_results raw_next
    eval "$(echo "$body" | jq -r '
      "results_type=" + (.results | type) +
      "\nraw_next=" + (.next_url // "" | @sh)
    ' 2>/dev/null)"

    # If .results is not an array (e.g. technical indicators), return raw
    if [[ "$results_type" != "array" ]]; then
      echo "$body"
      rm -f "$tmpfile"
      return 0
    fi

    # Append page results to temp file (avoids O(n^2) re-merge)
    echo "$body" | jq -c '.results // []' >> "$tmpfile" 2>/dev/null

    current_url=$(_resolve_next_url "$raw_next")
    page=$((page + 1))
  done

  # Merge all pages in one pass
  local all_results count
  all_results=$(jq -s 'add // []' "$tmpfile")
  count=$(echo "$all_results" | jq 'length')
  rm -f "$tmpfile"
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
# Outputs pretty-printed JSON if stdout is a terminal, raw otherwise.
# Skips jq re-parse when piped (API already returns valid JSON).
_json_output() {
  if [[ -t 1 ]]; then
    echo "$1" | jq '.'
  else
    echo "$1"
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
[[ -d "$LIB_CONFIG_DIR" ]] || mkdir -p "$LIB_CONFIG_DIR" 2>/dev/null
