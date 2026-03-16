#!/usr/bin/env bash
# scripts/massive_price.sh — Market data: aggregates, snapshots, and pricing

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_lib.sh"

show_help() {
  _usage "massive_price.sh" "Fetch price data (aggregates, snapshots, movers)" \
"  massive_price.sh bars <ticker> <from> <to> [options]
    --timespan   minute|hour|day|week|month|quarter|year (default: day)
    --multiplier N (default: 1)
    --adjusted   true|false
    --sort       asc|desc
    --limit      N

  massive_price.sh daily <date> [options]
    --adjusted   true|false

  massive_price.sh open-close <ticker> <date> [options]
    --adjusted   true|false

  massive_price.sh prev <ticker> [options]
    --adjusted   true|false

  massive_price.sh snapshot [ticker] [options]
    --tickers    Comma-separated list (e.g. AAPL,TSLA)
    --include-otc

  massive_price.sh movers <gainers|losers> [options]
    --include-otc

  massive_price.sh universal <tickers> [options]
    --type       stocks|options|forex|crypto"
}

cmd_bars() {
  if [[ $# -lt 3 ]]; then
    echo '{"error":"bars requires: <ticker> <from> <to>"}' >&2
    exit 1
  fi

  local ticker="$1" from="$2" to="$3"
  shift 3

  local timespan multiplier adjusted sort_order limit
  timespan=$(_parse_flag "--timespan" "$@")
  multiplier=$(_parse_flag "--multiplier" "$@")
  adjusted=$(_parse_flag "--adjusted" "$@")
  sort_order=$(_parse_flag "--sort" "$@")
  limit=$(_parse_flag "--limit" "$@")

  timespan="${timespan:-day}"
  multiplier="${multiplier:-1}"

  local path="/v2/aggs/ticker/${ticker}/range/${multiplier}/${timespan}/${from}/${to}"
  local url
  url=$(_build_url "$path" \
    "adjusted=${adjusted}" \
    "sort=${sort_order}" \
    "limit=${limit}")

  local body
  body=$(make_api_request "$url")
  _read_http_code
  check_http_status "$HTTP_CODE" "$body" "bars" || exit 1
  _json_output "$body"
}

cmd_daily() {
  if [[ $# -lt 1 ]]; then
    echo '{"error":"daily requires: <date>"}' >&2
    exit 1
  fi

  local date="$1"
  shift

  local adjusted
  adjusted=$(_parse_flag "--adjusted" "$@")

  local path="/v2/aggs/grouped/locale/us/market/stocks/${date}"
  local url
  url=$(_build_url "$path" "adjusted=${adjusted}")

  local body
  body=$(make_api_request "$url")
  _read_http_code
  check_http_status "$HTTP_CODE" "$body" "daily" || exit 1
  _json_output "$body"
}

cmd_open_close() {
  if [[ $# -lt 2 ]]; then
    echo '{"error":"open-close requires: <ticker> <date>"}' >&2
    exit 1
  fi

  local ticker="$1" date="$2"
  shift 2

  local adjusted
  adjusted=$(_parse_flag "--adjusted" "$@")

  local path="/v1/open-close/${ticker}/${date}"
  local url
  url=$(_build_url "$path" "adjusted=${adjusted}")

  local body
  body=$(make_api_request "$url")
  _read_http_code
  check_http_status "$HTTP_CODE" "$body" "open-close" || exit 1
  _json_output "$body"
}

cmd_prev() {
  if [[ $# -lt 1 ]]; then
    echo '{"error":"prev requires: <ticker>"}' >&2
    exit 1
  fi

  local ticker="$1"
  shift

  local adjusted
  adjusted=$(_parse_flag "--adjusted" "$@")

  local path="/v2/aggs/ticker/${ticker}/prev"
  local url
  url=$(_build_url "$path" "adjusted=${adjusted}")

  local body
  body=$(make_api_request "$url")
  _read_http_code
  check_http_status "$HTTP_CODE" "$body" "prev" || exit 1
  _json_output "$body"
}

cmd_snapshot() {
  local ticker=""
  # First positional arg is a ticker if it doesn't start with --
  if [[ $# -gt 0 && "$1" != --* ]]; then
    ticker="$1"
    shift
  fi

  local tickers_param
  tickers_param=$(_parse_flag "--tickers" "$@")

  local params=()
  if [[ -n "$tickers_param" ]]; then
    params+=("tickers=${tickers_param}")
  fi
  if _has_flag "--include-otc" "$@"; then
    params+=("include_otc=true")
  fi

  local path
  if [[ -n "$ticker" ]]; then
    path="/v2/snapshot/locale/us/markets/stocks/tickers/${ticker}"
  else
    path="/v2/snapshot/locale/us/markets/stocks/tickers"
  fi

  local url
  url=$(_build_url "$path" "${params[@]}")

  local body
  body=$(make_api_request "$url")
  _read_http_code
  check_http_status "$HTTP_CODE" "$body" "snapshot" || exit 1
  _json_output "$body"
}

cmd_movers() {
  if [[ $# -lt 1 ]]; then
    echo '{"error":"movers requires: <gainers|losers>"}' >&2
    exit 1
  fi

  local direction="$1"
  shift

  if [[ "$direction" != "gainers" && "$direction" != "losers" ]]; then
    echo '{"error":"movers direction must be gainers or losers"}' >&2
    exit 1
  fi

  local params=()
  if _has_flag "--include-otc" "$@"; then
    params+=("include_otc=true")
  fi

  local path="/v2/snapshot/locale/us/markets/stocks/${direction}"
  local url
  url=$(_build_url "$path" "${params[@]}")

  local body
  body=$(make_api_request "$url")
  _read_http_code
  check_http_status "$HTTP_CODE" "$body" "movers" || exit 1
  _json_output "$body"
}

cmd_universal() {
  if [[ $# -lt 1 ]]; then
    echo '{"error":"universal requires: <tickers>"}' >&2
    exit 1
  fi

  local tickers="$1"
  shift

  local snap_type
  snap_type=$(_parse_flag "--type" "$@")

  local params=("ticker.any_of=${tickers}")
  if [[ -n "$snap_type" ]]; then
    params+=("type=${snap_type}")
  fi

  local url
  url=$(_build_url "/v3/snapshot" "${params[@]}")

  local body
  body=$(make_api_request "$url")
  _read_http_code
  check_http_status "$HTTP_CODE" "$body" "universal snapshot" || exit 1
  _json_output "$body"
}

# --- Main dispatch ---
if [[ $# -lt 1 ]]; then
  show_help
fi

subcommand="$1"
shift

case "$subcommand" in
  bars)       cmd_bars "$@" ;;
  daily)      cmd_daily "$@" ;;
  open-close) cmd_open_close "$@" ;;
  prev)       cmd_prev "$@" ;;
  snapshot)   cmd_snapshot "$@" ;;
  movers)     cmd_movers "$@" ;;
  universal)  cmd_universal "$@" ;;
  -h|--help|help) show_help ;;
  *)
    echo "{\"error\":\"unknown subcommand: ${subcommand}\"}" >&2
    show_help
    ;;
esac
