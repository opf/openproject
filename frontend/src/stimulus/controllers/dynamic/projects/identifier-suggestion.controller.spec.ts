//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
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

import { vi } from 'vitest';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type IdentifierSuggestionControllerType from './identifier-suggestion.controller';

describe('Projects identifier-suggestion controller', () => {
  let ctx:StimulusTestContext;
  let IdentifierSuggestionController:typeof IdentifierSuggestionControllerType;

  beforeAll(async () => {
    ({ default: IdentifierSuggestionController } = await import('./identifier-suggestion.controller'));
  });

  beforeEach(async () => {
    ctx = await setupStimulusTest({
      controllers: { 'projects--identifier-suggestion': IdentifierSuggestionController },
    });
  });

  afterEach(() => {
    ctx.dispose();
    vi.restoreAllMocks();
  });

  async function renderController(mode:'semantic'|'classic') {
    await ctx.mount(`
      <div data-controller="projects--identifier-suggestion"
           data-projects--identifier-suggestion-mode-value="${mode}">
        <input type="text" data-projects--identifier-suggestion-target="name">
        <input type="text" data-projects--identifier-suggestion-target="identifier">
      </div>
    `);
    return ctx.getController<IdentifierSuggestionControllerType>('projects--identifier-suggestion');
  }

  function identifierInput() {
    return ctx.container.querySelector<HTMLInputElement>(
      'input[data-projects--identifier-suggestion-target="identifier"]',
    )!;
  }

  function typeIntoField(value:string) {
    const input = identifierInput();
    input.value = value;
    input.setSelectionRange(value.length, value.length);
    input.dispatchEvent(new Event('input', { bubbles: true }));
  }

  describe('in semantic mode', () => {
    it('autocapitalises lowercase letters instead of deleting them', async () => {
      await renderController('semantic');

      typeIntoField('abc');
      expect(identifierInput().value).toBe('ABC');
    });

    it('keeps existing uppercase letters', async () => {
      await renderController('semantic');

      typeIntoField('ABC');
      expect(identifierInput().value).toBe('ABC');
    });

    it('removes characters that are not allowed even after autocapitalising', async () => {
      await renderController('semantic');

      typeIntoField('ab c!');
      expect(identifierInput().value).toBe('ABC');
    });

    it('autocapitalises mixed-case input and drops disallowed characters', async () => {
      await renderController('semantic');

      typeIntoField('My Project_1');
      expect(identifierInput().value).toBe('MYPROJECT_1');
    });
  });

  describe('in classic mode', () => {
    it('keeps lowercase letters', async () => {
      await renderController('classic');

      typeIntoField('abc');
      expect(identifierInput().value).toBe('abc');
    });

    it('removes uppercase letters (does not downcase them)', async () => {
      await renderController('classic');

      typeIntoField('AbC');
      expect(identifierInput().value).toBe('b');
    });
  });
});
