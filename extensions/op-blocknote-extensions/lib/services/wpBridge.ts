import type { InlineWpSize, WpSize } from "../components/WorkPackage/types";
export interface WpResizePayload { instanceId: string; wpid: number; size: WpSize }
export interface WpDeletePayload { instanceId: string; wpid: number }
export interface WpToInlinePayload { wpid: number; size: InlineWpSize; blockId: string }

/**
 * Bridge between BlockNote inline components and the host application.
 *
 * BlockNote inline specs cannot receive React props or callbacks from outside —
 * the spec is registered once at schema creation time and has no access to
 * external React context or component props.
 *
 * Therefore, we use this bridge to notify the host app about user actions
 * (resize, delete, convert to block / inline). The host app subscribes via
 * `useInlineWpEvents(editor)` and handles these by mutating the editor directly.
 *
 * This is intentionally NOT a global state manager — only a communication layer.
 */

class WpBridge {
  private readonly listeners = new Map<string, Set<(payload: any) => void>>();

  // Typed emit helpers — prefer these over calling emit() directly
  resize(payload: WpResizePayload): void {
    this.emit("resize", payload);
  }

  delete(payload: WpDeletePayload): void {
    this.emit("delete", payload);
  }

  convertToInline(payload: WpToInlinePayload): void {
    this.emit("toInline", payload);
  }

  onResize(callback: (payload: WpResizePayload) => void): () => void {
    return this.on("resize", callback);
  }

  onDelete(callback: (payload: WpDeletePayload) => void): () => void {
    return this.on("delete", callback);
  }

  onConvertToInline(callback: (payload: WpToInlinePayload) => void): () => void {
    return this.on("toInline", callback);
  }

  private emit(event: string, payload: unknown): void {
    const listeners = this.listeners.get(event);
    if (!listeners) return;

    // Snapshot before iteration prevents issues if a listener calls off() during emit
    for (const callback of [...listeners]) {
      try {
        callback(payload);
      } catch (error) {
        console.error("[WpBridge]", event, { payload, error });
      }
    }
  }

  private on(event: string, callback: (payload: any) => void): () => void {
    let set = this.listeners.get(event);
    if (!set) {
      set = new Set();
      this.listeners.set(event, set);
    }
    set.add(callback);

    return () => {
      set!.delete(callback);
      if (set!.size === 0) this.listeners.delete(event);
    };
  }
}

export const wpBridge = new WpBridge();