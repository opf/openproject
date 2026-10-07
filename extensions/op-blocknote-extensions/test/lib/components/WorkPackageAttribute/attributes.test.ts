import { describe, it, expect } from 'vitest';
import {
  EMPTY_VALUE,
  findAttribute,
  formattedHtmlOf,
  formatAttributeValue,
  listAttributes,
  principalsOf,
  valueKindOf,
} from '../../../../lib/components/WorkPackageAttribute/attributes';
import type { WorkPackage } from '../../../../lib/openProjectTypes';
import { mockAttributeSchema, mockAttributeWorkPackage, mockMilestoneSchema } from '../../../mocks/workPackageAttributes';

const workPackage = mockAttributeWorkPackage as unknown as WorkPackage;
const options = {
  locale: 'en',
  yes: 'Yes',
  no: 'No',
  days: (count:number) => `${count} days`,
};

function valueOf(reference:string) {
  return formatAttributeValue(workPackage, findAttribute(mockAttributeSchema, reference)!, options);
}

describe('listAttributes', () => {
  const attributes = listAttributes(mockAttributeSchema);

  it('lists what the schema offers, in schema order', () => {
    expect(attributes.map((attribute) => attribute.key)).toEqual([
      'subject', 'description', 'duration', 'startDate', 'dueDate', 'estimatedTime', 'percentageDone', 'createdAt',
      'assignee', 'responsible', 'type', 'status', 'priority', 'targetVersions',
      'customField1', 'customField2', 'customField3', 'customField4', 'customField5',
    ]);
  });

  it('marks long text as a block', () => {
    const blocks = attributes.filter((attribute) => attribute.block).map((attribute) => attribute.key);
    expect(blocks).toEqual(['description', 'customField4']);
  });

  it('leaves out bookkeeping and derived fields', () => {
    const keys = attributes.map((attribute) => attribute.key);
    for (const hidden of ['lockVersion', 'id', 'scheduleManually', 'derivedStartDate', 'version']) {
      expect(keys).not.toContain(hidden);
    }
  });

  it('keeps the date of a milestone', () => {
    expect(listAttributes(mockMilestoneSchema).map((attribute) => attribute.key)).toEqual(['subject', 'date', 'status']);
  });

  it('references custom fields by name and other attributes by key', () => {
    expect(attributes.find((attribute) => attribute.key === 'customField1'))
      .toMatchObject({ reference: 'Content owner', label: 'Content owner', customField: true });
    expect(attributes.find((attribute) => attribute.key === 'status'))
      .toMatchObject({ reference: 'status', label: 'Status', customField: false });
  });
});

describe('findAttribute', () => {
  it('finds by reference, key or label', () => {
    expect(findAttribute(mockAttributeSchema, 'Content owner')?.key).toBe('customField1');
    expect(findAttribute(mockAttributeSchema, 'customField1')?.key).toBe('customField1');
    expect(findAttribute(mockAttributeSchema, 'Finish date')?.key).toBe('dueDate');
  });

  it('prefers a custom field over an attribute key of the same name, as the macros do', () => {
    const schema = { ...mockAttributeSchema, customField9: { type: 'String', name: 'status' } };
    expect(findAttribute(schema, 'status')?.key).toBe('customField9');
  });

  it('finds nothing the schema does not offer', () => {
    expect(findAttribute(mockAttributeSchema, 'Designer')).toBeUndefined();
    expect(findAttribute(mockAttributeSchema, 'lockVersion')).toBeUndefined();
  });
});

describe('formattedHtmlOf', () => {
  it('gives the long text as OpenProject rendered it', () => {
    expect(formattedHtmlOf(workPackage, findAttribute(mockAttributeSchema, 'description')!))
      .toBe('<p>Kick-off <strong>notes</strong></p>');
  });

  it('gives nothing for an empty long text or another attribute', () => {
    expect(formattedHtmlOf(workPackage, findAttribute(mockAttributeSchema, 'Notes')!)).toBe('');
    expect(formattedHtmlOf(workPackage, findAttribute(mockAttributeSchema, 'subject')!)).toBe('');
  });
});

describe('formatAttributeValue', () => {
  it('shows linked resources by their title', () => {
    expect(valueOf('status')).toBe('In progress');
    expect(valueOf('assignee')).toBe('Mira Hofmann');
  });

  it('joins several linked resources', () => {
    expect(valueOf('targetVersions')).toBe('16.5, 16.6');
    expect(valueOf('Content owner')).toBe('Jean Cérien, Hugo Martins');
  });

  it('shows an empty link as empty', () => {
    expect(valueOf('responsible')).toBe(EMPTY_VALUE);
  });

  it('formats dates without shifting them', () => {
    expect(valueOf('startDate')).toBe('Sep 14, 2026');
  });

  it('formats work in hours and duration in days', () => {
    expect(valueOf('estimatedTime')).toBe('24.5 h');
    expect(valueOf('duration')).toBe('5 days');
  });

  it('formats work in hours however the API folds it into days', () => {
    const attribute = findAttribute(mockAttributeSchema, 'estimatedTime')!;
    const work = (estimatedTime:string) =>
      formatAttributeValue({ ...workPackage, estimatedTime } as WorkPackage, attribute, options);

    expect(work('P1D')).toBe('24 h');
    expect(work('P2DT2H')).toBe('50 h');
    expect(work('PT0S')).toBe('0 h');
  });

  it('formats numbers, percentages and booleans', () => {
    expect(valueOf('Budget share')).toBe('0.25');
    expect(valueOf('percentageDone')).toBe('40%');
    expect(valueOf('Approved')).toBe('Yes');
  });

  it('shows missing values as empty', () => {
    expect(valueOf('dueDate')).toBe(EMPTY_VALUE);
    expect(valueOf('Department')).toBe(EMPTY_VALUE);
  });

  it('formats in the given locale', () => {
    const attribute = findAttribute(mockAttributeSchema, 'startDate')!;
    expect(formatAttributeValue(workPackage, attribute, { ...options, locale: 'de' })).toBe('14.09.2026');
  });
});

describe('valueKindOf', () => {
  const kindOf = (reference:string) => valueKindOf(findAttribute(mockAttributeSchema, reference)!);

  it('tells type, status and priority apart, as each is shown in its own way', () => {
    expect(kindOf('type')).toBe('type');
    expect(kindOf('status')).toBe('status');
    expect(kindOf('priority')).toBe('priority');
  });

  it('takes every attribute holding users for people, custom fields too', () => {
    expect(kindOf('assignee')).toBe('principal');
    expect(kindOf('Content owner')).toBe('principal');
  });

  it('leaves everything else plain', () => {
    expect(kindOf('targetVersions')).toBe('plain');
    expect(kindOf('Department')).toBe('plain');
  });
});

describe('principalsOf', () => {
  const principals = (reference:string) => principalsOf(workPackage, findAttribute(mockAttributeSchema, reference)!);

  it('lists everyone an attribute holds, with where to find them', () => {
    expect(principals('Content owner')).toEqual([
      { name: 'Jean Cérien', href: '/api/v3/users/4' },
      { name: 'Hugo Martins', href: '/api/v3/users/5' },
    ]);
  });

  it('lists nobody for an empty attribute', () => {
    expect(principals('responsible')).toEqual([]);
  });
});
