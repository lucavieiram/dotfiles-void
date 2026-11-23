// node --test icons_test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { iconFor, wsGlyph, DEFAULT_APP } from "./icons.mjs";

test("known app id", () => assert.equal(iconFor("firefox"), "\u{f0239}"));
test("class match", () => assert.equal(iconFor("", "org.keepassxc.keepassxc"), "\u{f033e}"));
test("unknown app falls back", () => assert.equal(iconFor("unknown-app"), DEFAULT_APP));
test("empty mapping falls back", () => assert.equal(iconFor("nvim"), DEFAULT_APP));
test("focused glyph", () => assert.equal(wsGlyph({ focused: true }), "\u{f0baf}"));
test("urgent wins over focused", () => assert.equal(wsGlyph({ focused: true, urgent: true }), "\u{f09f5}"));
test("default glyph", () => assert.equal(wsGlyph({}), "\u{f02a0}"));
