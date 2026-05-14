import { type StreamChat } from 'stream-chat';

// Shared singleton so chat-rooms can use the same client initialized by chat-panel.
let _client: StreamChat | null = null;
const _waiters: Array<(c: StreamChat) => void> = [];

export function signalClientReady(client: StreamChat): void {
  _client = client;
  _waiters.splice(0).forEach(fn => fn(client));
}

export function getStreamClient(): Promise<StreamChat> {
  return _client
    ? Promise.resolve(_client)
    : new Promise<StreamChat>(resolve => _waiters.push(resolve));
}
