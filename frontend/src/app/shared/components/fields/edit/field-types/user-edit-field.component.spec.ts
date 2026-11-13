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

import { ChangeDetectionStrategy, Component } from '@angular/core';
import { expectTypeOf, type Mock } from 'vitest';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { By } from '@angular/platform-browser';
import { Subject } from 'rxjs';
import { screen } from '@testing-library/dom';
import { States } from 'core-app/core/states/states.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PrincipalsResourceService } from 'core-app/core/state/principals/principals.service';
import { PrincipalRendererService } from 'core-app/shared/components/principal/principal-renderer.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { OpenprojectAutocompleterModule } from 'core-app/shared/components/autocompleter/openproject-autocompleter.module';
import { SelectionErrorComponent, SelectionInputAttrsPipe } from 'core-app/shared/components/autocompleter/selection/selection-error.component';
import {
  UserAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/user-autocompleter/user-autocompleter.component';
import {
  OpEditingPortalChangesetToken,
  OpEditingPortalHandlerToken,
  OpEditingPortalSchemaToken,
} from 'core-app/shared/components/fields/edit/edit-field.component';
import { UserSelection } from 'core-app/shared/components/autocompleter/selection/user-selection';
import { UserEditFieldComponent } from './user-edit-field.component';

expectTypeOf<UserEditFieldComponent['onSelectionChange']>().parameter(0).toEqualTypeOf<UserSelection>();

@Component({
  imports: [OpenprojectAutocompleterModule, SelectionErrorComponent, SelectionInputAttrsPipe],
  templateUrl: './user-edit-field.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [{ provide: PrincipalRendererService, useValue: { render: () => undefined } }],
})
class TestUserEditFieldComponent extends UserEditFieldComponent {}

describe('UserEditFieldComponent', () => {
  let fixture:ComponentFixture<TestUserEditFieldComponent>;
  let http:HttpTestingController;
  let resource:HalResource;
  let values$:Subject<unknown>;
  let handler:{
    fieldName:string;
    htmlId:string;
    inEditMode:boolean;
    handleUserSubmit:Mock<() => Promise<void>>;
    handleUserCancel:Mock<() => void>;
    deactivate:Mock<() => void>;
  };

  const schema = {
    name: 'Assignee',
    allowedValues: { $link: { href: '/api/v3/work_packages/1/available_assignees' } },
  };

  function changeset() {
    return {
      projectedResource: resource,
      schema: { ofProperty: () => schema, mappedName: (name:string) => name },
      state: { values$: () => values$ },
    };
  }

  function refresh() {
    values$.next(changeset());
    fixture.detectChanges();
  }

  async function openWithAda() {
    await vi.waitFor(() => {
      fixture.detectChanges();
      http.match(() => true).forEach((request) => request.flush({
        _embedded: {
          elements: [{ id: 7, name: 'Ada', email: 'ada@example.com', _links: { self: { href: '/api/v3/users/7' } } }],
        },
      }));
      fixture.detectChanges();
      expect(screen.getByRole('option', { name: /Ada/ })).toBeTruthy();
    });
  }

  async function recreateWith(assignee:unknown) {
    fixture.destroy();
    resource.assignee = assignee;
    fixture = TestBed.createComponent(TestUserEditFieldComponent);
    fixture.detectChanges();
    await openWithAda();
  }

  async function chooseAda() {
    screen.getByRole('option', { name: /Ada/ }).click();
    fixture.detectChanges();
    await fixture.whenStable();
  }

  beforeEach(async () => {
    vi.stubGlobal('ErrorReporter', { captureMessage: vi.fn() });
    values$ = new Subject();
    handler = {
      fieldName: 'assignee',
      htmlId: 'wp-assignee',
      inEditMode: false,
      handleUserSubmit: vi.fn(() => Promise.resolve()),
      handleUserCancel: vi.fn(),
      deactivate: vi.fn(),
    };

    await TestBed.configureTestingModule({
      imports: [TestUserEditFieldComponent],
      providers: [
        States,
        provideHttpClient(),
        provideHttpClientTesting(),
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: PrincipalsResourceService, useValue: {} },
        { provide: OpEditingPortalHandlerToken, useValue: handler },
        { provide: OpEditingPortalSchemaToken, useValue: schema },
        { provide: OpEditingPortalChangesetToken, useFactory: changeset },
      ],
    }).compileComponents();

    http = TestBed.inject(HttpTestingController);
    resource = TestBed.inject(HalResourceService).createHalResource({
      _links: { self: { href: '/api/v3/work_packages/1' } },
    });
    resource.assignee = null;
    fixture = TestBed.createComponent(TestUserEditFieldComponent);
    fixture.detectChanges();
    await openWithAda();
  });

  afterEach(() => {
    fixture.destroy();
    vi.unstubAllGlobals();
  });

  it('submits a user resource once when an option is selected', async () => {
    await chooseAda();

    expect(handler.handleUserSubmit).toHaveBeenCalledOnce();
    const assignee = resource.assignee as HalResource;
    expect(assignee).toBeInstanceOf(HalResource);
    expect(assignee.$halType).toBe('user');
    expect(assignee.href).toBe('/api/v3/users/7');
    expect(assignee.name).toBe('Ada');
  });

  it('reloads the selection only when the field value changes', () => {
    const load = vi.spyOn(fixture.componentInstance.selection.bridge, 'load');

    refresh();

    expect(load).not.toHaveBeenCalled();
    expect(handler.handleUserSubmit).not.toHaveBeenCalled();

    const other = { id: 8, name: 'Grace', href: '/api/v3/users/8' };
    resource.assignee = other;
    refresh();

    expect(load).toHaveBeenCalledExactlyOnceWith(other);
    expect(handler.handleUserSubmit).not.toHaveBeenCalled();
  });

  it('shows an alert for a malformed change and recovers on a valid choice', async () => {
    const autocompleter = fixture.debugElement.query(By.directive(UserAutocompleterComponent))
      .componentInstance as UserAutocompleterComponent;

    autocompleter.changed({ id: '99', name: 99 });
    fixture.detectChanges();

    expect(screen.getByRole('alert').textContent).toContain('js.autocompleter.invalid_selection');
    expect(handler.handleUserSubmit).not.toHaveBeenCalled();

    await chooseAda();

    expect(screen.queryByRole('alert')).toBeNull();
    expect(handler.handleUserSubmit).toHaveBeenCalledOnce();
  });

  it('clears a malformed change from the autocompleter when nothing was selected before', async () => {
    const autocompleter = fixture.debugElement.query(By.directive(UserAutocompleterComponent))
      .componentInstance as UserAutocompleterComponent;

    autocompleter.changed({ id: {}, name: 'Rejected' });
    await fixture.whenStable();

    expect(screen.queryByText('Rejected')).toBeNull();
    expect(screen.getByRole('alert')).toBeTruthy();
  });

  it('marks the combobox invalid and describes it by the error until recovery', async () => {
    const autocompleter = fixture.debugElement.query(By.directive(UserAutocompleterComponent))
      .componentInstance as UserAutocompleterComponent;
    const combobox = screen.getByRole('combobox');

    autocompleter.changed({ id: '99', name: 99 });
    await fixture.whenStable();

    expect(combobox).toHaveAttribute('aria-invalid', 'true');
    expect(combobox).toHaveAccessibleDescription('js.autocompleter.invalid_selection');

    await chooseAda();

    expect(combobox).toHaveAttribute('aria-invalid', 'false');
    expect(combobox).not.toHaveAccessibleDescription();
  });

  it('recovers by choosing the option a malformed change shares its identity with', async () => {
    const autocompleter = fixture.debugElement.query(By.directive(UserAutocompleterComponent))
      .componentInstance as UserAutocompleterComponent;

    autocompleter.changed({ id: '7', name: 7 });
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    expect(screen.getByRole('alert')).toBeTruthy();

    await chooseAda();

    expect(screen.queryByRole('alert')).toBeNull();
    expect(handler.handleUserSubmit).toHaveBeenCalledOnce();
    expect((resource.assignee as HalResource).href).toBe('/api/v3/users/7');
  });

  it('does not submit when loading options reconciles a link-only value', async () => {
    await recreateWith({ id: 7, href: '/api/v3/users/7' });
    await fixture.whenStable();
    fixture.detectChanges();

    expect(handler.handleUserSubmit).not.toHaveBeenCalled();
    expect(screen.queryByRole('alert')).toBeNull();
  });

  it('auto-submits null once when the selection is cleared', async () => {
    await recreateWith({ id: 7, name: 'Ada', href: '/api/v3/users/7' });

    screen.getByRole('button', { name: /clear/i }).click();
    fixture.detectChanges();
    await fixture.whenStable();

    expect(handler.handleUserSubmit).toHaveBeenCalledOnce();
    expect(resource.assignee).toBeNull();
  });
});
