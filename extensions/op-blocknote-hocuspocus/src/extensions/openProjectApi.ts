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

import { BlockNoteSchema } from "@blocknote/core";
import { ServerBlockNoteEditor } from "@blocknote/server-util";
import type { beforeHandleMessagePayload, onAuthenticatePayload, onLoadDocumentPayload, onStoreDocumentPayload, onTokenSyncPayload } from "@hocuspocus/server";
import { Extension } from "@hocuspocus/server";
import {
  openProjectWorkPackageStaticBlockSpec,
  openProjectWorkPackageStaticInlineSpec,
  openProjectWorkPackageAttributeStaticInlineSpec,
  openProjectWorkPackageAttributeStaticBlockSpec,
} from "@openproject/blocknote-extensions/server";
import * as Y from "yjs";
import { TokenExpired, TokenExpiryMissing, unauthorized } from "../closeEvents";
import { decryptAndValidateToken } from "../services/tokenValidationService";
import type { ApiResponseDocument } from "../types";
import { fetchResource } from "../services/resourceService";
import { createLogger } from "../logger";

export const editorSchema = BlockNoteSchema.create().extend({
  blockSpecs: {
    openProjectWorkPackageBlock: openProjectWorkPackageStaticBlockSpec(),
    openProjectWorkPackageAttributeBlock: openProjectWorkPackageAttributeStaticBlockSpec(),
  },
  inlineContentSpecs: {
    openProjectWorkPackageInline: openProjectWorkPackageStaticInlineSpec,
    openProjectWorkPackageAttributeInline: openProjectWorkPackageAttributeStaticInlineSpec,
  },
});

const authLogger = createLogger("Auth");
const documentLogger = createLogger("Document");

export function createEditor() {
  return ServerBlockNoteEditor.create({ schema: editorSchema });
}

export class OpenProjectApi implements Extension {
  /**
   * Authenticate the user by validating the token and document access
   */
  async onAuthenticate(data: onAuthenticatePayload) {
    try {
      await this.authenticate(data);
    } catch (error) {
      const reason = error instanceof Error ? error.message : "Authentication failed";
      authLogger.error(`Authentication failed for ${data.documentName}: ${reason}`);
      throw error;
    }
  }

  private async authenticate(data: onAuthenticatePayload) {
    const { token, documentName } = data;
    const resourceUrl = documentName;

    if (!token) {
      throw new Error('Unauthorized: Missing auth params');
    }

    const requestOrigin = data.requestHeaders?.get("origin") ?? undefined;
    const result = await decryptAndValidateToken(token, resourceUrl, requestOrigin);

    const tokenExpiresAtDate = new Date(result.tokenExpiresAt);
    if (tokenExpiresAtDate <= new Date()) {
      throw new Error('Unauthorized: Token already expired.');
    }

    data.context.resourceUrl = resourceUrl;
    data.context.token = result.decryptedToken;
    data.context.tokenExpiresAt = tokenExpiresAtDate;

    if (result.readonly) {
      // https://tiptap.dev/docs/hocuspocus/guides/auth#read-only-mode
      data.connectionConfig.readOnly = true;
      data.context.readonly = true;
    }
  }

  /**
   * Check token expiry before processing any message.
   * Throwing CloseEvent closes the connection with the specified reason.
   */
  async beforeHandleMessage(data: beforeHandleMessagePayload): Promise<void> {
    const { tokenExpiresAt } = data.context;

    if (!tokenExpiresAt) {
      authLogger.warn("Missing tokenExpiresAt, closing connection");
      throw TokenExpiryMissing;
    }

    if (tokenExpiresAt <= new Date()) {
      authLogger.warn("Token expired, closing connection");
      throw TokenExpired;
    }
  }

  /**
    * Retrieve data from the API. This should return the YDoc data
    */
  async onLoadDocument(data: onLoadDocumentPayload) {
    const { resourceUrl } = data.context;
    const response = await fetchResource(resourceUrl, data.context.token);

    if (response.status != 200) {
      return;
    }

    const jsonData = await response.json() as ApiResponseDocument;
    if (jsonData.contentBinary) {
      const update = new Uint8Array(Buffer.from(jsonData.contentBinary, 'base64'));
      Y.applyUpdate(data.document, update);
    }

    return data.document;
  }

  /**
    * Store data to the API. The data is a YDoc update
    */
  async onStoreDocument(data: onStoreDocumentPayload): Promise<void> {
    const { resourceUrl, readonly } = data.lastContext;

    if (!resourceUrl) {
      documentLogger.warn("Missing parameters in context. Skipping store.");
      return;
    }
    if (readonly) {
      documentLogger.warn(`Readonly user cannot store ${resourceUrl}`);
      return;
    }

    const base64Data = Buffer.from(Y.encodeStateAsUpdate(data.document)).toString("base64");

    // Create a copy of the document to avoid side effects
    const editor = createEditor();
    const tempYdoc = new Y.Doc();
    Y.applyUpdate(tempYdoc, Y.encodeStateAsUpdate(data.document));
    const tempFragment = tempYdoc.getXmlFragment("document-store");
    const editorData = editor.yXmlFragmentToBlocks(tempFragment);
    const markdownData = await editor.blocksToMarkdownLossy(editorData);

    const response = await fetchResource(resourceUrl, data.lastContext.token, {
      method: "PATCH",
      body: JSON.stringify({
        content_binary: base64Data,
        description: markdownData,
      }),
    });

    if (response.status != 200) {
      return;
    }

    data.document.broadcastStateless("storeEvent");
  }

  /**
   * Handle token sync from clients (triggered by provider.sendToken())
   */
  async onTokenSync(data: onTokenSyncPayload): Promise<void> {
    const { token, connection } = data;
    if (!token) {
      return;
    }

    const { resourceUrl } = connection.context;
    if (!resourceUrl) {
      return;
    }

    try {
      const result = await decryptAndValidateToken(token, resourceUrl);

      // Check if refreshed token is already expired (defensive)
      const tokenExpiresAt = new Date(result.tokenExpiresAt);
      if (tokenExpiresAt <= new Date()) {
        connection.close(unauthorized("Token sync failed: received expired token"));
        return;
      }

      connection.context.token = result.decryptedToken;
      connection.context.tokenExpiresAt = tokenExpiresAt;

      // Update permissions if changed
      const isReadOnly = result.readonly;
      if (isReadOnly !== connection.readOnly) {
        connection.readOnly = isReadOnly;
        connection.context.readonly = isReadOnly;
      }

      authLogger.log(`Token synced for ${resourceUrl} readonly=${result.readonly}`);
    } catch (error) {
      // Explicitly close connection on validation failure
      const reason = error instanceof Error ? error.message : "Token sync failed";
      authLogger.error(`Token sync failed: ${reason}`);
      connection.close(unauthorized(reason));
    }
  }
}
