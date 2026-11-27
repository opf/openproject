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

import { fireEvent } from '@testing-library/dom';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type MeetingAgendaItemFormControllerType from './meeting-agenda-item-form.controller';

describe('Meeting agenda item form controller', () => {
  let ctx:StimulusTestContext;
  let MeetingAgendaItemFormController:typeof MeetingAgendaItemFormControllerType;

  beforeAll(async () => {
    ({ default: MeetingAgendaItemFormController } = await import('./meeting-agenda-item-form.controller'));
  });

  beforeEach(async () => {
    ctx = await setupStimulusTest({
      controllers: { 'meeting-agenda-item-form': MeetingAgendaItemFormController },
    });
  });

  afterEach(() => {
    ctx.dispose();
  });

  async function renderForm({ initialPresenterId, presenterValue }:{ initialPresenterId:string, presenterValue:string }) {
    await ctx.mount(`
      <div data-controller="meeting-agenda-item-form"
           data-meeting-agenda-item-form-cancel-url-value="/cancel"
           data-meeting-agenda-item-form-initial-presenter-id-value="${initialPresenterId}">
        <input type="hidden"
               name="presenter_id"
               value="${presenterValue}"
               data-action="change->meeting-agenda-item-form#recordInitialPresenter">
        <div class="d-none" data-meeting-agenda-item-form-target="notesInput"></div>
      </div>
    `);
    return ctx.container.querySelector<HTMLInputElement>('input[name="presenter_id"]')!;
  }

  it('records the server-rendered presenter when the user picks another one', async () => {
    const presenter = await renderForm({ initialPresenterId: '7', presenterValue: '7' });

    fireEvent.change(presenter, { target: { value: '9' } });

    expect(presenter).toHaveAttribute('data-initial-value', '7');
  });

  it('records nothing while the presenter value loads asynchronously', async () => {
    const presenter = await renderForm({ initialPresenterId: '7', presenterValue: '' });

    presenter.value = '7';

    expect(presenter).not.toHaveAttribute('data-initial-value');
  });

  it('keeps the first recorded presenter on later picks', async () => {
    const presenter = await renderForm({ initialPresenterId: '7', presenterValue: '7' });

    fireEvent.change(presenter, { target: { value: '9' } });
    fireEvent.change(presenter, { target: { value: '11' } });

    expect(presenter).toHaveAttribute('data-initial-value', '7');
  });

  it('records an empty initial value when the item had no presenter', async () => {
    const presenter = await renderForm({ initialPresenterId: '', presenterValue: '' });

    fireEvent.change(presenter, { target: { value: '9' } });

    expect(presenter).toHaveAttribute('data-initial-value', '');
  });
});
