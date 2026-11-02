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

import { NO_ERRORS_SCHEMA } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { provideHttpClient, withInterceptorsFromDi, withXhr } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { NgSelectModule } from '@ng-select/ng-select';
import { of } from 'rxjs';
import { States } from 'core-app/core/states/states.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { LabelsAutocompleterComponent } from './labels-autocompleter.component';

describe('LabelsAutocompleterComponent', () => {
  let component:LabelsAutocompleterComponent;
  let currentUser:{ hasCapabilities$:ReturnType<typeof vi.fn> };

  const i18nStub = { t: (key:string) => key };

  beforeEach(async () => {
    currentUser = { hasCapabilities$: vi.fn(() => of(true)) };

    await TestBed.configureTestingModule({
      declarations: [LabelsAutocompleterComponent],
      imports: [NgSelectModule],
      schemas: [NO_ERRORS_SCHEMA],
      providers: [
        States,
        provideHttpClient(withXhr(), withInterceptorsFromDi()),
        provideHttpClientTesting(),
        { provide: I18nService, useValue: i18nStub },
        { provide: CurrentUserService, useValue: currentUser },
      ],
    }).compileComponents();

    component = TestBed.createComponent(LabelsAutocompleterComponent).componentInstance;
  });

  it('does not offer to create a blank term', () => {
    expect(component.createLabel('   ')).toBeUndefined();
  });

  it('returns a label with no href for a trimmed term', () => {
    expect(component.createLabel('  Needs triage ')).toEqual({ id: null, name: 'Needs triage', href: null });
  });

  it('enables addTag once the project grants work_packages/update, without throwing change-detection errors', () => {
    const fixture = TestBed.createComponent(LabelsAutocompleterComponent);
    fixture.componentRef.setInput('projectId', '1');

    expect(() => fixture.detectChanges()).not.toThrow();
    expect(typeof fixture.componentInstance.addTag).toBe('function');
    expect(currentUser.hasCapabilities$).toHaveBeenCalledWith('work_packages/update', '1');
  });

  it('does not offer addTag when the project withholds work_packages/update', () => {
    currentUser.hasCapabilities$.mockReturnValue(of(false));

    const fixture = TestBed.createComponent(LabelsAutocompleterComponent);
    fixture.componentRef.setInput('projectId', '1');
    fixture.detectChanges();

    expect(fixture.componentInstance.addTag).toBe(false);
  });

  it('does not offer addTag or query capabilities without a project', () => {
    const fixture = TestBed.createComponent(LabelsAutocompleterComponent);
    fixture.detectChanges();

    expect(fixture.componentInstance.addTag).toBe(false);
    expect(currentUser.hasCapabilities$).not.toHaveBeenCalled();
  });

  it('treats a label with no href and a persisted label with the same name as the same label, ignoring case', () => {
    const unsaved = { id: null, name: 'Needs Triage', href: null };
    const persisted = { id: 9, name: 'needs triage', href: '/api/v3/labels/9' };
    const other = { id: 10, name: 'Blocked', href: '/api/v3/labels/10' };

    expect(component.compareWith?.(unsaved, persisted)).toBe(true);
    expect(component.compareWith?.(unsaved, other)).toBe(false);
  });
});
