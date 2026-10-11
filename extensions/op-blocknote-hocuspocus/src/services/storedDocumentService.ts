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

import { setTimeout as sleep } from "node:timers/promises";
import * as Y from "yjs";
import type { ApiResponseDocument } from "../types";
import { fetchResource } from "./resourceService";

export const LOAD_RETRY_DELAYS_MS = [500, 1000, 2000, 4000];

const RETRYABLE_STATUSES = new Set([408, 429, 500, 502, 503, 504]);

export class DocumentLoadError extends Error {}

type FetchOutcome =
  { ok: true, document: ApiResponseDocument } |
  { ok: false, retryable: boolean, reason: string };

async function fetchStoredDocument(resourceUrl: string, oauthToken: string): Promise<FetchOutcome> {
  let response: Response;
  try {
    response = await fetchResource(resourceUrl, oauthToken);
  } catch (error) {
    return { ok: false, retryable: true, reason: error instanceof Error ? error.message : String(error) };
  }

  if (response.status !== 200) {
    return {
      ok: false,
      retryable: RETRYABLE_STATUSES.has(response.status),
      reason: `${response.status}: ${response.statusText}`,
    };
  }

  return { ok: true, document: await response.json() as ApiResponseDocument };
}

/**
 * Applies the persisted Yjs state of an OpenProject resource to the given document.
 *
 * Transient failures are retried with the given delays. Throws a DocumentLoadError if the state cannot be loaded,
 * because continuing with an empty document would overwrite the stored content on the next save.
 */
export async function loadStoredDocument(
  resourceUrl: string,
  oauthToken: string,
  document: Y.Doc,
  retryDelaysMs: number[] = LOAD_RETRY_DELAYS_MS,
): Promise<void> {
  for (let attempt = 0; ; attempt++) {
    const outcome = await fetchStoredDocument(resourceUrl, oauthToken);

    if (outcome.ok) {
      if (outcome.document.contentBinary) {
        Y.applyUpdate(document, new Uint8Array(Buffer.from(outcome.document.contentBinary, "base64")));
      }
      return;
    }

    if (!outcome.retryable || attempt >= retryDelaysMs.length) {
      throw new DocumentLoadError(`Error loading ${resourceUrl} after ${attempt + 1} attempt(s) (${outcome.reason})`);
    }

    console.warn(`Error loading ${resourceUrl} (${outcome.reason}), retrying in ${retryDelaysMs[attempt]}ms`);
    await sleep(retryDelaysMs[attempt]);
  }
}
