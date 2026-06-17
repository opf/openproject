import { beforeHandleMessagePayload, Document, onAuthenticatePayload, onLoadDocumentPayload, onStoreDocumentPayload, onTokenSyncPayload } from "@hocuspocus/server";
import { describe, expect, test, vi } from "vitest";
import * as Y from "yjs";
import { TokenExpired, TokenExpiryMissing, unauthorized } from "../../src/closeEvents";
import { createEditor, OpenProjectApi } from "../../src/extensions/openProjectApi";
import { createExpiredToken, createTestToken } from "../helpers/tokenHelper";
import { server } from "../mocks/node";
import { http, HttpResponse } from "msw";
import { text } from 'stream/consumers';

// All web requests that aren't explicitly mocked via `server.use`, are using the dynamic document
// request mock defined in `handlers.ts`, returning a document for any id that isn't a
// specific status code (that is defined there).
// Missing Content-type or Authorization headers lead to client error responses (415, 401).
describe("OpenProjectApi", () => {
  describe("onAuthenticate", () => {
    test("when the token is not present throw an error", async () => {
      await expect(() =>
        new OpenProjectApi().onAuthenticate({
          token: null,
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unauthorized: Missing auth params");
    });

    test("when the oauth_token is invalid throw an error", async () => {
      await expect(() =>
        new OpenProjectApi().onAuthenticate({
          // invalid token generated with a different secret
          token: "mXPMUDJ41lbo0xc0qjgeUrk0nYfuCKMxPZa+/euNNM8jVpeZI5uU/YQQa60WnLoYo7gkCKlOCcdY5BVS2MqkpnSf5RWQPhNjm0czkiZ6hK4G6Y3EJOZkE67MPyVmyYFGgxnoGajwMAI=--gyIqET3MOf8a+HDk--DW5I6ZOWaGHRgiJ6FjOcZQ==",
          documentName: "https://test.api/api/v3/documents/1",
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unsupported state or unable to authenticate data");
    });

    test("when the origin does not match the one in the token", async () => {
      await expect(() =>
        new OpenProjectApi().onAuthenticate({
          token: "Yjo1x80JGIjrK8J6IDOuRn5kIOGvaAUw8C1so+dJJq7cgkllf3dQnw6d8bgiKbHXw8ZaMYE4IyOI1KQgX2ZRmx1mKBkxtb/fc7eCpGyTKGTA2Y1r/q7VJYiJZlpX7gx3nu569joEl/k=--mUkLaPiK0E82vGT9--gj1ZnTNlydL9j+Xw8+YFAA==",
          documentName: "https://test.api/api/v3/documents/1",
          requestHeaders: new Headers({
            origin: "https://different.origin",
          }),
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unauthorized: Token origin does not match request origin.");
    });

    test("when the resourceUrl does not match the one in the token", async () => {
      await expect(() =>
        new OpenProjectApi().onAuthenticate({
          token: "Yjo1x80JGIjrK8J6IDOuRn5kIOGvaAUw8C1so+dJJq7cgkllf3dQnw6d8bgiKbHXw8ZaMYE4IyOI1KQgX2ZRmx1mKBkxtb/fc7eCpGyTKGTA2Y1r/q7VJYiJZlpX7gx3nu569joEl/k=--mUkLaPiK0E82vGT9--gj1ZnTNlydL9j+Xw8+YFAA==",
          documentName: "https://indemiddle/api/v3/documents/1",
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unauthorized: Token resource URL does not match document.");
    });

    test("when the auth server does not authorize the request throw an error", async () => {
      let authHeader: string = "";
      server.events.on('request:end', ({ request }) => {
        authHeader = request.headers.get("Authorization") || "";
      });
      server.use(http.get('https://test.api/api/v3/documents/1', () => { return HttpResponse.json({id: 42}, {status: 401})}));

      await expect(() =>
        new OpenProjectApi().onAuthenticate({
          token: "Yjo1x80JGIjrK8J6IDOuRn5kIOGvaAUw8C1so+dJJq7cgkllf3dQnw6d8bgiKbHXw8ZaMYE4IyOI1KQgX2ZRmx1mKBkxtb/fc7eCpGyTKGTA2Y1r/q7VJYiJZlpX7gx3nu569joEl/k=--mUkLaPiK0E82vGT9--gj1ZnTNlydL9j+Xw8+YFAA==",
          documentName: "https://test.api/api/v3/documents/1",
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unauthorized: Invalid token or document access denied");

      expect(authHeader).toEqual("Bearer some_token_value");
    });

    test("when the token is valid set the context", async () => {
      const data = {
        context: {},
        connectionConfig: {},
        token: "Yjo1x80JGIjrK8J6IDOuRn5kIOGvaAUw8C1so+dJJq7cgkllf3dQnw6d8bgiKbHXw8ZaMYE4IyOI1KQgX2ZRmx1mKBkxtb/fc7eCpGyTKGTA2Y1r/q7VJYiJZlpX7gx3nu569joEl/k=--mUkLaPiK0E82vGT9--gj1ZnTNlydL9j+Xw8+YFAA==",
        documentName: "https://test.api/api/v3/documents/1",
      } as unknown as onAuthenticatePayload;

      await new OpenProjectApi().onAuthenticate(data);

      expect(data.context.resourceUrl).toEqual("https://test.api/api/v3/documents/1");
      expect(data.context.token).toEqual("some_token_value");
      expect(data.documentName).toEqual("https://test.api/api/v3/documents/1");
    });

    test("when there is no update link, setup the connection as readonly", async () => {
      server.use(http.get('https://test.api/api/v3/documents/1', () => {
        return HttpResponse.json(
          {
            _links: {
              self: { href: "/api/v3/documents/1" }
            }
          }, {
            status: 200
          }
        )
      }));

      const data = {
        context: {},
        connectionConfig: {},
        token: "Yjo1x80JGIjrK8J6IDOuRn5kIOGvaAUw8C1so+dJJq7cgkllf3dQnw6d8bgiKbHXw8ZaMYE4IyOI1KQgX2ZRmx1mKBkxtb/fc7eCpGyTKGTA2Y1r/q7VJYiJZlpX7gx3nu569joEl/k=--mUkLaPiK0E82vGT9--gj1ZnTNlydL9j+Xw8+YFAA==",
        documentName: "https://test.api/api/v3/documents/1",
      } as unknown as onAuthenticatePayload;

      await new OpenProjectApi().onAuthenticate(data);

      expect(data.connectionConfig.readOnly).toBe(true);
      expect(data.context.readonly).toBe(true);
    });

    test("when there is an update link, setup the connection as writable", async () => {
      server.use(http.get('https://test.api/api/v3/documents/1', () => {
        return HttpResponse.json(
          {
            title: "TheDocName",
            _links: {
              self: { href: "/api/v3/documents/1" },
              update: { href: "/api/v3/documents/1" }
            }
          }, {
            status: 200
          }
        )
      }));

      const data = {
        context: {},
        connectionConfig: {},
        token: "Yjo1x80JGIjrK8J6IDOuRn5kIOGvaAUw8C1so+dJJq7cgkllf3dQnw6d8bgiKbHXw8ZaMYE4IyOI1KQgX2ZRmx1mKBkxtb/fc7eCpGyTKGTA2Y1r/q7VJYiJZlpX7gx3nu569joEl/k=--mUkLaPiK0E82vGT9--gj1ZnTNlydL9j+Xw8+YFAA==",
        documentName: "https://test.api/api/v3/documents/1",
      } as unknown as onAuthenticatePayload;

      await new OpenProjectApi().onAuthenticate(data);

      expect(data.connectionConfig.readOnly).toBeUndefined();
      expect(data.context.readonly).toBeUndefined();
    });

    test("when the token has expired throw an error", async () => {
      server.use(http.get('https://test.api/api/v3/documents/1', () => {
        return HttpResponse.json({
          _links: {
            self: { href: "/api/v3/documents/1" },
            update: { href: "/api/v3/documents/1" }
          }
        }, { status: 200 });
      }));

      const expiredToken = createExpiredToken();

      await expect(() =>
        new OpenProjectApi().onAuthenticate({
          token: expiredToken,
          documentName: "https://test.api/api/v3/documents/1",
          context: {},
          connectionConfig: {},
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unauthorized: Token already expired.");
    });
  });

  describe("beforeHandleMessage", () => {
    test("should allow message when token not expired", async () => {
      const futureDate = new Date(Date.now() + 5 * 60 * 1000);
      const data = {
        context: { tokenExpiresAt: futureDate },
      } as unknown as beforeHandleMessagePayload;

      const api = new OpenProjectApi();
      await expect(api.beforeHandleMessage(data)).resolves.toBeUndefined();
    });

    test("should throw CloseEvent when token has expired", async () => {
      const pastDate = new Date(Date.now() - 60 * 1000);
      const data = {
        context: { tokenExpiresAt: pastDate },
      } as unknown as beforeHandleMessagePayload;

      const api = new OpenProjectApi();
      await expect(api.beforeHandleMessage(data)).rejects.toEqual(TokenExpired);
    });

    test("should throw CloseEvent when tokenExpiresAt not set", async () => {
      const data = {
        context: {},
      } as unknown as beforeHandleMessagePayload;

      const api = new OpenProjectApi();
      await expect(api.beforeHandleMessage(data)).rejects.toEqual(TokenExpiryMissing);
    });
  });

  describe("onLoadDocument", () => {
    test("should fetch document content and apply update to YDoc", async () => {
      // Create a valid YJS update by encoding state from a document with content
      const sourceDoc = new Y.Doc();
      const text = sourceDoc.getText('content');
      text.insert(0, 'test content');
      const base64Update = Buffer.from(Y.encodeStateAsUpdate(sourceDoc)).toString('base64');

      server.use(http.get('https://test.api/api/v3/documents/121', () => {
        return HttpResponse.json(
          {
            contentBinary: base64Update
          }, {
            status: 200
          }
        )
      }));

      const targetDoc = new Y.Doc();
      const data = {
        context: { token: "superValidToken", resourceUrl: "https://test.api/api/v3/documents/121" },
        document: targetDoc,
      } as onLoadDocumentPayload;

      const api = new OpenProjectApi();
      await api.onLoadDocument(data);

      // Verify the document was updated with the content
      const updatedContent = targetDoc.getText('content').toString();
      expect(updatedContent).toBe('test content');
    });

    test("should return early when response is not successful", async () => {
      const data = {
        context: { token: "superValidToken", resourceUrl: "https://test.api/api/v3/documents/404" },
        document: new Y.Doc(),
      } as onLoadDocumentPayload;

      const initialContent = data.document.getText('content').toString();

      const api = new OpenProjectApi();
      await api.onLoadDocument(data);

      const updatedContent = data.document.getText('content').toString();
      expect(updatedContent).toBe(initialContent);
    });
  });

  describe("onStoreDocument", () => {
    test("should store document content successfully", async () => {
      server.use(http.patch('https://test.api/api/v3/documents/121', () => {
        return HttpResponse.json({}, { status: 200 });
      }));

      let body: Promise<string> = Promise.resolve("");

      server.events.on('request:end', async ({ request }) => {
        body = text(request.body!);
      });

      const editor = createEditor();
      const blocks = [
        {
          type: "paragraph",
          content: "test document content"
        }
      ];

      const document = new Y.Doc();
      const fragment = document.getXmlFragment('document-store');

      // @ts-expect-error BlockNote types are complicated
      editor.blocksToYXmlFragment(blocks, fragment);

      const broadcastStateless = vi.fn();
      const data = {
        lastContext: {
          token: "superValidToken",
          resourceUrl: "https://test.api/api/v3/documents/121",
          readonly: false,
          tokenExpiresAt: new Date(Date.now() + 5 * 60 * 1000), // 5 min from now
        },
        document: { ...document, broadcastStateless } as unknown as Document,
      } as unknown as onStoreDocumentPayload;

      const api = new OpenProjectApi();
      await api.onStoreDocument(data);

      await expect(body).resolves.toContain("content_binary");
      expect(broadcastStateless).toHaveBeenCalledWith("storeEvent");
    });
  });

  describe("onTokenSync", () => {
    test("should return early if token is missing", async () => {
      const data = {
        token: "",
        connection: {
          readOnly: false,
          context: { resourceUrl: "https://test.api/api/v3/documents/1" },
        },
        document: {},
      } as unknown as onTokenSyncPayload;

      const api = new OpenProjectApi();
      await api.onTokenSync(data);

      // No error thrown, early return
    });

    test("should return early if resourceUrl is missing", async () => {
      const token = createTestToken();
      const data = {
        token,
        connection: {
          readOnly: false,
          context: {},
        },
        document: {},
      } as unknown as onTokenSyncPayload;

      const api = new OpenProjectApi();
      await api.onTokenSync(data);

      // No error thrown, early return
    });

    test("should validate and update token on successful sync", async () => {
      let authHeader: string = "";
      server.events.on('request:end', ({ request }) => {
        authHeader = request.headers.get("Authorization") || "";
      });

      server.use(http.get('https://test.api/api/v3/documents/1', () => {
        return HttpResponse.json({
          _links: {
            self: { href: "/api/v3/documents/1" },
            update: { href: "/api/v3/documents/1" }
          }
        }, { status: 200 });
      }));

      const token = createTestToken();
      const data = {
        token,
        connection: {
          readOnly: false,
          context: {
            resourceUrl: "https://test.api/api/v3/documents/1",
            token: "old_token",
            readonly: false,
          },
        },
        document: {},
      } as unknown as onTokenSyncPayload;

      const api = new OpenProjectApi();
      await api.onTokenSync(data);

      expect(authHeader).toEqual("Bearer some_token_value");
      expect(data.connection.context.token).toBe("some_token_value");
    });

    test("should update tokenExpiresAt in context after sync", async () => {
      server.use(http.get('https://test.api/api/v3/documents/1', () => {
        return HttpResponse.json({
          _links: {
            self: { href: "/api/v3/documents/1" },
            update: { href: "/api/v3/documents/1" }
          }
        }, { status: 200 });
      }));

      const token = createTestToken({ expires_at: "2030-01-01T00:00:00.000Z" });
      const data = {
        token,
        connection: {
          readOnly: false,
          context: {
            resourceUrl: "https://test.api/api/v3/documents/1",
            token: "old_token",
            tokenExpiresAt: new Date("2020-01-01"),
          },
        },
        document: {},
      } as unknown as onTokenSyncPayload;

      await new OpenProjectApi().onTokenSync(data);

      expect(data.connection.context.tokenExpiresAt).toEqual(new Date("2030-01-01T00:00:00.000Z"));
    });

    test("should update readonly status when permissions change from writable to readonly", async () => {
      // Note: Token readonly: false reflects user's permission at token creation time.
      // API response without 'update' link means user lost write permission since then.
      // The API response is authoritative, so connection becomes readonly.
      server.use(http.get('https://test.api/api/v3/documents/1', () => {
        return HttpResponse.json({
          _links: {
            self: { href: "/api/v3/documents/1" }
            // No update link = readonly
          }
        }, { status: 200 });
      }));

      const token = createTestToken();
      const data = {
        token,
        connection: {
          readOnly: false,
          context: {
            resourceUrl: "https://test.api/api/v3/documents/1",
            token: "old_token",
            readonly: false,
          },
        },
        document: {},
      } as unknown as onTokenSyncPayload;

      const api = new OpenProjectApi();
      await api.onTokenSync(data);

      expect(data.connection.context.readonly).toBe(true);
      expect(data.connection.readOnly).toBe(true);
    });

    test("should close connection if token validation fails", async () => {
      server.use(http.get('https://test.api/api/v3/documents/1', () => {
        return HttpResponse.json({}, { status: 401 });
      }));

      const closeMock = vi.fn();
      const token = createTestToken();
      const data = {
        token,
        connection: {
          close: closeMock,
          readOnly: false,
          context: {
            resourceUrl: "https://test.api/api/v3/documents/1",
            token: "old_token",
            readonly: false,
          },
        },
        document: {},
      } as unknown as onTokenSyncPayload;

      const api = new OpenProjectApi();
      await api.onTokenSync(data);

      expect(closeMock).toHaveBeenCalledWith(unauthorized(expect.stringContaining("Unauthorized")));
      expect(data.connection.context.token).toBe("old_token");
    });

    test("should close connection if decryption fails", async () => {
      const closeMock = vi.fn();
      const data = {
        token: "invalid_encrypted_token",
        connection: {
          close: closeMock,
          readOnly: false,
          context: {
            resourceUrl: "https://test.api/api/v3/documents/1",
            token: "old_token",
          },
        },
        document: {},
      } as unknown as onTokenSyncPayload;

      const api = new OpenProjectApi();
      await api.onTokenSync(data);

      expect(closeMock).toHaveBeenCalledWith(unauthorized(expect.any(String)));
      expect(data.connection.context.token).toBe("old_token");
    });

    test("should close connection if refreshed token is already expired", async () => {
      server.use(http.get('https://test.api/api/v3/documents/1', () => {
        return HttpResponse.json({
          _links: {
            self: { href: "/api/v3/documents/1" },
            update: { href: "/api/v3/documents/1" }
          }
        }, { status: 200 });
      }));

      const closeMock = vi.fn();
      const expiredToken = createExpiredToken();
      const data = {
        token: expiredToken,
        connection: {
          close: closeMock,
          readOnly: false,
          context: {
            resourceUrl: "https://test.api/api/v3/documents/1",
            token: "old_token",
          },
        },
        document: {},
      } as unknown as onTokenSyncPayload;

      await new OpenProjectApi().onTokenSync(data);

      expect(closeMock).toHaveBeenCalledWith(unauthorized("Token sync failed: received expired token"));
    });
  });
});
