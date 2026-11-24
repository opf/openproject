//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { createLogger } from "../logger";

const logger = createLogger();

const ERROR_BODY_MAX_LENGTH = 2000;

const OPENPROJECT_URL = process.env.OPENPROJECT_URL?.trim() || null;
const OPENPROJECT_HTTPS = process.env.OPENPROJECT_HTTPS?.trim() === 'true';

if (OPENPROJECT_URL) {
  const openProjectDirectUrl = new URL(OPENPROJECT_URL);
  if (!openProjectDirectUrl.protocol || !openProjectDirectUrl.hostname) {
    throw new Error(`Invalid OPENPROJECT_DIRECT_URL: ${OPENPROJECT_URL}`);
  }

  logger.log(`using OPENPROJECT_URL: ${OPENPROJECT_URL}`);
}

if (OPENPROJECT_HTTPS) {
  logger.log(`using OPENPROJECT_HTTPS: ${OPENPROJECT_HTTPS}`);
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

  const target = `${init.method} ${url}`;
  const startedAt = performance.now();
  const elapsed = () => Math.round(performance.now() - startedAt);

  let response: Response;
  try {
    response = await fetch(url, init);
  } catch (error) {
    logger.error(`${target} failed after ${elapsed()}ms`, error);
    logger.error(OPENPROJECT_URL
      ? `Hint: OpenProject is not reachable under OPENPROJECT_URL (${OPENPROJECT_URL}). Check that it is correct (see README).`
      : "Hint: if OpenProject is not reachable from hocuspocus under this URL, configure OPENPROJECT_URL (see README).");
    throw error;
  }

  if (response.ok) {
    logger.log(`${target} -> ${response.status} (${elapsed()}ms)`);
  } else {
    const body = await response.clone().text();
    logger.warn(`${target} -> ${response.status} (${elapsed()}ms)`, body.slice(0, ERROR_BODY_MAX_LENGTH));
  }

  return response;
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
