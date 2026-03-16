#!/usr/bin/env bash
# massive_news.sh — Fetch market news articles from Massive.com API

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_lib.sh"

usage() {
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
  usage
fi

ticker=$(_parse_flag "--ticker" "$@")
published_gte=$(_parse_flag "--published-utc.gte" "$@")
published_lte=$(_parse_flag "--published-utc.lte" "$@")
order=$(_parse_flag "--order" "$@")
limit=$(_parse_flag "--limit" "$@")
sort=$(_parse_flag "--sort" "$@")

url=$(_build_url "/v2/reference/news" \
  "ticker=${ticker}" \
  "published_utc.gte=${published_gte}" \
  "published_utc.lte=${published_lte}" \
  "order=${order}" \
  "limit=${limit}" \
  "sort=${sort}")

body=$(paginate "$url")
# shellcheck disable=SC2181
if [[ $? -ne 0 ]]; then
  exit 1
fi

_json_output "$body"
