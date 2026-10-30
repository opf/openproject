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
import { TestBed } from '@angular/core/testing';
import { NEVER } from 'rxjs';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { States } from 'core-app/core/states/states.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { EditFormComponent } from '../edit-form/edit-form.component';
import { HalResourceEditingService } from '../services/hal-resource-editing.service';
import { EditableAttributeFieldComponent } from './editable-attribute-field.component';

describe('EditableAttributeFieldComponent activation events', () => {
  function setup(doubleClick = false) {
    const activate = vi.fn().mockResolvedValue(undefined);
    const close = vi.fn();
    TestBed.configureTestingModule({
      imports: [CommonModule],
      declarations: [EditableAttributeFieldComponent],
      providers: [
        { provide: ConfigurationService, useValue: { requireDoubleClickForInlineEdit: () => doubleClick } },
        { provide: I18nService, useValue: {} },
        { provide: SchemaCacheService, useValue: { of: () => ({ isAttributeEditable: () => true }) } },
        { provide: States, useValue: {} },
        { provide: OPContextMenuService, useValue: { close } },
        { provide: EditFormComponent, useValue: { register: vi.fn(), activate } },
        { provide: HalResourceEditingService, useValue: {
          temporaryEditResource: () => ({ values$: () => NEVER }),
          typedState: () => ({ hasValue: () => false }),
        } },
      ],
    });
    const fixture = TestBed.createComponent(EditableAttributeFieldComponent);
    fixture.componentRef.setInput('fieldName', 'subject');
    fixture.componentRef.setInput('resource', {});
    fixture.detectChanges();
    const display = fixture.componentInstance.displayContainer.nativeElement;
    return { fixture, display, activate, close };
  }

  it.each(['click', 'keydown'])('activates with a %s event from the real template', (type) => {
    const { display, activate, close } = setup();
    const event = type === 'click'
      ? new MouseEvent(type, { bubbles: true, cancelable: true })
      : new KeyboardEvent(type, { key: 'Enter', bubbles: true, cancelable: true });
    display.dispatchEvent(event);
    expect(activate).toHaveBeenCalledExactlyOnceWith('subject', false);
    expect(close).toHaveBeenCalledExactlyOnceWith();
    expect(event.defaultPrevented).toBe(true);
  });

  it('keeps double-click configuration and ignores links', () => {
    const { display, activate } = setup(true);
    display.dispatchEvent(new MouseEvent('click', { bubbles: true }));
    expect(activate).not.toHaveBeenCalled();
    const link = document.createElement('a');
    display.append(link);
    link.dispatchEvent(new MouseEvent('dblclick', { bubbles: true }));
    expect(activate).not.toHaveBeenCalled();
    display.dispatchEvent(new MouseEvent('dblclick', { bubbles: true }));
    expect(activate).toHaveBeenCalledExactlyOnceWith('subject', false);
  });
});
