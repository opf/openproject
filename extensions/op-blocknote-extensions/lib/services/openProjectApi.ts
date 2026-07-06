
import type {OpenProjectResponse, StatusCollection, TypeCollection, WorkPackage} from '../openProjectTypes';

let baseUrl = 'https://openproject.local';


export class OpenProjectApiError extends Error {
  responseStatus?:number;

  constructor(message:string, responseStatus?:number) {
    super(message);
    this.responseStatus = responseStatus;
    this.name = 'OpenProjectApiError';
  }
}

export function initOpenProjectApi(config:{ baseUrl:string }) {
  baseUrl = config.baseUrl;
  if (baseUrl.endsWith('/')) {
    baseUrl = baseUrl.slice(0, -1);
  }
}

async function get<T>(endpoint:string):Promise<T> {
  const response = await fetch(`${baseUrl}${endpoint}`, {
    method: 'GET',
    headers: { 'Content-Type': 'application/json' },
  });
  if (!response.ok) {
    throw new OpenProjectApiError(`HTTP error! status: ${response.status} - ${response.statusText}`, response.status);
  }
  return response.json() as Promise<T>;
}

export function linkToWorkPackage(displayId:string):string {
  return `${baseUrl}/wp/${encodeURIComponent(displayId)}`;
}

/**
 * Parses a URL of this OpenProject instance pointing to a work package.
 * Recognizes `/wp/{id}`, `/work_packages/{id}` and
 * `/projects/{identifier}/work_packages/{id}` paths, including
 * `/work_packages/details/{id}`, trailing tab segments (`/activity`, ...),
 * query strings and hashes. Returns the numeric work package id, or null
 * for any other URL.
 */
export function parseWorkPackageUrl(url:string):number | null {
  if (!url.startsWith(`${baseUrl}/`)) return null;
  const path = url.slice(baseUrl.length);
  const match = /^\/(?:projects\/[^/]+\/)?(?:wp|work_packages)(?:\/details)?\/(\d+)(?:[/?#]|$)/.exec(path);
  if (!match) return null;
  const id = Number(match[1]);
  return id > 0 ? id : null;
}

export function fetchWorkPackage(id:number):Promise<WorkPackage> {
  if (isNaN(id) || id <= 0) {
    return Promise.reject(new OpenProjectApiError(`Invalid work package ID: ${id}`));
  }
  return get<WorkPackage>(`/api/v3/work_packages/${id}`);
}

export function fetchStatuses():Promise<StatusCollection> {
  return get<StatusCollection>('/api/v3/statuses').catch((error:unknown) => {
    console.error('[OpenProjectApi] fetchStatuses failed:', error);
    // eslint-disable-next-line @typescript-eslint/prefer-promise-reject-errors
    return Promise.reject(error);
  });
}

export function fetchTypes():Promise<TypeCollection> {
  return get<TypeCollection>('/api/v3/types').catch((error:unknown) => {
    console.error('[OpenProjectApi] fetchTypes failed:', error);
    // eslint-disable-next-line @typescript-eslint/prefer-promise-reject-errors
    return Promise.reject(error);
  });
}

export async function searchWorkPackages(query:string):Promise<WorkPackage[]> {
  const filters = encodeURIComponent(`[{"typeahead":{"operator":"**","values":["${query}"]}}]`);
  const sortBy = encodeURIComponent('[["updatedAt","desc"]]');

  const endpoint = `/api/v3/work_packages?filters=${filters}&sortBy=${sortBy}`;
  const data = await get<OpenProjectResponse>(endpoint);
  return data?._embedded?.elements as unknown as WorkPackage[] ?? [];
}
