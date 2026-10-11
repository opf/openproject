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

import type { IncomingMessage, ServerResponse } from "node:http";
import type { Extension, Hocuspocus, onRequestPayload } from "@hocuspocus/server";
import * as Y from "yjs";
import { mergeBlocks, type MergeConflict } from "../services/blockMergeService";
import {
  type DocumentBlock,
  duplicateBlockIds,
  normalizeBlocks,
  readBlocks,
  revisionOf,
  writeBlocks,
} from "../services/documentContentService";
import { documentJsonSchema, validateBlocks } from "../services/documentSchemaService";
import { RevisionStore } from "../services/revisionStore";
import { loadStoredDocument } from "../services/storedDocumentService";
import { validateRequestToken } from "../services/tokenValidationService";

export const SCHEMA_PATH = "/api/v1/documents/schema";
export const CONTENT_PATH = "/api/v1/documents/content";

const MAX_BODY_BYTES = 5 * 1024 * 1024;

class HttpError extends Error {
  constructor(readonly status: number, message: string, readonly details: Record<string, unknown> = {}) {
    super(message);
  }
}

interface AuthenticatedRequest {
  resourceUrl: string;
  token: string;
  tokenExpiresAt: Date;
  readonly: boolean;
}

function sendJson(response: ServerResponse, status: number, body: unknown) {
  response.writeHead(status, { "Content-Type": "application/json" });
  response.end(JSON.stringify(body));
}

async function readJsonBody(request: IncomingMessage): Promise<unknown> {
  const chunks: Buffer[] = [];
  let size = 0;

  for await (const chunk of request) {
    size += chunk.length;
    if (size > MAX_BODY_BYTES) {
      throw new HttpError(413, "Request body too large.");
    }
    chunks.push(chunk);
  }

  try {
    return JSON.parse(Buffer.concat(chunks).toString("utf8"));
  } catch {
    throw new HttpError(400, "Request body is not valid JSON.");
  }
}

async function authenticate(request: IncomingMessage): Promise<AuthenticatedRequest> {
  const [scheme, encryptedToken] = (request.headers.authorization ?? "").split(" ");
  if (scheme !== "Bearer" || !encryptedToken) {
    throw new HttpError(401, "Missing bearer token.");
  }

  try {
    const result = await validateRequestToken(encryptedToken);
    return {
      resourceUrl: result.resourceUrl,
      token: result.decryptedToken,
      tokenExpiresAt: new Date(result.tokenExpiresAt),
      readonly: result.readonly,
    };
  } catch (error) {
    throw new HttpError(401, error instanceof Error ? error.message : "Unauthorized.");
  }
}

function conflictError(conflict: MergeConflict | "unknown_revision"): HttpError {
  const message = "The document was changed by someone else in a way that conflicts with your edit. " +
    "Read the document again and reapply your changes to its current content.";

  if (conflict === "unknown_revision") {
    return new HttpError(409, message, { reason: "unknown_revision" });
  }

  return new HttpError(409, message, { ...conflict });
}

function parseUpdate(body: unknown): { revision: string, blocks: DocumentBlock[] } {
  const { revision, blocks } = (body ?? {}) as { revision?: unknown, blocks?: unknown };

  if (typeof revision !== "string" || revision.length === 0) {
    throw new HttpError(422, "The revision of the document content the edit is based on is required.");
  }

  const validation = validateBlocks(blocks);
  if (!validation.valid) {
    throw new HttpError(422, "The blocks do not match the document schema.", { errors: validation.errors });
  }

  const duplicates = duplicateBlockIds(blocks as unknown[]);
  if (duplicates.length > 0) {
    throw new HttpError(422, "Block ids must be unique.", { errors: duplicates.map((id) => `Duplicate block id ${id}`) });
  }

  try {
    return { revision, blocks: normalizeBlocks(blocks as unknown[]) };
  } catch (error) {
    throw new HttpError(422, "The blocks cannot be represented in the document.", {
      errors: [error instanceof Error ? error.message : String(error)],
    });
  }
}

/**
 * HTTP API for reading and editing document content outside of a websocket editing session,
 * e.g. on behalf of an AI assistant connected through OpenProject's MCP server.
 *
 * Edits are applied to the live Yjs document, so they reach every connected editor immediately.
 */
export class DocumentContentApi implements Extension {
  constructor(private readonly revisions = new RevisionStore()) {}

  async onRequest({ request, response, instance }: onRequestPayload): Promise<void> {
    const path = new URL(request.url ?? "/", "http://localhost").pathname;
    const route = `${request.method} ${path}`;

    if (path !== SCHEMA_PATH && path !== CONTENT_PATH) {
      return;
    }

    try {
      switch (route) {
        case `GET ${SCHEMA_PATH}`:
          sendJson(response, 200, documentJsonSchema);
          break;
        case `GET ${CONTENT_PATH}`:
          sendJson(response, 200, await this.read(await authenticate(request), instance));
          break;
        case `PUT ${CONTENT_PATH}`:
          sendJson(response, 200, await this.update(await authenticate(request), await readJsonBody(request), instance));
          break;
        default:
          throw new HttpError(405, "Method not allowed.");
      }
    } catch (error) {
      if (error instanceof HttpError) {
        sendJson(response, error.status, { error: error.message, ...error.details });
      } else {
        console.error(`[DocumentContentApi] ${route} failed`, error);
        sendJson(response, 500, { error: "Internal server error." });
      }
    }

    // Hocuspocus answers every request it did not see rejected; null ends the hook chain silently.
    throw null;
  }

  private async read(auth: AuthenticatedRequest, instance: Hocuspocus) {
    const liveDocument = instance.documents.get(auth.resourceUrl);
    const document = liveDocument ?? new Y.Doc();

    if (!liveDocument && !(await loadStoredDocument(auth.resourceUrl, auth.token, document))) {
      throw new HttpError(502, "The document could not be loaded from OpenProject.");
    }

    return this.snapshot(auth.resourceUrl, readBlocks(document));
  }

  private async update(auth: AuthenticatedRequest, body: unknown, instance: Hocuspocus) {
    if (auth.readonly) {
      throw new HttpError(403, "You are not allowed to edit this document.");
    }

    const { revision, blocks } = parseUpdate(body);
    const connection = await instance.openDirectConnection(auth.resourceUrl, {
      resourceUrl: auth.resourceUrl,
      token: auth.token,
      tokenExpiresAt: auth.tokenExpiresAt,
      readonly: false,
    });

    try {
      let failure: HttpError | undefined;
      let result: DocumentBlock[] = [];

      await connection.transact((document) => {
        const current = readBlocks(document);
        const target = this.resolveTarget(auth.resourceUrl, revision, blocks, current);

        if (target instanceof HttpError) {
          failure = target;
          return;
        }

        writeBlocks(document, target);
        result = readBlocks(document);
      });

      if (failure) throw failure;

      return this.snapshot(auth.resourceUrl, result);
    } finally {
      await connection.disconnect();
    }
  }

  private resolveTarget(resourceUrl: string, revision: string, mine: DocumentBlock[], current: DocumentBlock[]) {
    if (revisionOf(current) === revision) {
      return mine;
    }

    const base = this.revisions.recall(resourceUrl, revision);
    if (!base) {
      return conflictError("unknown_revision");
    }

    const merge = mergeBlocks(base, mine, current);
    return "conflict" in merge ? conflictError(merge.conflict) : merge.merged;
  }

  private snapshot(resourceUrl: string, blocks: DocumentBlock[]) {
    const revision = revisionOf(blocks);
    this.revisions.remember(resourceUrl, revision, blocks);
    return { revision, blocks };
  }
}
