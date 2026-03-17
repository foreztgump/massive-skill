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
  local ticker="${1:-}" from="${2:-}" to="${3:-}"
  _require_arg "ticker" "$ticker" "bars"
  _require_arg "from" "$from" "bars"
  _require_arg "to" "$to" "bars"
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

  _fetch_and_output "bars" "$url"
}

cmd_daily() {
  local date="${1:-}"
  _require_arg "date" "$date" "daily"
  shift

  local adjusted
  adjusted=$(_parse_flag "--adjusted" "$@")

  local path="/v2/aggs/grouped/locale/us/market/stocks/${date}"
  local url
  url=$(_build_url "$path" "adjusted=${adjusted}")

  _fetch_and_output "daily" "$url"
}

cmd_open_close() {
  local ticker="${1:-}" date="${2:-}"
  _require_arg "ticker" "$ticker" "open-close"
  _require_arg "date" "$date" "open-close"
  shift 2

  local adjusted
  adjusted=$(_parse_flag "--adjusted" "$@")

  local path="/v1/open-close/${ticker}/${date}"
  local url
  url=$(_build_url "$path" "adjusted=${adjusted}")

  _fetch_and_output "open-close" "$url"
}

cmd_prev() {
  local ticker="${1:-}"
  _require_arg "ticker" "$ticker" "prev"
  shift

  local adjusted
  adjusted=$(_parse_flag "--adjusted" "$@")

  local path="/v2/aggs/ticker/${ticker}/prev"
  local url
  url=$(_build_url "$path" "adjusted=${adjusted}")

  _fetch_and_output "prev" "$url"
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

  _fetch_and_output "snapshot" "$url"
}

cmd_movers() {
  local direction="${1:-}"
  _require_arg "direction" "$direction" "movers"
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

  _fetch_and_output "movers" "$url"
}

cmd_universal() {
  local tickers="${1:-}"
  _require_arg "tickers" "$tickers" "universal"
  shift

  local snap_type
  snap_type=$(_parse_flag "--type" "$@")

  local params=("ticker.any_of=${tickers}")
  if [[ -n "$snap_type" ]]; then
    params+=("type=${snap_type}")
  fi

  local url
  url=$(_build_url "/v3/snapshot" "${params[@]}")

  _fetch_and_output "universal snapshot" "$url"
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
