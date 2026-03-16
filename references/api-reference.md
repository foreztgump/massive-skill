# Massive REST API Reference

Base URL: `https://api.massive.com`
Auth: `?apiKey=YOUR_API_KEY` (query param) or `Authorization: Bearer YOUR_API_KEY` (header)
All responses return JSON with `status` field ("OK" on success).
Paginated endpoints include `next_url` field for cursor-based pagination.

---

## Stocks

### Aggregates

| Endpoint | Path | Key Params |
|----------|------|-----------|
| Custom Bars (OHLC) | `GET /v2/aggs/ticker/{ticker}/range/{multiplier}/{timespan}/{from}/{to}` | adjusted, sort, limit |
| Daily Market Summary | `GET /v2/aggs/grouped/locale/us/market/stocks/{date}` | adjusted, include_otc |
| Daily Ticker Summary | `GET /v1/open-close/{ticker}/{date}` | adjusted |
| Previous Day Bar | `GET /v2/aggs/ticker/{ticker}/prev` | adjusted |

**Timespans**: second, minute, hour, day, week, month, quarter, year
**Date format**: YYYY-MM-DD
**Aggregate response fields**: `o` (open), `h` (high), `l` (low), `c` (close), `v` (volume), `vw` (VWAP), `t` (timestamp ms), `n` (transactions), `T` (ticker)

### Trades & Quotes

| Endpoint | Path | Key Params |
|----------|------|-----------|
| Trades | `GET /v3/trades/{ticker}` | timestamp.gte, timestamp.lte, order, limit, sort |
| Quotes (NBBO) | `GET /v3/quotes/{ticker}` | timestamp.gte, timestamp.lte, order, limit, sort |
| Last Trade | `GET /v2/last/trade/{ticker}` | — |
| Last Quote (NBBO) | `GET /v2/last/nbbo/{ticker}` | — |

Trades and Quotes support pagination via `next_url`.

### Snapshots

| Endpoint | Path | Key Params |
|----------|------|-----------|
| Full Market | `GET /v2/snapshot/locale/us/markets/stocks/tickers` | tickers, include_otc |
| Single Ticker | `GET /v2/snapshot/locale/us/markets/stocks/tickers/{ticker}` | — |
| Top Movers | `GET /v2/snapshot/locale/us/markets/stocks/{direction}` | include_otc |
| Unified Snapshot | `GET /v3/snapshot` | ticker.any_of, type |

**Direction**: `gainers` or `losers`
**Snapshot data**: day bar, lastTrade, lastQuote, min bar, prevDay, todaysChange, todaysChangePerc

### Tickers / Reference

| Endpoint | Path | Key Params |
|----------|------|-----------|
| All Tickers | `GET /v3/reference/tickers` | search, type, market, exchange, active, sort, order, limit |
| Ticker Overview | `GET /v3/reference/tickers/{ticker}` | — |
| Ticker Types | `GET /v3/reference/tickers/types` | asset_class, locale |
| Related Tickers | `GET /v1/related-companies/{ticker}` | — |

All Tickers supports pagination via `next_url`.

### News

| Endpoint | Path | Key Params |
|----------|------|-----------|
| News | `GET /v2/reference/news` | ticker, published_utc.gte, published_utc.lte, order, limit, sort |

Supports pagination. Response includes: title, author, article_url, image_url, description, keywords, insights (sentiment, ticker associations), publisher info.

### Corporate Actions

| Endpoint | Path | Key Params |
|----------|------|-----------|
| Dividends | `GET /stocks/v1/dividends` | ticker, ex_dividend_date.gte/lte, frequency, order, limit |
| Splits | `GET /stocks/v1/splits` | ticker, execution_date.gte/lte, order, limit |
| IPOs | `GET /stocks/v1/ipos` | ticker, listing_date.gte/lte, order, limit |

All support pagination. Dividend frequency: 1 (annual), 2 (semi), 4 (quarterly), 12 (monthly).

### Fundamentals

| Endpoint | Path | Key Params |
|----------|------|-----------|
| Balance Sheets | `GET /stocks/v1/financials/balance-sheets` | ticker, period, filing_date.gte/lte, order, limit |
| Income Statements | `GET /stocks/v1/financials/income-statements` | ticker, period, filing_date.gte/lte, order, limit |
| Cash Flow | `GET /stocks/v1/financials/cash-flow-statements` | ticker, period, filing_date.gte/lte, order, limit |
| Ratios | `GET /stocks/v1/financials/ratios` | ticker, period, order, limit |
| Short Interest | `GET /stocks/v1/short-interest` | ticker, order, limit |
| Short Volume | `GET /stocks/v1/short-volume` | ticker, order, limit |

**Period**: annual, quarterly, ttm

### Technical Indicators

| Endpoint | Path | Key Params |
|----------|------|-----------|
| SMA | `GET /v1/indicators/sma/{ticker}` | timestamp.gte/lte, timespan, window, series_type, order, limit |
| EMA | `GET /v1/indicators/ema/{ticker}` | (same as SMA) |
| RSI | `GET /v1/indicators/rsi/{ticker}` | (same as SMA) |
| MACD | `GET /v1/indicators/macd/{ticker}` | short_window, long_window, signal_window + common params |

**Series types**: close, open, high, low

### Market Operations

| Endpoint | Path | Key Params |
|----------|------|-----------|
| Market Status | `GET /v1/marketstatus/now` | — |
| Market Holidays | `GET /v1/marketstatus/upcoming` | — |
| Exchanges | `GET /v3/reference/exchanges` | asset_class, locale |
| Condition Codes | `GET /v3/reference/conditions` | asset_class, data_type |

---

## Options

### Aggregates

| Endpoint | Path | Key Params |
|----------|------|-----------|
| Custom Bars | `GET /v2/aggs/ticker/{optionsTicker}/range/{multiplier}/{timespan}/{from}/{to}` | adjusted, sort, limit |
| Daily Ticker Summary | `GET /v1/open-close/{optionsTicker}/{date}` | adjusted |
| Previous Day Bar | `GET /v2/aggs/ticker/{optionsTicker}/prev` | adjusted |

### Contracts

| Endpoint | Path | Key Params |
|----------|------|-----------|
| All Contracts | `GET /v3/reference/options/contracts` | underlying_ticker, contract_type, expiration_date.gte/lte, strike_price.gte/lte, expired, order, limit, sort |
| Contract Overview | `GET /v3/reference/options/contracts/{options_ticker}` | — |

All Contracts supports pagination.

### Snapshots

| Endpoint | Path | Key Params |
|----------|------|-----------|
| Options Chain | `GET /v3/snapshot/options/{underlyingAsset}` | strike_price, expiration_date, contract_type, order, limit |
| Contract Snapshot | `GET /v3/snapshot/options/{underlyingAsset}/{optionContract}` | — |

Chain snapshot includes: break_even_price, greeks (delta, gamma, theta, vega), implied_volatility, open_interest, day bar, lastTrade, lastQuote, underlying asset price.

### Trades & Quotes

| Endpoint | Path | Key Params |
|----------|------|-----------|
| Trades | `GET /v3/trades/{optionsTicker}` | timestamp.gte/lte, order, limit, sort |
| Quotes | `GET /v3/quotes/{optionsTicker}` | timestamp.gte/lte, order, limit, sort |
| Last Trade | `GET /v2/last/trade/{optionsTicker}` | — |

### Technical Indicators

Same endpoints as stocks — pass options ticker instead of stock ticker:
`GET /v1/indicators/{sma|ema|rsi|macd}/{optionsTicker}`

### Options Ticker Format (OCC)
`O:AAPL250321C00185000`
- `O:` prefix
- `AAPL` underlying ticker
- `250321` expiration (YYMMDD)
- `C` call / `P` put
- `00185000` strike price * 1000

---

## Futures

All futures endpoints use `/futures/vX/` prefix (the `vX` is literal).
Timestamps are in Central Time (CT).

### Aggregates

| Endpoint | Path | Key Params |
|----------|------|-----------|
| Aggregate Bars | `GET /futures/vX/aggs/{ticker}` | from, to, timespan, multiplier, adjusted, sort, limit |

### Reference

| Endpoint | Path | Key Params |
|----------|------|-----------|
| Contracts | `GET /futures/vX/contracts` | product_code, expiration_date.gte/lte, order, limit |
| Products | `GET /futures/vX/products` | asset_class, exchange, search, order, limit |
| Schedules | `GET /futures/vX/schedules` | product_code, exchange |

### Snapshots

| Endpoint | Path | Key Params |
|----------|------|-----------|
| Contracts Snapshot | `GET /futures/vX/snapshot` | ticker, product_code, order, limit |

### Trades & Quotes

| Endpoint | Path | Key Params |
|----------|------|-----------|
| Trades | `GET /futures/vX/trades/{ticker}` | timestamp.gte/lte, order, limit, sort |
| Quotes | `GET /futures/vX/quotes/{ticker}` | timestamp.gte/lte, order, limit, sort |

### Futures Ticker Format
`GCJ5`
- `GC` product code (Gold)
- `J` month letter (F=Jan, G=Feb, H=Mar, J=Apr, K=May, M=Jun, N=Jul, Q=Aug, U=Sep, V=Oct, X=Nov, Z=Dec)
- `5` last digit of year (2025)

---

## Common Response Patterns

### Paginated Response
```json
{
  "status": "OK",
  "request_id": "abc123",
  "results": [...],
  "next_url": "https://api.massive.com/v3/...?cursor=xxx"
}
```

### Error Response
```json
{
  "status": "ERROR",
  "error": "Description of what went wrong",
  "request_id": "abc123"
}
```

### HTTP Status Codes
| Code | Meaning |
|------|---------|
| 200 | Success |
| 400 | Bad request (invalid params) |
| 401 | Unauthorized (invalid API key) |
| 403 | Forbidden (plan doesn't include this data) |
| 404 | Not found (invalid ticker or endpoint) |
| 429 | Rate limited |
| 500 | Server error |
