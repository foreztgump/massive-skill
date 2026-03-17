#!/usr/bin/env bash
# scripts/massive_options.sh — Options market data: contracts, chains, snapshots, bars, trades, quotes

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_lib.sh"

show_help() {
  _usage "massive_options.sh" "Fetch options market data" \
"  massive_options.sh contracts [options]
    --underlying-ticker   Underlying ticker (e.g. AAPL)
    --contract-type       call|put
    --expiration-date.gte YYYY-MM-DD
    --expiration-date.lte YYYY-MM-DD
    --strike-price.gte    N
    --strike-price.lte    N
    --expired             true|false
    --order               asc|desc
    --limit               N
    --sort                expiration_date|strike_price|ticker

  massive_options.sh contract <options_ticker>

  massive_options.sh chain <underlying_ticker> [options]
    --strike-price      N
    --expiration-date   YYYY-MM-DD
    --contract-type     call|put
    --order             asc|desc
    --limit             N

  massive_options.sh snapshot <underlying_ticker> <option_contract>

  massive_options.sh bars <options_ticker> <from> <to> [options]
    --timespan    minute|hour|day|week|month|quarter|year (default: day)
    --multiplier  N (default: 1)
    --adjusted    true|false
    --sort        asc|desc
    --limit       N

  massive_options.sh prev <options_ticker> [options]
    --adjusted    true|false

  massive_options.sh trades <options_ticker> [options]
    --timestamp.gte   Timestamp
    --timestamp.lte   Timestamp
    --order           asc|desc
    --limit           N

  massive_options.sh quotes <options_ticker> [options]
    --timestamp.gte   Timestamp
    --timestamp.lte   Timestamp
    --order           asc|desc
    --limit           N

  massive_options.sh last-trade <options_ticker>"
}

cmd_contracts() {
  local underlying_ticker contract_type exp_gte exp_lte strike_gte strike_lte expired order limit sort_val
  underlying_ticker=$(_parse_flag "--underlying-ticker" "$@")
  contract_type=$(_parse_flag "--contract-type" "$@")
  exp_gte=$(_parse_flag "--expiration-date.gte" "$@")
  exp_lte=$(_parse_flag "--expiration-date.lte" "$@")
  strike_gte=$(_parse_flag "--strike-price.gte" "$@")
  strike_lte=$(_parse_flag "--strike-price.lte" "$@")
  expired=$(_parse_flag "--expired" "$@")
  order=$(_parse_flag "--order" "$@")
  limit=$(_parse_flag "--limit" "$@")
  sort_val=$(_parse_flag "--sort" "$@")

  local url
  url=$(_build_url "/v3/reference/options/contracts" \
    "underlying_ticker=${underlying_ticker}" \
    "contract_type=${contract_type}" \
    "expiration_date.gte=${exp_gte}" \
    "expiration_date.lte=${exp_lte}" \
    "strike_price.gte=${strike_gte}" \
    "strike_price.lte=${strike_lte}" \
    "expired=${expired}" \
    "order=${order}" \
    "limit=${limit}" \
    "sort=${sort_val}")

  _paginate_and_output "$url"
}

cmd_contract() {
  _require_arg "options_ticker" "${1:-}" "contract"

  local options_ticker="$1"
  shift

  local url
  url=$(_build_url "/v3/reference/options/contracts/${options_ticker}")

  _fetch_and_output "contract" "$url"
}

cmd_chain() {
  _require_arg "underlying_ticker" "${1:-}" "chain"

  local underlying_ticker="$1"
  shift

  local strike_price expiration_date contract_type order limit
  strike_price=$(_parse_flag "--strike-price" "$@")
  expiration_date=$(_parse_flag "--expiration-date" "$@")
  contract_type=$(_parse_flag "--contract-type" "$@")
  order=$(_parse_flag "--order" "$@")
  limit=$(_parse_flag "--limit" "$@")

  local url
  url=$(_build_url "/v3/snapshot/options/${underlying_ticker}" \
    "strike_price=${strike_price}" \
    "expiration_date=${expiration_date}" \
    "contract_type=${contract_type}" \
    "order=${order}" \
    "limit=${limit}")

  _paginate_and_output "$url"
}

cmd_snapshot() {
  _require_arg "underlying_ticker" "${1:-}" "snapshot"
  _require_arg "option_contract" "${2:-}" "snapshot"

  local underlying_ticker="$1" option_contract="$2"
  shift 2

  local url
  url=$(_build_url "/v3/snapshot/options/${underlying_ticker}/${option_contract}")

  _fetch_and_output "snapshot" "$url"
}

cmd_bars() {
  _require_arg "options_ticker" "${1:-}" "bars"
  _require_arg "from" "${2:-}" "bars"
  _require_arg "to" "${3:-}" "bars"

  local options_ticker="$1" from="$2" to="$3"
  shift 3

  local timespan multiplier adjusted sort_order limit
  timespan=$(_parse_flag "--timespan" "$@")
  multiplier=$(_parse_flag "--multiplier" "$@")
  adjusted=$(_parse_flag "--adjusted" "$@")
  sort_order=$(_parse_flag "--sort" "$@")
  limit=$(_parse_flag "--limit" "$@")

  timespan="${timespan:-day}"
  multiplier="${multiplier:-1}"

  local path="/v2/aggs/ticker/${options_ticker}/range/${multiplier}/${timespan}/${from}/${to}"
  local url
  url=$(_build_url "$path" \
    "adjusted=${adjusted}" \
    "sort=${sort_order}" \
    "limit=${limit}")

  _fetch_and_output "bars" "$url"
}

cmd_prev() {
  _require_arg "options_ticker" "${1:-}" "prev"

  local options_ticker="$1"
  shift

  local adjusted
  adjusted=$(_parse_flag "--adjusted" "$@")

  local url
  url=$(_build_url "/v2/aggs/ticker/${options_ticker}/prev" \
    "adjusted=${adjusted}")

  _fetch_and_output "prev" "$url"
}

cmd_trades() {
  _require_arg "options_ticker" "${1:-}" "trades"

  local options_ticker="$1"
  shift

  local ts_gte ts_lte order limit sort
  ts_gte=$(_parse_flag "--timestamp.gte" "$@")
  ts_lte=$(_parse_flag "--timestamp.lte" "$@")
  order=$(_parse_flag "--order" "$@")
  limit=$(_parse_flag "--limit" "$@")
  sort=$(_parse_flag "--sort" "$@")

  local url
  url=$(_build_url "/v3/trades/${options_ticker}" \
    "timestamp.gte=${ts_gte}" \
    "timestamp.lte=${ts_lte}" \
    "order=${order}" \
    "limit=${limit}" \
    "sort=${sort}")

  _paginate_and_output "$url"
}

cmd_quotes() {
  _require_arg "options_ticker" "${1:-}" "quotes"

  local options_ticker="$1"
  shift

  local ts_gte ts_lte order limit sort
  ts_gte=$(_parse_flag "--timestamp.gte" "$@")
  ts_lte=$(_parse_flag "--timestamp.lte" "$@")
  order=$(_parse_flag "--order" "$@")
  limit=$(_parse_flag "--limit" "$@")
  sort=$(_parse_flag "--sort" "$@")

  local url
  url=$(_build_url "/v3/quotes/${options_ticker}" \
    "timestamp.gte=${ts_gte}" \
    "timestamp.lte=${ts_lte}" \
    "order=${order}" \
    "limit=${limit}" \
    "sort=${sort}")

  _paginate_and_output "$url"
}

cmd_last_trade() {
  _require_arg "options_ticker" "${1:-}" "last-trade"

  local options_ticker="$1"
  shift

  local url
  url=$(_build_url "/v2/last/trade/${options_ticker}")

  _fetch_and_output "last-trade" "$url"
}

# --- Main dispatch ---
if [[ $# -lt 1 ]]; then
  show_help
fi

subcommand="$1"
shift

case "$subcommand" in
  contracts)  cmd_contracts "$@" ;;
  contract)   cmd_contract "$@" ;;
  chain)      cmd_chain "$@" ;;
  snapshot)   cmd_snapshot "$@" ;;
  bars)       cmd_bars "$@" ;;
  prev)       cmd_prev "$@" ;;
  trades)     cmd_trades "$@" ;;
  quotes)     cmd_quotes "$@" ;;
  last-trade) cmd_last_trade "$@" ;;
  -h|--help|help) show_help ;;
  *)
    echo "{\"error\":\"unknown subcommand: ${subcommand}\"}" >&2
    show_help
    ;;
esac
