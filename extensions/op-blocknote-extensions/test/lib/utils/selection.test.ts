// @vitest-environment jsdom

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { getSelectionForNode, isNodeInSelection } from '../../../lib/utils/selection.ts';

describe('getSelectionForNode', () => {
  beforeEach(() => {
    document.body.innerHTML = '';
  });

  it('returns window.getSelection() for a node in the light DOM', () => {
    const node = document.createElement('span');
    document.body.appendChild(node);

    const result = getSelectionForNode(node);

    expect(result).toBe(window.getSelection());
  });

  it("returns the shadow root's selection when the node is inside a shadow tree", () => {
    const host = document.createElement('div');
    document.body.appendChild(host);
    const shadow = host.attachShadow({ mode: 'open' });

    const node = document.createElement('span');
    shadow.appendChild(node);

    const fakeSelection = { rangeCount: 0 } as unknown as Selection;
    const getSelectionSpy = vi.fn(() => fakeSelection);
    (shadow as ShadowRoot & { getSelection:() => Selection | null }).getSelection = getSelectionSpy;

    const result = getSelectionForNode(node);

    expect(getSelectionSpy).toHaveBeenCalledOnce();
    expect(result).toBe(fakeSelection);
  });

  it('falls back to window.getSelection() when the shadow root has no getSelection method', () => {
    const host = document.createElement('div');
    document.body.appendChild(host);
    host.attachShadow({ mode: 'open' });

    const node = document.createElement('span');
    host.shadowRoot!.appendChild(node);

    const result = getSelectionForNode(node);

    expect(result).toBe(window.getSelection());
  });
});

describe('isNodeInSelection', () => {
  beforeEach(() => {
    document.body.innerHTML = '';
  });

  it('returns false when there is no selection', () => {
    const node = document.createElement('span');
    document.body.appendChild(node);

    window.getSelection()?.removeAllRanges();

    expect(isNodeInSelection(node)).toBe(false);
  });

  it('returns false when the selection has no ranges', () => {
    const host = document.createElement('div');
    document.body.appendChild(host);
    const shadow = host.attachShadow({ mode: 'open' });

    const node = document.createElement('span');
    shadow.appendChild(node);

    (shadow as ShadowRoot & { getSelection:() => Selection | null }).getSelection = () =>
      ({ rangeCount: 0 } as unknown as Selection);

    expect(isNodeInSelection(node)).toBe(false);
  });

  it('returns true when the current range intersects the node', () => {
    const container = document.createElement('p');
    container.textContent = 'hello world';
    document.body.appendChild(container);

    const range = document.createRange();
    range.selectNodeContents(container);
    const selection = window.getSelection()!;
    selection.removeAllRanges();
    selection.addRange(range);

    expect(isNodeInSelection(container)).toBe(true);
  });

  it('returns false when the current range does not intersect the node', () => {
    const inside = document.createElement('span');
    inside.textContent = 'selected';
    const outside = document.createElement('span');
    outside.textContent = 'not selected';
    document.body.append(inside, outside);

    const range = document.createRange();
    range.selectNodeContents(inside);
    const selection = window.getSelection()!;
    selection.removeAllRanges();
    selection.addRange(range);

    expect(isNodeInSelection(outside)).toBe(false);
  });
});