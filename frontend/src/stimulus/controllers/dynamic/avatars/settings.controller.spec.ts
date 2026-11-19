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
import AvatarSettingsController from './settings.controller';

describe('AvatarSettingsController text validation', () => {
  let ctx:StimulusTestContext;
  let input:HTMLInputElement;

  beforeEach(async () => {
    ctx = await setupStimulusTest({ controllers: { 'avatars--settings': AvatarSettingsController } });
    await ctx.mount(`
      <div data-controller="avatars--settings"
           data-avatars--settings-max-length-value="2"
           data-avatars--settings-text-length-error-value="Enter up to two characters."
           data-avatars--settings-text-invalid-error-value="Use only visible characters.">
        <input type="radio" value="initials" checked data-avatars--settings-target="type">
        <input aria-label="Avatar text" data-avatars--settings-target="text"
               data-action="input->avatars--settings#update compositionend->avatars--settings#update">
        <input data-avatars--settings-target="color">
        <button data-avatars--settings-target="submit">Save</button>
      </div>
    `);
    input = ctx.screen.getByRole('textbox', { name: 'Avatar text' });
  });

  afterEach(() => ctx?.dispose());

  it.each(['本田', 'OP', '👩🏽‍💻🇯🇵', 'e\u0301x'])('accepts %s', (text) => {
    input.value = text;
    input.dispatchEvent(new InputEvent('input', { bubbles: true }));

    expect(input.validity.valid).toBe(true);
  });

  it('rejects more than two visible characters', () => {
    input.value = '本田技';
    input.dispatchEvent(new InputEvent('input', { bubbles: true }));

    expect(input.validationMessage).toBe('Enter up to two characters.');
  });

  it.each(['\u00A0山田\u3000', '\uFEFFOP '])('trims Unicode spaces around %j like the server', (text) => {
    input.value = text;
    input.dispatchEvent(new InputEvent('input', { bubbles: true }));

    expect(input.validity.valid).toBe(true);
  });

  it.each(['\u200B\u200B', 'A\u202E', 'x\u007F', `a${'\u0301'.repeat(5)}`])('rejects invisible characters in %j', (text) => {
    input.value = text;
    input.dispatchEvent(new InputEvent('input', { bubbles: true }));

    expect(input.validationMessage).toBe('Use only visible characters.');
  });

  it('validates the committed text after Japanese input composition', () => {
    input.value = 'honda';
    input.dispatchEvent(new InputEvent('input', { bubbles: true, isComposing: true }));
    expect(input.validity.valid).toBe(true);

    input.value = '本田';
    input.dispatchEvent(new CompositionEvent('compositionend', { bubbles: true, data: '本田' }));
    expect(input.validity.valid).toBe(true);

    input.value = '本田技';
    input.dispatchEvent(new InputEvent('input', { bubbles: true, isComposing: true }));
    expect(input.validity.valid).toBe(true);

    input.dispatchEvent(new CompositionEvent('compositionend', { bubbles: true, data: '本田技' }));
    expect(input.validity.customError).toBe(true);
  });
});
