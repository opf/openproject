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
  missingRequiredFields,
  unsupportedRequiredFields,
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
    it('asks for the project before the type, and for the type before the status', () => {
      const withoutProject = fixedFields(schema, { project: false, type: false });
      const withProject = fixedFields(schema, { project: true, type: false });
      const withType = fixedFields(schema, { project: true, type: true });

      expect(withoutProject.map((field) => field.key)).toEqual(['subject', 'project']);
      expect(withProject.map((field) => field.key)).toEqual(['subject', 'project', 'assignee', 'type']);
      expect(withType.map((field) => field.key)).toEqual(['subject', 'project', 'assignee', 'type', 'status']);
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

    it('keeps the project and the assignee when the type changes', () => {
      const values = {
        subject: 'Fix the header',
        project: '/api/v3/projects/1',
        type: '/api/v3/types/1',
        status: '/api/v3/statuses/1',
        assignee: '/api/v3/users/5',
        customField1: 'note',
      };

      expect(applyValue(values, 'type', '/api/v3/types/2')).toEqual({
        subject: 'Fix the header',
        project: '/api/v3/projects/1',
        assignee: '/api/v3/users/5',
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
});
