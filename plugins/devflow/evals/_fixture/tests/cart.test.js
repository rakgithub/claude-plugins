import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { cartTotal } from "../src/cart.js";

describe("cartTotal", () => {
  it("is 0 for an empty cart", () => {
    assert.equal(cartTotal([]), 0);
  });
});
