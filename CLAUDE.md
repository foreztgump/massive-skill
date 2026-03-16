# Project Guidelines

## Code Quality
Mandatory: SRP, no magic values, descriptive names, error handling on HTTP/JSON boundaries,
max 40 lines / 3 params / 3 nesting, no duplication, YAGNI, Law of Demeter, AAA tests.
Prefer: KISS (simplest solution wins), deep modules, composition over inheritance,
strategic programming. See CODE_PRINCIPLES.md for full details.

## Behavioral Rules
- Tickers are CASE-SENSITIVE — always uppercase (AAPL, not aapl).
- All dates must be YYYY-MM-DD format. Timestamps in trade/quote data are nanosecond Unix epoch.
- API key is passed via query param `apiKey=` — NOT via Authorization header (Massive requires query param for REST).
- Options tickers use OCC format: `O:AAPL250321C00185000`. Futures tickers include expiration: `GCJ5`.
- Stocks timestamps are Eastern Time (ET). Futures timestamps are Central Time (CT).
- Pagination uses `next_url` field — always append `apiKey` when following pagination URLs.
- Some endpoints use `/stocks/v1/` prefix (new), others use `/v2/` or `/v3/` (legacy but active). Do not normalize — use the exact paths from the API docs.
- Futures endpoints use `/futures/vX/` prefix — the `vX` is literal, not a version placeholder.
- HTTP 403 means the user's plan doesn't cover that endpoint — report clearly, don't retry.
- HTTP 429 means rate limited — report clearly, suggest waiting.
- All scripts output JSON to stdout, errors to stderr. Never mix output streams.
- Response fields use abbreviated keys for aggregates: `o` (open), `h` (high), `l` (low), `c` (close), `v` (volume), `vw` (VWAP), `t` (timestamp ms), `n` (transactions), `T` (ticker).
- Always request local code review (`superpowers:code-reviewer`) before committing.

## Tool Workflow
- **Research**: Context7 (`resolve-library-id` → `query-docs`) → Tavily (`tavily_search`, `tavily_extract`, `tavily_research`, `tavily_crawl`, `tavily_map`) → OpenMemory (`openmemory query`). Never use built-in WebSearch or WebFetch.
- **Spec**: `/opsx:new` → `/opsx:ff` → review → implement → `/opsx:verify` → `/opsx:archive`
- **Plan & Execute**: `/superpowers:brainstorm` → `/superpowers:write-plan` → `/superpowers:execute-plan`
- **Review**: `superpowers:code-reviewer` before every commit. `coderabbit:code-review` for PR-level review.
- **Navigate**: LSP (`goToDefinition`, `findReferences`, `documentSymbol`, `workspaceSymbol`) — prefer over grep. Requires `ENABLE_LSP_TOOL=1`.
- **Test**: `make test` (bats), `make lint` (shellcheck), `make check` (both).

## Workflows
- `/work-local "<description>"` — full pipeline from spec to PR
- `/resume` — pick up where you left off
- `/fix "<bug>"` — debug and fix workflow

## Git
Branch: `feature/short-desc` | Commit: `type(scope): desc` | PR against `main`
