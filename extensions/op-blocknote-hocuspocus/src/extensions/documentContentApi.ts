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
import {
  type DocumentBlock,
  duplicateBlockIds,
  editOnto,
  normalizeBlocks,
  readBlocks,
} from "../services/documentContentService";
import { documentJsonSchema, validateBlocks } from "../services/documentSchemaService";
import { RevisionStore } from "../services/revisionStore";
import { DocumentLoadError, loadStoredDocument } from "../services/storedDocumentService";
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

// Reverse proxies may forward requests without stripping the path hocuspocus is mounted under.
function routedPath(request: IncomingMessage): string | undefined {
  const { pathname } = new URL(request.url ?? "/", "http://localhost");
  return [SCHEMA_PATH, CONTENT_PATH].find((path) => pathname.endsWith(path));
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

async function withLoadErrorHandling<T>(load: () => Promise<T>): Promise<T> {
  try {
    return await load();
  } catch (error) {
    if (error instanceof DocumentLoadError) {
      throw new HttpError(502, "The document could not be loaded from OpenProject.");
    }
    throw error;
  }
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
 * The client takes part like any other editor: an edit becomes a Yjs update relative to the revision it was based on,
 * which merges with concurrent changes and reaches every connected editor immediately.
 */
export class DocumentContentApi implements Extension {
  constructor(private readonly revisions = new RevisionStore()) {}

  async onRequest({ request, response, instance }: onRequestPayload): Promise<void> {
    const path = routedPath(request);
    if (!path) {
      return;
    }

    const route = `${request.method} ${path}`;

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
    if (liveDocument) {
      return this.snapshot(auth.resourceUrl, liveDocument);
    }

    const document = new Y.Doc();
    await withLoadErrorHandling(() => loadStoredDocument(auth.resourceUrl, auth.token, document));
    return this.snapshot(auth.resourceUrl, document);
  }

  private async update(auth: AuthenticatedRequest, body: unknown, instance: Hocuspocus) {
    if (auth.readonly) {
      throw new HttpError(403, "You are not allowed to edit this document.");
    }

    const { revision, blocks } = parseUpdate(body);
    const baseState = this.revisions.recall(auth.resourceUrl, revision);
    if (!baseState) {
      throw new HttpError(409, "The revision is unknown or has expired. Read the document again and reapply your changes.");
    }

    const { update, editedState } = editOnto(baseState, blocks);
    const connection = await withLoadErrorHandling(() => instance.openDirectConnection(auth.resourceUrl, {
      resourceUrl: auth.resourceUrl,
      token: auth.token,
      tokenExpiresAt: auth.tokenExpiresAt,
      readonly: false,
    }));

    try {
      let result: ReturnType<DocumentContentApi["snapshot"]> | undefined;

      await connection.transact((document) => {
        Y.applyUpdate(document, update);
        this.revisions.replace(auth.resourceUrl, revision, editedState);
        result = this.snapshot(auth.resourceUrl, document);
      });

      return result!;
    } finally {
      await connection.disconnect();
    }
  }

  private snapshot(resourceUrl: string, document: Y.Doc) {
    const revision = this.revisions.remember(resourceUrl, Y.encodeStateAsUpdate(document));
    return { revision, blocks: readBlocks(document) };
  }
}
