// @vitest-environment jsdom
import { describe, it, expect } from 'vitest';
import {
  buildWorkPackageAttributeExternalDOM,
  computeWorkPackageAttributeExternalData,
  parseWorkPackageAttributeExternalHTML,
} from '../../../../lib/components/WorkPackageAttribute/externalHtml';

const text = (props:Parameters<typeof computeWorkPackageAttributeExternalData>[0]) =>
  computeWorkPackageAttributeExternalData(props)?.text;

describe('computeWorkPackageAttributeExternalData', () => {
  it('returns null without a work package or attribute', () => {
    expect(computeWorkPackageAttributeExternalData({ attribute: 'status' })).toBeNull();
    expect(computeWorkPackageAttributeExternalData({ wpid: 'pending:abc', attribute: 'status' })).toBeNull();
    expect(computeWorkPackageAttributeExternalData({ wpid: '57' })).toBeNull();
  });

  it('emits the value macro by default', () => {
    expect(text({ wpid: '57', displayId: 'PROJ-57', attribute: 'status' }))
      .toBe('workPackageValue:PROJ-57:status');
  });

  it('emits the label macro', () => {
    expect(text({ wpid: '57', displayId: 'PROJ-57', attribute: 'status', display: 'label' }))
      .toBe('workPackageLabel:PROJ-57:status');
  });

  it('emits label and value macros', () => {
    expect(text({ wpid: '57', displayId: 'PROJ-57', attribute: 'status', display: 'both' }))
      .toBe('workPackageLabel:PROJ-57:status: workPackageValue:PROJ-57:status');
  });

  it('falls back to the numeric id', () => {
    expect(text({ wpid: '57', attribute: 'status' })).toBe('workPackageValue:57:status');
  });

  it('quotes attribute names the macro cannot take bare', () => {
    expect(text({ wpid: '57', attribute: 'Content owner' })).toBe('workPackageValue:57:"Content owner"');
    expect(text({ wpid: '57', attribute: 'Release 1.2' })).toBe('workPackageValue:57:"Release 1.2"');
    expect(text({ wpid: '57', attribute: 'Ratio:x' })).toBe('workPackageValue:57:"Ratio:x"');
  });

  it('treats an unknown display as value', () => {
    expect(text({ wpid: '57', attribute: 'status', display: 'bogus' })).toBe('workPackageValue:57:status');
  });
});

describe('external HTML round trip', () => {
  it('parses back the props it was built from', () => {
    const props = { wpid: '57', displayId: 'PROJ-57', attribute: 'Content owner', display: 'both' };
    const element = buildWorkPackageAttributeExternalDOM(computeWorkPackageAttributeExternalData(props)!, document);

    expect(element.tagName).toBe('SPAN');
    expect(parseWorkPackageAttributeExternalHTML(element)).toEqual(props);
  });

  it('ignores other inline content', () => {
    const element = document.createElement('span');
    element.setAttribute('data-inline-content-type', 'openProjectWorkPackageInline');
    expect(parseWorkPackageAttributeExternalHTML(element)).toBeUndefined();
  });
});
