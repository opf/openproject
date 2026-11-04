import type { HalCollection, HalResource } from '../../openProjectTypes';
import { get } from './client';
import { OpenProjectApiError } from './errors';
import { type HalFilter, typeaheadFilter } from './filters';

/*  Beyond one page of them a listing is searched rather than browsed.  */
const ALLOWED_VALUES_PAGE_SIZE = 100;

/*  What the API reads as "not a page of them, all of them".  */
const UNPAGINATED_PAGE_SIZE = -1;

const FAVORED_FILTER:HalFilter = { favored: { operator: '=', values: ['t'] } };

const HIERARCHY_ORDER = JSON.stringify([['lft', 'asc']]);

export interface AllowedValuesQuery {
  favoredOnly?:boolean;
  nested?:boolean;
  /** Whether the endpoint narrows nothing itself: the listing is then asked for whole and matched here. */
  notServerSideFilterable?:boolean;
}

function withQuery(
  href:string,
  added:HalFilter[],
  { nested, notServerSideFilterable }:AllowedValuesQuery
):string {
  const separator = href.indexOf('?');
  const path = separator === -1 ? href : href.slice(0, separator);
  const params = new URLSearchParams(separator === -1 ? '' : href.slice(separator + 1));

  if (added.length > 0) {
    let filters:unknown[] = [];
    try {
      const parsed = JSON.parse(params.get('filters') ?? '[]') as unknown;
      if (Array.isArray(parsed)) filters = parsed;
    } catch { /* not our filters to interpret */ }

    params.set('filters', JSON.stringify([...filters, ...added]));
  }

  if (nested && !params.has('sortBy')) params.set('sortBy', HIERARCHY_ORDER);
  if (!params.has('pageSize')) {
    const size = notServerSideFilterable ? UNPAGINATED_PAGE_SIZE : ALLOWED_VALUES_PAGE_SIZE;
    params.set('pageSize', String(size));
  }

  return `${path}?${params.toString()}`;
}

async function listValues(url:string):Promise<HalResource[]> {
  const data = await get<HalCollection<HalResource>>(url);
  return data._embedded?.elements ?? [];
}

function assertApiHref(href:string):void {
  if (!href.startsWith('/api/v3/')) {
    throw new OpenProjectApiError(`Unexpected allowed values href: ${href}`);
  }
}

/**
 * Follows the `allowedValues` link of a schema attribute, narrowed by a typeahead
 * term and by what the caller asks for. An endpoint that rejects the typeahead
 * filter answers 400 and is retried without the term.
 */
export async function fetchAllowedValues(
  href:string,
  query = '',
  { favoredOnly = false, nested = false, notServerSideFilterable = false }:AllowedValuesQuery = {}
):Promise<{ resources:HalResource[]; filtered:boolean }> {
  assertApiHref(href);

  const listing = { nested, notServerSideFilterable };
  const kept = favoredOnly ? [FAVORED_FILTER] : [];
  const trimmedQuery = query.trim();

  if (trimmedQuery) {
    try {
      const narrowing = [...kept, typeaheadFilter(trimmedQuery)];
      return { resources: await listValues(withQuery(href, narrowing, listing)), filtered: true };
    } catch (error) {
      if (!(error instanceof OpenProjectApiError) || error.responseStatus !== 400) throw error;
      console.warn('[OpenProjectApi] typeahead filter rejected, retrying unfiltered:', error);
    }
  }

  return { resources: await listValues(withQuery(href, kept, listing)), filtered: false };
}

/** Follows the `allowedValues` link of a schema attribute, narrowed to the resource of the given id. */
export async function fetchAllowedValueById(
  href:string,
  id:string | number
):Promise<HalResource | undefined> {
  assertApiHref(href);

  const [resource] = await listValues(withQuery(href, [{ id: { operator: '=', values: [String(id)] } }], {}));
  return resource;
}
