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

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type JiraConfigurationFormControllerType from './jira-configuration-form.controller';

const BASIC_AUTH_REQUIRED_EVENT = 'op-dispatched:jira-configuration:basic-auth-required';

describe('Admin Jira configuration form controller', () => {
  let ctx:StimulusTestContext;
  let JiraConfigurationFormController:typeof JiraConfigurationFormControllerType;

  beforeAll(async () => {
    ({ default: JiraConfigurationFormController } = await import('./jira-configuration-form.controller'));
  });

  beforeEach(async () => {
    ctx = await setupStimulusTest({
      controllers: { 'admin--jira-configuration-form': JiraConfigurationFormController },
    });
  });

  afterEach(() => {
    ctx.dispose();
  });

  async function renderForm() {
    await ctx.mount(`
      <div data-controller="admin--jira-configuration-form"
           data-action="${BASIC_AUTH_REQUIRED_EVENT}@document->admin--jira-configuration-form#requireBasicAuth">
        <input type="url"
               data-admin--jira-configuration-form-target="url"
               data-action="change->admin--jira-configuration-form#allowPersonalAccessToken">
        <div data-admin--jira-configuration-form-target="authMethodGroup">
          <input type="radio" name="auth_method" value="bearer" checked>
          <input type="radio" name="auth_method" value="basic">
        </div>
      </div>
    `);
  }

  function authMethodOption(value:string):HTMLInputElement {
    return document.querySelector<HTMLInputElement>(`input[value="${value}"]`)!;
  }

  describe('when the server requires basic auth', () => {
    it('selects basic auth and disables the personal access token', async () => {
      await renderForm();

      document.dispatchEvent(new CustomEvent(BASIC_AUTH_REQUIRED_EVENT));

      expect(authMethodOption('basic').checked).toBe(true);
      expect(authMethodOption('bearer').disabled).toBe(true);
    });

    it('announces the selection so the basic auth fields are shown', async () => {
      await renderForm();
      const onChange = vi.fn();
      authMethodOption('basic').addEventListener('change', onChange);

      document.dispatchEvent(new CustomEvent(BASIC_AUTH_REQUIRED_EVENT));

      expect(onChange).toHaveBeenCalledOnce();
    });
  });

  describe('when the URL changes after basic auth was required', () => {
    it('allows the personal access token again', async () => {
      await renderForm();
      document.dispatchEvent(new CustomEvent(BASIC_AUTH_REQUIRED_EVENT));

      document.querySelector('input[type="url"]')!.dispatchEvent(new Event('change'));

      expect(authMethodOption('bearer').disabled).toBe(false);
      expect(authMethodOption('basic').checked).toBe(true);
    });
  });
});
