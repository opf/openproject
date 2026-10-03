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

import React, { useEffect, useState } from 'react';
import { workPackageCardLink } from './work-package-cards';

interface HalLink { href:string|null; title?:string }

interface WorkPackageResource {
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

type CardData =
  | { state:'loading' }
  | { state:'loaded'; workPackage:WorkPackageResource }
  | { state:'unavailable' }
  | { state:'error' };

const requests = new Map<string, Promise<CardData>>();

async function requestWorkPackage(id:string):Promise<CardData> {
  try {
    const response = await fetch(`${window.appBasePath || ''}/api/v3/work_packages/${encodeURIComponent(id)}`, {
      credentials: 'same-origin',
      headers: { Accept: 'application/hal+json', 'X-Requested-With': 'XMLHttpRequest' },
    });

    if (response.status === 403 || response.status === 404) return { state: 'unavailable' };
    if (!response.ok) return { state: 'error' };

    return { state: 'loaded', workPackage: await response.json() as WorkPackageResource };
  } catch {
    return { state: 'error' };
  }
}

function loadWorkPackage(id:string):Promise<CardData> {
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

function useWorkPackage(id:string):CardData {
  const [data, setData] = useState<CardData>({ state: 'loading' });

  useEffect(() => {
    let current = true;
    setData({ state: 'loading' });
    void loadWorkPackage(id).then((result) => {
      if (current) setData(result);
    });
    return () => { current = false; };
  }, [id]);

  return data;
}

function resourceId(link:HalLink|undefined):string|undefined {
  return link?.href?.split('/').pop();
}

const t = (key:string) => window.I18n.t(`js.whiteboards.work_package_card.${key}`);

function formattedId(id:string):string {
  return /^\d+$/.test(id) ? `#${id}` : id;
}

function LoadedCard({ workPackage }:{ workPackage:WorkPackageResource }) {
  const { type, status, assignee, project } = workPackage._links;
  const meta = [assignee?.title, project?.title].filter(Boolean).join(' · ');

  return (
    <>
      <div className="op-whiteboard-wp-card--header">
        <span className={`op-whiteboard-wp-card--type __hl_foreground __hl_uppercase __hl_type_${resourceId(type)}`}>{type?.title}</span>
        <span className="op-whiteboard-wp-card--id">{formattedId(workPackage.displayId ?? String(workPackage.id))}</span>
        {status?.title && (
          <span className={`op-whiteboard-wp-card--status __hl_background __hl_status_${resourceId(status)}`}>{status.title}</span>
        )}
      </div>
      <div className="op-whiteboard-wp-card--subject">{workPackage.subject}</div>
      {meta && <div className="op-whiteboard-wp-card--meta">{meta}</div>}
    </>
  );
}

function PlaceholderCard({ id, state }:{ id:string; state:'loading'|'unavailable'|'error' }) {
  return (
    <>
      <div className="op-whiteboard-wp-card--header">
        <span className="op-whiteboard-wp-card--id">{formattedId(id)}</span>
      </div>
      <div className="op-whiteboard-wp-card--subject">{t(`${state}.header`)}</div>
      {state !== 'loading' && <div className="op-whiteboard-wp-card--meta">{t(`${state}.message`)}</div>}
    </>
  );
}

export function WorkPackageCard({ id }:{ id:string }) {
  const data = useWorkPackage(id);

  return (
    <a
      className={`op-whiteboard-wp-card op-whiteboard-wp-card_${data.state}`}
      href={workPackageCardLink(id)}
      target="_blank"
      rel="noopener noreferrer"
      data-test-selector="whiteboard-work-package-card"
    >
      {data.state === 'loaded'
        ? <LoadedCard workPackage={data.workPackage} />
        : <PlaceholderCard id={id} state={data.state} />}
    </a>
  );
}
