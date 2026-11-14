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

import { ChangeOptions, type ChangeOptionsData } from '../src/core/changeOptions';
import type { ProposalScope } from '../src/shared/types';

export const optionsData:ChangeOptionsData = {
  writable: ['subject', 'description', 'status', 'priority', 'assigned_to', 'responsible', 'start_date', 'due_date'],
  choices: {
    status: [
      { href: '/api/v3/statuses/1', name: 'New' },
      { href: '/api/v3/statuses/7', name: 'In progress' },
      { href: '/api/v3/statuses/12', name: 'Closed' },
    ],
    priority: [{ href: '/api/v3/priorities/8', name: 'Normal' }, { href: '/api/v3/priorities/9', name: 'High' }],
    assigned_to: [{ href: '/api/v3/users/5', name: 'Jane Doe' }],
  },
  current: {
    subject: 'Old subject',
    description: 'Old description',
    status: '/api/v3/statuses/1',
    priority: '/api/v3/priorities/8',
    assigned_to: null,
    due_date: '2026-12-01',
  },
};

export function changeOptions(scope:ProposalScope = 'changes', data:ChangeOptionsData = optionsData):ChangeOptions {
  return new ChangeOptions(scope, data);
}
