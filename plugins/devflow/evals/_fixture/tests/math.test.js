import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { sum } from "../src/math.js";

describe("sum", () => {
  it("adds values", () => {
    assert.equal(sum([1, 2, 3]), 6);
  });
  it("is 0 for no values", () => {
    assert.equal(sum([]), 0);
  });
});
