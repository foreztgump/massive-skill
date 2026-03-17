#!/usr/bin/env bash
# scripts/massive_quotes.sh — retrieve quote (NBBO) data from the Massive market data API

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_lib.sh"

show_help() {
  _usage "massive_quotes.sh" "Retrieve quote (NBBO) data for a stock ticker" \
"  massive_quotes.sh list <ticker> [options]
    List historical quotes for a ticker.
    Options:
      --timestamp.gte YYYY-MM-DDThh:mm:ss   Start time (inclusive)
      --timestamp.lte YYYY-MM-DDThh:mm:ss   End time (inclusive)
      --order asc|desc                       Sort order (default: desc)
      --limit N                              Max results per page
      --sort timestamp                       Field to sort by

  massive_quotes.sh last <ticker>
    Get the most recent NBBO quote for a ticker.

  massive_quotes.sh help
    Show this help message."
}

cmd_list() {
  local ticker="$1"
  _require_arg "ticker" "$ticker" "list"
  shift

  local ts_gte ts_lte order limit sort
  ts_gte=$(_parse_flag "--timestamp.gte" "$@")
  ts_lte=$(_parse_flag "--timestamp.lte" "$@")
  order=$(_parse_flag "--order" "$@")
  limit=$(_parse_flag "--limit" "$@")
  sort=$(_parse_flag "--sort" "$@")

  local url
  url=$(_build_url "/v3/quotes/${ticker}" \
    "timestamp.gte=${ts_gte}" \
    "timestamp.lte=${ts_lte}" \
    "order=${order}" \
    "limit=${limit}" \
    "sort=${sort}")

  _paginate_and_output "$url"
}

cmd_last() {
  local ticker="$1"
  _require_arg "ticker" "$ticker" "last"

  local url
  url=$(_build_url "/v2/last/nbbo/${ticker}")

  _fetch_and_output "get last quote" "$url"
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
