#!/usr/bin/env bash
# massive_fundamentals.sh — Fetch company fundamentals from Massive.com API

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_lib.sh"

show_help() {
  _usage "massive_fundamentals.sh" "Fetch company fundamentals data" \
"  massive_fundamentals.sh <subcommand> [OPTIONS]

Subcommands:
  financials <TICKER>      [--timeframe annual|quarterly|ttm] [--limit N]
                           [--order asc|desc] [--filing-date.gte DATE]
                           [--filing-date.lte DATE]
                           Returns balance sheet, income statement, cash flow,
                           and comprehensive income in one call.
  dividends                [--ticker SYMBOL] [--ex-dividend-date.gte DATE]
                           [--ex-dividend-date.lte DATE] [--frequency 1|2|4|12]
                           [--order asc|desc] [--limit N]
  splits                   [--ticker SYMBOL] [--execution-date.gte DATE]
                           [--execution-date.lte DATE] [--order asc|desc]
                           [--limit N]
  ipos                     [--ticker SYMBOL] [--listing-date.gte DATE]
                           [--listing-date.lte DATE] [--order asc|desc]
                           [--limit N]
  short-interest <TICKER>  [--order asc|desc] [--limit N]
  short-volume <TICKER>    [--order asc|desc] [--limit N]

Options:
  --help                   Show this help message"
}

if _has_flag "--help" "$@" || [[ $# -eq 0 ]]; then
  show_help
fi

subcommand="$1"
shift

# --- Helpers for common flag groups ---

# Fetch financials (balance sheet, income statement, cash flow, comprehensive income)
# Uses the /vX/reference/financials endpoint which returns all statement types.
cmd_financials() {
  local ticker="${1:-}"
  [[ "$ticker" == --* ]] && ticker=""
  _require_arg "ticker" "$ticker" "financials"
  shift

  local timeframe limit order filing_gte filing_lte
  timeframe=$(_parse_flag "--timeframe" "$@")
  limit=$(_parse_flag "--limit" "$@")
  order=$(_parse_flag "--order" "$@")
  filing_gte=$(_parse_flag "--filing-date.gte" "$@")
  filing_lte=$(_parse_flag "--filing-date.lte" "$@")

  local url
  url=$(_build_url "/vX/reference/financials" \
    "ticker=${ticker}" \
    "timeframe=${timeframe}" \
    "limit=${limit}" \
    "order=${order}" \
    "filing_date.gte=${filing_gte}" \
    "filing_date.lte=${filing_lte}")

  _paginate_and_output "$url"
}

# Fetch a ticker-required simple endpoint (short-interest, short-volume)
fetch_ticker_required() {
  local endpoint="$1"
  local action="$2"
  shift 2

  local ticker="${1:-}"
  [[ "$ticker" == --* ]] && ticker=""
  _require_arg "ticker" "$ticker" "$action"
  shift

  local limit order
  limit=$(_parse_flag "--limit" "$@")
  order=$(_parse_flag "--order" "$@")

  local url
  url=$(_build_url "$endpoint" \
    "ticker=${ticker}" \
    "limit=${limit}" \
    "order=${order}")

  _fetch_and_output "$action" "$url"
}

cmd_dividends() {
  local ticker ex_div_gte ex_div_lte frequency order limit
  ticker=$(_parse_flag "--ticker" "$@")
  ex_div_gte=$(_parse_flag "--ex-dividend-date.gte" "$@")
  ex_div_lte=$(_parse_flag "--ex-dividend-date.lte" "$@")
  frequency=$(_parse_flag "--frequency" "$@")
  order=$(_parse_flag "--order" "$@")
  limit=$(_parse_flag "--limit" "$@")

  local url
  url=$(_build_url "/stocks/v1/dividends" \
    "ticker=${ticker}" \
    "ex_dividend_date.gte=${ex_div_gte}" \
    "ex_dividend_date.lte=${ex_div_lte}" \
    "frequency=${frequency}" \
    "order=${order}" \
    "limit=${limit}")

  _paginate_and_output "$url"
}

cmd_splits() {
  local ticker exec_gte exec_lte order limit
  ticker=$(_parse_flag "--ticker" "$@")
  exec_gte=$(_parse_flag "--execution-date.gte" "$@")
  exec_lte=$(_parse_flag "--execution-date.lte" "$@")
  order=$(_parse_flag "--order" "$@")
  limit=$(_parse_flag "--limit" "$@")

  local url
  url=$(_build_url "/stocks/v1/splits" \
    "ticker=${ticker}" \
    "execution_date.gte=${exec_gte}" \
    "execution_date.lte=${exec_lte}" \
    "order=${order}" \
    "limit=${limit}")

  _paginate_and_output "$url"
}

cmd_ipos() {
  local ticker listing_gte listing_lte order limit
  ticker=$(_parse_flag "--ticker" "$@")
  listing_gte=$(_parse_flag "--listing-date.gte" "$@")
  listing_lte=$(_parse_flag "--listing-date.lte" "$@")
  order=$(_parse_flag "--order" "$@")
  limit=$(_parse_flag "--limit" "$@")

  local url
  url=$(_build_url "/vX/reference/ipos" \
    "ticker=${ticker}" \
    "listing_date.gte=${listing_gte}" \
    "listing_date.lte=${listing_lte}" \
    "order=${order}" \
    "limit=${limit}")

  _paginate_and_output "$url"
}

cmd_short_interest() {
  fetch_ticker_required "/stocks/v1/short-interest" "short-interest" "$@"
}

cmd_short_volume() {
  fetch_ticker_required "/stocks/v1/short-volume" "short-volume" "$@"
}

case "$subcommand" in
  financials)
    cmd_financials "$@"
    ;;
  dividends)
    cmd_dividends "$@"
    ;;
  splits)
    cmd_splits "$@"
    ;;
  ipos)
    cmd_ipos "$@"
    ;;
  short-interest)
    cmd_short_interest "$@"
    ;;
  short-volume)
    cmd_short_volume "$@"
    ;;
  *)
    echo "{\"error\":\"unknown subcommand: ${subcommand}\"}" >&2
    show_help
    ;;
esac
