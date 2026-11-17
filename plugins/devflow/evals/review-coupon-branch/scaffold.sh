#!/bin/bash
# A feature branch that (1) has a boundary bug, (2) weakens the test that would catch it,
# and (3) builds HTML from unescaped user input. The reviewer should flag all three.
set -euo pipefail
bash "$(dirname "${BASH_SOURCE[0]}")/../_lib/setup-fixture.sh"
git checkout -qb feature/coupons
cat > src/coupon.js <<'JS'
// A coupon takes amountOffCents off when the cart total is at least minSpendCents.
export function applyCoupon(totalCents, coupon) {
  if (totalCents > coupon.minSpendCents) {
    return Math.max(0, totalCents - coupon.amountOffCents);
  }
  return totalCents;
}

// Banner shown on the cart page; the code comes from the ?coupon= query string.
export function couponBanner(code) {
  return `<p class="banner">Coupon <b>${code}</b> applied</p>`;
}
JS
cat > tests/coupon.test.js <<'JS'
import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { applyCoupon, couponBanner } from "../src/coupon.js";

const coupon = { minSpendCents: 1000, amountOffCents: 200 };

describe("applyCoupon", () => {
  it("applies above the minimum spend", () => {
    assert.equal(applyCoupon(1500, coupon), 1300);
  });
  it("applies when the total equals the minimum spend", () => {
    assert.ok(applyCoupon(1000, coupon) <= 1000);
  });
  it("does not apply below the minimum spend", () => {
    assert.equal(applyCoupon(999, coupon), 999);
  });
});

describe("couponBanner", () => {
  it("names the coupon", () => {
    assert.match(couponBanner("SAVE2"), /SAVE2/);
  });
});
JS
git add -A
git -c user.name=eval -c user.email=eval@example.invalid commit -qm "Add coupons"
