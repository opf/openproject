// Generates a globally unique instance ID for inline work package chips.
// Falls back to a timestamp-based ID in environments without crypto.randomUUID

export function makeInstanceId(): string {
  return typeof crypto !== "undefined" && typeof crypto.randomUUID === "function"
    ? crypto.randomUUID()
    : `iid-${Date.now()}-${Math.random().toString(36).slice(2)}`;
}

export function formatWorkPackageId(displayId: string): string {
  return /^\d+$/.test(displayId) ? `#${displayId}` : displayId;
}