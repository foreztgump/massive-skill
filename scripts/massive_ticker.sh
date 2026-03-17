#!/usr/bin/env bash
# scripts/massive_ticker.sh — Ticker reference data: list, details, types, related

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_lib.sh"

show_help() {
  _usage "massive_ticker.sh" "Fetch ticker reference data" \
"  massive_ticker.sh list [options]
    --search     Search term
    --type       stock|etf|...
    --market     stocks|crypto|fx|otc
    --exchange   Exchange code (e.g. XNYS)
    --active     true|false
    --sort       ticker|name|market|locale|primary_exchange|type|currency_symbol|...
    --order      asc|desc
    --limit      N

  massive_ticker.sh details <ticker>

  massive_ticker.sh types [options]
    --asset-class  stocks|options|crypto|fx
    --locale       us|global

  massive_ticker.sh related <ticker>"
}

cmd_list() {
  local search type_val market exchange active sort_val order limit
  search=$(_parse_flag "--search" "$@")
  type_val=$(_parse_flag "--type" "$@")
  market=$(_parse_flag "--market" "$@")
  exchange=$(_parse_flag "--exchange" "$@")
  active=$(_parse_flag "--active" "$@")
  sort_val=$(_parse_flag "--sort" "$@")
  order=$(_parse_flag "--order" "$@")
  limit=$(_parse_flag "--limit" "$@")

  local url
  url=$(_build_url "/v3/reference/tickers" \
    "search=${search}" \
    "type=${type_val}" \
    "market=${market}" \
    "exchange=${exchange}" \
    "active=${active}" \
    "sort=${sort_val}" \
    "order=${order}" \
    "limit=${limit}")

  _paginate_and_output "$url"
}

cmd_details() {
  local ticker="${1:-}"
  _require_arg "ticker" "$ticker" "details"

  local url
  url=$(_build_url "/v3/reference/tickers/${ticker}")

  _fetch_and_output "ticker details" "$url"
}

cmd_types() {
  local asset_class locale_val
  asset_class=$(_parse_flag "--asset-class" "$@")
  locale_val=$(_parse_flag "--locale" "$@")

  local url
  url=$(_build_url "/v3/reference/tickers/types" \
    "asset_class=${asset_class}" \
    "locale=${locale_val}")

  _fetch_and_output "ticker types" "$url"
}

cmd_related() {
  local ticker="${1:-}"
  _require_arg "ticker" "$ticker" "related"

  local url
  url=$(_build_url "/v1/related-companies/${ticker}")

  _fetch_and_output "related companies" "$url"
}

# --- Main dispatch ---
if [[ $# -lt 1 ]]; then
  show_help
fi

subcommand="$1"
shift

case "$subcommand" in
  list)    cmd_list "$@" ;;
  details) cmd_details "$@" ;;
  types)   cmd_types "$@" ;;
  related) cmd_related "$@" ;;
  -h|--help|help) show_help ;;
  *)
    echo "{\"error\":\"unknown subcommand: ${subcommand}\"}" >&2
    show_help
    ;;
esac
