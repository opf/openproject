import type { WorkPackagePayload } from '../../openProjectTypes';
import { fetchAllowedValues } from '../../services/openProjectApi';
import { allowedValueOf, toAllowedValues } from './formSchema';
import type { AllowedValue, FieldLabels, FieldValues, FormField } from './formSchema';
import { lastSelection } from './lastSelection';
import type { LastSelection } from './lastSelection';

export interface Prefill {
  values:FieldValues;
  labels:FieldLabels;
}

// A type is chosen even where nothing is remembered, so the attributes it brings
// can be asked for right away.
const PREFILLED_FIELDS:{ key:string; fallsBackToFirst:boolean }[] = [
  { key: 'type', fallsBackToFirst: true },
  { key: 'assignee', fallsBackToFirst: false },
];

function payloadDefaultOf(payload:WorkPackagePayload, key:string):string | undefined {
  const link = payload._links?.[key];
  if (!link || Array.isArray(link)) return undefined;
  return link.href ?? undefined;
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

/** The values the given fields open with, from what the session remembers and what the API defaults to. */
export async function prefillFor(fields:FormField[], payload:WorkPackagePayload):Promise<Prefill> {
  const remembered = lastSelection();
  const values:FieldValues = {};
  const labels:FieldLabels = {};

  for (const { key, fallsBackToFirst } of PREFILLED_FIELDS) {
    const field = fields.find((candidate) => candidate.key === key);
    if (!field) continue;

    const chosen = await chosenFor(field, payload, remembered[key], fallsBackToFirst);
    if (!chosen) continue;

    values[key] = chosen.href;
    labels[key] = chosen.label;
  }

  return { values, labels };
}

export function selectionToRemember(
  fields:FormField[],
  values:FieldValues,
  labels:FieldLabels
):LastSelection {
  const selection:LastSelection = {};

  for (const { key } of PREFILLED_FIELDS) {
    const field = fields.find((candidate) => candidate.key === key);
    const href = values[key];
    if (!field || typeof href !== 'string' || !href) continue;

    const label = allowedValueOf(field, href)?.label ?? labels[key];
    if (!label) continue;

    selection[key] = { href, label };
  }

  return selection;
}
