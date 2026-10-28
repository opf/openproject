import type { WorkPackage, WorkPackageSchema } from '../../openProjectTypes';

export interface WorkPackageAttribute {
  key:string;
  // What the attribute macros resolve: the key, or the name of a custom field.
  reference:string;
  label:string;
  type:string;
  customField:boolean;
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

// Long text renders as a block, which an inline chip cannot hold.
const HIDDEN_TYPES = new Set(['Formattable']);

export function listAttributes(schema:WorkPackageSchema):WorkPackageAttribute[] {
  const attributes:WorkPackageAttribute[] = [];
  for (const [key, field] of Object.entries(schema)) {
    if (key.startsWith('_') || HIDDEN_KEYS.has(key)) continue;
    if (!field || typeof field !== 'object') continue;
    const { type, name } = field as FieldSchema;
    if (typeof type !== 'string' || typeof name !== 'string' || HIDDEN_TYPES.has(type)) continue;

    const customField = CUSTOM_FIELD_KEY.test(key);
    attributes.push({ key, reference: customField ? name : key, label: name, type, customField });
  }

  return attributes;
}

// As in the attribute macros, so a reference survives the deprecation of
// `version` and a change of the type to a milestone.
const KEY_ALIASES:Record<string, string> = {
  version: 'targetVersions',
  startDate: 'date',
  dueDate: 'date',
};

// Resolves a reference the way the attribute macros do: by the localized name
// first, then by the key.
export function findAttribute(schema:WorkPackageSchema, reference:string):WorkPackageAttribute | undefined {
  const attributes = listAttributes(schema);
  return attributes.find((attribute) => attribute.label === reference)
    ?? attributes.find((attribute) => attribute.key === reference)
    ?? attributes.find((attribute) => attribute.key === KEY_ALIASES[reference]);
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

function durationInHours(value:string):number | undefined {
  const match = ISO_DURATION.exec(value);
  if (!match) return undefined;

  const [days, hours, minutes, seconds] = match.slice(1).map((part) => Number(part ?? 0));
  return days * 24 + hours + minutes / 60 + seconds / 3600;
}

function formatDuration(attribute:WorkPackageAttribute, value:string, options:FormatOptions):string {
  const hours = durationInHours(value);
  if (hours === undefined) return value;

  if (attribute.key === 'duration') return options.days(Math.round(hours / 24 * 100) / 100);

  const formattedHours = new Intl.NumberFormat(options.locale, { maximumFractionDigits: 2 }).format(hours);
  return `${formattedHours} h`;
}

function formatNumber(attribute:WorkPackageAttribute, value:number, locale:string):string {
  const formatted = new Intl.NumberFormat(locale).format(value);
  return attribute.key === 'percentageDone' ? `${formatted}%` : formatted;
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
  if (typeof value === 'number') return formatNumber(attribute, value, options.locale);
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
