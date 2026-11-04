import { errorFromBody, errorFromStatus } from './errors';

let baseUrl = 'https://openproject.local';
let proxyUrl = 'https://openproject.local';

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

export function instanceUrl(path:string):string {
  return `${baseUrl}${path}`;
}

export function instancePathOf(url:string):string | null {
  return url.startsWith(`${baseUrl}/`) ? url.slice(baseUrl.length) : null;
}

export async function get<T>(endpoint:string):Promise<T> {
  const response = await fetch(`${proxyUrl}${endpoint}`, {
    method: 'GET',
    headers: { 'Content-Type': 'application/json' },
  });
  if (!response.ok) throw errorFromStatus(response);
  return response.json() as Promise<T>;
}

export async function post<T>(endpoint:string, body:unknown):Promise<T> {
  const response = await fetch(`${proxyUrl}${endpoint}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      // The API refuses a session authenticated write without it over plain HTTP.
      'X-Requested-With': 'XMLHttpRequest',
    },
    body: JSON.stringify(body),
  });
  if (!response.ok) throw await errorFromBody(response);
  return response.json() as Promise<T>;
}
