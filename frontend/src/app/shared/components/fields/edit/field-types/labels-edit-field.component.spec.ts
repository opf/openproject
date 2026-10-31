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

import {
  ChangeDetectionStrategy, Component, CUSTOM_ELEMENTS_SCHEMA, input, output,
} from '@angular/core';
import { expectTypeOf } from 'vitest';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { By } from '@angular/platform-browser';
import { of, Subject } from 'rxjs';
import { screen } from '@testing-library/dom';
import { States } from 'core-app/core/states/states.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { OpenprojectAutocompleterModule } from 'core-app/shared/components/autocompleter/openproject-autocompleter.module';
import {
  LabelsAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/labels-autocompleter/labels-autocompleter.component';
import { SelectionErrorComponent } from 'core-app/shared/components/autocompleter/selection/selection-error.component';
import {
  OpEditingPortalChangesetToken,
  OpEditingPortalHandlerToken,
  OpEditingPortalSchemaToken,
} from 'core-app/shared/components/fields/edit/edit-field.component';
import { LabelSelection } from 'core-app/shared/components/autocompleter/selection/label-selection';
import { LabelsEditFieldComponent } from './labels-edit-field.component';

expectTypeOf<LabelsEditFieldComponent['onSelectionChange']>().parameter(0).toEqualTypeOf<LabelSelection[]>();

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'edit-field-controls',
  template: '<button type="button" [disabled]="invalid()" (click)="onSave.emit()">{{ saveTitle() }}</button>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
class EditFieldControlsStubComponent {
  readonly fieldController = input<unknown>();
  readonly invalid = input(false);
  readonly saveTitle = input('');
  readonly cancelTitle = input('');
  // eslint-disable-next-line @angular-eslint/no-output-on-prefix
  readonly onSave = output();
  // eslint-disable-next-line @angular-eslint/no-output-on-prefix
  readonly onCancel = output();
}

@Component({
  imports: [OpenprojectAutocompleterModule, SelectionErrorComponent, EditFieldControlsStubComponent],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
  templateUrl: './labels-edit-field.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
class TestLabelsEditFieldComponent extends LabelsEditFieldComponent {}

describe('LabelsEditFieldComponent', () => {
  let fixture:ComponentFixture<TestLabelsEditFieldComponent>;
  let http:HttpTestingController;
  let resource:HalResource;
  let values$:Subject<unknown>;
  let handler:{
    fieldName:string;
    htmlId:string;
    inEditMode:boolean;
    inFlight:boolean;
    handleUserSubmit:ReturnType<typeof vi.fn>;
    handleUserCancel:ReturnType<typeof vi.fn>;
    handleUserKeydown:ReturnType<typeof vi.fn>;
    deactivate:ReturnType<typeof vi.fn>;
  };

  const schema = {
    name: 'Labels',
    allowedValues: { $link: { href: '/api/v3/projects/1/labels' } },
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

  function saveButton() {
    return screen.getByRole('button', { name: 'js.inplace.button_save' });
  }

  function autocompleter() {
    return fixture.debugElement.query(By.directive(LabelsAutocompleterComponent))
      .componentInstance as LabelsAutocompleterComponent;
  }

  async function openWithBug() {
    await vi.waitFor(() => {
      fixture.detectChanges();
      http.match(() => true).forEach((request) => request.flush({
        _embedded: {
          elements: [{ id: 3, name: 'Bug', _links: { self: { href: '/api/v3/labels/3' } } }],
        },
      }));
      fixture.detectChanges();
      expect(screen.getByRole('option', { name: /Bug/ })).toBeTruthy();
    });
  }

  async function createTag(name:string) {
    const input = screen.getByRole('combobox');
    input.focus();
    (input as HTMLInputElement).value = name;
    input.dispatchEvent(new Event('input'));
    fixture.detectChanges();
    await vi.waitFor(() => {
      fixture.detectChanges();
      http.match(() => true).forEach((request) => request.flush({ _embedded: { elements: [] } }));
      fixture.detectChanges();
      expect(screen.getByRole('option', { name: /js.autocompleter.create_label/ })).toBeTruthy();
    });
    screen.getByRole('option', { name: /js.autocompleter.create_label/ }).click();
    fixture.detectChanges();
    await fixture.whenStable();
  }

  async function configure(labels:unknown) {
    await TestBed.configureTestingModule({
      imports: [TestLabelsEditFieldComponent],
      providers: [
        States,
        provideHttpClient(),
        provideHttpClientTesting(),
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: CurrentUserService, useValue: { hasCapabilities$: () => of(true) } },
        { provide: OpEditingPortalHandlerToken, useValue: handler },
        { provide: OpEditingPortalSchemaToken, useValue: schema },
        { provide: OpEditingPortalChangesetToken, useFactory: changeset },
      ],
    }).compileComponents();

    http = TestBed.inject(HttpTestingController);
    const halResourceService = TestBed.inject(HalResourceService);
    resource = halResourceService.createHalResource({
      _links: { self: { href: '/api/v3/work_packages/1' } },
    });
    resource.project = halResourceService.createHalResourceOfType('project', { id: '1', _links: { self: { href: '/api/v3/projects/1' } } });
    resource.labels = labels;
    fixture = TestBed.createComponent(TestLabelsEditFieldComponent);
    fixture.detectChanges();
    await vi.waitFor(() => {
      fixture.detectChanges();
      expect(screen.getByRole('combobox').getAttribute('aria-expanded')).toBe('true');
    });
  }

  beforeEach(() => {
    vi.stubGlobal('ErrorReporter', { captureMessage: vi.fn(), addHook: vi.fn() });
    values$ = new Subject();
    handler = {
      fieldName: 'labels',
      htmlId: 'wp-labels',
      inEditMode: false,
      inFlight: false,
      handleUserSubmit: vi.fn(() => Promise.resolve()),
      handleUserCancel: vi.fn(),
      handleUserKeydown: vi.fn(),
      deactivate: vi.fn(),
    };
  });

  afterEach(() => {
    fixture?.destroy();
    vi.unstubAllGlobals();
  });

  describe('with no labels', () => {
    beforeEach(async () => {
      await configure([]);
    });

    it('submits a created label as a draft only when Save is pressed', async () => {
      await createTag('Needs triage');

      expect(handler.handleUserSubmit).not.toHaveBeenCalled();
      saveButton().click();

      expect(handler.handleUserSubmit).toHaveBeenCalledOnce();
      const labels = resource.labels as HalResource[];
      expect(labels).toHaveLength(1);
      expect(labels[0].$halType).toBe('Label');
      expect(labels[0].name).toBe('Needs triage');
      expect(labels[0].id).toBeNull();
      expect(labels[0].href).toBeNull();
    });

    it('disables Save while the selection is invalid and recovers on a valid one', async () => {
      autocompleter().change.emit([{ id: '99', name: 99 }]);
      fixture.detectChanges();

      expect((saveButton() as HTMLButtonElement).disabled).toBe(true);
      expect(screen.getByRole('alert').textContent).toContain('js.autocompleter.invalid_selection');
      expect(resource.labels).toEqual([]);

      await createTag('Fresh');

      expect(screen.queryByRole('alert')).toBeNull();
      expect((saveButton() as HTMLButtonElement).disabled).toBe(false);
    });
  });

  describe('with selected labels', () => {
    beforeEach(async () => {
      await configure([
        { id: 3, name: 'Bug', href: '/api/v3/labels/3' },
        { id: 4, name: 'Task', href: '/api/v3/labels/4' },
      ]);
    });

    function removePill(name:string) {
      const pill = screen.getByText(name).closest('.ng-value');
      pill?.querySelector<HTMLElement>('.ng-value-icon')?.click();
      fixture.detectChanges();
    }

    it('submits the remainder when a pill is removed and Save is pressed', async () => {
      removePill('Bug');
      await fixture.whenStable();

      expect(handler.handleUserSubmit).not.toHaveBeenCalled();
      saveButton().click();

      const labels = resource.labels as HalResource[];
      expect(labels.map((label) => label.href)).toEqual(['/api/v3/labels/4']);
    });

    it('submits an empty list when the last pills are removed', async () => {
      removePill('Bug');
      removePill('Task');
      await fixture.whenStable();

      saveButton().click();

      expect(handler.handleUserSubmit).toHaveBeenCalledOnce();
      expect(resource.labels).toEqual([]);
    });
  });

  describe('with an unresolved reference', () => {
    beforeEach(async () => {
      await configure([{ id: '7', href: '/api/v3/labels/7' }]);
    });

    it('keeps the reference when an option is added', async () => {
      await openWithBug();
      screen.getByRole('option', { name: /Bug/ }).click();
      fixture.detectChanges();
      await fixture.whenStable();

      saveButton().click();

      const labels = resource.labels as HalResource[];
      expect(labels.map((label) => label.href)).toEqual(['/api/v3/labels/7', '/api/v3/labels/3']);
      expect(labels[1].name).toBe('Bug');
    });

    it('reloads the selection only when the field value changes', () => {
      const load = vi.spyOn(fixture.componentInstance.selection.bridge, 'load');

      refresh();

      expect(load).not.toHaveBeenCalled();

      const other = [{ id: 8, name: 'Other', href: '/api/v3/labels/8' }];
      resource.labels = other;
      refresh();

      expect(load).toHaveBeenCalledExactlyOnceWith(other);
    });
  });

  describe.each([
    ['a scalar ID', '7', [{ id: '7' }]],
    ['an empty relationship', { href: null }, []],
  ])('with %s as the initial value', (_name, labels, expectedModel) => {
    beforeEach(async () => {
      await configure(labels);
    });

    it('renders without error and keeps the bound model stable', () => {
      const model = autocompleter().model;

      expect(model).toEqual(expectedModel);
      expect(screen.queryByRole('alert')).toBeNull();

      fixture.componentInstance.cdRef.markForCheck();
      fixture.detectChanges();

      expect(autocompleter().model).toBe(model);
    });
  });

  describe('when writing the value re-emits the changeset', () => {
    it('does not reload the selection from its own write', async () => {
      await configure([]);
      const load = vi.spyOn(fixture.componentInstance.selection.bridge, 'load');
      const stored = { labels: resource.labels };
      Object.defineProperty(resource, 'labels', {
        configurable: true,
        get: () => stored.labels,
        set: (value) => {
          stored.labels = value;
          values$.next(changeset());
        },
      });

      await createTag('Needs triage');

      expect(load).not.toHaveBeenCalled();
      expect(stored.labels).toHaveLength(1);
    });
  });

  describe('with malformed initial data', () => {
    it('shows an error without rendering the payload', async () => {
      await configure([{ id: '5', name: 5 }]);

      expect(screen.getByRole('alert')).toBeTruthy();
      expect((saveButton() as HTMLButtonElement).disabled).toBe(true);
    });

    it('clears a further malformed change from the autocompleter', async () => {
      await configure([{ id: '5', name: 5 }]);

      autocompleter().changed([{ id: '99', name: 99 }]);
      fixture.detectChanges();

      expect(autocompleter().model).toEqual([]);
      expect(screen.getByRole('alert')).toBeTruthy();
    });
  });
});
