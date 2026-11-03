export function formatWorkPackageId(displayId:string):string {
  return /^\d+$/.test(displayId) ? `#${displayId}` : displayId;
}

export function projectIdFromHref(href:string | undefined):string | undefined {
  return href ? (/\/api\/v3\/projects\/([^/?#]+)/.exec(href))?.[1] : undefined;
}
