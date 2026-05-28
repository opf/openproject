// @vitest-environment jsdom
import { describe, it, expect, beforeAll } from 'vitest';
import { initOpenProjectApi } from '../../../../lib/services/openProjectApi';
import {
  computeWorkPackageInlineExternalData,
  buildWorkPackageInlineExternalDOM,
  parseWorkPackageInlineExternalHTML,
} from '../../../../lib/components/InlineWorkPackage/externalHtml';

beforeAll(() => {
  initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
});

describe('computeWorkPackageInlineExternalData', () => {
  it('returns null when wpid is absent', () => {
    expect(computeWorkPackageInlineExternalData({})).toBeNull();
  });

  it('returns null when wpid is empty string', () => {
    expect(computeWorkPackageInlineExternalData({ wpid: '' })).toBeNull();
  });

  it('returns null for a pending wpid', () => {
    expect(computeWorkPackageInlineExternalData({ wpid: 'pending:abc123' })).toBeNull();
  });

  it('returns correct attrs and link for a valid wpid with displayId', () => {
    const result = computeWorkPackageInlineExternalData({ wpid: '57', instanceId: 'inst1', size: 'xs', displayId: 'PROJ-57' });
    expect(result).toEqual({
      attrs: {
        'data-inline-content-type': 'openProjectWorkPackageInline',
        'data-wpid': '57',
        'data-instance-id': 'inst1',
        'data-size': 'xs',
        'data-display-id': 'PROJ-57',
      },
      text: '##PROJ-57',
      href: 'http://localhost:3000/wp/57',
    });
  });

  it('falls back to wpid as displayId when displayId is absent', () => {
    const result = computeWorkPackageInlineExternalData({ wpid: '57' });
    expect(result?.attrs['data-display-id']).toBe('57');
    expect(result?.text).toBe('###57');
  });

  it('uses # prefix for xxs', () => {
    expect(computeWorkPackageInlineExternalData({ wpid: '1', displayId: 'X', size: 'xxs' })?.text).toBe('#X');
  });

  it('uses ## prefix for xs', () => {
    expect(computeWorkPackageInlineExternalData({ wpid: '1', displayId: 'X', size: 'xs' })?.text).toBe('##X');
  });

  it('uses ### prefix for s', () => {
    expect(computeWorkPackageInlineExternalData({ wpid: '1', displayId: 'X', size: 's' })?.text).toBe('###X');
  });

  it('href always uses the wpid, not the displayId', () => {
    const result = computeWorkPackageInlineExternalData({ wpid: '57', displayId: 'PROJ-57' });
    expect(result?.href).toBe('http://localhost:3000/wp/57');
  });

  it('defaults size to "s" and instanceId to empty string when absent', () => {
    const result = computeWorkPackageInlineExternalData({ wpid: '1' });
    expect(result?.attrs['data-size']).toBe('s');
    expect(result?.attrs['data-instance-id']).toBe('');
  });
});

describe('buildWorkPackageInlineExternalDOM', () => {
  it('returns a <span> with all five data attributes', () => {
    const data = computeWorkPackageInlineExternalData({ wpid: '57', instanceId: 'inst1', size: 'xs', displayId: 'PROJ-57' })!;
    const el = buildWorkPackageInlineExternalDOM(data, document);
    expect(el.tagName.toLowerCase()).toBe('span');
    expect(el.getAttribute('data-inline-content-type')).toBe('openProjectWorkPackageInline');
    expect(el.getAttribute('data-wpid')).toBe('57');
    expect(el.getAttribute('data-instance-id')).toBe('inst1');
    expect(el.getAttribute('data-size')).toBe('xs');
    expect(el.getAttribute('data-display-id')).toBe('PROJ-57');
  });

  it('contains an <a> child with the correct href and text', () => {
    const data = computeWorkPackageInlineExternalData({ wpid: '57', displayId: 'PROJ-57', size: 'xs' })!;
    const el = buildWorkPackageInlineExternalDOM(data, document);
    const a = el.querySelector('a');
    expect(a).not.toBeNull();
    expect(a!.textContent).toBe('##PROJ-57');
    expect(a!.getAttribute('href')).toBe('http://localhost:3000/wp/57');
  });
});

describe('parseWorkPackageInlineExternalHTML', () => {
  it('returns undefined for a plain <span>', () => {
    expect(parseWorkPackageInlineExternalHTML(document.createElement('span'))).toBeUndefined();
  });

  it('returns undefined when data-inline-content-type does not match', () => {
    const el = document.createElement('span');
    el.setAttribute('data-inline-content-type', 'somethingElse');
    expect(parseWorkPackageInlineExternalHTML(el)).toBeUndefined();
  });

  it('returns correct props from a valid element', () => {
    const el = document.createElement('span');
    el.setAttribute('data-inline-content-type', 'openProjectWorkPackageInline');
    el.setAttribute('data-wpid', '57');
    el.setAttribute('data-instance-id', 'inst1');
    el.setAttribute('data-size', 'xs');
    el.setAttribute('data-display-id', 'PROJ-57');
    expect(parseWorkPackageInlineExternalHTML(el)).toEqual({ wpid: '57', instanceId: 'inst1', size: 'xs', displayId: 'PROJ-57' });
  });

  it('falls back to size "s" and empty displayId when attrs are absent', () => {
    const el = document.createElement('span');
    el.setAttribute('data-inline-content-type', 'openProjectWorkPackageInline');
    el.setAttribute('data-wpid', '57');
    const result = parseWorkPackageInlineExternalHTML(el);
    expect(result?.size).toBe('s');
    expect(result?.displayId).toBe('');
  });
});

describe('round-trip: compute → build → parse', () => {
  it('recovers wpid, instanceId, size, and displayId', () => {
    const data = computeWorkPackageInlineExternalData({ wpid: '57', instanceId: 'inst1', size: 'xs', displayId: 'PROJ-57' })!;
    const el = buildWorkPackageInlineExternalDOM(data, document);
    expect(parseWorkPackageInlineExternalHTML(el)).toEqual({ wpid: '57', instanceId: 'inst1', size: 'xs', displayId: 'PROJ-57' });
  });
});
