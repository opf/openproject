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

import { render } from 'lit-html';
import { within } from '@testing-library/dom';
import type { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import { timeEntryPopoverHtml, timeEntryPopoverRows } from './te-calendar-popover';
import type { TimeEntrySchema } from './te-calendar-popover';

describe('timeEntryPopoverHtml', () => {
  let host:HTMLElement;

  beforeEach(() => {
    host = document.createElement('div');
  });

  const rows = [{ label: 'Project', value: 'Demo' }, { label: 'Hours', value: '2h' }];

  it('renders a hint popover anchored to the entry', () => {
    render(timeEntryPopoverHtml('pop-1', 'anchor-1', rows, null), host);
    const popover = host.querySelector('anchored-position')!;

    expect(popover).toHaveAttribute('id', 'pop-1');
    expect(popover).toHaveAttribute('anchor', 'anchor-1');
    expect(popover).toHaveAttribute('popover', 'hint');
    expect(popover).toHaveAttribute('role', 'dialog');
    expect(popover).toHaveClass('op-anchored-popover--host');
  });

  it('lists every row as label and value', () => {
    render(timeEntryPopoverHtml('pop-1', 'anchor-1', rows, null), host);
    const entries = within(host).getAllByRole('listitem');

    expect(entries).toHaveLength(2);
    expect(entries[0]).toHaveTextContent('Project: Demo');
    expect(entries[1]).toHaveTextContent('Hours: 2h');
  });

  it('renders the caret from the placement', () => {
    render(timeEntryPopoverHtml('pop-1', 'anchor-1', rows, { side: 'right', offset: 20 }), host);
    const message = host.querySelector<HTMLElement>('.Popover-message')!;

    expect(message).toHaveClass('Popover-message--right');
    expect(message.style.getPropertyValue('--op-anchored-popover-caret-offset')).toBe('20px');
  });

  it('binds values as text, never as markup', () => {
    render(timeEntryPopoverHtml('pop-1', 'anchor-1', [{ label: 'Comment', value: '<b>bold</b>' }], null), host);
    const [entry] = within(host).getAllByRole('listitem');

    expect(entry).toHaveTextContent('Comment: <b>bold</b>');
    expect(host.querySelector('b')).toBeNull();
  });
});

describe('timeEntryPopoverRows', () => {
  const schema = {
    project: { name: 'Проект' },
    entity: { name: 'Учтено' },
    activity: { name: 'Деятельность' },
    hours: { name: 'Часы' },
    comment: { name: 'Комментарий' },
  } as unknown as TimeEntrySchema;

  const context = { placeholder: '-', formattedDuration: '7 ч' };

  const entry = (overrides:Record<string, unknown> = {}) => ({
    project: { name: 'Техподдержка, BIM и т.п.' },
    entity: { name: 'Провести анализ', href: '/api/v3/work_packages/42' },
    activity: { name: 'Разработка' },
    hours: 'PT7H',
    comment: { raw: 'Комментарий <b>жирный</b>' },
    ...overrides,
  }) as unknown as TimeEntryResource;

  it('keeps non-ASCII values verbatim', () => {
    const rows = timeEntryPopoverRows(entry(), schema, context);

    expect(rows).toEqual([
      { label: 'Проект', value: 'Техподдержка, BIM и т.п.' },
      { label: 'Учтено', value: '#42: Провести анализ' },
      { label: 'Деятельность', value: 'Разработка' },
      { label: 'Часы', value: '7 ч' },
      { label: 'Комментарий', value: 'Комментарий <b>жирный</b>' },
    ]);
  });

  it('falls back to the placeholder without entity and comment', () => {
    const rows = timeEntryPopoverRows(entry({ entity: null, comment: { raw: null } }), schema, context);

    expect(rows[1]).toEqual({ label: 'Учтено', value: '-' });
    expect(rows[4]).toEqual({ label: 'Комментарий', value: '-' });
  });

  it('shows an empty activity as blank', () => {
    const rows = timeEntryPopoverRows(entry({ activity: null }), schema, context);

    expect(rows[2]).toEqual({ label: 'Деятельность', value: '' });
  });
});
