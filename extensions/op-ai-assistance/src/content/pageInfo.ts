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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

// A numeric id or a semantic identifier such as PROJ-42.
const ID = '(\\d+|[A-Za-z][A-Za-z0-9_]*-\\d+)';
const SPLIT_VIEW = new RegExp(`/details/${ID}(?:/|$)`);
const FULL_VIEW = new RegExp(`/(?:work_packages|wp)/${ID}(?:/|$)`);

// The work package of the page: the split view shows the one in /details/:id, the full view
// the one in /work_packages/:id.
export function workPackageIdFrom(pathname:string, view:'split' | 'full'):string | null {
  const match = (view === 'split' ? SPLIT_VIEW : FULL_VIEW).exec(pathname);
  return match?.[1] ?? null;
}
