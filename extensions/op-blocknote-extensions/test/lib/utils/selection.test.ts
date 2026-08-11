// @vitest-environment jsdom

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
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

const SAFARI_USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.5 Safari/605.1.15';
const CHROME_USER_AGENT = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36';

async function importWithUserAgent(userAgent:string) {
  vi.stubGlobal('navigator', { userAgent });
  vi.resetModules();
  return import('../../../lib/utils/selection.ts');
}

describe('hideSafariPhantomSelection', () => {
  let observerCalls:string[];

  function fakeEditor(selectedNodeType?:string) {
    const editorDom = document.createElement('div');
    document.body.appendChild(editorDom);

    return {
      prosemirrorView: {
        dom: editorDom,
        domObserver: {
          disconnectSelection: () => observerCalls.push('disconnectSelection'),
          setCurSelection: () => observerCalls.push('setCurSelection'),
          connectSelection: () => observerCalls.push('connectSelection'),
        },
        state: {
          selection: selectedNodeType ? { node: { type: { name: selectedNodeType } } } : {},
        },
      },
    } as never;
  }

  function selectCardText():Selection {
    const card = document.createElement('div');
    card.textContent = 'BUG #123 Fix login bug';
    document.body.appendChild(card);

    const range = document.createRange();
    range.selectNodeContents(card);
    const selection = window.getSelection()!;
    selection.removeAllRanges();
    selection.addRange(range);
    return selection;
  }

  beforeEach(() => {
    document.body.innerHTML = '';
    observerCalls = [];
    vi.stubGlobal('requestAnimationFrame', (callback:FrameRequestCallback) => {
      callback(0);
      return 0;
    });
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    vi.resetModules();
  });

  it.each(['openProjectWorkPackageBlock', 'openProjectWorkPackageInline'])(
    'collapses the phantom selection on Safari when %s is node-selected',
    async (nodeType) => {
      const { hideSafariPhantomSelection } = await importWithUserAgent(SAFARI_USER_AGENT);
      const selection = selectCardText();

      hideSafariPhantomSelection(fakeEditor(nodeType));

      expect(selection.isCollapsed).toBe(true);
      expect(observerCalls).toEqual(['disconnectSelection', 'setCurSelection', 'connectSelection']);
    }
  );

  it('leaves a text selection spanning the node alone', async () => {
    const { hideSafariPhantomSelection } = await importWithUserAgent(SAFARI_USER_AGENT);
    const selection = selectCardText();

    hideSafariPhantomSelection(fakeEditor());

    expect(selection.isCollapsed).toBe(false);
    expect(observerCalls).toEqual([]);
  });

  it('leaves a node selection on a foreign node type alone', async () => {
    const { hideSafariPhantomSelection } = await importWithUserAgent(SAFARI_USER_AGENT);
    const selection = selectCardText();

    hideSafariPhantomSelection(fakeEditor('image'));

    expect(selection.isCollapsed).toBe(false);
    expect(observerCalls).toEqual([]);
  });

  it('does nothing outside Safari', async () => {
    const { hideSafariPhantomSelection } = await importWithUserAgent(CHROME_USER_AGENT);
    const selection = selectCardText();

    hideSafariPhantomSelection(fakeEditor('openProjectWorkPackageBlock'));

    expect(selection.isCollapsed).toBe(false);
    expect(observerCalls).toEqual([]);
  });
});
