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

interface HalLink { href:string|null; title?:string }

export interface WorkPackageResource {
  id:number;
  displayId?:string;
  subject:string;
  _links:{
    type?:HalLink;
    status?:HalLink;
    assignee?:HalLink;
    project?:HalLink;
  };
}

interface WorkPackageCollection {
  _embedded:{ elements:WorkPackageResource[] };
}

export type WorkPackageData =
  | { state:'loading' }
  | { state:'loaded'; workPackage:WorkPackageResource }
  | { state:'unavailable' }
  | { state:'error' };

const SEARCH_RESULT_COUNT = 10;

const requests = new Map<string, Promise<WorkPackageData>>();

function apiGet(path:string, signal?:AbortSignal):Promise<Response> {
  return fetch(`${window.appBasePath || ''}/api/v3/${path}`, {
    credentials: 'same-origin',
    headers: { Accept: 'application/hal+json', 'X-Requested-With': 'XMLHttpRequest' },
    signal,
  });
}

async function requestWorkPackage(id:string):Promise<WorkPackageData> {
  try {
    const response = await apiGet(`work_packages/${encodeURIComponent(id)}`);

    if (response.status === 403 || response.status === 404) return { state: 'unavailable' };
    if (!response.ok) return { state: 'error' };

    return { state: 'loaded', workPackage: await response.json() as WorkPackageResource };
  } catch {
    return { state: 'error' };
  }
}

export function loadWorkPackage(id:string):Promise<WorkPackageData> {
  let request = requests.get(id);
  if (!request) {
    request = requestWorkPackage(id);
    requests.set(id, request);
    void request.then((data) => {
      if (data.state === 'error') requests.delete(id);
    });
  }
  return request;
}

export function workPackageReference(workPackage:WorkPackageResource):string {
  return workPackage.displayId ?? String(workPackage.id);
}

export function rememberWorkPackage(workPackage:WorkPackageResource):void {
  requests.set(workPackageReference(workPackage), Promise.resolve({ state: 'loaded', workPackage }));
}

export async function searchWorkPackages(term:string, signal?:AbortSignal):Promise<WorkPackageResource[]> {
  const params = new URLSearchParams({
    filters: JSON.stringify([{ typeahead: { operator: '**', values: [term] } }]),
    sortBy: JSON.stringify([['exactMatch', 'desc'], ['updatedAt', 'desc']]),
    pageSize: String(SEARCH_RESULT_COUNT),
  });
  const response = await apiGet(`work_packages?${params.toString()}`, signal);
  if (!response.ok) throw new Error(`Work package search failed with ${response.status}`);

  return (await response.json() as WorkPackageCollection)._embedded.elements;
}

export function resourceId(link:HalLink|undefined):string|undefined {
  return link?.href?.split('/').pop();
}

export function formattedId(reference:string):string {
  return /^\d+$/.test(reference) ? `#${reference}` : reference;
}
