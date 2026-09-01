
import type {
  HalCollection,
  HalResource,
  OpenProjectApiErrorBody,
  OpenProjectResponse,
  StatusCollection,
  TypeCollection,
  WorkPackage,
  WorkPackageForm,
  WorkPackagePayload,
} from '../openProjectTypes';

let baseUrl = 'https://openproject.local';
let proxyUrl = 'https://openproject.local';


export class OpenProjectApiError extends Error {
  responseStatus?:number;
  attributeErrors:Record<string, string>;

  constructor(message:string, responseStatus?:number, attributeErrors:Record<string, string> = {}) {
    super(message);
    this.responseStatus = responseStatus;
    this.attributeErrors = attributeErrors;
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

interface ApiError {
  message:string;
  attributeErrors:Record<string, string>;
}

async function readError(response:Response):Promise<ApiError> {
  const statusLine = `HTTP error! status: ${response.status} - ${response.statusText}`;

  try {
    const body = await response.json() as OpenProjectApiErrorBody;
    // A lone violation is the error itself; several are nested under a summary.
    const entries = body._embedded?.errors ?? [body];
    const messages = entries.flatMap((entry) => (entry.message ? [entry.message] : []));

    const attributeErrors:Record<string, string> = {};
    for (const entry of entries) {
      const attribute = entry._embedded?.details?.attribute;
      if (attribute && entry.message && !attributeErrors[attribute]) attributeErrors[attribute] = entry.message;
    }

    if (messages.length > 0) return { message: messages.join(' '), attributeErrors };

    return { message: body.message ?? statusLine, attributeErrors };
  } catch { /* no JSON body */ }

  return { message: statusLine, attributeErrors: {} };
}

async function post<T>(endpoint:string, body:unknown):Promise<T> {
  const response = await fetch(`${proxyUrl}${endpoint}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      // The API refuses a session authenticated write without it over plain HTTP.
      'X-Requested-With': 'XMLHttpRequest',
    },
    body: JSON.stringify(body),
  });
  if (!response.ok) {
    const { message, attributeErrors } = await readError(response);
    throw new OpenProjectApiError(message, response.status, attributeErrors);
  }
  return response.json() as Promise<T>;
}

export function linkToWorkPackage(displayId:string):string {
  return `${baseUrl}/wp/${encodeURIComponent(displayId)}`;
}

export function linkToNewWorkPackage(projectId?:string):string {
  return projectId
    ? `${baseUrl}/projects/${encodeURIComponent(projectId)}/work_packages/new`
    : `${baseUrl}/work_packages/new`;
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

const ALLOWED_VALUES_PAGE_SIZE = 20;

/**
 * Asks the API which attributes a new work package needs: an empty payload yields
 * the bare schema, sending the project back its types, the type its statuses.
 */
export function fetchWorkPackageCreateForm(payload:WorkPackagePayload = {}):Promise<WorkPackageForm> {
  return post<WorkPackageForm>('/api/v3/work_packages/form', payload);
}

export function createWorkPackage(payload:WorkPackagePayload):Promise<WorkPackage> {
  return post<WorkPackage>('/api/v3/work_packages', payload);
}

function withFilter(href:string, filter:Record<string, unknown>):string {
  const separator = href.indexOf('?');
  const path = separator === -1 ? href : href.slice(0, separator);
  const params = new URLSearchParams(separator === -1 ? '' : href.slice(separator + 1));

  let filters:unknown[] = [];
  try {
    const parsed = JSON.parse(params.get('filters') ?? '[]') as unknown;
    if (Array.isArray(parsed)) filters = parsed;
  } catch { /* not our filters to interpret */ }
  filters.push(filter);

  params.set('filters', JSON.stringify(filters));
  if (!params.has('pageSize')) params.set('pageSize', String(ALLOWED_VALUES_PAGE_SIZE));

  return `${path}?${params.toString()}`;
}

/**
 * Follows the `allowedValues` link of a schema attribute, narrowed by a typeahead
 * term. An endpoint that rejects the filter answers 400 and is retried unfiltered.
 */
export async function fetchAllowedValues(
  href:string,
  query = ''
):Promise<{ resources:HalResource[]; filtered:boolean }> {
  if (!href.startsWith('/api/v3/')) {
    throw new OpenProjectApiError(`Unexpected allowed values href: ${href}`);
  }

  const trimmedQuery = query.trim();
  if (trimmedQuery) {
    try {
      const filtered = await get<HalCollection<HalResource>>(
        withFilter(href, { typeahead: { operator: '**', values: [trimmedQuery] } })
      );
      return { resources: filtered._embedded?.elements ?? [], filtered: true };
    } catch (error) {
      if (!(error instanceof OpenProjectApiError) || error.responseStatus !== 400) throw error;
      console.warn('[OpenProjectApi] typeahead filter rejected, retrying unfiltered:', error);
    }
  }

  const data = await get<HalCollection<HalResource>>(href);
  return { resources: data._embedded?.elements ?? [], filtered: false };
}

/** Follows the `allowedValues` link of a schema attribute, narrowed to the resource of the given id. */
export async function fetchAllowedValueById(
  href:string,
  id:string | number
):Promise<HalResource | undefined> {
  if (!href.startsWith('/api/v3/')) {
    throw new OpenProjectApiError(`Unexpected allowed values href: ${href}`);
  }

  const data = await get<HalCollection<HalResource>>(
    withFilter(href, { id: { operator: '=', values: [String(id)] } })
  );
  return data._embedded?.elements?.[0];
}

export async function searchWorkPackages(query:string):Promise<WorkPackage[]> {
  const params = new URLSearchParams({
    filters: JSON.stringify([{ typeahead: { operator: '**', values: [query] } }]),
    sortBy: JSON.stringify([['exactMatch', 'desc'], ['updatedAt', 'desc']]),
  });

  const data = await get<OpenProjectResponse>(`/api/v3/work_packages?${params.toString()}`);
  return data?._embedded?.elements as unknown as WorkPackage[] ?? [];
}
