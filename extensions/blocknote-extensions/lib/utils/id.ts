export function uniqueId():string {
  return typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function'
    ? crypto.randomUUID()
    : `${Date.now()}-${Math.random().toString(36).slice(2)}`;
}

export function formatWorkPackageId(displayId:string):string {
  return /^\d+$/.test(displayId) ? `#${displayId}` : displayId;
}

export function projectIdFromHref(href:string | undefined):string | undefined {
  return href ? (/\/api\/v3\/projects\/([^/?#]+)/.exec(href))?.[1] : undefined;
}
