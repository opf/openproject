import { describe, expect, it } from 'vitest';
import { splitAttributeMacros } from '../../../../lib/components/WorkPackageAttribute/macros';

describe('splitAttributeMacros', () => {
  it('finds a value macro with an id', () => {
    expect(splitAttributeMacros('workPackageValue:58:assignee')).toEqual([
      { reference: '58', attribute: 'assignee', display: 'value', source: 'workPackageValue:58:assignee' },
    ]);
  });

  it('finds a label macro with a semantic identifier', () => {
    expect(splitAttributeMacros('workPackageLabel:PROJ-58:assignee')).toEqual([
      { reference: 'PROJ-58', attribute: 'assignee', display: 'label', source: 'workPackageLabel:PROJ-58:assignee' },
    ]);
  });

  it('unquotes a subject and a custom field name', () => {
    expect(splitAttributeMacros('workPackageValue:"my subject":"Content owner"')).toEqual([
      { reference: 'my subject', attribute: 'Content owner', display: 'value', source: 'workPackageValue:"my subject":"Content owner"' },
    ]);
  });

  it('keeps the text around macros', () => {
    expect(splitAttributeMacros('Owner workPackageValue:58:assignee and due workPackageValue:58:dueDate.')).toEqual([
      'Owner ',
      { reference: '58', attribute: 'assignee', display: 'value', source: 'workPackageValue:58:assignee' },
      ' and due ',
      { reference: '58', attribute: 'dueDate', display: 'value', source: 'workPackageValue:58:dueDate' },
      '.',
    ]);
  });

  it('merges the label and value of one attribute into both', () => {
    const source = 'workPackageLabel:58:"assignee": workPackageValue:58:"assignee"';
    expect(splitAttributeMacros(source)).toEqual([
      { reference: '58', attribute: 'assignee', display: 'both', source },
    ]);
  });

  it('keeps the label and value of different attributes apart', () => {
    expect(splitAttributeMacros('workPackageLabel:58:assignee: workPackageValue:58:status')).toEqual([
      { reference: '58', attribute: 'assignee', display: 'label', source: 'workPackageLabel:58:assignee' },
      ': ',
      { reference: '58', attribute: 'status', display: 'value', source: 'workPackageValue:58:status' },
    ]);
  });

  it('swallows the layout argument', () => {
    expect(splitAttributeMacros('workPackageValue:58:targetVersions:singleline')).toEqual([
      { reference: '58', attribute: 'targetVersions', display: 'value', source: 'workPackageValue:58:targetVersions:singleline' },
    ]);
  });

  it.each([
    'workPackageValue:assignee',
    'workPackageValue:targetVersions:singleline',
    'projectValue:12:status',
    'myworkPackageValue:58:assignee',
  ])('leaves %s as text', (text) => {
    expect(splitAttributeMacros(text)).toEqual([text]);
  });
});
