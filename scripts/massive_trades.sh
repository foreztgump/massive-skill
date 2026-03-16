#!/usr/bin/env bash
# scripts/massive_trades.sh — retrieve trade data from the Massive market data API

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_lib.sh"

show_help() {
  _usage "massive_trades.sh" "Retrieve trade data for a stock ticker" \
"  massive_trades.sh list <ticker> [options]
    List historical trades for a ticker.
    Options:
      --timestamp.gte YYYY-MM-DDThh:mm:ss   Start time (inclusive)
      --timestamp.lte YYYY-MM-DDThh:mm:ss   End time (inclusive)
      --order asc|desc                       Sort order (default: desc)
      --limit N                              Max results per page
      --sort timestamp                       Field to sort by

  massive_trades.sh last <ticker>
    Get the most recent trade for a ticker.

  massive_trades.sh help
    Show this help message."
}

cmd_list() {
  local ticker="$1"
  if [[ -z "$ticker" ]]; then
    echo '{"error":"ticker is required for list subcommand"}' >&2
    exit 1
  fi
  shift

  local ts_gte ts_lte order limit sort
  ts_gte=$(_parse_flag "--timestamp.gte" "$@")
  ts_lte=$(_parse_flag "--timestamp.lte" "$@")
  order=$(_parse_flag "--order" "$@")
  limit=$(_parse_flag "--limit" "$@")
  sort=$(_parse_flag "--sort" "$@")

  local url
  url=$(_build_url "/v3/trades/${ticker}" \
    "timestamp.gte=${ts_gte}" \
    "timestamp.lte=${ts_lte}" \
    "order=${order}" \
    "limit=${limit}" \
    "sort=${sort}")

  local body
  body=$(paginate "$url")
  local rc=$?

  _read_http_code

  if [[ $rc -ne 0 ]]; then
    exit 1
  fi

  _json_output "$body"
}

cmd_last() {
  local ticker="$1"
  if [[ -z "$ticker" ]]; then
    echo '{"error":"ticker is required for last subcommand"}' >&2
    exit 1
  fi

  local url
  url=$(_build_url "/v2/last/trade/${ticker}")

  local body
  body=$(make_api_request "$url")
  _read_http_code

  if ! check_http_status "$HTTP_CODE" "$body" "get last trade"; then
    exit 1
  fi

  _json_output "$body"
}

# --- main ---

subcommand="${1:-help}"
shift 2>/dev/null || true

case "$subcommand" in
  list)  cmd_list "$@" ;;
  last)  cmd_last "$@" ;;
  help|--help|-h) show_help ;;
  *)
    echo "{\"error\":\"unknown subcommand: ${subcommand}\"}" >&2
    show_help
    ;;
esac
