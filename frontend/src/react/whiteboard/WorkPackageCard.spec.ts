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

import { act, createElement } from 'react';
import { createRoot, type Root } from 'react-dom/client';
import { WorkPackageCard } from './WorkPackageCard';

describe('WorkPackageCard', () => {
  let container:HTMLElement;
  let root:Root;

  function respondWith(status:number, body:object = {}) {
    vi.spyOn(window, 'fetch').mockResolvedValue(new Response(JSON.stringify(body), { status }));
  }

  async function renderCard(id:string) {
    await act(async () => {
      root.render(createElement(WorkPackageCard, { id }));
      await Promise.resolve();
    });
    await act(async () => { await new Promise((resolve) => { setTimeout(resolve); }); });
    return container.querySelector<HTMLAnchorElement>('[data-test-selector="whiteboard-work-package-card"]')!;
  }

  beforeAll(() => {
    (globalThis as { IS_REACT_ACT_ENVIRONMENT?:boolean }).IS_REACT_ACT_ENVIRONMENT = true;
  });

  beforeEach(() => {
    container = document.createElement('div');
    document.body.appendChild(container);
    root = createRoot(container);
  });

  afterEach(() => {
    vi.restoreAllMocks();
    act(() => root.unmount());
    container.remove();
  });

  it('shows the work package with its type and status colors', async () => {
    respondWith(200, {
      id: 5001,
      subject: 'Plan the launch',
      _links: {
        type: { href: '/api/v3/types/2', title: 'Milestone' },
        status: { href: '/api/v3/statuses/7', title: 'In progress' },
        assignee: { href: '/api/v3/users/3', title: 'Ada Lovelace' },
        project: { href: '/api/v3/projects/1', title: 'Rocket' },
      },
    });

    const card = await renderCard('5001');

    expect(card.textContent).toContain('Plan the launch');
    expect(card.textContent).toContain('#5001');
    expect(card.textContent).toContain('Ada Lovelace · Rocket');
    expect(card.querySelector('.op-whiteboard-wp-card--type')!.classList).toContain('__hl_type_2');
    expect(card.querySelector('.op-whiteboard-wp-card--status')!.classList).toContain('__hl_status_7');
    expect(card.getAttribute('href')).toMatch(/\/wp\/5001$/);
  });

  it('shows a placeholder without details when the user may not see the work package', async () => {
    respondWith(404);

    const card = await renderCard('5002');

    expect(card.classList).toContain('op-whiteboard-wp-card_unavailable');
    expect(card.textContent).toContain('#5002');
    expect(card.querySelector('.op-whiteboard-wp-card--status')).toBeNull();
  });
});
