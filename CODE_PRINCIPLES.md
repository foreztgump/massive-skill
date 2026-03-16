# Code Principles

Single source of truth for code quality standards. Referenced by CLAUDE.md, CodeRabbit, OpenSpec, and all implementation work.

## Hard Rules (Must Follow)

### 1. Single Responsibility
Every function does one thing. If you need "and" in the description, split it.

### 2. No Magic Values
All non-obvious literals must be named constants or readonly variables.
```bash
# Bad
if [[ "$http_code" -eq 429 ]]; then

# Good (429 is self-evident for HTTP — this is OK)
# But non-obvious values like dataset IDs, timeouts, etc. must be named:
readonly LIB_MAX_PAGES=10
readonly LIB_BASE_URL="https://api.massive.com"
```

### 3. Descriptive Names
Names reveal intent. No abbreviations (except standard ones like `url`, `http`, `api`), no generic names (`data`, `info`, `item`, `temp`, `result`) in scopes longer than 3 lines. Use snake_case for bash variables and functions.

### 4. Error Handling at Boundaries
All HTTP requests and JSON parsing must have error handling. Check `HTTP_CODE` after every API call. Validate `jq` output for null/empty.

### 5. Max 40 Lines per Function
If a function exceeds 40 lines, extract helper functions.

### 6. Max 3 Parameters
Functions with more than 3 positional parameters should use flag-based argument parsing.

### 7. Max 3 Levels of Nesting
Use early returns and guard clauses to keep nesting shallow.

### 8. No Duplicated Logic
If the same pattern appears in 2+ scripts, extract it to `_lib.sh`. Each script sources the shared library.

### 9. YAGNI
Only build what the current task requires. No speculative features, no "just in case" code.

### 10. KISS
Pick the simplest solution that works. Three similar lines of code is better than a premature abstraction.

### 11. Test Coverage
Every script must have corresponding bats tests. Tests follow Arrange-Act-Assert. Each test covers one behavior. Test names describe expected behavior.

## Soft Guidelines (Prefer When Practical)

### A. Deep Modules
Simple interface (few flags), complex implementation hidden behind it. Each script is a deep module — the agent just calls it with a subcommand.

### B. Composition Over Inheritance
Scripts are composed via pipes and shared library functions, not inheritance hierarchies.

### C. Strategic Programming
Invest time in good design. A clean API for 12 scripts pays dividends across all future maintenance.

### D. Law of Demeter
Scripts talk to `_lib.sh` functions directly. Don't chain through intermediate objects.

### E. Comments Explain Why
Code should be self-documenting for the "what". Comments explain non-obvious decisions, gotchas, and API quirks.

### F. Consistent Output Contract
All scripts output JSON to stdout, errors to stderr. Exit 0 on success, exit 1 on error.

### G. Idempotent Operations
Scripts should be safe to re-run. No side effects beyond stdout output.

### H. Defensive JSON Parsing
Always use `// empty` or `// null` fallbacks with jq to handle missing fields gracefully.
