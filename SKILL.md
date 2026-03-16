---
name: massive
description: >
  Query stock, options, and futures market data from Massive.com's REST API.
  Use when the user asks about stock prices, market data, financial news,
  company fundamentals, technical indicators, options chains, futures contracts,
  market status, or any U.S. financial market data. Requires MASSIVE_API_KEY env var.
  Covers: real-time and historical prices, aggregates (OHLC bars), trades, quotes,
  snapshots, news with sentiment, dividends, splits, IPOs, financials (balance sheets,
  income statements, cash flow, ratios), short interest, technical indicators
  (SMA, EMA, RSI, MACD), options contracts and chains, futures contracts and products,
  market status, exchanges, and top movers.
version: 1.0.0
license: MIT
allowed-tools: Bash
metadata: {"openclaw":{"requires":{"env":["MASSIVE_API_KEY"],"bins":["curl","jq"]},"primaryEnv":"MASSIVE_API_KEY","configPaths":["~/.config/massive-skill/"]}}
---

# Massive Market Data Skill

Query U.S. stock, options, and futures market data via Massive.com's REST API. All data is sourced directly from major U.S. exchanges (NYSE, Nasdaq, CBOE, CME, etc.) via SIPs and direct feeds.

## Prerequisites

- `MASSIVE_API_KEY` environment variable must be set
- `curl` and `jq` must be available

## Workflow Decision Tree

```text
User wants market data?
├── Current price / what's a stock trading at?
│   ├── Single ticker → massive_price.sh snapshot <TICKER>
│   ├── Multiple tickers → massive_price.sh snapshot --tickers AAPL,TSLA,GOOG
│   └── Full market → massive_price.sh snapshot
├── Historical prices / chart data / OHLC bars?
│   ├── Custom range → massive_price.sh bars <TICKER> <from> <to> [--timespan day]
│   ├── Previous day → massive_price.sh prev <TICKER>
│   ├── Specific date open/close → massive_price.sh open-close <TICKER> <date>
│   └── Daily market summary → massive_price.sh daily <date>
├── Top gainers / losers?
│   └── massive_price.sh movers <gainers|losers>
├── Ticker / company info?
│   ├── Company details → massive_ticker.sh details <TICKER>
│   ├── Search tickers → massive_ticker.sh list --search "apple"
│   ├── Related companies → massive_ticker.sh related <TICKER>
│   └── Ticker types → massive_ticker.sh types
├── News?
│   └── massive_news.sh [--ticker AAPL] [--limit 10]
├── Financials / fundamentals?
│   ├── Balance sheet → massive_fundamentals.sh balance-sheets <TICKER>
│   ├── Income statement → massive_fundamentals.sh income <TICKER>
│   ├── Cash flow → massive_fundamentals.sh cash-flow <TICKER>
│   ├── Financial ratios → massive_fundamentals.sh ratios <TICKER>
│   ├── Dividends → massive_fundamentals.sh dividends --ticker <TICKER>
│   ├── Stock splits → massive_fundamentals.sh splits --ticker <TICKER>
│   ├── IPOs → massive_fundamentals.sh ipos
│   ├── Short interest → massive_fundamentals.sh short-interest <TICKER>
│   └── Short volume → massive_fundamentals.sh short-volume <TICKER>
├── Technical indicators?
│   ├── SMA → massive_technicals.sh sma <TICKER> [--window 50]
│   ├── EMA → massive_technicals.sh ema <TICKER> [--window 20]
│   ├── RSI → massive_technicals.sh rsi <TICKER> [--window 14]
│   └── MACD → massive_technicals.sh macd <TICKER>
├── Tick-level trade data?
│   ├── Historical trades → massive_trades.sh list <TICKER>
│   └── Last trade → massive_trades.sh last <TICKER>
├── Quote (bid/ask) data?
│   ├── Historical quotes → massive_quotes.sh list <TICKER>
│   └── Last quote → massive_quotes.sh last <TICKER>
├── Options?
│   ├── Options chain → massive_options.sh chain <TICKER>
│   ├── Find contracts → massive_options.sh contracts --underlying-ticker <TICKER>
│   ├── Contract details → massive_options.sh contract <OPTIONS_TICKER>
│   ├── Contract snapshot → massive_options.sh snapshot <TICKER> <CONTRACT>
│   ├── Options bars → massive_options.sh bars <OPTIONS_TICKER> <from> <to>
│   ├── Options trades → massive_options.sh trades <OPTIONS_TICKER>
│   └── Options quotes → massive_options.sh quotes <OPTIONS_TICKER>
├── Futures?
│   ├── Contracts → massive_futures.sh contracts [--product-code GC]
│   ├── Products → massive_futures.sh products [--exchange CME]
│   ├── Schedules → massive_futures.sh schedules [--product-code GC]
│   ├── Snapshot → massive_futures.sh snapshot [--ticker GCJ5]
│   ├── Futures bars → massive_futures.sh bars <TICKER> <from> <to>
│   ├── Futures trades → massive_futures.sh trades <TICKER>
│   └── Futures quotes → massive_futures.sh quotes <TICKER>
└── Market operations?
    ├── Market open/closed? → massive_market.sh status
    ├── Upcoming holidays → massive_market.sh holidays
    ├── Exchange list → massive_market.sh exchanges
    └── Condition codes → massive_market.sh conditions
```

## Scripts Reference

| Script | Purpose | Key Subcommands |
|--------|---------|-----------------|
| `massive_price.sh` | Current & historical prices | `bars`, `daily`, `open-close`, `prev`, `snapshot`, `movers`, `universal` |
| `massive_ticker.sh` | Ticker lookup & company info | `list`, `details`, `types`, `related` |
| `massive_trades.sh` | Tick-level trade data | `list`, `last` |
| `massive_quotes.sh` | NBBO quote data | `list`, `last` |
| `massive_news.sh` | Market news with sentiment | (flat — no subcommands) |
| `massive_fundamentals.sh` | Financials & corporate actions | `balance-sheets`, `income`, `cash-flow`, `ratios`, `dividends`, `splits`, `ipos`, `short-interest`, `short-volume` |
| `massive_technicals.sh` | Technical indicators | `sma`, `ema`, `rsi`, `macd` |
| `massive_options.sh` | Options data | `contracts`, `contract`, `chain`, `snapshot`, `bars`, `prev`, `trades`, `quotes`, `last-trade` |
| `massive_futures.sh` | Futures data | `contracts`, `products`, `schedules`, `snapshot`, `bars`, `trades`, `quotes` |
| `massive_market.sh` | Market operations | `status`, `holidays`, `exchanges`, `conditions` |
| `massive_format.sh` | Format JSON for display | `--type`, `--format`, `--top` |
| `_lib.sh` | Shared library (internal) | — |

## Quick Start

Get Apple's current stock price:
```bash
scripts/massive_price.sh snapshot AAPL
```

Get 30 days of daily OHLC bars for Tesla:
```bash
scripts/massive_price.sh bars TSLA 2025-01-01 2025-01-31
```

Get latest market news:
```bash
scripts/massive_news.sh --limit 5 | scripts/massive_format.sh --type news --top 5
```

Get Apple's financial ratios:
```bash
scripts/massive_fundamentals.sh ratios AAPL
```

Get options chain for SPY:
```bash
scripts/massive_options.sh chain SPY --contract-type call --expiration-date 2025-03-21
```

Check if market is open:
```bash
scripts/massive_market.sh status
```

## Behavior Rules (MANDATORY)

1. **Tickers are CASE-SENSITIVE.** Always use uppercase: `AAPL`, not `aapl`.
2. **Dates use YYYY-MM-DD format** for all date parameters.
3. **Timestamps use nanosecond Unix epoch** in trade/quote data — the format script handles conversion.
4. **All responses are JSON.** Pipe through `massive_format.sh` for human-readable output.
5. **Pagination is automatic** for endpoints that support it (trades, quotes, tickers, contracts). Default max 10 pages.
6. **Rate limits apply.** If you get HTTP 429, wait and retry. The scripts report this clearly.
7. **Plan limits apply.** Some endpoints (trades, quotes, financials) require higher-tier plans. HTTP 403 means the user's plan doesn't include that data.
8. **Options tickers use OCC format**: `O:AAPL250321C00185000` (O:UNDERLYING+YYMMDD+C/P+STRIKE*1000).
9. **Futures tickers include expiration**: `GCJ5` (product code + month letter + year digit).
10. **Stocks timestamps are Eastern Time (ET).** Futures timestamps are Central Time (CT).

## Result Formatting

```bash
# Human-readable stock snapshot
scripts/massive_price.sh snapshot AAPL | scripts/massive_format.sh --type snapshot

# CSV export of bars
scripts/massive_price.sh bars AAPL 2025-01-01 2025-01-31 | scripts/massive_format.sh --type stocks --format csv

# Top 5 news articles
scripts/massive_news.sh --ticker AAPL --limit 10 | scripts/massive_format.sh --type news --top 5

# Pretty-print any JSON
scripts/massive_fundamentals.sh ratios AAPL | scripts/massive_format.sh --format full
```

## Exit Codes

| Code | Meaning | Agent should... |
|------|---------|-----------------|
| 0 | Success — results on stdout | Format and present results |
| 1 | Error — something failed | Report the error from stderr |

## Data Storage

Minimal local state at `~/.config/massive-skill/` — created on first run for potential future caching. No persistent data is stored by default.

## Security

All scripts source `scripts/_lib.sh` for shared HTTP functions. The library:

- Makes requests to a **single endpoint**: `https://api.massive.com`
- Uses **one credential**: `MASSIVE_API_KEY` (sent via query parameter)
- Writes **only** to `~/.config/massive-skill/`
- Does not read other environment variables, contact other hosts, or modify files outside its config directory

## For full API parameter details

See `references/api-reference.md` for complete endpoint documentation, response schemas, and parameter options.
