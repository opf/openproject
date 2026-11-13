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

import { CommonModule } from '@angular/common';
import { page } from 'vitest/browser';
import { Type } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { FormsModule } from '@angular/forms';
import { fireEvent, within } from '@testing-library/dom';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpModalLocalsToken, OpModalService } from 'core-app/shared/components/modal/modal.service';
import { ChildPagesMacroModalComponent } from './macro-child-pages-modal/child-pages-macro.modal';
import { WikiIncludePageMacroModalComponent } from './macro-wiki-include-page-modal/wiki-include-page-macro.modal';

async function render<T extends ChildPagesMacroModalComponent|WikiIncludePageMacroModalComponent>(component:Type<T>) {
  await page.viewport(1280, 800);
  const close = vi.fn<OpModalService['close']>();
  TestBed.configureTestingModule({
    imports: [CommonModule, FormsModule],
    declarations: [component],
    providers: [
      { provide: I18nService, useValue: { t: (key:string) => key } },
      { provide: OpModalLocalsToken, useValue: { service: { close }, page: 'demo:Original', includeParent: true } },
    ],
  });
  const fixture = TestBed.createComponent(component);
  await fixture.whenStable();
  const root = fixture.nativeElement as HTMLElement;
  return { fixture, root, close, modal: fixture.componentInstance, queries: within(root) };
}

describe.each([
  { component: ChildPagesMacroModalComponent, name: 'Child pages' },
  { component: WikiIncludePageMacroModalComponent, name: 'Wiki include' },
])('$name macro modal', ({ component }) => {
  it('renders the initial page and focuses its input', async () => {
    const { queries } = await render<ChildPagesMacroModalComponent|WikiIncludePageMacroModalComponent>(component);
    expect(queries.getByRole('textbox')).toHaveValue('demo:Original');
    expect(queries.getByRole('textbox')).toHaveFocus();
  });

  it('saves the edited page with the Save button', async () => {
    const { fixture, queries, modal, close } = await render<ChildPagesMacroModalComponent|WikiIncludePageMacroModalComponent>(component);
    fireEvent.change(queries.getByRole('textbox'), { target: { value: 'demo:Edited' } });
    await fixture.whenStable();
    expect(queries.getByRole('textbox')).toHaveValue('demo:Edited');
    fireEvent.click(queries.getByRole('button', { name: 'js.button_save' }));
    await fixture.whenStable();
    expect(modal.changed).toBe(true);
    expect(modal.page).toBe('demo:Edited');
    expect(close).toHaveBeenCalledOnce();
  });

  it('cancels without applying edited values', async () => {
    const { fixture, queries, modal, close } = await render<ChildPagesMacroModalComponent|WikiIncludePageMacroModalComponent>(component);
    fireEvent.change(queries.getByRole('textbox'), { target: { value: 'demo:Discarded' } });
    await fixture.whenStable();
    fireEvent.click(queries.getByRole('button', { name: 'js.button_cancel' }));
    await fixture.whenStable();
    expect(modal.changed).toBe(false);
    expect(modal.page).toBe('demo:Original');
    expect(close).toHaveBeenCalledOnce();
  });
});

describe('Child pages include-parent option', () => {
  it('renders and saves the changed checkbox value', async () => {
    const { fixture, queries, modal, close } = await render(ChildPagesMacroModalComponent);
    expect(queries.getByRole('checkbox')).toBeChecked();
    fireEvent.click(queries.getByRole('checkbox'));
    await fixture.whenStable();
    expect(queries.getByRole('checkbox')).not.toBeChecked();
    fireEvent.click(queries.getByRole('button', { name: 'js.button_save' }));
    await fixture.whenStable();
    expect(modal.includeParent).toBe(false);
    expect(close).toHaveBeenCalledOnce();
  });
});
