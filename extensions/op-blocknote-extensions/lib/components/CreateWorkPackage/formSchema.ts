import type {
  HalLink,
  HalResource,
  SchemaProperty,
  WorkPackagePayload,
  WorkPackageSchema,
} from '../../openProjectTypes';

export type FieldKind =
  | 'text'
  | 'textarea'
  | 'number'
  | 'checkbox'
  | 'date'
  | 'select'
  | 'typeahead'
  | 'unsupported';

export interface AllowedValue {
  href:string;
  label:string;
}

export interface FormField {
  key:string;
  label:string;
  kind:FieldKind;
  required:boolean;
  isLink:boolean;
  placeholder?:string;
  maxLength?:number;
  integer?:boolean;
  allowedValues?:AllowedValue[];
  allowedValuesHref?:string;
}

export type FieldValue = string | boolean;
export type FieldValues = Record<string, FieldValue>;
export type FieldErrors = Record<string, string>;

export type ValueProblem = 'missing' | 'notANumber' | 'notAWholeNumber';
export type ValueProblems = Record<string, ValueProblem>;

export type FieldDependency = 'project' | 'type' | undefined;

const FIXED_FIELDS:{ key:string; dependsOn?:FieldDependency }[] = [
  { key: 'subject' },
  { key: 'project' },
  { key: 'assignee', dependsOn: 'project' },
  { key: 'type', dependsOn: 'project' },
  { key: 'status', dependsOn: 'type' },
];

export const FIXED_FIELD_KEYS = FIXED_FIELDS.map((field) => field.key);

export function dependencyOf(key:string):FieldDependency {
  const fixed = FIXED_FIELDS.find((field) => field.key === key);
  return fixed ? fixed.dependsOn : 'type';
}

const SCHEMA_META_KEYS = ['_type', '_dependencies', '_attributeGroups', '_links', '_embedded'];

const NON_EDITABLE_KEYS = ['id', 'lockVersion', 'createdAt', 'updatedAt', 'author', 'position'];

const KIND_BY_TYPE:Record<string, FieldKind> = {
  'String': 'text',
  'Link': 'text',
  'Formattable': 'textarea',
  'Integer': 'number',
  'Float': 'number',
  'Boolean': 'checkbox',
  'Date': 'date',
};

export function readSchemaProperty(
  schema:WorkPackageSchema | undefined,
  key:string
):SchemaProperty | undefined {
  const candidate = schema?.[key];
  if (typeof candidate !== 'object' || candidate === null) return undefined;

  const property = candidate as Partial<SchemaProperty>;
  if (typeof property.type !== 'string' || typeof property.name !== 'string') return undefined;

  return property as SchemaProperty;
}

export function labelOfResource(resource:HalResource):string {
  return resource.name ?? resource.subject ?? resource.value ?? '';
}

export function toAllowedValues(resources:HalResource[]):AllowedValue[] {
  return resources.flatMap((resource) => {
    const href = resource._links?.self?.href;
    return href ? [{ href, label: labelOfResource(resource) }] : [];
  });
}

export function allowedValuesOf(property:SchemaProperty):AllowedValue[] | undefined {
  const links = property._links?.allowedValues;
  if (Array.isArray(links)) {
    const values = links
      .filter((link):link is HalLink & { href:string } => typeof link.href === 'string')
      .map((link) => ({ href: link.href, label: link.title ?? link.href }));
    return values.length > 0 ? values : undefined;
  }

  const embedded = property._embedded?.allowedValues;
  if (!embedded) return undefined;

  const values = toAllowedValues(embedded);
  return values.length > 0 ? values : undefined;
}

export function allowedValuesHrefOf(property:SchemaProperty):string | undefined {
  const links = property._links?.allowedValues;
  if (!links || Array.isArray(links)) return undefined;
  return links.href ?? undefined;
}

export function buildField(key:string, property:SchemaProperty):FormField {
  const field:FormField = {
    key,
    label: property.name,
    kind: 'unsupported',
    required: property.required,
    isLink: property.location === '_links',
    ...(property.placeholder ? { placeholder: property.placeholder } : {}),
    ...(property.maxLength ? { maxLength: property.maxLength } : {}),
  };

  // An href belongs under `_links` even when the schema leaves the location out.
  const allowedValues = allowedValuesOf(property);
  if (allowedValues) return { ...field, kind: 'select', isLink: true, allowedValues };

  const allowedValuesHref = allowedValuesHrefOf(property);
  if (allowedValuesHref) return { ...field, kind: 'typeahead', isLink: true, allowedValuesHref };

  if (property.type.startsWith('[]')) return field;

  return {
    ...field,
    kind: KIND_BY_TYPE[property.type] ?? 'unsupported',
    ...(property.type === 'Integer' ? { integer: true } : {}),
  };
}

export function fieldFor(schema:WorkPackageSchema | undefined, key:string):FormField | undefined {
  const property = readSchemaProperty(schema, key);
  if (!property) return undefined;
  return buildField(key, property);
}

// Left out of the form: the default the API put into the payload is submitted as
// it is, required attribute or not.
function isOffered(property:SchemaProperty):boolean {
  return property.writable && !property.hasDefault;
}

export function fixedFields(
  schema:WorkPackageSchema | undefined,
  selected:{ project:boolean; type:boolean }
):FormField[] {
  return FIXED_FIELDS
    .filter(({ dependsOn }) => dependsOn === undefined || selected[dependsOn])
    .flatMap(({ key }) => {
      const property = readSchemaProperty(schema, key);
      return property && isOffered(property) ? [buildField(key, property)] : [];
    });
}

export function extraRequiredFields(schema:WorkPackageSchema | undefined):FormField[] {
  if (!schema) return [];

  const fields:FormField[] = [];
  for (const key of Object.keys(schema)) {
    if (SCHEMA_META_KEYS.includes(key)) continue;
    if (FIXED_FIELD_KEYS.includes(key)) continue;
    if (NON_EDITABLE_KEYS.includes(key)) continue;

    const property = readSchemaProperty(schema, key);
    if (!property) continue;
    if (!property.required || !isOffered(property)) continue;
    if (property.location === '_meta') continue;

    fields.push(buildField(key, property));
  }
  return fields;
}

export function isValueFilled(field:FormField, value:FieldValue | undefined):boolean {
  if (field.kind === 'checkbox') return true;
  return typeof value === 'string' && value.trim().length > 0;
}

export function missingRequiredFields(fields:FormField[], values:FieldValues):FormField[] {
  return fields.filter((field) => field.required && !isValueFilled(field, values[field.key]));
}

export function missingProblems(fields:FormField[], values:FieldValues):ValueProblems {
  return Object.fromEntries(
    missingRequiredFields(fields, values).map((field) => [field.key, 'missing' as const])
  );
}

export function unsupportedRequiredFields(fields:FormField[]):FormField[] {
  return fields.filter((field) => field.required && field.kind === 'unsupported');
}

function numberValueOf(value:string):number | null {
  const parsed = Number(value.trim());
  return Number.isFinite(parsed) ? parsed : null;
}

// An empty field is answered by its required mark rather than by a complaint.
function valueProblemOf(field:FormField, value:FieldValue | undefined):ValueProblem | undefined {
  if (field.kind !== 'number' || typeof value !== 'string' || value.trim().length === 0) return undefined;

  const parsed = numberValueOf(value);
  if (parsed === null) return 'notANumber';
  if (field.integer && !Number.isInteger(parsed)) return 'notAWholeNumber';
  return undefined;
}

export function valueProblems(fields:FormField[], values:FieldValues):ValueProblems {
  const problems:ValueProblems = {};
  for (const field of fields) {
    const problem = valueProblemOf(field, values[field.key]);
    if (problem) problems[field.key] = problem;
  }
  return problems;
}

// A violation no field of this form can carry has to stay in the message on
// top rather than be dropped.
export function splitAttributeErrors(
  fields:FormField[],
  attributeErrors:FieldErrors
):{ fieldErrors:FieldErrors; otherMessages:string[] } {
  const shown = new Set(fields.map((field) => field.key));
  const fieldErrors:FieldErrors = {};
  const otherMessages:string[] = [];

  for (const [attribute, message] of Object.entries(attributeErrors)) {
    if (shown.has(attribute)) fieldErrors[attribute] = message;
    else otherMessages.push(message);
  }
  return { fieldErrors, otherMessages };
}

const KEPT_ON_CHANGE:Record<string, string[]> = {
  'project': ['subject'],
  'type': ['subject', 'project', 'assignee'],
};

export function clearsOtherValues(key:string):boolean {
  return key in KEPT_ON_CHANGE;
}

export function applyValue(previous:FieldValues, key:string, value:FieldValue):FieldValues {
  const kept = KEPT_ON_CHANGE[key];
  if (!kept) return { ...previous, [key]: value };

  const next:FieldValues = {};
  for (const name of kept) {
    const existing = previous[name];
    if (existing !== undefined) next[name] = existing;
  }
  next[key] = value;
  return next;
}

function payloadValueOf(field:FormField, value:FieldValue | undefined):unknown {
  if (field.kind === 'checkbox') return value === true;
  if (typeof value !== 'string' || value.trim().length === 0) return null;

  switch (field.kind) {
    case 'number':
      return numberValueOf(value);
    case 'textarea':
      return { raw: value };
    default:
      return value;
  }
}

export function buildCreatePayload(
  basePayload:WorkPackagePayload,
  fields:FormField[],
  values:FieldValues
):WorkPackagePayload {
  const payload:WorkPackagePayload = { ...basePayload };
  const links:Record<string, HalLink | HalLink[]> = { ...basePayload._links };

  for (const field of fields) {
    if (field.kind === 'unsupported') continue;

    const value = values[field.key];
    if (field.isLink) {
      if (typeof value === 'string' && value.trim().length > 0) {
        links[field.key] = { href: value };
      } else {
        delete links[field.key];
      }
    } else {
      payload[field.key] = payloadValueOf(field, value);
    }
  }

  payload._links = links;
  return payload;
}
