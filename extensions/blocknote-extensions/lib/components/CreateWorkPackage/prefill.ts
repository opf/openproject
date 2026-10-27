import type { WorkPackagePayload } from '../../openProjectTypes';
import { fetchAllowedValueById, fetchAllowedValues } from '../../services/openProjectApi';
import { contextProjectId } from '../../services/editorContext';
import { projectIdFromHref } from '../../utils/id';
import { allowedValueOf, toAllowedValues } from './formSchema';
import type { AllowedValue, FieldLabels, FieldValues, FormField } from './formSchema';
import { lastSelection } from './lastSelection';
import type { LastSelection } from './lastSelection';

export interface Prefill {
  values:FieldValues;
  labels:FieldLabels;
}

const PROJECT_KEY = 'project';

// A type is chosen even where nothing is remembered, so the attributes it brings
// can be asked for right away.
const PROJECT_DEPENDENT_FIELDS:{ key:string; fallsBackToFirst:boolean }[] = [
  { key: 'type', fallsBackToFirst: true },
  { key: 'assignee', fallsBackToFirst: false },
];

const REMEMBERED_KEYS = [PROJECT_KEY, ...PROJECT_DEPENDENT_FIELDS.map(({ key }) => key)];

function payloadDefaultOf(payload:WorkPackagePayload, key:string):string | undefined {
  const link = payload._links?.[key];
  if (!link || Array.isArray(link)) return undefined;
  return link.href ?? undefined;
}

function prefillOf(chosen:[string, AllowedValue | undefined][]):Prefill {
  const values:FieldValues = {};
  const labels:FieldLabels = {};

  for (const [key, value] of chosen) {
    if (!value) continue;
    values[key] = value.href;
    labels[key] = value.label;
  }

  return { values, labels };
}

function chosenFromList(
  field:FormField,
  payload:WorkPackagePayload,
  remembered:AllowedValue | undefined,
  fallsBackToFirst:boolean
):AllowedValue | undefined {
  const onOffer = [remembered?.href, payloadDefaultOf(payload, field.key)]
    .map((href) => allowedValueOf(field, href))
    .find(Boolean);

  return onOffer ?? (fallsBackToFirst ? field.allowedValues?.[0] : undefined);
}

// The people of one project are not the people of the next, so a remembered
// value is only prefilled where the API still offers it.
async function chosenFromApi(
  field:FormField,
  remembered:AllowedValue | undefined
):Promise<AllowedValue | undefined> {
  if (!remembered || !field.allowedValuesHref) return undefined;

  try {
    const { resources } = await fetchAllowedValues(field.allowedValuesHref, remembered.label);
    return toAllowedValues(resources).find((value) => value.href === remembered.href);
  } catch (error) {
    console.error('[create work package] Failed to check a remembered value:', error);
    return undefined;
  }
}

async function chosenFor(
  field:FormField,
  payload:WorkPackagePayload,
  remembered:AllowedValue | undefined,
  fallsBackToFirst:boolean
):Promise<AllowedValue | undefined> {
  if (field.kind === 'select') return chosenFromList(field, payload, remembered, fallsBackToFirst);
  if (field.kind === 'typeahead') return chosenFromApi(field, remembered);
  return undefined;
}

// Asked for by its id and matched back to it: a project that cannot be created
// in would open a form that cannot be submitted.
async function offeredProject(field:FormField, id:string | number):Promise<AllowedValue | undefined> {
  const isWanted = (value:AllowedValue) => projectIdFromHref(value.href) === String(id);

  if (field.kind === 'select') return field.allowedValues?.find(isWanted);
  if (!field.allowedValuesHref) return undefined;

  try {
    const offered = await fetchAllowedValueById(field.allowedValuesHref, id);
    const value = offered ? toAllowedValues([offered])[0] : undefined;
    return value && isWanted(value) ? value : undefined;
  } catch (error) {
    console.error('[create work package] Failed to look up the project to open on:', error);
    return undefined;
  }
}

/** The project the form opens on, by the name it goes by now. */
export async function projectPrefill(field:FormField | undefined):Promise<Prefill> {
  if (!field) return prefillOf([]);

  // A project picked by hand outranks the one the editor is rendered in, which
  // seeds the first creation and stands in where the picked one is gone.
  const candidates = [projectIdFromHref(lastSelection()[PROJECT_KEY]?.href), contextProjectId()];

  for (const id of candidates) {
    if (id === undefined) continue;

    const chosen = await offeredProject(field, id);
    if (chosen) return prefillOf([[PROJECT_KEY, chosen]]);
  }

  return prefillOf([]);
}

/** The values the given fields open with, from what the document remembers and what the API defaults to. */
export async function prefillFor(fields:FormField[], payload:WorkPackagePayload):Promise<Prefill> {
  const remembered = lastSelection();
  const chosen:[string, AllowedValue | undefined][] = [];

  for (const { key, fallsBackToFirst } of PROJECT_DEPENDENT_FIELDS) {
    const field = fields.find((candidate) => candidate.key === key);
    if (!field) continue;

    chosen.push([key, await chosenFor(field, payload, remembered[key], fallsBackToFirst)]);
  }

  return prefillOf(chosen);
}

export function selectionToRemember(
  fields:FormField[],
  values:FieldValues,
  labels:FieldLabels
):LastSelection {
  const selection:LastSelection = {};

  for (const key of REMEMBERED_KEYS) {
    const field = fields.find((candidate) => candidate.key === key);
    const href = values[key];
    if (!field || typeof href !== 'string' || !href) continue;

    const label = allowedValueOf(field, href)?.label ?? labels[key];
    if (!label) continue;

    selection[key] = { href, label };
  }

  return selection;
}
