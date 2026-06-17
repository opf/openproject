import { BlockNoteSchema } from "@blocknote/core";
import { ServerBlockNoteEditor } from "@blocknote/server-util";
import type { beforeHandleMessagePayload, onAuthenticatePayload, onLoadDocumentPayload, onStoreDocumentPayload, onTokenSyncPayload } from "@hocuspocus/server";
import { Extension } from "@hocuspocus/server";
import {
  openProjectWorkPackageStaticBlockSpec,
  openProjectWorkPackageStaticInlineSpec,
} from "op-blocknote-extensions/server";
import * as Y from "yjs";
import { TokenExpired, TokenExpiryMissing, unauthorized } from "../closeEvents";
import { decryptAndValidateToken } from "../services/tokenValidationService";
import type { ApiResponseDocument } from "../types";
import { fetchResource } from "../services/resourceService";

export const editorSchema = BlockNoteSchema.create().extend({
  blockSpecs: {
    openProjectWorkPackageBlock: openProjectWorkPackageStaticBlockSpec(),
  },
  inlineContentSpecs: {
    openProjectWorkPackageInline: openProjectWorkPackageStaticInlineSpec,
  },
});

function printLog(message:string) {
  console.log(`[${new Date().toISOString()}] ${message}`);
}

export function createEditor() {
  return ServerBlockNoteEditor.create({ schema: editorSchema });
}

export class OpenProjectApi implements Extension {
  /**
   * Authenticate the user by validating the token and document access
   */
  async onAuthenticate(data: onAuthenticatePayload) {
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
      printLog("[beforeHandleMessage] Missing tokenExpiresAt, closing connection");
      throw TokenExpiryMissing;
    }

    if (tokenExpiresAt <= new Date()) {
      printLog("[beforeHandleMessage] Token expired, closing connection");
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
      console.warn(`Error fetching document (${response.status}: ${response.statusText})`);
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
      console.warn("Missing parameters in context. Skipping store.");
      return;
    }
    if (readonly) {
      console.warn("Readonly user cannot make requests to store the document");
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
      console.warn(`Error storing document (${response.status}: ${response.statusText})`);
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

      printLog(`[onTokenSync] Resource: ${resourceUrl} Readonly: ${result.readonly}`);
    } catch (error) {
      // Explicitly close connection on validation failure
      const reason = error instanceof Error ? error.message : "Token sync failed";
      printLog(`[onTokenSync] Error: ${reason}`);
      connection.close(unauthorized(reason));
    }
  }
}
