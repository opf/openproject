import { type StreamChat } from 'stream-chat';

// Shared singleton so chat-rooms can use the same client initialized by chat-panel.
let _client: StreamChat | null = null;
const _waiters: Array<(c: StreamChat) => void> = [];

export function signalClientReady(client: StreamChat): void {
  _client = client;
  _waiters.splice(0).forEach((fn) => fn(client));
}

export function getStreamClient(timeoutMs = 15000): Promise<StreamChat> {
  if (_client) return Promise.resolve(_client);
  return new Promise<StreamChat>((resolve, reject) => {
    const timer = setTimeout(() => {
      const idx = _waiters.findIndex((fn) => fn === wrapped);
      if (idx !== -1) _waiters.splice(idx, 1);
      reject(new Error('[mngt] Stream client initialization timeout'));
    }, timeoutMs);
    const wrapped = (c: StreamChat): void => { clearTimeout(timer); resolve(c); };
    _waiters.push(wrapped);
  });
}
