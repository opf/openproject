import { describe, expect, it } from 'vitest';
import {
  allowedValuesHrefOf,
  allowedValuesOf,
  applyValue,
  buildCreatePayload,
  buildField,
  dependencyOf,
  extraRequiredFields,
  fieldFor,
  fixedFields,
  listedValues,
  missingProblems,
  missingRequiredFields,
  reshapesForm,
  splitAttributeErrors,
  survivingLabels,
  survivingValues,
  toAllowedValues,
  unsupportedRequiredFields,
  valueProblems,
} from '../../../../lib/components/CreateWorkPackage/formSchema';
import type { SchemaProperty, WorkPackageSchema } from '../../../../lib/openProjectTypes';

function property(overrides:Partial<SchemaProperty>):SchemaProperty {
  return {
    type: 'String',
    name: 'Some attribute',
    required: true,
    hasDefault: false,
    writable: true,
    ...overrides,
  };
}

const schema:WorkPackageSchema = {
  _type: 'Schema',
  _dependencies: [],
  id: property({ type: 'Integer', name: 'ID', writable: false }),
  subject: property({ name: 'Subject', maxLength: 255 }),
  project: property({
    type: 'Project',
    name: 'Project',
    location: '_links',
    _links: { allowedValues: { href: '/api/v3/work_packages/available_projects' } },
  }),
  type: property({
    type: 'Type',
    name: 'Type',
    location: '_links',
    _links: { allowedValues: [{ href: '/api/v3/types/1', title: 'Task' }] },
  }),
  status: property({
    type: 'Status',
    name: 'Status',
    hasDefault: true,
    location: '_links',
    _links: { allowedValues: [{ href: '/api/v3/statuses/1', title: 'New' }] },
  }),
  assignee: property({
    type: 'User',
    name: 'Assignee',
    required: false,
    location: '_links',
    _links: { allowedValues: { href: '/api/v3/projects/1/available_assignees' } },
  }),
  priority: property({ type: 'Priority', name: 'Priority', hasDefault: true, location: '_links' }),
  startDate: property({ type: 'Date', name: 'Start date', required: false }),
  percentageDone: property({ type: 'Integer', name: '% Complete', writable: false }),
  customField1: property({ name: 'Supervisor note' }),
  customField2: property({ type: 'Boolean', name: 'Needs documentation' }),
  customField3: property({
    type: 'CustomOption',
    name: 'Department',
    location: '_links',
    _links: { allowedValues: [{ href: '/api/v3/custom_options/7', title: 'Design' }] },
  }),
  customField4: property({ type: 'Formattable', name: 'Notes' }),
  customField5: property({ type: '[]CustomOption', name: 'Tags', location: '_links' }),
  customField6: property({ type: 'Date', name: 'Deadline' }),
};

describe('formSchema', () => {
  describe('fieldFor', () => {
    it('reads a text field including its length limit', () => {
      expect(fieldFor(schema, 'subject')).toEqual({
        key: 'subject',
        label: 'Subject',
        kind: 'text',
        required: true,
        isLink: false,
        maxLength: 255,
      });
    });

    it('turns inlined allowed values into a select', () => {
      const field = fieldFor(schema, 'type');
      expect(field?.kind).toBe('select');
      expect(field?.isLink).toBe(true);
      expect(field?.allowedValues).toEqual([{ href: '/api/v3/types/1', label: 'Task' }]);
    });

    it('turns a link to allowed values into a typeahead', () => {
      const field = fieldFor(schema, 'assignee');
      expect(field?.kind).toBe('typeahead');
      expect(field?.required).toBe(false);
      expect(field?.allowedValuesHref).toBe('/api/v3/projects/1/available_assignees');
    });

    it('maps the remaining attribute types to their control', () => {
      expect(fieldFor(schema, 'customField2')?.kind).toBe('checkbox');
      expect(fieldFor(schema, 'customField4')?.kind).toBe('textarea');
      expect(fieldFor(schema, 'customField6')?.kind).toBe('date');
      expect(fieldFor(schema, 'percentageDone')?.kind).toBe('number');
    });

    it('reports multi value attributes as unsupported', () => {
      expect(fieldFor(schema, 'customField5')?.kind).toBe('unsupported');
    });

    it('reports an attribute whose list of allowed values is empty as unsupported', () => {
      const emptyLinks = property({ type: 'Type', name: 'Type', location: '_links', _links: { allowedValues: [] } });
      const emptyEmbedded = property({ type: 'Status', name: 'Status', _embedded: { allowedValues: [] } });

      expect(allowedValuesOf(emptyLinks)).toBeUndefined();
      expect(allowedValuesOf(emptyEmbedded)).toBeUndefined();
      expect(buildField('type', emptyLinks).kind).toBe('unsupported');
      expect(unsupportedRequiredFields([buildField('type', emptyLinks)])).toHaveLength(1);
    });

    it('falls back to the allowed values endpoint when the inlined list is empty', () => {
      const field = buildField('assignee', property({
        type: 'User',
        name: 'Assignee',
        location: '_links',
        _links: { allowedValues: { href: '/api/v3/projects/1/available_assignees' } },
      }));

      expect(field.kind).toBe('typeahead');
    });

    it('submits a picked value as a link even when the schema omits the location', () => {
      const withoutLocation = property({
        type: 'Status',
        name: 'Status',
        _links: { allowedValues: [{ href: '/api/v3/statuses/1', title: 'New' }] },
      });

      expect(buildField('status', withoutLocation).isLink).toBe(true);
    });

    it('returns nothing for a key that is not an attribute', () => {
      expect(fieldFor(schema, '_dependencies')).toBeUndefined();
      expect(fieldFor(schema, 'nonExistent')).toBeUndefined();
      expect(fieldFor(undefined, 'subject')).toBeUndefined();
    });
  });

  describe('allowed values', () => {
    it('falls back to embedded resources when there are no links', () => {
      const embedded = property({
        type: 'Status',
        name: 'Status',
        _embedded: {
          allowedValues: [
            { id: 1, name: 'New', _links: { self: { href: '/api/v3/statuses/1' } } },
            { id: 2, value: 'Design', _links: { self: { href: '/api/v3/custom_options/2' } } },
            { id: 3, name: 'Without a link' },
          ],
        },
      });

      expect(allowedValuesOf(embedded)).toEqual([
        { href: '/api/v3/statuses/1', label: 'New' },
        { href: '/api/v3/custom_options/2', label: 'Design' },
      ]);
    });

    it('ignores a link list when asked for a single href', () => {
      expect(allowedValuesHrefOf(schema.type as SchemaProperty)).toBeUndefined();
      expect(allowedValuesHrefOf(schema.project as SchemaProperty)).toBe('/api/v3/work_packages/available_projects');
    });
  });

  describe('fixedFields', () => {
    it('asks for the project before the type, and only for what has no default', () => {
      const withoutProject = fixedFields(schema, { project: false, type: false });
      const withProject = fixedFields(schema, { project: true, type: false });
      const withType = fixedFields(schema, { project: true, type: true });

      expect(withoutProject.map((field) => field.key)).toEqual(['subject', 'project']);
      expect(withProject.map((field) => field.key)).toEqual(['subject', 'project', 'assignee', 'type']);
      expect(withType.map((field) => field.key)).toEqual(['subject', 'project', 'assignee', 'type']);
    });

    it('asks for a fixed attribute the instance leaves without a default', () => {
      const withoutDefault = { ...schema, status: { ...schema.status as SchemaProperty, hasDefault: false } };

      expect(fixedFields(withoutDefault, { project: true, type: true }).map((field) => field.key))
        .toEqual(['subject', 'project', 'assignee', 'type', 'status']);
    });

    it('never asks for a fixed attribute it may not write', () => {
      const readOnly = { ...schema, assignee: { ...schema.assignee as SchemaProperty, writable: false } };

      expect(fixedFields(readOnly, { project: true, type: true }).map((field) => field.key))
        .toEqual(['subject', 'project', 'type']);
    });

    it('reports which selection each field follows', () => {
      expect(dependencyOf('subject')).toBeUndefined();
      expect(dependencyOf('project')).toBeUndefined();
      expect(dependencyOf('assignee')).toBe('project');
      expect(dependencyOf('type')).toBe('project');
      expect(dependencyOf('status')).toBe('type');
      expect(dependencyOf('customField1')).toBe('type');
    });

    it('never overlaps with the attributes picked up from the schema', () => {
      const fixed = fixedFields(schema, { project: true, type: true }).map((field) => field.key);
      const extra = extraRequiredFields(schema).map((field) => field.key);

      expect(fixed.filter((key) => extra.includes(key))).toEqual([]);
    });
  });

  describe('extraRequiredFields', () => {
    it('lists the required attributes the modal does not render itself', () => {
      expect(extraRequiredFields(schema).map((field) => field.key)).toEqual([
        'customField1',
        'customField2',
        'customField3',
        'customField4',
        'customField5',
        'customField6',
      ]);
    });

    it('skips defaulted, optional and read only attributes', () => {
      const keys = extraRequiredFields(schema).map((field) => field.key);
      expect(keys).not.toContain('priority');
      expect(keys).not.toContain('startDate');
      expect(keys).not.toContain('percentageDone');
      expect(keys).not.toContain('id');
    });
  });

  describe('applyValue', () => {
    it('drops everything derived from the project when it changes', () => {
      const values = {
        subject: 'Fix the header',
        project: '/api/v3/projects/1',
        type: '/api/v3/types/1',
        status: '/api/v3/statuses/1',
        assignee: '/api/v3/users/5',
        customField1: 'note',
      };

      expect(applyValue(values, 'project', '/api/v3/projects/2')).toEqual({
        subject: 'Fix the header',
        project: '/api/v3/projects/2',
      });
    });

    // What of it the new type can still hold is decided once its schema is known.
    it('carries everything filled in over when the type changes', () => {
      const values = {
        subject: 'Fix the header',
        project: '/api/v3/projects/1',
        type: '/api/v3/types/1',
        status: '/api/v3/statuses/1',
        assignee: '/api/v3/users/5',
        customField1: 'note',
      };

      expect(applyValue(values, 'type', '/api/v3/types/2')).toEqual({
        ...values,
        type: '/api/v3/types/2',
      });
    });

    it('leaves the other values untouched', () => {
      expect(applyValue({ subject: 'a' }, 'customField1', 'b')).toEqual({ subject: 'a', customField1: 'b' });
    });

    it('also resets when the same project is picked again', () => {
      const values = { subject: 'a', project: '/api/v3/projects/1', type: '/api/v3/types/1' };
      expect(applyValue(values, 'project', '/api/v3/projects/1')).toEqual({
        subject: 'a',
        project: '/api/v3/projects/1',
      });
    });
  });

  describe('missing and unsupported fields', () => {
    const fields = [
      fieldFor(schema, 'subject'),
      fieldFor(schema, 'type'),
      fieldFor(schema, 'assignee'),
      fieldFor(schema, 'customField2'),
      fieldFor(schema, 'customField5'),
    ].flatMap((field) => (field ? [field] : []));

    it('treats blank required values as missing, but never a checkbox', () => {
      const missing = missingRequiredFields(fields, { subject: '   ', customField2: false });
      expect(missing.map((field) => field.key)).toEqual(['subject', 'type', 'customField5']);
    });

    it('reports required attributes without a control', () => {
      expect(unsupportedRequiredFields(fields).map((field) => field.key)).toEqual(['customField5']);
    });

    it('hands what is missing to the field it belongs to', () => {
      expect(missingProblems(fields, { subject: '   ', customField2: false })).toEqual({
        subject: 'missing',
        type: 'missing',
        customField5: 'missing',
      });
    });
  });

  describe('valueProblems', () => {
    const wholeNumber = fieldFor(schema, 'percentageDone')!;
    const anyNumber = buildField('estimatedTime', property({ type: 'Float', name: 'Work' }));
    const fields = [wholeNumber, anyNumber, fieldFor(schema, 'subject')!];

    it('complains about what cannot be read as a number', () => {
      expect(valueProblems(fields, { percentageDone: '2-4', estimatedTime: 'a lot' })).toEqual({
        percentageDone: 'notANumber',
        estimatedTime: 'notANumber',
      });
    });

    it('complains about a decimal only where whole numbers are asked for', () => {
      expect(valueProblems(fields, { percentageDone: '12.5', estimatedTime: '12.5' }))
        .toEqual({ percentageDone: 'notAWholeNumber' });
    });

    it('says nothing about a number, nor about a field left empty', () => {
      expect(valueProblems(fields, { percentageDone: '30', estimatedTime: '-1.5', subject: '' })).toEqual({});
      expect(valueProblems(fields, { percentageDone: '  ' })).toEqual({});
      expect(valueProblems(fields, {})).toEqual({});
    });

    it('leaves what is not a number field to the API', () => {
      expect(valueProblems(fields, { subject: '2-4' })).toEqual({});
    });
  });

  describe('splitAttributeErrors', () => {
    const fields = [fieldFor(schema, 'subject'), fieldFor(schema, 'assignee')]
      .flatMap((field) => (field ? [field] : []));

    it('hands each violation to the field it belongs to', () => {
      const { fieldErrors, otherMessages } = splitAttributeErrors(fields, {
        subject: 'Subject can\'t be blank.',
        assignee: 'Assignee is not set to one of the allowed values.',
      });

      expect(fieldErrors).toEqual({
        subject: 'Subject can\'t be blank.',
        assignee: 'Assignee is not set to one of the allowed values.',
      });
      expect(otherMessages).toEqual([]);
    });

    it('keeps a violation no field can show, rather than dropping it', () => {
      const { fieldErrors, otherMessages } = splitAttributeErrors(fields, {
        subject: 'Subject can\'t be blank.',
        startDate: 'Start date must be before the finish date.',
      });

      expect(Object.keys(fieldErrors)).toEqual(['subject']);
      expect(otherMessages).toEqual(['Start date must be before the finish date.']);
    });
  });

  describe('reshapesForm', () => {
    it('knows which selections the rest of the form hangs on', () => {
      expect(reshapesForm('project')).toBe(true);
      expect(reshapesForm('type')).toBe(true);
      expect(reshapesForm('subject')).toBe(false);
    });
  });

  describe('survivingValues', () => {
    const offered = [
      fieldFor(schema, 'subject'),
      fieldFor(schema, 'customField1'),
      fieldFor(schema, 'customField2'),
      fieldFor(schema, 'customField3'),
    ].flatMap((field) => (field ? [field] : []));

    it('keeps what the reshaped form still offers, and what does not hang on the type', () => {
      const values = {
        subject: 'Fix the header',
        project: '/api/v3/projects/1',
        type: '/api/v3/types/2',
        assignee: '/api/v3/users/5',
        customField1: 'note',
        customField2: true,
        customField3: '/api/v3/custom_options/7',
      };

      expect(survivingValues(offered, values)).toEqual(values);
    });

    it('drops the value of an attribute the new type does not bring', () => {
      expect(survivingValues(offered, { customField1: 'note', customField9: 'gone' }))
        .toEqual({ customField1: 'note' });
    });

    it('drops a choice the new type does not allow', () => {
      expect(survivingValues(offered, { customField3: '/api/v3/custom_options/8' })).toEqual({});
    });

    it('drops a value the attribute of the new type cannot hold', () => {
      // A checkbox does not hold a text, and "Tags" is a kind no control answers for.
      const fields = [
        fieldFor(schema, 'customField2'),
        fieldFor(schema, 'customField5'),
      ].flatMap((field) => (field ? [field] : []));

      expect(survivingValues(fields, { customField2: 'yes', customField5: '/api/v3/custom_options/7' }))
        .toEqual({});
    });
  });

  describe('survivingLabels', () => {
    const supervisor = buildField('customField6', property({
      type: 'User',
      name: 'Supervisor',
      location: '_links',
      _links: { allowedValues: { href: '/api/v3/principals' } },
    }));

    it('keeps the labels the reshaped form still has a field for', () => {
      const labels = { assignee: 'Elif Yildiz', customField6: 'Anna Kovalenko' };

      expect(survivingLabels([supervisor], labels)).toEqual(labels);
    });

    it('drops the label of an attribute the new type does not bring', () => {
      expect(survivingLabels([], { customField6: 'Anna Kovalenko' })).toEqual({});
    });
  });

  describe('buildCreatePayload', () => {
    const fields = [
      fieldFor(schema, 'subject'),
      fieldFor(schema, 'project'),
      fieldFor(schema, 'type'),
      fieldFor(schema, 'assignee'),
      fieldFor(schema, 'customField2'),
      fieldFor(schema, 'customField4'),
      fieldFor(schema, 'customField5'),
      fieldFor(schema, 'percentageDone'),
    ].flatMap((field) => (field ? [field] : []));

    const basePayload = {
      subject: null,
      scheduleManually: false,
      _links: {
        priority: { href: '/api/v3/priorities/8' },
        assignee: { href: null },
      },
    };

    it('submits link attributes under _links and keeps the form defaults', () => {
      const payload = buildCreatePayload(basePayload, fields, {
        subject: 'Fix the header',
        project: '/api/v3/projects/1',
        type: '/api/v3/types/1',
        customField2: true,
        customField4: 'Some notes',
        percentageDone: '30',
      });

      expect(payload).toEqual({
        subject: 'Fix the header',
        scheduleManually: false,
        customField2: true,
        customField4: { raw: 'Some notes' },
        percentageDone: 30,
        _links: {
          priority: { href: '/api/v3/priorities/8' },
          project: { href: '/api/v3/projects/1' },
          type: { href: '/api/v3/types/1' },
        },
      });
    });

    it('sends nothing for an attribute without a control', () => {
      const payload = buildCreatePayload(basePayload, fields, { customField5: '/api/v3/custom_options/1' });
      expect(payload.customField5).toBeUndefined();
      expect(payload._links?.customField5).toBeUndefined();
    });

    it('coerces numbers and refuses what is not one', () => {
      const numberField = fieldFor(schema, 'percentageDone');
      const dateField = fieldFor(schema, 'customField6');
      const fields = [numberField, dateField].flatMap((field) => (field ? [field] : []));

      expect(buildCreatePayload({}, fields, { percentageDone: '30.5' }).percentageDone).toBe(30.5);
      expect(buildCreatePayload({}, fields, { percentageDone: 'abc' }).percentageDone).toBeNull();
      expect(buildCreatePayload({}, fields, { customField6: '2026-08-04' }).customField6).toBe('2026-08-04');
    });

    it('works without a base payload of its own', () => {
      const subject = fieldFor(schema, 'subject');
      const project = fieldFor(schema, 'project');
      const payload = buildCreatePayload({}, [subject!, project!], {
        subject: 'Fix the header',
        project: '/api/v3/projects/1',
      });

      expect(payload).toEqual({
        subject: 'Fix the header',
        _links: { project: { href: '/api/v3/projects/1' } },
      });
    });

    it('nulls emptied values and drops emptied links', () => {
      const payload = buildCreatePayload(
        { _links: { assignee: { href: '/api/v3/users/5' } } },
        fields,
        { subject: 'Only a subject', assignee: '' }
      );

      expect(payload._links?.assignee).toBeUndefined();
      expect(payload.customField4).toBeNull();
      expect(payload.percentageDone).toBeNull();
    });
  });

  describe('toAllowedValues', () => {
    it('carries the ancestors a nested resource names, and whether it is favored', () => {
      expect(toAllowedValues([
        {
          name: 'Subproject',
          favorited: true,
          _links: {
            self: { href: '/api/v3/projects/3' },
            ancestors: [
              { href: '/api/v3/projects/1', title: 'Root' },
              { href: '/api/v3/projects/2', title: 'Parent' },
            ],
          },
        },
        { name: 'Flat', _links: { self: { href: '/api/v3/projects/9' } } },
      ])).toEqual([
        {
          href: '/api/v3/projects/3',
          label: 'Subproject',
          favored: true,
          ancestors: ['/api/v3/projects/1', '/api/v3/projects/2'],
        },
        // Nothing but projects is favored, and silence is not a claim to be one.
        { href: '/api/v3/projects/9', label: 'Flat' },
      ]);
    });
  });

  describe('listedValues', () => {
    const root = { href: '/api/v3/projects/1', label: 'Root' };
    const child = {
      href: '/api/v3/projects/2',
      label: 'Child',
      favored: true,
      ancestors: ['/api/v3/projects/1'],
    };
    const grandchild = {
      href: '/api/v3/projects/3',
      label: 'Grandchild',
      ancestors: ['/api/v3/projects/1', '/api/v3/projects/2'],
    };
    const sibling = {
      href: '/api/v3/projects/4',
      label: 'Sibling',
      ancestors: ['/api/v3/projects/1'],
    };
    const all = new Set([root.href, child.href, grandchild.href, sibling.href]);

    it('lists only the roots while nothing is unfolded', () => {
      const listed = listedValues([root, child, grandchild], new Set());

      expect(listed.map((value) => value.label)).toEqual(['Root']);
      expect(listed[0]).toMatchObject({ depth: 0, hasChildren: true, expanded: false });
    });

    it('walks each unfolded parent into its children, one level in at a time', () => {
      expect(listedValues([root, child, grandchild], all).map((value) => [value.label, value.depth]))
        .toEqual([['Root', 0], ['Child', 1], ['Grandchild', 2]]);
    });

    it('stops where the unfolding does', () => {
      expect(listedValues([root, child, grandchild], new Set([root.href])).map((value) => value.label))
        .toEqual(['Root', 'Child']);
    });

    it('keeps the children of a parent together and in the order given', () => {
      expect(listedValues([root, child, sibling, grandchild], all).map((value) => value.label))
        .toEqual(['Root', 'Child', 'Grandchild', 'Sibling']);
    });

    it('roots a value whose ancestors are not listed', () => {
      expect(listedValues([grandchild], all)).toMatchObject([{ depth: 0, hasChildren: false }]);
      expect(listedValues([child, grandchild], all).map((value) => [value.label, value.depth]))
        .toEqual([['Child', 0], ['Grandchild', 1]]);
    });

    it('marks a favorite wherever it stands in the tree', () => {
      expect(listedValues([root, child], all).map((value) => [value.label, value.favored]))
        .toEqual([['Root', undefined], ['Child', true]]);
    });

    it('unfolds nothing for a parent whose children are not listed', () => {
      expect(listedValues([root], all)).toMatchObject([{ hasChildren: false, expanded: false }]);
    });
  });
});
