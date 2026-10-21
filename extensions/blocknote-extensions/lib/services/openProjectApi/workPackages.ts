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

export async function searchWorkPackages(query:string):Promise<WorkPackage[]> {
  const params = new URLSearchParams({
    filters: JSON.stringify([typeaheadFilter(query)]),
    sortBy: JSON.stringify([['exactMatch', 'desc'], ['updatedAt', 'desc']]),
  });

  const data = await get<HalCollection<WorkPackage>>(`/api/v3/work_packages?${params.toString()}`);
  return data._embedded?.elements ?? [];
}
