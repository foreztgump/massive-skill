#!/usr/bin/env bash
# massive_news.sh — Fetch market news articles from Massive.com API

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_lib.sh"

show_help() {
  _usage "massive_news.sh" "Fetch market news articles" \
"  massive_news.sh [OPTIONS]

Options:
  --ticker SYMBOL            Filter by ticker symbol (e.g. AAPL)
  --published-utc.gte DATE   Published on or after date (YYYY-MM-DD)
  --published-utc.lte DATE   Published on or before date (YYYY-MM-DD)
  --order asc|desc           Sort order (default: desc)
  --limit N                  Number of results per page
  --sort FIELD               Sort field (e.g. published_utc)
  --help                     Show this help message"
}

if _has_flag "--help" "$@"; then
  show_help
fi

main() {
  local ticker published_gte published_lte order limit sort_field
  ticker=$(_parse_flag "--ticker" "$@")
  published_gte=$(_parse_flag "--published-utc.gte" "$@")
  published_lte=$(_parse_flag "--published-utc.lte" "$@")
  order=$(_parse_flag "--order" "$@")
  limit=$(_parse_flag "--limit" "$@")
  sort_field=$(_parse_flag "--sort" "$@")

  local url
  url=$(_build_url "/v2/reference/news" \
    "ticker=${ticker}" \
    "published_utc.gte=${published_gte}" \
    "published_utc.lte=${published_lte}" \
    "order=${order}" \
    "limit=${limit}" \
    "sort=${sort_field}")

  local body
  if ! body=$(paginate "$url"); then
    exit 1
  fi

  _json_output "$body"
}

main "$@"
