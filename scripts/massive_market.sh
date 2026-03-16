#!/usr/bin/env bash
# scripts/massive_market.sh — retrieve market status and reference data from the Massive market data API

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_lib.sh"

show_help() {
  _usage "massive_market.sh" "Retrieve market status and reference data" \
"  massive_market.sh status
    Get current market status (open/closed for each exchange).

  massive_market.sh holidays
    Get upcoming market holidays.

  massive_market.sh exchanges [options]
    List exchanges.
    Options:
      --asset-class stocks|options|crypto|fx   Filter by asset class
      --locale us|global                       Filter by locale

  massive_market.sh conditions [options]
    List trade conditions.
    Options:
      --asset-class stocks|options|crypto|fx   Filter by asset class
      --data-type trade|bbo|nbbo              Filter by data type

  massive_market.sh help
    Show this help message."
}

cmd_status() {
  local url
  url=$(_build_url "/v1/marketstatus/now")

  local body
  body=$(make_api_request "$url")
  _read_http_code

  if ! check_http_status "$HTTP_CODE" "$body" "get market status"; then
    _json_output "$body"
    exit 1
  fi

  _json_output "$body"
}

cmd_holidays() {
  local url
  url=$(_build_url "/v1/marketstatus/upcoming")

  local body
  body=$(make_api_request "$url")
  _read_http_code

  if ! check_http_status "$HTTP_CODE" "$body" "get market holidays"; then
    _json_output "$body"
    exit 1
  fi

  _json_output "$body"
}

cmd_exchanges() {
  local asset_class locale
  asset_class=$(_parse_flag "--asset-class" "$@")
  locale=$(_parse_flag "--locale" "$@")

  local url
  url=$(_build_url "/v3/reference/exchanges" \
    "asset_class=${asset_class}" \
    "locale=${locale}")

  local body
  body=$(make_api_request "$url")
  _read_http_code

  if ! check_http_status "$HTTP_CODE" "$body" "get exchanges"; then
    _json_output "$body"
    exit 1
  fi

  _json_output "$body"
}

cmd_conditions() {
  local asset_class data_type
  asset_class=$(_parse_flag "--asset-class" "$@")
  data_type=$(_parse_flag "--data-type" "$@")

  local url
  url=$(_build_url "/v3/reference/conditions" \
    "asset_class=${asset_class}" \
    "data_type=${data_type}")

  local body
  body=$(make_api_request "$url")
  _read_http_code

  if ! check_http_status "$HTTP_CODE" "$body" "get conditions"; then
    _json_output "$body"
    exit 1
  fi

  _json_output "$body"
}

# --- main ---

subcommand="${1:-help}"
shift 2>/dev/null || true

case "$subcommand" in
  status)     cmd_status "$@" ;;
  holidays)   cmd_holidays "$@" ;;
  exchanges)  cmd_exchanges "$@" ;;
  conditions) cmd_conditions "$@" ;;
  help|--help|-h) show_help ;;
  *)
    echo "{\"error\":\"unknown subcommand: ${subcommand}\"}" >&2
    show_help
    ;;
esac
