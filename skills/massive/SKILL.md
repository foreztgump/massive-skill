---
name: massive
description: >
  Query U.S. stock, options, and futures market data from the Massive API.
  Use when the user asks about stock prices, market data, financial news,
  company fundamentals, technical indicators, options chains, futures contracts,
  or any U.S. financial market data. Requires MASSIVE_API_KEY env var.
---

# Massive Market Data Skill

Query U.S. stock, options, and futures market data via the Massive REST API. Data sourced from all 19 U.S. exchanges, dark pools, FINRA, OTC, 17 options exchanges (OPRA), and CME/CBOT/COMEX/NYMEX futures.

## Prerequisites

- `MASSIVE_API_KEY` environment variable must be set ([get one here](https://massive.com/dashboard))
- `curl` and `jq` must be available

## Setup

```bash
export MASSIVE_API_KEY=your_key_here
```

## Script Location

All scripts are in the `scripts/` directory relative to this skill folder. Reference them as:

```bash
bash "${SKILL_DIR}/scripts/<script_name>.sh" <subcommand> [options]
```

Where `SKILL_DIR` is the directory containing this SKILL.md file. In Claude Code, use `${CLAUDE_SKILL_DIR}/scripts/`.

## Quick Decision Tree

```text
User wants market data?
├── Current price / what's trading at?
│   ├── Single ticker → massive_price.sh snapshot <TICKER>
│   ├── Multiple tickers → massive_price.sh snapshot --tickers AAPL,TSLA,GOOG
│   └── Full market → massive_price.sh snapshot
├── Historical prices / chart / OHLC?
│   ├── Custom range → massive_price.sh bars <TICKER> <from> <to> [--timespan day]
│   ├── Previous day → massive_price.sh prev <TICKER>
│   ├── Specific date → massive_price.sh open-close <TICKER> <date>
│   └── Daily summary → massive_price.sh daily <date>
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
│   ├── All financials → massive_fundamentals.sh financials <TICKER>
│   │   [--timeframe annual|quarterly|ttm] [--limit N]
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
├── Tick-level trades? (requires upgraded plan)
│   ├── Historical → massive_trades.sh list <TICKER>
│   └── Last trade → massive_trades.sh last <TICKER>
├── Quotes / bid-ask? (requires upgraded plan)
│   ├── Historical → massive_quotes.sh list <TICKER>
│   └── Last quote → massive_quotes.sh last <TICKER>
├── Options? (snapshots require upgraded plan)
│   ├── Options chain → massive_options.sh chain <TICKER>
│   ├── Find contracts → massive_options.sh contracts --underlying-ticker <TICKER>
│   ├── Contract details → massive_options.sh contract <OPTIONS_TICKER>
│   ├── Options bars → massive_options.sh bars <OPTIONS_TICKER> <from> <to>
│   ├── Options trades → massive_options.sh trades <OPTIONS_TICKER>
│   └── Options quotes → massive_options.sh quotes <OPTIONS_TICKER>
├── Futures? (requires upgraded plan)
│   ├── Contracts → massive_futures.sh contracts [--product-code GC]
│   ├── Products → massive_futures.sh products [--exchange CME]
│   ├── Snapshot → massive_futures.sh snapshot [--ticker GCJ5]
│   ├── Bars → massive_futures.sh bars <TICKER> <from> <to>
│   └── Trades / quotes → massive_futures.sh trades|quotes <TICKER>
└── Market operations?
    ├── Open/closed? → massive_market.sh status
    ├── Holidays → massive_market.sh holidays
    ├── Exchanges → massive_market.sh exchanges
    └── Conditions → massive_market.sh conditions
```

## Scripts Reference

| Script | Purpose | Key Subcommands |
|--------|---------|-----------------|
| `massive_price.sh` | Current & historical prices | `bars`, `daily`, `open-close`, `prev`, `snapshot`, `movers`, `universal` |
| `massive_ticker.sh` | Ticker lookup & company info | `list`, `details`, `types`, `related` |
| `massive_trades.sh` | Tick-level trade data | `list`, `last` |
| `massive_quotes.sh` | NBBO quote data | `list`, `last` |
| `massive_news.sh` | Market news with sentiment | `--ticker`, `--limit` |
| `massive_fundamentals.sh` | Financials & corporate actions | `financials`, `dividends`, `splits`, `ipos`, `short-interest`, `short-volume` |
| `massive_technicals.sh` | Technical indicators | `sma`, `ema`, `rsi`, `macd` |
| `massive_options.sh` | Options data | `contracts`, `contract`, `chain`, `snapshot`, `bars`, `prev`, `trades`, `quotes`, `last-trade` |
| `massive_futures.sh` | Futures data | `contracts`, `products`, `schedules`, `snapshot`, `bars`, `trades`, `quotes` |
| `massive_market.sh` | Market status & reference | `status`, `holidays`, `exchanges`, `conditions` |
| `massive_format.sh` | Format JSON output | `--type`, `--format summary\|full\|csv`, `--top N` |

## Output Formatting

Pipe any script output through the formatter:

```bash
bash massive_price.sh snapshot AAPL | bash massive_format.sh --type snapshot --format summary
bash massive_price.sh movers gainers | bash massive_format.sh --type movers --top 5
bash massive_news.sh --ticker AAPL | bash massive_format.sh --type news --format csv
```

Formats: `summary` (default, human-readable table), `full` (pretty JSON), `csv`.

## Plan Tiers

Some endpoints require a paid plan. If you get a 403 error, the response will include the upgrade URL. Endpoints available on the free plan include: prices, tickers, technicals, market status, news, financials, dividends, splits, short data.

## Error Handling

All errors are returned as JSON to stderr:
```json
{"error": "access denied (HTTP 403): You are not entitled to this data. Please upgrade your plan at https://massive.com/pricing"}
```
