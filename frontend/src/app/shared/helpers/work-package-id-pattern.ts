//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

/**
 * URL-safe pattern that matches work package identifiers:
 * numeric IDs ("123") and semantic identifiers ("PROJ-42").
 *
 * Used in UI Router route definitions so that both forms are accepted in URLs.
 * The backend equivalent lives in WorkPackage::SemanticIdentifier::ID_ROUTE_CONSTRAINT.
 */
export const WP_ID_URL_PATTERN = '\\d+|[A-Za-z][A-Za-z0-9_]*-\\d+';

/**
 * Detect whether a work package identifier is a semantic one (e.g. `PROJ-42`)
 * rather than a plain numeric id (e.g. `42`).
 *
 * Semantic identifiers are self-describing because they contain letters; numeric
 * ids do not. This is the canonical, mode-agnostic way for the frontend to tell
 * the two apart — there is no semantic-mode flag exposed to the client.
 *
 * @example
 * isSemanticWorkPackageId('PROJ-42') // => true
 * isSemanticWorkPackageId('42')      // => false
 * isSemanticWorkPackageId('')        // => false
 */
export function isSemanticWorkPackageId(id:string):boolean {
  return /[A-Za-z]/.test(id);
}

/**
 * Format a work package identifier for inline UI display.
 *
 * OpenProject supports two identifier modes:
 * - **Semantic**: project-scoped identifiers like `PROJ-42` that contain letters.
 *   These are self-describing and returned as-is.
 * - **Classic**: numeric-only identifiers like `42`.
 *   These are prefixed with `#` to visually distinguish them as WP references.
 *
 * @example
 * formatWorkPackageId('PROJ-42') // => 'PROJ-42'
 * formatWorkPackageId('42')      // => '#42'
 * formatWorkPackageId('')        // => ''
 */
export function formatWorkPackageId(id:string):string {
  if (!id) return '';
  return isSemanticWorkPackageId(id) ? id : `#${id}`;
}
