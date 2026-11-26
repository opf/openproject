import type { TFunction } from 'i18next';

export function formatWorkPackageId(displayId:string):string {
  return /^\d+$/.test(displayId) ? `#${displayId}` : displayId;
}

// Announced as is, the dash of a semantic identifier went unread
// (https://community.openproject.org/wp/BNE-198).
export function spokenWorkPackageId(t:TFunction, displayId:string):string {
  return formatWorkPackageId(displayId).replace(/-/g, ` ${t('options.idDash')} `);
}

export function projectIdFromHref(href:string | undefined):string | undefined {
  return href ? (/\/api\/v3\/(?:projects|programs|portfolios|workspaces)\/([^/?#]+)/.exec(href))?.[1] : undefined;
}
