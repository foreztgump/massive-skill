#!/usr/bin/env bash
# scripts/massive_technicals.sh — retrieve technical indicators from the Massive market data API

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_lib.sh"

show_help() {
  _usage "massive_technicals.sh" "Retrieve technical indicators for a stock ticker" \
"  massive_technicals.sh sma <ticker> [options]
    Simple Moving Average for a ticker.

  massive_technicals.sh ema <ticker> [options]
    Exponential Moving Average for a ticker.

  massive_technicals.sh rsi <ticker> [options]
    Relative Strength Index for a ticker.

    Options (sma, ema, rsi):
      --timestamp.gte YYYY-MM-DD           Start date (inclusive)
      --timestamp.lte YYYY-MM-DD           End date (inclusive)
      --timespan day|week|month|quarter|year  Aggregation window
      --window N                           Window size
      --series-type close|open|high|low    Price series to use
      --order asc|desc                     Sort order
      --limit N                            Max results per page

  massive_technicals.sh macd <ticker> [options]
    Moving Average Convergence/Divergence for a ticker.

    Options (macd):
      --timestamp.gte YYYY-MM-DD           Start date (inclusive)
      --timestamp.lte YYYY-MM-DD           End date (inclusive)
      --timespan day|week|month|quarter|year  Aggregation window
      --short-window N                     Short window size
      --long-window N                      Long window size
      --signal-window N                    Signal window size
      --series-type close|open|high|low    Price series to use
      --order asc|desc                     Sort order
      --limit N                            Max results per page

  massive_technicals.sh help
    Show this help message."
}

cmd_sma() {
  local ticker="$1"
  if [[ -z "$ticker" ]]; then
    echo '{"error":"ticker is required for sma subcommand"}' >&2
    exit 1
  fi
  shift

  local ts_gte ts_lte timespan window series_type order limit
  ts_gte=$(_parse_flag "--timestamp.gte" "$@")
  ts_lte=$(_parse_flag "--timestamp.lte" "$@")
  timespan=$(_parse_flag "--timespan" "$@")
  window=$(_parse_flag "--window" "$@")
  series_type=$(_parse_flag "--series-type" "$@")
  order=$(_parse_flag "--order" "$@")
  limit=$(_parse_flag "--limit" "$@")

  local url
  url=$(_build_url "/v1/indicators/sma/${ticker}" \
    "timestamp.gte=${ts_gte}" \
    "timestamp.lte=${ts_lte}" \
    "timespan=${timespan}" \
    "window=${window}" \
    "series_type=${series_type}" \
    "order=${order}" \
    "limit=${limit}" \
    "adjusted=true")

  local body
  body=$(paginate "$url")
  local rc=$?

  _read_http_code

  if [[ $rc -ne 0 ]]; then
    _json_output "$body"
    exit 1
  fi

  _json_output "$body"
}

cmd_ema() {
  local ticker="$1"
  if [[ -z "$ticker" ]]; then
    echo '{"error":"ticker is required for ema subcommand"}' >&2
    exit 1
  fi
  shift

  local ts_gte ts_lte timespan window series_type order limit
  ts_gte=$(_parse_flag "--timestamp.gte" "$@")
  ts_lte=$(_parse_flag "--timestamp.lte" "$@")
  timespan=$(_parse_flag "--timespan" "$@")
  window=$(_parse_flag "--window" "$@")
  series_type=$(_parse_flag "--series-type" "$@")
  order=$(_parse_flag "--order" "$@")
  limit=$(_parse_flag "--limit" "$@")

  local url
  url=$(_build_url "/v1/indicators/ema/${ticker}" \
    "timestamp.gte=${ts_gte}" \
    "timestamp.lte=${ts_lte}" \
    "timespan=${timespan}" \
    "window=${window}" \
    "series_type=${series_type}" \
    "order=${order}" \
    "limit=${limit}" \
    "adjusted=true")

  local body
  body=$(paginate "$url")
  local rc=$?

  _read_http_code

  if [[ $rc -ne 0 ]]; then
    _json_output "$body"
    exit 1
  fi

  _json_output "$body"
}

cmd_rsi() {
  local ticker="$1"
  if [[ -z "$ticker" ]]; then
    echo '{"error":"ticker is required for rsi subcommand"}' >&2
    exit 1
  fi
  shift

  local ts_gte ts_lte timespan window series_type order limit
  ts_gte=$(_parse_flag "--timestamp.gte" "$@")
  ts_lte=$(_parse_flag "--timestamp.lte" "$@")
  timespan=$(_parse_flag "--timespan" "$@")
  window=$(_parse_flag "--window" "$@")
  series_type=$(_parse_flag "--series-type" "$@")
  order=$(_parse_flag "--order" "$@")
  limit=$(_parse_flag "--limit" "$@")

  local url
  url=$(_build_url "/v1/indicators/rsi/${ticker}" \
    "timestamp.gte=${ts_gte}" \
    "timestamp.lte=${ts_lte}" \
    "timespan=${timespan}" \
    "window=${window}" \
    "series_type=${series_type}" \
    "order=${order}" \
    "limit=${limit}" \
    "adjusted=true")

  local body
  body=$(paginate "$url")
  local rc=$?

  _read_http_code

  if [[ $rc -ne 0 ]]; then
    _json_output "$body"
    exit 1
  fi

  _json_output "$body"
}

cmd_macd() {
  local ticker="$1"
  if [[ -z "$ticker" ]]; then
    echo '{"error":"ticker is required for macd subcommand"}' >&2
    exit 1
  fi
  shift

  local ts_gte ts_lte timespan short_window long_window signal_window series_type order limit
  ts_gte=$(_parse_flag "--timestamp.gte" "$@")
  ts_lte=$(_parse_flag "--timestamp.lte" "$@")
  timespan=$(_parse_flag "--timespan" "$@")
  short_window=$(_parse_flag "--short-window" "$@")
  long_window=$(_parse_flag "--long-window" "$@")
  signal_window=$(_parse_flag "--signal-window" "$@")
  series_type=$(_parse_flag "--series-type" "$@")
  order=$(_parse_flag "--order" "$@")
  limit=$(_parse_flag "--limit" "$@")

  local url
  url=$(_build_url "/v1/indicators/macd/${ticker}" \
    "timestamp.gte=${ts_gte}" \
    "timestamp.lte=${ts_lte}" \
    "timespan=${timespan}" \
    "short_window=${short_window}" \
    "long_window=${long_window}" \
    "signal_window=${signal_window}" \
    "series_type=${series_type}" \
    "order=${order}" \
    "limit=${limit}" \
    "adjusted=true")

  local body
  body=$(paginate "$url")
  local rc=$?

  _read_http_code

  if [[ $rc -ne 0 ]]; then
    _json_output "$body"
    exit 1
  fi

  _json_output "$body"
}

# --- main ---

subcommand="${1:-help}"
shift 2>/dev/null || true

case "$subcommand" in
  sma)  cmd_sma "$@" ;;
  ema)  cmd_ema "$@" ;;
  rsi)  cmd_rsi "$@" ;;
  macd) cmd_macd "$@" ;;
  help|--help|-h) show_help ;;
  *)
    echo "{\"error\":\"unknown subcommand: ${subcommand}\"}" >&2
    show_help
    ;;
esac
