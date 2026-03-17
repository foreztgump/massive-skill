#!/usr/bin/env bash
# scripts/massive_futures.sh — Futures market data: contracts, products, schedules, snapshots, bars, trades, quotes

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_lib.sh"

show_help() {
  _usage "massive_futures.sh" "Fetch futures market data" \
"  massive_futures.sh contracts [options]
    --product-code        Product code (e.g. GC)
    --expiration-date.gte YYYY-MM-DD
    --expiration-date.lte YYYY-MM-DD
    --order               asc|desc
    --limit               N

  massive_futures.sh products [options]
    --asset-class   commodity|financial|index
    --exchange      CME|CBOT|COMEX|NYMEX
    --search        Search term
    --order         asc|desc
    --limit         N

  massive_futures.sh schedules [options]
    --product-code  Product code (e.g. GC)
    --exchange      CME|CBOT|COMEX|NYMEX

  massive_futures.sh snapshot [options]
    --ticker        Futures ticker (e.g. GCJ5)
    --product-code  Product code (e.g. GC)
    --order         asc|desc
    --limit         N

  massive_futures.sh bars <ticker> <from> <to> [options]
    --timespan    minute|hour|day|week|month|quarter|year (default: day)
    --multiplier  N (default: 1)
    --adjusted    true|false
    --sort        asc|desc
    --limit       N

  massive_futures.sh trades <ticker> [options]
    --timestamp.gte   Timestamp
    --timestamp.lte   Timestamp
    --order           asc|desc
    --limit           N

  massive_futures.sh quotes <ticker> [options]
    --timestamp.gte   Timestamp
    --timestamp.lte   Timestamp
    --order           asc|desc
    --limit           N"
}

cmd_contracts() {
  local product_code exp_gte exp_lte order limit
  product_code=$(_parse_flag "--product-code" "$@")
  exp_gte=$(_parse_flag "--expiration-date.gte" "$@")
  exp_lte=$(_parse_flag "--expiration-date.lte" "$@")
  order=$(_parse_flag "--order" "$@")
  limit=$(_parse_flag "--limit" "$@")

  local url
  url=$(_build_url "/futures/vX/contracts" \
    "product_code=${product_code}" \
    "expiration_date.gte=${exp_gte}" \
    "expiration_date.lte=${exp_lte}" \
    "order=${order}" \
    "limit=${limit}")

  _paginate_and_output "$url"
}

cmd_products() {
  local asset_class exchange search order limit
  asset_class=$(_parse_flag "--asset-class" "$@")
  exchange=$(_parse_flag "--exchange" "$@")
  search=$(_parse_flag "--search" "$@")
  order=$(_parse_flag "--order" "$@")
  limit=$(_parse_flag "--limit" "$@")

  local url
  url=$(_build_url "/futures/vX/products" \
    "asset_class=${asset_class}" \
    "exchange=${exchange}" \
    "search=${search}" \
    "order=${order}" \
    "limit=${limit}")

  _paginate_and_output "$url"
}

cmd_schedules() {
  local product_code exchange
  product_code=$(_parse_flag "--product-code" "$@")
  exchange=$(_parse_flag "--exchange" "$@")

  local url
  url=$(_build_url "/futures/vX/schedules" \
    "product_code=${product_code}" \
    "exchange=${exchange}")

  _fetch_and_output "schedules" "$url"
}

cmd_snapshot() {
  local ticker product_code order limit
  ticker=$(_parse_flag "--ticker" "$@")
  product_code=$(_parse_flag "--product-code" "$@")
  order=$(_parse_flag "--order" "$@")
  limit=$(_parse_flag "--limit" "$@")

  local url
  url=$(_build_url "/futures/vX/snapshot" \
    "ticker=${ticker}" \
    "product_code=${product_code}" \
    "order=${order}" \
    "limit=${limit}")

  _paginate_and_output "$url"
}

cmd_bars() {
  _require_arg "ticker" "${1:-}" "bars"
  _require_arg "from" "${2:-}" "bars"
  _require_arg "to" "${3:-}" "bars"

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

  local url
  url=$(_build_url "/futures/vX/aggs/${ticker}" \
    "from=${from}" \
    "to=${to}" \
    "timespan=${timespan}" \
    "multiplier=${multiplier}" \
    "adjusted=${adjusted}" \
    "sort=${sort_order}" \
    "limit=${limit}")

  _fetch_and_output "bars" "$url"
}

cmd_trades() {
  _require_arg "ticker" "${1:-}" "trades"

  local ticker="$1"
  shift

  local ts_gte ts_lte order limit sort
  ts_gte=$(_parse_flag "--timestamp.gte" "$@")
  ts_lte=$(_parse_flag "--timestamp.lte" "$@")
  order=$(_parse_flag "--order" "$@")
  limit=$(_parse_flag "--limit" "$@")
  sort=$(_parse_flag "--sort" "$@")

  local url
  url=$(_build_url "/futures/vX/trades/${ticker}" \
    "timestamp.gte=${ts_gte}" \
    "timestamp.lte=${ts_lte}" \
    "order=${order}" \
    "limit=${limit}" \
    "sort=${sort}")

  _paginate_and_output "$url"
}

cmd_quotes() {
  _require_arg "ticker" "${1:-}" "quotes"

  local ticker="$1"
  shift

  local ts_gte ts_lte order limit sort
  ts_gte=$(_parse_flag "--timestamp.gte" "$@")
  ts_lte=$(_parse_flag "--timestamp.lte" "$@")
  order=$(_parse_flag "--order" "$@")
  limit=$(_parse_flag "--limit" "$@")
  sort=$(_parse_flag "--sort" "$@")

  local url
  url=$(_build_url "/futures/vX/quotes/${ticker}" \
    "timestamp.gte=${ts_gte}" \
    "timestamp.lte=${ts_lte}" \
    "order=${order}" \
    "limit=${limit}" \
    "sort=${sort}")

  _paginate_and_output "$url"
}

# --- Main dispatch ---
if [[ $# -lt 1 ]]; then
  show_help
fi

subcommand="$1"
shift

case "$subcommand" in
  contracts) cmd_contracts "$@" ;;
  products)  cmd_products "$@" ;;
  schedules) cmd_schedules "$@" ;;
  snapshot)  cmd_snapshot "$@" ;;
  bars)      cmd_bars "$@" ;;
  trades)    cmd_trades "$@" ;;
  quotes)    cmd_quotes "$@" ;;
  -h|--help|help) show_help ;;
  *)
    echo "{\"error\":\"unknown subcommand: ${subcommand}\"}" >&2
    show_help
    ;;
esac
