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

import { userEvent } from 'vitest/browser';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import ProjectSpecificValuesController from './project-specific-values.controller';

const section = (value:string, mode:string, selected:boolean, enterprise:boolean) => {
  const disabled = !selected || !enterprise ? 'disabled' : '';
  const manageCheckbox = mode === 'all'
    ? ''
    : `<input type="checkbox" aria-label="Manage ${mode}" ${disabled}>`;

  return `
    <div data-admin--project-specific-values-target="section" data-value="${value}" ${selected ? '' : 'hidden'}>
      ${manageCheckbox}
      <input type="checkbox" aria-label="Add ${mode}" ${disabled}>
    </div>
  `;
};

const radio = (value:string, mode:string, checked:boolean) => `
  <input type="radio" name="mode" value="${value}" aria-label="Mode ${mode}" ${checked ? 'checked' : ''}
         data-action="admin--project-specific-values#selectMode">
`;

const form = (enterprise:boolean) => `
  <form data-controller="admin--project-specific-values"
        data-admin--project-specific-values-enterprise-value="${enterprise}">
    ${radio('', 'all', true)}
    ${section('', 'all', true, enterprise)}
    ${radio('allow', 'allow', false)}
    ${section('allow', 'allow', false, enterprise)}
    ${radio('block', 'block', false)}
    ${section('block', 'block', false, enterprise)}
  </form>
`;

describe('ProjectSpecificValuesController', () => {
  let ctx:StimulusTestContext;

  const field = (label:string) => ctx.container.querySelector<HTMLInputElement>(`[aria-label="${label}"]`)!;
  const sectionFor = (label:string) => field(label).closest<HTMLElement>('div')!;

  beforeEach(async () => {
    ctx = await setupStimulusTest({
      controllers: { 'admin--project-specific-values': ProjectSpecificValuesController },
    });
  });

  afterEach(() => ctx.dispose());

  describe('with the enterprise plan', () => {
    beforeEach(async () => {
      await ctx.mount(form(true));
    });

    it('shows and enables only the settings of the selected mode', async () => {
      await userEvent.click(field('Mode allow'));

      expect(sectionFor('Manage allow').hidden).toBe(false);
      expect(field('Manage allow')).toBeEnabled();
      expect(field('Add allow')).toBeEnabled();

      expect(sectionFor('Add all').hidden).toBe(true);
      expect(field('Add all')).toBeDisabled();
      expect(sectionFor('Manage block').hidden).toBe(true);
      expect(field('Manage block')).toBeDisabled();
    });
  });

  describe('without the enterprise plan', () => {
    beforeEach(async () => {
      await ctx.mount(form(false));
    });

    it('shows the settings of the selected mode but keeps them disabled', async () => {
      await userEvent.click(field('Mode allow'));

      expect(sectionFor('Manage allow').hidden).toBe(false);
      expect(field('Manage allow')).toBeDisabled();
      expect(field('Add allow')).toBeDisabled();
    });
  });
});
