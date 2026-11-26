// @vitest-environment jsdom

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { getSelectionForNode } from '../../../lib/utils/selection.ts';

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
