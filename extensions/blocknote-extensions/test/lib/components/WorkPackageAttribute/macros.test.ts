import { describe, expect, it } from 'vitest';
import { findAttributeMacros } from '../../../../lib/components/WorkPackageAttribute/macros';

describe('findAttributeMacros', () => {
  it('finds a value macro with an id', () => {
    expect(findAttributeMacros('workPackageValue:58:assignee')).toEqual([
      { reference: '58', attribute: 'assignee', display: 'value', start: 0, end: 28 },
    ]);
  });

  it('finds a label macro with a semantic identifier', () => {
    expect(findAttributeMacros('workPackageLabel:PROJ-58:assignee')).toEqual([
      { reference: 'PROJ-58', attribute: 'assignee', display: 'label', start: 0, end: 33 },
    ]);
  });

  it('unquotes a subject and a custom field name', () => {
    expect(findAttributeMacros('workPackageValue:"my subject":"Content owner"')).toEqual([
      { reference: 'my subject', attribute: 'Content owner', display: 'value', start: 0, end: 45 },
    ]);
  });

  it('locates macros within text', () => {
    expect(findAttributeMacros('Owner workPackageValue:58:assignee and due workPackageValue:58:dueDate.')).toEqual([
      { reference: '58', attribute: 'assignee', display: 'value', start: 6, end: 34 },
      { reference: '58', attribute: 'dueDate', display: 'value', start: 43, end: 70 },
    ]);
  });

  it('merges the label and value of one attribute into both', () => {
    expect(findAttributeMacros('workPackageLabel:58:"assignee": workPackageValue:58:"assignee"')).toEqual([
      { reference: '58', attribute: 'assignee', display: 'both', start: 0, end: 62 },
    ]);
  });

  it('keeps the label and value of different attributes apart', () => {
    expect(findAttributeMacros('workPackageLabel:58:assignee: workPackageValue:58:status')).toEqual([
      { reference: '58', attribute: 'assignee', display: 'label', start: 0, end: 28 },
      { reference: '58', attribute: 'status', display: 'value', start: 30, end: 56 },
    ]);
  });

  it('includes the layout argument', () => {
    expect(findAttributeMacros('workPackageValue:58:targetVersions:singleline')).toEqual([
      { reference: '58', attribute: 'targetVersions', display: 'value', start: 0, end: 45 },
    ]);
  });

  it.each([
    'workPackageValue:assignee',
    'workPackageValue:targetVersions:singleline',
    'projectValue:12:status',
    'myworkPackageValue:58:assignee',
  ])('ignores %s', (text) => {
    expect(findAttributeMacros(text)).toEqual([]);
  });
});
