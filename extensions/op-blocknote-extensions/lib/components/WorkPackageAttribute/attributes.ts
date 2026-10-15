import type { WorkPackage, WorkPackageSchema } from '../../openProjectTypes';

export interface WorkPackageAttribute {
  key:string;
  // What the attribute macros resolve: the key, or the name of a custom field.
  reference:string;
  label:string;
  type:string;
  customField:boolean;
  // Long text renders as a block, which an inline element cannot hold.
  block:boolean;
}

interface FieldSchema {
  type?:unknown;
  name?:unknown;
}

const CUSTOM_FIELD_KEY = /^customField\d+$/;

// Bookkeeping fields, the derived twins of shown ones, and `version`, which
// `targetVersions` replaces and the macros already map onto it. `date` stays:
// it is the only date a milestone has.
const HIDDEN_KEYS = new Set([
  'id',
  'lockVersion',
  'readonly',
  'scheduleManually',
  'ignoreNonWorkingDays',
  'derivedStartDate',
  'derivedDueDate',
  'derivedEstimatedTime',
  'derivedRemainingTime',
  'derivedPercentageDone',
  'version',
]);

export function listAttributes(schema:WorkPackageSchema):WorkPackageAttribute[] {
  const attributes:WorkPackageAttribute[] = [];
  for (const [key, field] of Object.entries(schema)) {
    if (key.startsWith('_') || HIDDEN_KEYS.has(key)) continue;
    if (!field || typeof field !== 'object') continue;
    const { type, name } = field as FieldSchema;
    if (typeof type !== 'string' || typeof name !== 'string') continue;

    const customField = CUSTOM_FIELD_KEY.test(key);
    attributes.push({
      key,
      reference: customField ? name : key,
      label: name,
      type,
      customField,
      block: type === 'Formattable',
    });
  }
  return attributes;
}

export function findAttribute(schema:WorkPackageSchema, reference:string):WorkPackageAttribute | undefined {
  const attributes = listAttributes(schema);
  return attributes.find((attribute) => attribute.customField && attribute.reference === reference)
    ?? attributes.find((attribute) => attribute.reference === reference)
    ?? attributes.find((attribute) => attribute.key === reference || attribute.label === reference);
}

export const EMPTY_VALUE = '–';

export interface FormatOptions {
  locale:string;
  yes:string;
  no:string;
  days:(count:number) => string;
}

interface LinkValue { title?:string | null; href?:string | null }

function linkTitles(link:LinkValue | LinkValue[] | null | undefined):string[] {
  const links = Array.isArray(link) ? link : link ? [link] : [];
  return links.flatMap((entry) => (entry.title ? [entry.title] : []));
}

const ISO_DURATION = /^P(?:(\d+(?:\.\d+)?)D)?(?:T(?:(\d+(?:\.\d+)?)H)?(?:(\d+(?:\.\d+)?)M)?(?:(\d+(?:\.\d+)?)S)?)?$/;

function formatDuration(attribute:WorkPackageAttribute, value:string, options:FormatOptions):string {
  const match = ISO_DURATION.exec(value);
  if (!match) return value;
  const [days, hours, minutes, seconds] = match.slice(1).map((part) => Number(part ?? 0));
  const totalHours = days * 24 + hours + minutes / 60 + seconds / 3600;
  const number = new Intl.NumberFormat(options.locale, { maximumFractionDigits: 2 });
  if (attribute.key === 'duration') return options.days(Math.round(totalHours / 24 * 100) / 100);
  return `${number.format(totalHours)} h`;
}

function formatDate(value:string, locale:string):string {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
  if (!match) return value;
  // Built from parts so the date does not shift with the time zone.
  const date = new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3]));
  return new Intl.DateTimeFormat(locale, { dateStyle: 'medium' }).format(date);
}

function formatDateTime(value:string, locale:string):string {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return new Intl.DateTimeFormat(locale, { dateStyle: 'medium', timeStyle: 'short' }).format(date);
}

function formatScalar(attribute:WorkPackageAttribute, value:unknown, options:FormatOptions):string {
  if (typeof value === 'boolean') return value ? options.yes : options.no;
  if (typeof value === 'number') {
    const formatted = new Intl.NumberFormat(options.locale).format(value);
    return attribute.key === 'percentageDone' ? `${formatted}%` : formatted;
  }
  if (typeof value !== 'string') return EMPTY_VALUE;
  if (attribute.type === 'Duration') return formatDuration(attribute, value, options);
  if (attribute.type === 'Date') return formatDate(value, options.locale);
  if (attribute.type === 'DateTime') return formatDateTime(value, options.locale);
  return value;
}

export function formatAttributeValue(
  workPackage:WorkPackage,
  attribute:WorkPackageAttribute,
  options:FormatOptions,
):string {
  const links = workPackage._links as Record<string, LinkValue | LinkValue[] | null | undefined> | null | undefined;
  if (links && attribute.key in links) {
    const titles = linkTitles(links[attribute.key]);
    return titles.length > 0 ? titles.join(', ') : EMPTY_VALUE;
  }

  const value = (workPackage as unknown as Record<string, unknown>)[attribute.key];
  if (value === null || value === undefined || value === '') return EMPTY_VALUE;
  if (Array.isArray(value)) {
    const parts = value.map((entry) => formatScalar(attribute, entry, options)).filter((part) => part !== EMPTY_VALUE);
    return parts.length > 0 ? parts.join(', ') : EMPTY_VALUE;
  }
  return formatScalar(attribute, value, options);
}

/** The long text of a block attribute, as OpenProject rendered it. */
export function formattedHtmlOf(workPackage:WorkPackage, attribute:WorkPackageAttribute):string {
  const value = (workPackage as unknown as Record<string, unknown>)[attribute.key];
  if (!value || typeof value !== 'object') return '';
  const { html } = value as { html?:unknown };
  return typeof html === 'string' ? html : '';
}
