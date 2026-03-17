# massive-skill

Agent skill for querying U.S. stock, options, and futures market data from [Massive.com](https://massive.com)'s REST API. Built with pure bash (`curl` + `jq`) following the [Agent Skills](https://agentskills.io) open standard — works across Claude Code, Cursor, Codex, OpenClaw, and 30+ AI agents.

## Prerequisites

- `curl` and `jq`
- `MASSIVE_API_KEY` environment variable ([get one here](https://massive.com/dashboard/signup))

## Quick Start

```bash
export MASSIVE_API_KEY=your_key_here

# Current stock price
scripts/massive_price.sh snapshot AAPL

# Weekly OHLC bars
scripts/massive_price.sh bars TSLA 2025-01-01 2025-01-31

# Company info
scripts/massive_ticker.sh details MSFT

# Market news
scripts/massive_news.sh --ticker AAPL --limit 5

# Technical indicators
scripts/massive_technicals.sh sma NVDA --window 20 --timespan day

# Options chain
scripts/massive_options.sh chain SPY --contract-type call

# Market status
scripts/massive_market.sh status

# Format output as a table
scripts/massive_price.sh bars AAPL 2025-03-10 2025-03-14 | scripts/massive_format.sh --type stocks
```

## Scripts

| Script | Purpose | Subcommands |
|--------|---------|-------------|
| `massive_price.sh` | Current & historical prices | `bars`, `daily`, `open-close`, `prev`, `snapshot`, `movers`, `universal` |
| `massive_ticker.sh` | Ticker lookup & company info | `list`, `details`, `types`, `related` |
| `massive_trades.sh` | Tick-level trade data | `list`, `last` |
| `massive_quotes.sh` | NBBO quote data | `list`, `last` |
| `massive_news.sh` | Market news with sentiment | *(flat)* |
| `massive_fundamentals.sh` | Financials & corporate actions | `balance-sheets`, `income`, `cash-flow`, `ratios`, `dividends`, `splits`, `ipos`, `short-interest`, `short-volume` |
| `massive_technicals.sh` | Technical indicators | `sma`, `ema`, `rsi`, `macd` |
| `massive_options.sh` | Options data | `contracts`, `contract`, `chain`, `snapshot`, `bars`, `prev`, `trades`, `quotes`, `last-trade` |
| `massive_futures.sh` | Futures data | `contracts`, `products`, `schedules`, `snapshot`, `bars`, `trades`, `quotes` |
| `massive_market.sh` | Market operations | `status`, `holidays`, `exchanges`, `conditions` |
| `massive_format.sh` | Format JSON for display | `--type`, `--format`, `--top` |
| `_lib.sh` | Shared library | *(internal)* |

## Output Formats

```bash
# Human-readable table (default)
scripts/massive_price.sh bars AAPL 2025-01-01 2025-01-31 | scripts/massive_format.sh --type stocks

# CSV
scripts/massive_price.sh bars AAPL 2025-01-01 2025-01-31 | scripts/massive_format.sh --type stocks --format csv

# Pretty JSON
scripts/massive_price.sh bars AAPL 2025-01-01 2025-01-31 | scripts/massive_format.sh --format full

# Top N results
scripts/massive_news.sh --limit 20 | scripts/massive_format.sh --type news --top 5
```

## Installation

```bash
# Clone
git clone https://github.com/foreztgump/massive-skill.git
cd massive-skill

# Install for your AI agent platform
./install.sh              # auto-detect
./install.sh claude-code  # Claude Code
./install.sh cursor       # Cursor
./install.sh codex        # Codex
./install.sh generic      # symlink to ~/.local/bin
```

Or use `make install` to copy scripts to `~/.local/bin/massive-skill/`.

## Data Coverage

- **Stocks**: All 19 U.S. exchanges + dark pools + FINRA + OTC
- **Options**: All 17 U.S. options exchanges via OPRA
- **Futures**: CME, CBOT, COMEX, NYMEX

## License

MIT
