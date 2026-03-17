#!/usr/bin/env bash
# scripts/massive_format.sh — Format JSON output from massive_* scripts for human-readable display
#
# This is a local formatter. It does NOT source _lib.sh and makes no API calls.
#
# Usage:
#   massive_price.sh snapshot AAPL | massive_format.sh --type snapshot
#   massive_format.sh --type news --format csv < news.json
#   massive_format.sh --type stocks --top 10 results.json

set -euo pipefail

# ---------------------------------------------------------------------------
# Dependency check
# ---------------------------------------------------------------------------
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
show_help() {
  cat >&2 <<'EOF'
massive_format.sh — Format JSON output from massive_* scripts

Usage:
  <command> | massive_format.sh --type <TYPE> [--format <FORMAT>] [--top N]
  massive_format.sh --type <TYPE> [--format <FORMAT>] [--top N] <file>

Types:
  stocks, snapshot, movers, news, tickers, fundamentals,
  technicals, trades, quotes, options, futures

Formats:
  summary   Concise human-readable output (default)
  full      Pretty-printed JSON
  csv       Comma-separated values with header row

Options:
  --top N   Limit output to top N results
EOF
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
TYPE=""
FORMAT="summary"
TOP=""
INPUT_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)    TYPE="$2";   shift 2 ;;
    --format)  FORMAT="$2"; shift 2 ;;
    --top)     TOP="$2";    shift 2 ;;
    -h|--help)
      show_help
      exit 0
      ;;
    -*)
      echo "Error: unknown flag: $1" >&2
      exit 1
      ;;
    *)
      INPUT_FILE="$1"
      shift
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Validate arguments
# ---------------------------------------------------------------------------
VALID_TYPES="stocks snapshot movers news tickers fundamentals technicals trades quotes options futures"
if [[ -z "$TYPE" ]]; then
  echo "Error: --type is required." >&2
  show_help
  exit 1
fi

type_valid=false
for vt in $VALID_TYPES; do
  if [[ "$vt" == "$TYPE" ]]; then
    type_valid=true
    break
  fi
done
if [[ "$type_valid" != "true" ]]; then
  echo "Error: invalid type '$TYPE'. Must be one of: $VALID_TYPES" >&2
  exit 1
fi

if [[ "$FORMAT" != "summary" && "$FORMAT" != "full" && "$FORMAT" != "csv" ]]; then
  echo "Error: invalid format '$FORMAT'. Must be summary, full, or csv." >&2
  exit 1
fi

if [[ -n "$TOP" ]] && ! [[ "$TOP" =~ ^[0-9]+$ ]]; then
  echo "Error: --top must be a positive integer." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Read input (stdin or file)
# ---------------------------------------------------------------------------
if [[ -n "$INPUT_FILE" ]]; then
  if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: file not found: $INPUT_FILE" >&2
    exit 1
  fi
  INPUT=$(cat "$INPUT_FILE")
else
  if [[ -t 0 ]]; then
    echo "Error: no input. Pipe JSON or provide a file argument." >&2
    show_help
    exit 1
  fi
  INPUT=$(cat)
fi

# Validate JSON
if ! echo "$INPUT" | jq empty 2>/dev/null; then
  echo "Error: input is not valid JSON." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

# _format_number <value>
# Format large numbers: 1000000 -> 1.0M, 1000 -> 1.0K
_format_number() {
  local val="$1"
  if [[ -z "$val" || "$val" == "null" ]]; then
    echo "N/A"
    return
  fi
  echo "$val" | awk '{
    v = $1 + 0
    if (v < 0) { sign = "-"; v = -v } else { sign = "" }
    if (v >= 1000000000000) printf "%s%.1fT\n", sign, v / 1000000000000
    else if (v >= 1000000000) printf "%s%.1fB\n", sign, v / 1000000000
    else if (v >= 1000000) printf "%s%.1fM\n", sign, v / 1000000
    else if (v >= 1000) printf "%s%.1fK\n", sign, v / 1000
    else printf "%s%.0f\n", sign, v
  }'
}

# _format_timestamp <unix_ms_or_nanoseconds>
# Convert Unix ms or nanosecond timestamp to human-readable date.
# Also handles ISO 8601 strings (passed through).
_format_timestamp() {
  local ts="$1"
  if [[ -z "$ts" || "$ts" == "null" ]]; then
    echo "N/A"
    return
  fi
  # If it looks like an ISO date string already, pass through
  if [[ "$ts" =~ ^[0-9]{4}-[0-9]{2} ]]; then
    echo "$ts"
    return
  fi
  # Nanoseconds (19 digits) -> convert to seconds
  if [[ ${#ts} -ge 19 ]]; then
    local secs
    secs=$(echo "$ts" | awk '{ printf "%.0f", $1 / 1000000000 }')
    date -d "@${secs}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$ts"
  # Milliseconds (13 digits) -> convert to seconds
  elif [[ ${#ts} -ge 13 ]]; then
    local secs
    secs=$(echo "$ts" | awk '{ printf "%.0f", $1 / 1000 }')
    date -d "@${secs}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$ts"
  # Already seconds
  else
    date -d "@${ts}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$ts"
  fi
}

# _format_price <value>
# Format price with $ and 2 decimal places
_format_price() {
  local val="$1"
  if [[ -z "$val" || "$val" == "null" ]]; then
    echo "N/A"
    return
  fi
  printf '$%.2f' "$val"
}

# ---------------------------------------------------------------------------
# Extract results array from various API response shapes
# ---------------------------------------------------------------------------
_extract_results() {
  local json="$1"
  echo "$json" | jq '
    if (.results | type) == "object" and (.results.values | type) == "array" then .results.values
    elif (.results | type) == "array" then .results
    elif (.tickers | type) == "array" then .tickers
    elif (.ticker | type) == "object" then [.ticker]
    elif (. | type) == "array" then .
    else [.]
    end
  ' 2>/dev/null
}

# Apply --top limit to a JSON array
_apply_top() {
  local json_array="$1"
  if [[ -n "$TOP" ]]; then
    echo "$json_array" | jq ".[0:${TOP}]"
  else
    echo "$json_array"
  fi
}

# ---------------------------------------------------------------------------
# Full format — just pretty-print the JSON
# ---------------------------------------------------------------------------
if [[ "$FORMAT" == "full" ]]; then
  if [[ -n "$TOP" ]]; then
    echo "$INPUT" | jq --argjson top "$TOP" '
      if (.results | type) == "array" then .results = .results[0:$top]
      elif (.tickers | type) == "array" then .tickers = .tickers[0:$top]
      else .
      end
    '
  else
    echo "$INPUT" | jq '.'
  fi
  exit 0
fi

# ---------------------------------------------------------------------------
# Auto-detect bars/aggregates from JSON structure (has o,h,l,c,v keys)
# ---------------------------------------------------------------------------
_is_bars_data() {
  local json="$1"
  echo "$json" | jq -e '
    if (. | type) == "array" and (. | length) > 0 then
      .[0] | has("o") and has("h") and has("l") and has("c") and has("v")
    else false
    end
  ' &>/dev/null
}

# ---------------------------------------------------------------------------
# Formatting: stocks / snapshot
# ---------------------------------------------------------------------------
_format_stocks_summary() {
  local items="$1"
  echo "$items" | jq -r '
    .[] |
    (if .lastTrade then .lastTrade.p
     elif .day then .day.c
     elif .c then .c
     elif .close then .close
     else null end) as $price |
    (if .todaysChange then .todaysChange
     elif .change then .change
     else null end) as $change |
    (if .todaysChangePerc then .todaysChangePerc
     elif .changePercent then .changePercent
     else null end) as $changePct |
    (if .day then .day.v
     elif .v then .v
     elif .volume then .volume
     else null end) as $vol |
    (.ticker // .T // .symbol // "???") as $sym |
    [$sym, ($price // "" | tostring), ($change // "" | tostring), ($changePct // "" | tostring), ($vol // "" | tostring)] | @tsv
  ' | while IFS=$'\t' read -r sym price change changePct vol; do
    local priceFmt changeFmt pctFmt volFmt sign
    priceFmt=$(_format_price "$price")
    volFmt=$(_format_number "$vol")
    if [[ -n "$change" && "$change" != "null" && "$change" != "" ]]; then
      sign=""
      if echo "$change" | awk '{ exit ($1 >= 0) ? 1 : 0 }'; then
        sign=""
      else
        sign="+"
      fi
      changeFmt=$(printf '%s%.2f' "$sign" "$change")
      pctFmt=$(printf '(%s%.2f%%)' "$sign" "$changePct")
    else
      changeFmt="N/A"
      pctFmt=""
    fi
    printf '%-6s  %10s  %8s %10s  Vol: %s\n' "$sym" "$priceFmt" "$changeFmt" "$pctFmt" "$volFmt"
  done
}

_format_stocks_csv() {
  local items="$1"
  echo "ticker,price,change,change_pct,volume"
  echo "$items" | jq -r '
    .[] |
    (if .lastTrade then .lastTrade.p
     elif .day then .day.c
     elif .c then .c
     elif .close then .close
     else "" end) as $price |
    (if .todaysChange then .todaysChange
     elif .change then .change
     else "" end) as $change |
    (if .todaysChangePerc then .todaysChangePerc
     elif .changePercent then .changePercent
     else "" end) as $changePct |
    (if .day then .day.v
     elif .v then .v
     elif .volume then .volume
     else "" end) as $vol |
    (.ticker // .T // .symbol // "") as $sym |
    [$sym, ($price | tostring), ($change | tostring), ($changePct | tostring), ($vol | tostring)] | @csv
  '
}

# ---------------------------------------------------------------------------
# Formatting: movers (snapshot with rank prefix)
# ---------------------------------------------------------------------------
_format_movers_summary() {
  local items="$1"
  local rank=0
  echo "$items" | jq -r '
    .[] |
    (if .lastTrade then .lastTrade.p
     elif .day then .day.c
     elif .c then .c
     elif .close then .close
     else null end) as $price |
    (if .todaysChange then .todaysChange
     elif .change then .change
     else null end) as $change |
    (if .todaysChangePerc then .todaysChangePerc
     elif .changePercent then .changePercent
     else null end) as $changePct |
    (if .day then .day.v
     elif .v then .v
     elif .volume then .volume
     else null end) as $vol |
    (.ticker // .T // .symbol // "???") as $sym |
    [$sym, ($price // "" | tostring), ($change // "" | tostring), ($changePct // "" | tostring), ($vol // "" | tostring)] | @tsv
  ' | while IFS=$'\t' read -r sym price change changePct vol; do
    rank=$((rank + 1))
    local priceFmt changeFmt pctFmt volFmt sign
    priceFmt=$(_format_price "$price")
    volFmt=$(_format_number "$vol")
    if [[ -n "$change" && "$change" != "null" && "$change" != "" ]]; then
      sign=""
      if echo "$change" | awk '{ exit ($1 >= 0) ? 1 : 0 }'; then
        sign=""
      else
        sign="+"
      fi
      changeFmt=$(printf '%s%.2f' "$sign" "$change")
      pctFmt=$(printf '(%s%.2f%%)' "$sign" "$changePct")
    else
      changeFmt="N/A"
      pctFmt=""
    fi
    printf '%2d. %-6s  %10s  %8s %10s  Vol: %s\n' "$rank" "$sym" "$priceFmt" "$changeFmt" "$pctFmt" "$volFmt"
  done
}

_format_movers_csv() {
  local items="$1"
  echo "rank,ticker,price,change,change_pct,volume"
  local rank=0
  echo "$items" | jq -r '
    .[] |
    (if .lastTrade then .lastTrade.p
     elif .day then .day.c
     elif .c then .c
     elif .close then .close
     else "" end) as $price |
    (if .todaysChange then .todaysChange
     elif .change then .change
     else "" end) as $change |
    (if .todaysChangePerc then .todaysChangePerc
     elif .changePercent then .changePercent
     else "" end) as $changePct |
    (if .day then .day.v
     elif .v then .v
     elif .volume then .volume
     else "" end) as $vol |
    (.ticker // .T // .symbol // "") as $sym |
    [$sym, ($price | tostring), ($change | tostring), ($changePct | tostring), ($vol | tostring)] | @csv
  ' | while IFS= read -r line; do
    rank=$((rank + 1))
    echo "${rank},${line}"
  done
}

# ---------------------------------------------------------------------------
# Formatting: news
# ---------------------------------------------------------------------------
_format_news_summary() {
  local items="$1"
  echo "$items" | jq -r '
    .[] |
    (.title // "Untitled") as $title |
    (.publisher.name // .source // "Unknown") as $source |
    (.published_utc // .published // "N/A") as $date |
    (if .tickers then (.tickers | join(", ")) else "N/A" end) as $tickers |
    (.description // "" | if (. | length) > 120 then (.[0:117] + "...") else . end) as $desc |
    ((.sentiment // "N/A") | tostring) as $sentiment |
    [$title, $source, $date, $tickers, $desc, $sentiment] | @tsv
  ' | while IFS=$'\t' read -r title source date tickers desc sentiment; do
    echo "---"
    echo "  $title"
    echo "  Source: $source  |  Date: $date"
    echo "  Tickers: $tickers  |  Sentiment: $sentiment"
    if [[ -n "$desc" ]]; then
      echo "  $desc"
    fi
  done
}

_format_news_csv() {
  local items="$1"
  echo "title,source,published,tickers,sentiment,description"
  echo "$items" | jq -r '
    .[] |
    (.title // "") as $title |
    (.publisher.name // .source // "") as $source |
    (.published_utc // .published // "") as $date |
    (if .tickers then (.tickers | join("; ")) else "" end) as $tickers |
    (.description // "" | if (. | length) > 120 then (.[0:117] + "...") else . end) as $desc |
    ((.sentiment // "") | tostring) as $sentiment |
    [$title, $source, $date, $tickers, $sentiment, $desc] | @csv
  '
}

# ---------------------------------------------------------------------------
# Formatting: tickers
# ---------------------------------------------------------------------------
_format_tickers_summary() {
  local items="$1"
  printf '%-10s  %-40s  %-10s  %-10s  %s\n' "TICKER" "NAME" "MARKET" "TYPE" "ACTIVE"
  printf '%-10s  %-40s  %-10s  %-10s  %s\n' "------" "----" "------" "----" "------"
  echo "$items" | jq -r '
    .[] |
    (.ticker // .symbol // "???") as $sym |
    (.name // "N/A") as $name |
    (.market // "N/A") as $market |
    (.type // "N/A") as $type |
    (if .active == true then "Yes"
     elif .active == false then "No"
     else "N/A" end) as $active |
    [$sym, $name, $market, $type, $active] | @tsv
  ' | while IFS=$'\t' read -r sym name market type_val active; do
    printf '%-10s  %-40s  %-10s  %-10s  %s\n' "$sym" "$name" "$market" "$type_val" "$active"
  done
}

_format_tickers_csv() {
  local items="$1"
  echo "ticker,name,market,type,active"
  echo "$items" | jq -r '
    .[] |
    (.ticker // .symbol // "") as $sym |
    (.name // "") as $name |
    (.market // "") as $market |
    (.type // "") as $type |
    (if .active == true then "true"
     elif .active == false then "false"
     else "" end) as $active |
    [$sym, $name, $market, $type, $active] | @csv
  '
}

# ---------------------------------------------------------------------------
# Formatting: fundamentals
# ---------------------------------------------------------------------------
_format_fundamentals_summary() {
  local items="$1"
  echo "$items" | jq -r '
    .[] |
    to_entries |
    map(select(.value != null and (.value | type) != "object" and (.value | type) != "array")) |
    .[] |
    "\(.key): \(.value)"
  ' | while IFS= read -r line; do
    echo "  $line"
  done
  # Also show nested financials if present
  echo "$items" | jq -r '
    .[] |
    if .financials then
      .financials | to_entries[] |
      "\n[\(.key)]",
      (.value | to_entries[] |
        if (.value | type) == "object" then
          "  \(.key): \(.value.value // .value.amount // .value | tostring)"
        else
          "  \(.key): \(.value | tostring)"
        end
      )
    else empty end
  ' 2>/dev/null
}

_format_fundamentals_csv() {
  local items="$1"
  # Extract all unique top-level scalar keys for header
  local header
  header=$(echo "$items" | jq -r '
    [.[] | to_entries[] | select(.value != null and (.value | type) != "object" and (.value | type) != "array") | .key] | unique | join(",")
  ')
  echo "$header"
  echo "$items" | jq -r --arg hdr "$header" '
    ($hdr | split(",")) as $keys |
    .[] |
    . as $item |
    [$keys[] | ($item[.] // "" | tostring)] | @csv
  '
}

# ---------------------------------------------------------------------------
# Formatting: technicals
# ---------------------------------------------------------------------------
_format_technicals_summary() {
  local items="$1"
  printf '%-22s  %s\n' "TIMESTAMP" "VALUE"
  printf '%-22s  %s\n' "---------" "-----"
  echo "$items" | jq -r '
    .[] |
    (.timestamp // .t // "N/A" | tostring) as $ts |
    (.value // .sma // .ema // .rsi // .macd // "N/A" | tostring) as $val |
    [$ts, $val] | @tsv
  ' | while IFS=$'\t' read -r ts val; do
    local tsFmt
    tsFmt=$(_format_timestamp "$ts")
    printf '%-22s  %s\n' "$tsFmt" "$val"
  done
}

_format_technicals_csv() {
  local items="$1"
  echo "timestamp,value"
  echo "$items" | jq -r '
    .[] |
    (.timestamp // .t // "" | tostring) as $ts |
    (.value // .sma // .ema // .rsi // .macd // "" | tostring) as $val |
    [$ts, $val] | @csv
  '
}

# ---------------------------------------------------------------------------
# Formatting: trades
# ---------------------------------------------------------------------------
_format_trades_summary() {
  local items="$1"
  printf '%-22s  %10s  %8s  %s\n' "TIMESTAMP" "PRICE" "SIZE" "EXCHANGE"
  printf '%-22s  %10s  %8s  %s\n' "---------" "-----" "----" "--------"
  echo "$items" | jq -r '
    .[] |
    (.sip_timestamp // .participant_timestamp // .t // "N/A" | tostring) as $ts |
    (.price // .p // null) as $price |
    (.size // .s // null) as $size |
    (.exchange // .x // "N/A" | tostring) as $exch |
    [$ts, ($price // "" | tostring), ($size // "" | tostring), $exch] | @tsv
  ' | while IFS=$'\t' read -r ts price size exch; do
    local tsFmt priceFmt
    tsFmt=$(_format_timestamp "$ts")
    priceFmt=$(_format_price "$price")
    printf '%-22s  %10s  %8s  %s\n' "$tsFmt" "$priceFmt" "$size" "$exch"
  done
}

_format_trades_csv() {
  local items="$1"
  echo "timestamp,price,size,exchange"
  echo "$items" | jq -r '
    .[] |
    (.sip_timestamp // .participant_timestamp // .t // "" | tostring) as $ts |
    (.price // .p // "" | tostring) as $price |
    (.size // .s // "" | tostring) as $size |
    (.exchange // .x // "" | tostring) as $exch |
    [$ts, $price, $size, $exch] | @csv
  '
}

# ---------------------------------------------------------------------------
# Formatting: quotes
# ---------------------------------------------------------------------------
_format_quotes_summary() {
  local items="$1"
  printf '%-22s  %10s  %8s  %10s  %8s  %s\n' "TIMESTAMP" "BID" "BID_SZ" "ASK" "ASK_SZ" "EXCHANGE"
  printf '%-22s  %10s  %8s  %10s  %8s  %s\n' "---------" "---" "------" "---" "------" "--------"
  echo "$items" | jq -r '
    .[] |
    (.sip_timestamp // .participant_timestamp // .t // "N/A" | tostring) as $ts |
    (.bid_price // .bp // .p // null) as $bid |
    (.bid_size // .bs // .s // null) as $bidSz |
    (.ask_price // .ap // null) as $ask |
    (.ask_size // .as_val // null) as $askSz |
    (.bid_exchange // .bx // .x // "N/A" | tostring) as $exch |
    [$ts, ($bid // "" | tostring), ($bidSz // "" | tostring), ($ask // "" | tostring), ($askSz // "" | tostring), $exch] | @tsv
  ' | while IFS=$'\t' read -r ts bid bidSz ask askSz exch; do
    local tsFmt bidFmt askFmt
    tsFmt=$(_format_timestamp "$ts")
    bidFmt=$(_format_price "$bid")
    askFmt=$(_format_price "$ask")
    printf '%-22s  %10s  %8s  %10s  %8s  %s\n' "$tsFmt" "$bidFmt" "$bidSz" "$askFmt" "$askSz" "$exch"
  done
}

_format_quotes_csv() {
  local items="$1"
  echo "timestamp,bid,bid_size,ask,ask_size,exchange"
  echo "$items" | jq -r '
    .[] |
    (.sip_timestamp // .participant_timestamp // .t // "" | tostring) as $ts |
    (.bid_price // .bp // .p // "" | tostring) as $bid |
    (.bid_size // .bs // .s // "" | tostring) as $bidSz |
    (.ask_price // .ap // "" | tostring) as $ask |
    (.ask_size // .as_val // "" | tostring) as $askSz |
    (.bid_exchange // .bx // .x // "" | tostring) as $exch |
    [$ts, $bid, $bidSz, $ask, $askSz, $exch] | @csv
  '
}

# ---------------------------------------------------------------------------
# Formatting: bars / aggregates (auto-detected by o,h,l,c,v keys)
# Also used for stocks type when data has bar structure
# ---------------------------------------------------------------------------
_format_bars_summary() {
  local items="$1"
  printf '%-22s  %10s  %10s  %10s  %10s  %10s\n' "DATE" "OPEN" "HIGH" "LOW" "CLOSE" "VOLUME"
  printf '%-22s  %10s  %10s  %10s  %10s  %10s\n' "----" "----" "----" "---" "-----" "------"
  echo "$items" | jq -r '
    .[] |
    (.t // .timestamp // "N/A" | tostring) as $ts |
    (.o // .open // null) as $open |
    (.h // .high // null) as $high |
    (.l // .low // null) as $low |
    (.c // .close // null) as $close |
    (.v // .volume // null) as $vol |
    [$ts, ($open // "" | tostring), ($high // "" | tostring), ($low // "" | tostring), ($close // "" | tostring), ($vol // "" | tostring)] | @tsv
  ' | while IFS=$'\t' read -r ts open high low close vol; do
    local tsFmt openFmt highFmt lowFmt closeFmt volFmt
    tsFmt=$(_format_timestamp "$ts")
    openFmt=$(_format_price "$open")
    highFmt=$(_format_price "$high")
    lowFmt=$(_format_price "$low")
    closeFmt=$(_format_price "$close")
    volFmt=$(_format_number "$vol")
    printf '%-22s  %10s  %10s  %10s  %10s  %10s\n' "$tsFmt" "$openFmt" "$highFmt" "$lowFmt" "$closeFmt" "$volFmt"
  done
}

_format_bars_csv() {
  local items="$1"
  echo "date,open,high,low,close,volume"
  echo "$items" | jq -r '
    .[] |
    (.t // .timestamp // "" | tostring) as $ts |
    (.o // .open // "" | tostring) as $open |
    (.h // .high // "" | tostring) as $high |
    (.l // .low // "" | tostring) as $low |
    (.c // .close // "" | tostring) as $close |
    (.v // .volume // "" | tostring) as $vol |
    [$ts, $open, $high, $low, $close, $vol] | @csv
  '
}

# ---------------------------------------------------------------------------
# Main dispatch
# ---------------------------------------------------------------------------

RESULTS=$(_extract_results "$INPUT")
RESULTS=$(_apply_top "$RESULTS")

# Check for empty results
result_count=$(echo "$RESULTS" | jq 'length' 2>/dev/null || echo "0")
if [[ "$result_count" == "0" || "$result_count" == "null" ]]; then
  echo "No results found."
  exit 0
fi

# For stocks type, auto-detect bars data
if [[ "$TYPE" == "stocks" ]] && _is_bars_data "$RESULTS"; then
  if [[ "$FORMAT" == "summary" ]]; then
    _format_bars_summary "$RESULTS"
  else
    _format_bars_csv "$RESULTS"
  fi
  exit 0
fi

case "${TYPE}" in
  stocks|snapshot|options|futures)
    if [[ "$FORMAT" == "summary" ]]; then
      _format_stocks_summary "$RESULTS"
    else
      _format_stocks_csv "$RESULTS"
    fi
    ;;
  movers)
    if [[ "$FORMAT" == "summary" ]]; then
      _format_movers_summary "$RESULTS"
    else
      _format_movers_csv "$RESULTS"
    fi
    ;;
  news)
    if [[ "$FORMAT" == "summary" ]]; then
      _format_news_summary "$RESULTS"
    else
      _format_news_csv "$RESULTS"
    fi
    ;;
  tickers)
    if [[ "$FORMAT" == "summary" ]]; then
      _format_tickers_summary "$RESULTS"
    else
      _format_tickers_csv "$RESULTS"
    fi
    ;;
  fundamentals)
    if [[ "$FORMAT" == "summary" ]]; then
      _format_fundamentals_summary "$RESULTS"
    else
      _format_fundamentals_csv "$RESULTS"
    fi
    ;;
  technicals)
    if [[ "$FORMAT" == "summary" ]]; then
      _format_technicals_summary "$RESULTS"
    else
      _format_technicals_csv "$RESULTS"
    fi
    ;;
  trades)
    if [[ "$FORMAT" == "summary" ]]; then
      _format_trades_summary "$RESULTS"
    else
      _format_trades_csv "$RESULTS"
    fi
    ;;
  quotes)
    if [[ "$FORMAT" == "summary" ]]; then
      _format_quotes_summary "$RESULTS"
    else
      _format_quotes_csv "$RESULTS"
    fi
    ;;
  *)
    echo "Error: unhandled type '$TYPE'" >&2
    exit 1
    ;;
esac
