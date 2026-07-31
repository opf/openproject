
import type {OpenProjectResponse, StatusCollection, TypeCollection, WorkPackage} from '../openProjectTypes';

let baseUrl = 'https://openproject.local';
let proxyUrl = 'https://openproject.local';


export class OpenProjectApiError extends Error {
  responseStatus?:number;

  constructor(message:string, responseStatus?:number) {
    super(message);
    this.responseStatus = responseStatus;
    this.name = 'OpenProjectApiError';
  }
}

function stripTrailingSlash(url:string):string {
  return url.endsWith('/') ? url.slice(0, -1) : url;
}

/**
 * Initializes the API configuration.
 *
 * `baseUrl` is the address of the OpenProject instance. It is used for links
 * pointing to work packages and for recognizing pasted work package URLs.
 * `proxyUrl` is the address the authorized API requests are sent to. It
 * defaults to `baseUrl` and only needs to be given if the API traffic has to
 * be routed through a proxy, for example to inject authorization.
 */
export function initOpenProjectApi(config:{ baseUrl:string, proxyUrl?:string }) {
  baseUrl = stripTrailingSlash(config.baseUrl);
  proxyUrl = stripTrailingSlash(config.proxyUrl ?? config.baseUrl);
}

async function get<T>(endpoint:string):Promise<T> {
  const response = await fetch(`${proxyUrl}${endpoint}`, {
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
  if (!url.startsWith(`${baseUrl}/`)) return null;
  const path = url.slice(baseUrl.length);
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
