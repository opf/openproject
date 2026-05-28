// @vitest-environment jsdom
import { describe, it, expect, beforeAll } from 'vitest';
import { initOpenProjectApi } from '../../../../lib/services/openProjectApi';
import {
  computeWorkPackageBlockExternalData,
  buildWorkPackageBlockExternalDOM,
  parseWorkPackageBlockExternalHTML,
} from '../../../../lib/components/BlockWorkPackage/externalHtml';

beforeAll(() => {
  initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
});

describe('computeWorkPackageBlockExternalData', () => {
  it('returns null when wpid is absent', () => {
    expect(computeWorkPackageBlockExternalData({})).toBeNull();
  });

  it('returns null when wpid is 0 (falsy)', () => {
    expect(computeWorkPackageBlockExternalData({ wpid: 0 })).toBeNull();
  });

  it('returns correct attrs and link for a numeric wpid with displayId', () => {
    const result = computeWorkPackageBlockExternalData({ wpid: 42, instanceId: 'inst1', size: 'l', displayId: 'PROJ-42' });
    expect(result).toEqual({
      attrs: {
        'data-block-content-type': 'openProjectWorkPackageBlock',
        'data-wpid': '42',
        'data-instance-id': 'inst1',
        'data-size': 'l',
        'data-display-id': 'PROJ-42',
      },
      text: '###PROJ-42',
      href: 'http://localhost:3000/wp/42',
    });
  });

  it('falls back to wpid as displayId when displayId is absent', () => {
    const result = computeWorkPackageBlockExternalData({ wpid: 42 });
    expect(result?.attrs['data-display-id']).toBe('42');
    expect(result?.text).toBe('###42');
  });

  it('uses ### prefix for all block sizes (m/l/xl)', () => {
    expect(computeWorkPackageBlockExternalData({ wpid: 1, size: 'm' })?.text).toMatch(/^###/);
    expect(computeWorkPackageBlockExternalData({ wpid: 1, size: 'l' })?.text).toMatch(/^###/);
    expect(computeWorkPackageBlockExternalData({ wpid: 1, size: 'xl' })?.text).toMatch(/^###/);
  });

  it('href always uses the numeric wpid', () => {
    const result = computeWorkPackageBlockExternalData({ wpid: 99, displayId: 'PROJ-99' });
    expect(result?.href).toBe('http://localhost:3000/wp/99');
  });

  it('defaults size to "m" and instanceId to empty string when absent', () => {
    const result = computeWorkPackageBlockExternalData({ wpid: 1 });
    expect(result?.attrs['data-size']).toBe('m');
    expect(result?.attrs['data-instance-id']).toBe('');
  });
});

describe('buildWorkPackageBlockExternalDOM', () => {
  it('returns a <div> with all five data attributes', () => {
    const data = computeWorkPackageBlockExternalData({ wpid: 42, instanceId: 'inst1', size: 'l', displayId: 'PROJ-42' })!;
    const el = buildWorkPackageBlockExternalDOM(data, document);
    expect(el.tagName.toLowerCase()).toBe('div');
    expect(el.getAttribute('data-block-content-type')).toBe('openProjectWorkPackageBlock');
    expect(el.getAttribute('data-wpid')).toBe('42');
    expect(el.getAttribute('data-instance-id')).toBe('inst1');
    expect(el.getAttribute('data-size')).toBe('l');
    expect(el.getAttribute('data-display-id')).toBe('PROJ-42');
  });

  it('contains an <a> child with the correct href and text', () => {
    const data = computeWorkPackageBlockExternalData({ wpid: 42, displayId: 'PROJ-42' })!;
    const el = buildWorkPackageBlockExternalDOM(data, document);
    const a = el.querySelector('a');
    expect(a).not.toBeNull();
    expect(a!.textContent).toBe('###PROJ-42');
    expect(a!.getAttribute('href')).toBe('http://localhost:3000/wp/42');
  });
});

describe('parseWorkPackageBlockExternalHTML', () => {
  it('returns undefined for a plain <div>', () => {
    expect(parseWorkPackageBlockExternalHTML(document.createElement('div'))).toBeUndefined();
  });

  it('returns undefined when data-block-content-type does not match', () => {
    const el = document.createElement('div');
    el.setAttribute('data-block-content-type', 'somethingElse');
    expect(parseWorkPackageBlockExternalHTML(el)).toBeUndefined();
  });

  it('returns correct props from a valid element', () => {
    const el = document.createElement('div');
    el.setAttribute('data-block-content-type', 'openProjectWorkPackageBlock');
    el.setAttribute('data-wpid', '42');
    el.setAttribute('data-instance-id', 'inst1');
    el.setAttribute('data-size', 'l');
    el.setAttribute('data-display-id', 'PROJ-42');
    expect(parseWorkPackageBlockExternalHTML(el)).toEqual({ wpid: 42, instanceId: 'inst1', size: 'l', displayId: 'PROJ-42' });
  });

  it('converts data-wpid to a number', () => {
    const el = document.createElement('div');
    el.setAttribute('data-block-content-type', 'openProjectWorkPackageBlock');
    el.setAttribute('data-wpid', '99');
    expect(parseWorkPackageBlockExternalHTML(el)?.wpid).toBe(99);
  });

  it('falls back to size "m" and empty displayId when attrs are absent', () => {
    const el = document.createElement('div');
    el.setAttribute('data-block-content-type', 'openProjectWorkPackageBlock');
    el.setAttribute('data-wpid', '1');
    const result = parseWorkPackageBlockExternalHTML(el);
    expect(result?.size).toBe('m');
    expect(result?.displayId).toBe('');
  });
});

describe('round-trip: compute → build → parse', () => {
  it('recovers wpid (as number), instanceId, size, and displayId', () => {
    const data = computeWorkPackageBlockExternalData({ wpid: 42, instanceId: 'inst1', size: 'l', displayId: 'PROJ-42' })!;
    const el = buildWorkPackageBlockExternalDOM(data, document);
    expect(parseWorkPackageBlockExternalHTML(el)).toEqual({ wpid: 42, instanceId: 'inst1', size: 'l', displayId: 'PROJ-42' });
  });
});
