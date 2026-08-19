const OPENPROJECT_URL = process.env.OPENPROJECT_URL?.trim() || null;
const OPENPROJECT_HTTPS = process.env.OPENPROJECT_HTTPS?.trim() === 'true';

if (OPENPROJECT_URL) {
  const openProjectDirectUrl = new URL(OPENPROJECT_URL);
  if (!openProjectDirectUrl.protocol || !openProjectDirectUrl.hostname) {
    throw new Error(`Invalid OPENPROJECT_DIRECT_URL: ${OPENPROJECT_URL}`);
  }

  console.log(`using OPENPROJECT_URL: ${OPENPROJECT_URL}`);
}

if (OPENPROJECT_HTTPS) {
  console.log(`using OPENPROJECT_HTTPS: ${OPENPROJECT_HTTPS}`);
}

/**
 * Fetches an OpenProject resource while automatically adjusting request URL and host header
 * based on the value of OPENPROJECT_URL in the environment.
 * 
 * @param resourceUrl URL of OpenProject resource to fetch
 * @param oauthToken OAuth Bearer token to authenticate with
 * @param override Override request init params (e.g. method, headers)
 * @returns Http response
 */
export async function fetchResource(
  resourceUrl: string,
  oauthToken: string,
  override?: RequestInit
): Promise<Response> {
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    "Authorization": `Bearer ${oauthToken}`,
    ...(OPENPROJECT_URL && OPENPROJECT_HTTPS && { "X-Forwarded-Proto": "https" })
  };
  const url = overrideUrl(resourceUrl);
  const init = {
    method: 'GET',
    headers: headers,
    ...override
  }

  console.log(`[${new Date().toISOString()}] ${init.method} ${url}`);

  return fetch(url, init);
}

/**
 * Get the effective OpenProject resource URL considering the value of
 * OPENPROJECT_URL in the environment.
 * 
 * @param resourceUrl URL of OpenProject resource
 * @returns Either the given resource URL if no override has been configured, or the adjusted URL.
 */
function overrideUrl(resourceUrl: string): string {
  return OPENPROJECT_URL ? overrideBaseUrl(resourceUrl, OPENPROJECT_URL) : resourceUrl;
}

/**
 * Replaces the protocol and hostname of the given resource URL with those of the given overrideUrl.
 */
function overrideBaseUrl(resourceUrl:string, overrideUrl: string):string {
  const baseUrl = new URL(overrideUrl);
  const resourcePath = new URL(resourceUrl).pathname;

  if (baseUrl.pathname.endsWith('/') && resourcePath.startsWith('/')) {
    baseUrl.pathname += resourcePath.slice(1);
  } else {
    baseUrl.pathname += resourcePath;
  }

  return baseUrl.toString();
}
