import { RenderRequest, Transport } from '@camertron/live-component';

// Replaces the library's HTTPTransport, which sends no CSRF token
// (library gap, v0.4.0). Skips gzip: the server's Payload.decode sniffs
// the gzip magic bytes and accepts plain base64.
//
// Note: Transport#render returns Promise<string> (the decoded HTML), not
// a RenderResponse object -- the package's public types export no such
// type, and HTTPTransport itself just resolves/rejects a string. On a
// non-2xx response we throw; LiveController's internal task queue logs
// the error but still re-rejects it, so callers of `render()` must
// attach their own `.catch()` or the rejection is unhandled.
export class OpLiveComponentTransport implements Transport {
  constructor(public url:string) {}

  start():void {
    // No connection/handshake to establish; fetch() is stateless per-request.
  }

  async render(request:RenderRequest):Promise<string> {
    const json = JSON.stringify(request);
    const bytes = new TextEncoder().encode(json);
    let binary = '';
    bytes.forEach((b) => { binary += String.fromCharCode(b); });
    const payload = btoa(binary);

    const csrfToken = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? '';

    const response = await fetch(this.url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'text/html',
        'X-CSRF-Token': csrfToken,
      },
      credentials: 'same-origin',
      body: JSON.stringify({ payload }),
    });

    const text = await response.text();

    if (!response.ok) {
      throw new Error(`LiveComponent render failed (${response.status}): ${text}`);
    }

    const decodedBinary = atob(text.trim());
    const decodedBytes = Uint8Array.from(decodedBinary, (c) => c.charCodeAt(0));

    return new TextDecoder().decode(decodedBytes);
  }
}
