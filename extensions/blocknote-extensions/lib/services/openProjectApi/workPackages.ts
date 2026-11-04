import type { HalCollection, WorkPackage } from '../../openProjectTypes';
import { get, instancePathOf, instanceUrl } from './client';
import { OpenProjectApiError } from './errors';
import { typeaheadFilter } from './filters';

export function linkToWorkPackage(displayId:string):string {
  return instanceUrl(`/wp/${encodeURIComponent(displayId)}`);
}

export function linkToNewWorkPackage(projectId?:string):string {
  return projectId
    ? instanceUrl(`/projects/${encodeURIComponent(projectId)}/work_packages/new`)
    : instanceUrl('/work_packages/new');
}

const WP_ID_URL_PATTERN = '\\d+|[A-Za-z][A-Za-z0-9_]*-\\d+';

const WP_ID_REGEX = new RegExp(`^(?:${WP_ID_URL_PATTERN})$`);
const WP_URL_REGEX = new RegExp(`^/(?:wp|(?:projects/[^/]+/)?work_packages)(?:/details)?/(${WP_ID_URL_PATTERN})(?:[/?#]|$)`);

/**
 * Parses a URL of this OpenProject instance pointing to a work package.
 * Recognizes `/wp/{id}`, `/work_packages/{id}` and
 * `/projects/{identifier}/work_packages/{id}` paths, including
 * `/work_packages/details/{id}`, trailing tab segments (`/activity`, ...),
 * query strings and hashes. The id may be numeric (`123`) or a semantic
 * identifier (`PROJ-42`, mirroring WP_ID_URL_PATTERN in the frontend).
 * Returns the work package identifier as a string, or null for any other URL.
 */
export function parseWorkPackageUrl(url:string):string | null {
  const path = instancePathOf(url);
  if (path === null) return null;
  const match = WP_URL_REGEX.exec(path);
  if (!match) return null;
  const id = match[1];
  if (/^\d+$/.test(id)) return Number(id) > 0 ? id : null;
  return id;
}

export function fetchWorkPackage(id:string | number):Promise<WorkPackage> {
  const identifier = String(id);
  if (!WP_ID_REGEX.test(identifier)) {
    return Promise.reject(new OpenProjectApiError(`Invalid work package ID: ${id}`));
  }
  return get<WorkPackage>(`/api/v3/work_packages/${encodeURIComponent(identifier)}`);
}

/*  Keeps the filter short enough for any proxy's URL limit.  */
const WORK_PACKAGES_PER_REQUEST = 100;

async function fetchWorkPackagesPaged(ids:number[]):Promise<WorkPackage[]> {
  const workPackages:WorkPackage[] = [];
  let offset = 1;

  for (;;) {
    const params = new URLSearchParams({
      filters: JSON.stringify([{ id: { operator: '=', values: ids.map(String) } }]),
      // Without it, a single deleted or invisible work package fails the whole request.
      valid_subset: 'true',
      sortBy: JSON.stringify([['id', 'asc']]),
      pageSize: String(ids.length),
      offset: String(offset),
    });
    const page = await get<HalCollection<WorkPackage>>(`/api/v3/work_packages?${params.toString()}`);
    const elements = page._embedded?.elements ?? [];
    const total = page.total ?? elements.length;

    // With none of the ids valid, the API drops the filter and answers with unrelated work packages.
    if (total > ids.length) return [];

    workPackages.push(...elements);
    // The instance may cap the page size below the one asked for.
    if (elements.length === 0 || workPackages.length >= total) return workPackages;
    offset += 1;
  }
}

/**
 * Loads the given work packages in as few requests as possible. Work packages
 * that do not exist or are not visible are missing from the result.
 */
export async function fetchWorkPackages(ids:readonly number[]):Promise<WorkPackage[]> {
  const wanted = [...new Set(ids)].filter((id) => Number.isSafeInteger(id) && id > 0);

  const chunks:number[][] = [];
  for (let start = 0; start < wanted.length; start += WORK_PACKAGES_PER_REQUEST) {
    chunks.push(wanted.slice(start, start + WORK_PACKAGES_PER_REQUEST));
  }

  const workPackages = (await Promise.all(chunks.map(fetchWorkPackagesPaged))).flat();
  const requested = new Set(wanted);
  return workPackages.filter((workPackage) => requested.has(workPackage.id));
}

export async function searchWorkPackages(query:string):Promise<WorkPackage[]> {
  const params = new URLSearchParams({
    filters: JSON.stringify([typeaheadFilter(query)]),
    sortBy: JSON.stringify([['exactMatch', 'desc'], ['updatedAt', 'desc']]),
  });

  const data = await get<HalCollection<WorkPackage>>(`/api/v3/work_packages?${params.toString()}`);
  return data._embedded?.elements ?? [];
}
