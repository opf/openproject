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

import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { CausedUpdatesService } from './caused-updates.service';

describe('CausedUpdatesService', () => {
  const query = (href:string, updatedAt = '2026-10-21T06:26:02.785Z') => ({ id: '2552', href, updatedAt }) as unknown as QueryResource;

  let service:CausedUpdatesService;

  beforeEach(() => {
    service = new CausedUpdatesService();
  });

  it('recognises an update to a board list query in the polled query', () => {
    service.add(query('/api/v3/queries/2552?columns%5B%5D=id&pageSize=500'));

    expect(service.includes(query('/api/v3/queries/2552'))).toBe(true);
  });

  it('does not recognise a later update of the same query', () => {
    service.add(query('/api/v3/queries/2552'));

    expect(service.includes(query('/api/v3/queries/2552', '2026-10-21T06:26:03.000Z'))).toBe(false);
  });
});
