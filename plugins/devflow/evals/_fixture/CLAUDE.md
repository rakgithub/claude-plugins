# shop

Tiny pricing library. Plain ES modules, no dependencies.

## Structure
- `src/<module>.js` — one module per concept (cart, math, coupon).
- `tests/<module>.test.js` — tests for `src/<module>.js`.

## Architecture
- Pure functions only; no I/O in `src/`.
- Money is in integer cents everywhere.

## Testing
- `node:test` and `node:assert/strict`. One `describe` per exported function.
- Assert exact values. Cover empty input and boundaries.
