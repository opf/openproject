/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import * as Turbo from '@hotwired/turbo';
import { WP_ID_URL_PATTERN } from 'core-app/shared/helpers/work-package-id-pattern';

// Compiled once: matches a work package id anywhere in the pathname, reusing the
// shared WP_ID_URL_PATTERN so numeric ("42") and semantic ("PROJ-42") ids both match.
const workPackageIdPathRegex = new RegExp(`/work_packages/(${WP_ID_URL_PATTERN})(?:/|$)`);

function extractWorkPackageId(pathname:string):string | undefined {
  return workPackageIdPathRegex.exec(pathname)?.[1];
}

export function canonicalizeWorkPackageIdInUrl():void {
  const currentPath = window.location.pathname;
  const currentId = extractWorkPackageId(currentPath);
  if (!currentId) return;

  const canonical = document.querySelector<HTMLLinkElement>('link[rel="canonical"]');
  if (!canonical?.href) return;

  const canonicalPath = new URL(canonical.href).pathname;
  const canonicalId = extractWorkPackageId(canonicalPath);
  if (!canonicalId || canonicalId === currentId) return;

  const newPath = currentPath.replace(`/work_packages/${currentId}`, `/work_packages/${canonicalId}`);
  const newUrl = new URL(newPath + window.location.search + window.location.hash, window.location.origin);

  // Use Turbo's history.replace (not window.history.replaceState) so Turbo's internal
  // location stays in sync — otherwise back/forward popstate resolves the stale URL.
  // Pass the current restorationIdentifier explicitly: History.replace defaults to a
  // fresh uuid, orphaning the recorded scroll-restoration data.
  Turbo.session.history.replace(newUrl, Turbo.session.history.restorationIdentifier);
  // PageView#cacheSnapshot keys the snapshot cache by lastRenderedLocation; left stale,
  // back/forward misses the cache and re-fetches instead of restoring instantly.
  Turbo.session.view.lastRenderedLocation = newUrl;
}
