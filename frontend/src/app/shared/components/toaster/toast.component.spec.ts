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
import { NO_ERRORS_SCHEMA } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ToastComponent } from './toast.component';
import { ToastsContainerComponent } from './toasts-container.component';
import { ToastService } from './toast.service';
import { OPToastEvent } from './toast-event';

describe('Toast rendering through the window event bridge', () => {
  let fixture:ComponentFixture<ToastsContainerComponent>;
  let service:ToastService;
  let element:HTMLElement;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [CommonModule],
      declarations: [ToastComponent, ToastsContainerComponent],
      schemas: [NO_ERRORS_SCHEMA],
      providers: [
        { provide: ConfigurationService, useValue: { autoHidePopups: () => false } },
        { provide: I18nService, useValue: { t: (key:string) => key } },
      ],
    }).compileComponents();
    service = TestBed.inject(ToastService);
    fixture = TestBed.createComponent(ToastsContainerComponent);
    element = fixture.nativeElement as HTMLElement;
    await fixture.whenStable();
  });

  it.each(['error', 'success'] as const)('keeps announcement semantics optional for %s toasts', async (type) => {
    window.dispatchEvent(new CustomEvent(OPToastEvent, { detail: { message: 'Ordinary feedback', type } }));
    await fixture.whenStable();
    expect(element.querySelector('[role="alert"][aria-atomic="true"]')?.textContent).toContain('Ordinary feedback');

    window.dispatchEvent(new CustomEvent(OPToastEvent, { detail: { message: 'Explicit announcement', type, announce: true } }));
    await fixture.whenStable();
    expect(element.querySelector('[role="alert"][aria-atomic="true"]')?.textContent).toContain('Explicit announcement');

    window.dispatchEvent(new CustomEvent(OPToastEvent, { detail: { message: 'Visual feedback', type, announce: false } }));
    await fixture.whenStable();
    expect(element.querySelector('.op-toast')?.textContent).toContain('Visual feedback');
    expect(element.querySelector('[role="alert"], [aria-live], [aria-atomic]')).toBeNull();
  });

  it('passes visual-only refusals through add and replaces the previous error toast', async () => {
    const add = vi.spyOn(service, 'add');
    for (let attempt = 1; attempt <= 2; attempt++) {
      const toast = { message: `Refusal ${attempt}`, type: 'error' as const, announce: false };
      window.dispatchEvent(new CustomEvent(OPToastEvent, { detail: toast }));
      await fixture.whenStable();
      expect(add).toHaveBeenCalledTimes(attempt);
      expect(add).toHaveBeenLastCalledWith(toast);
      expect(service.current.value).toEqual([toast]);
      expect(element.querySelectorAll('.op-toast')).toHaveLength(1);
      expect(element.querySelector('.op-toast')?.textContent).toContain(toast.message);
      expect(element.querySelector('[role="alert"], [aria-live], [aria-atomic]')).toBeNull();
    }
  });
});
