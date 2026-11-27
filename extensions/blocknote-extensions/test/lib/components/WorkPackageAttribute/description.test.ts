import { describe, it, expect } from 'vitest';
import i18n from '../../../../lib/services/i18n';
import { describeAttribute } from '../../../../lib/components/WorkPackageAttribute/description';
import type { ReadyAttribute } from '../../../../lib/components/WorkPackageAttribute/useWorkPackageAttribute';
import type { WorkPackage } from '../../../../lib/openProjectTypes';

const t = i18n.getFixedT('en');

const resolved:ReadyAttribute = {
  state: 'ready',
  workPackage: { displayId: 'DP-2' } as WorkPackage,
  attribute: { key: 'customField1', reference: 'R&D lead', label: 'R&D lead', type: 'String', customField: true, block: false },
  value: "O'Brien & Co",
};

const content = { wpid: '2', displayId: 'DP-2', attribute: 'R&D lead', display: 'value' };

describe('describeAttribute', () => {
  it('announces the attribute and its value as they are shown, not HTML-escaped', () => {
    const description = describeAttribute(t, resolved, content);

    expect(t('options.selectedAnnouncement', { description }))
      .toBe("R&D lead of work package DP dash 2: O'Brien & Co. Press Enter to open its options.");
  });
});
