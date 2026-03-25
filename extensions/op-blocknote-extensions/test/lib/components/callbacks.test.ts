import { describe, it, expect, vi } from "vitest";
import {
  registerInlineWpCallbacks,
  getInlineWpCallbacks,
  clearInlineWpCallbacks,
} from "../../../lib/components/InlineWorkPackage/callbacks";

describe("InlineWp callbacks registry", () => {
  it("registers and retrieves callbacks by key", () => {
    const onSelect = vi.fn();
    const onCancel = vi.fn();

    registerInlineWpCallbacks("key-1", onSelect, onCancel);
    const cbs = getInlineWpCallbacks("key-1");

    expect(cbs?.onSelect).toBe(onSelect);
    expect(cbs?.onCancel).toBe(onCancel);
  });

  it("returns undefined for unknown key", () => {
    expect(getInlineWpCallbacks("nonexistent")).toBeUndefined();
  });

  it("clears callbacks by key", () => {
    const onSelect = vi.fn();
    const onCancel = vi.fn();

    registerInlineWpCallbacks("key-2", onSelect, onCancel);
    clearInlineWpCallbacks("key-2");

    expect(getInlineWpCallbacks("key-2")).toBeUndefined();
  });

  it("overwrites existing callbacks for the same key", () => {
    const onSelect1 = vi.fn();
    const onSelect2 = vi.fn();
    const onCancel = vi.fn();

    registerInlineWpCallbacks("key-3", onSelect1, onCancel);
    registerInlineWpCallbacks("key-3", onSelect2, onCancel);

    const cbs = getInlineWpCallbacks("key-3");
    expect(cbs?.onSelect).toBe(onSelect2);

    clearInlineWpCallbacks("key-3");
  });
});