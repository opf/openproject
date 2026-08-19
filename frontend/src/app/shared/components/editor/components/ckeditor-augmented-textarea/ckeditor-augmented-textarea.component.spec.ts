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

import { ComponentFixture, TestBed } from '@angular/core/testing';
import { vi } from 'vitest';

import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { States } from 'core-app/core/states/states.service';
import { CkeditorAugmentedTextareaComponent } from './ckeditor-augmented-textarea.component';

describe('CkeditorAugmentedTextareaComponent', () => {
  let fixture:ComponentFixture<CkeditorAugmentedTextareaComponent>;
  let component:CkeditorAugmentedTextareaComponent;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [CkeditorAugmentedTextareaComponent],
      providers: [
        { provide: PathHelperService, useValue: {} },
        { provide: HalResourceService, useValue: {} },
        { provide: ToastService, useValue: {} },
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: States, useValue: {} },
      ],
    })
      // Skip the real template (op-ckeditor and friends) — this skeleton only
      // exercises the refresh listener, not the editor itself.
      .overrideComponent(CkeditorAugmentedTextareaComponent, { set: { template: '' } })
      .compileComponents();

    // No detectChanges() → ngOnInit does not run, so no CKEditor instance is created.
    fixture = TestBed.createComponent(CkeditorAugmentedTextareaComponent);
    component = fixture.componentInstance;
  });

  afterEach(() => vi.restoreAllMocks());

  it('flushes to the textarea when a refresh beforeSnapshot event fires', () => {
    const form = document.createElement('form');
    component.formElement = form;
    const sync = vi.spyOn(component, 'syncToTextarea').mockImplementation(() => undefined);

    (component as unknown as { registerRefreshSyncListener():void }).registerRefreshSyncListener();
    form.dispatchEvent(new Event('refresh-on-form-changes:beforeSnapshot'));

    expect(sync).toHaveBeenCalledTimes(1);
  });

  describe('form submit interception', () => {
    let form:HTMLFormElement;
    let sync:ReturnType<typeof vi.spyOn>;
    let saveForm:ReturnType<typeof vi.spyOn>;

    beforeEach(() => {
      form = document.createElement('form');
      component.formElement = form;
      sync = vi.spyOn(component, 'syncToTextarea').mockImplementation(() => undefined);
      saveForm = vi.spyOn(component, 'saveForm').mockResolvedValue(undefined);
      (component as unknown as { registerFormSubmitListener():void }).registerFormSubmitListener();
    });

    it('delegates to saveForm when submit is not already prevented', () => {
      const event = new SubmitEvent('submit', { cancelable: true, bubbles: true });
      form.dispatchEvent(event);

      expect(event.defaultPrevented).toBe(true);
      expect(saveForm).toHaveBeenCalledWith(event);
      expect(sync).not.toHaveBeenCalled();
    });

    it('only syncs when another handler already prevented default', () => {
      const event = new SubmitEvent('submit', { cancelable: true, bubbles: true });
      event.preventDefault();
      form.dispatchEvent(event);

      expect(saveForm).not.toHaveBeenCalled();
      expect(sync).toHaveBeenCalledTimes(1);
    });
  });
});
