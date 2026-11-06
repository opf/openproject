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

import { randomUUID } from "node:crypto";
import { loggableUrl, printLog } from "../logger";

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

const UNREACHABLE_HINT =
  "Hint: if OpenProject is not reachable from hocuspocus under this URL, configure OPENPROJECT_URL (see README).";
const ERROR_BODY_MAX_LENGTH = 2_000;

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
  const requestId = randomUUID();
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    "Authorization": `Bearer ${oauthToken}`,
    "X-Request-Id": requestId,
    ...(OPENPROJECT_URL && OPENPROJECT_HTTPS && { "X-Forwarded-Proto": "https" })
  };
  const url = overrideUrl(resourceUrl);
  const init = {
    method: 'GET',
    headers: headers,
    ...override
  }

  const target = `${init.method} ${loggableUrl(url)} request_id=${requestId}`;
  const startedAt = performance.now();
  const elapsed = () => Math.round(performance.now() - startedAt);

  try {
    const response = await fetch(url, init);
    const errorDetails = response.ok ? "" : ` ${await describeErrorResponse(response)}`;
    printLog(`${target} -> ${response.status} (${elapsed()}ms)${errorDetails}`);
    return response;
  } catch (error) {
    printLog(`${target} failed after ${elapsed()}ms: ${describeFetchError(error)}`);
    printLog(UNREACHABLE_HINT);
    throw error;
  }
}

export async function describeErrorResponse(response: Response): Promise<string> {
  try {
    const body = (await response.clone().text()).replace(/\s+/g, " ").trim();
    return body ? truncate(body, ERROR_BODY_MAX_LENGTH) : "(empty body)";
  } catch {
    return "(unreadable body)";
  }
}

function truncate(text: string, maxLength: number): string {
  return text.length > maxLength ? `${text.slice(0, maxLength)}…` : text;
}

export function describeFetchError(error: unknown): string {
  if (!(error instanceof Error)) {
    return String(error);
  }

  const cause = error.cause as (NodeJS.ErrnoException & { address?: string, port?: number }) | undefined;
  if (!(cause instanceof Error)) {
    return `${error.name}: ${error.message}`;
  }

  const details = [
    cause.code,
    cause.syscall,
    cause.address && `${cause.address}:${cause.port}`,
  ].filter((detail) => detail && !cause.message.includes(detail));

  return `${error.message} (${cause.message}${details.length ? `; ${details.join(" ")}` : ""})`;
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
