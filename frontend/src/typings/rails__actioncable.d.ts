declare module '@rails/actioncable' {
  export interface Consumer {
    subscriptions: Subscriptions;
    disconnect(): void;
  }
  export interface Subscriptions {
    create(
      channelNameOrParams: string | Record<string, unknown>,
      callbacks: Partial<{
        initialized(): void;
        connected(): void;
        disconnected(): void;
        received(data: unknown): void;
        rejected(): void;
      }>
    ): Subscription;
  }
  export interface Subscription {
    unsubscribe(): void;
  }
  export function createConsumer(url?: string): Consumer;
}
