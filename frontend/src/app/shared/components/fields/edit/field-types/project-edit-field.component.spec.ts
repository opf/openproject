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

import { ChangeDetectionStrategy, Component, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { expectTypeOf, type Mock } from 'vitest';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { By } from '@angular/platform-browser';
import { Subject } from 'rxjs';
import { screen } from '@testing-library/dom';
import { States } from 'core-app/core/states/states.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { OpenprojectAutocompleterModule } from 'core-app/shared/components/autocompleter/openproject-autocompleter.module';
import {
  ProjectAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/project-autocompleter/project-autocompleter.component';
import { SelectionErrorComponent, SelectionInputAttrsPipe } from 'core-app/shared/components/autocompleter/selection/selection-error.component';
import {
  OpEditingPortalChangesetToken,
  OpEditingPortalHandlerToken,
  OpEditingPortalSchemaToken,
} from 'core-app/shared/components/fields/edit/edit-field.component';
import { ProjectSelection } from 'core-app/shared/components/autocompleter/selection/project-selection';
import { ProjectEditFieldComponent } from './project-edit-field.component';

expectTypeOf<ProjectEditFieldComponent['onSelectionChange']>().parameter(0).toEqualTypeOf<ProjectSelection>();

@Component({
  imports: [OpenprojectAutocompleterModule, SelectionErrorComponent, SelectionInputAttrsPipe],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
  templateUrl: './project-edit-field.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
class TestProjectEditFieldComponent extends ProjectEditFieldComponent {}

describe('ProjectEditFieldComponent', () => {
  let fixture:ComponentFixture<TestProjectEditFieldComponent>;
  let http:HttpTestingController;
  let resource:HalResource;
  let values$:Subject<unknown>;
  let typeValue:{ href:string }|null;
  let getForm:ReturnType<typeof vi.fn>;
  let resolveForm:() => void;
  let handler:{
    fieldName:string;
    htmlId:string;
    inEditMode:boolean;
    handleUserSubmit:Mock<() => Promise<void>>;
    handleUserCancel:Mock<() => void>;
    deactivate:Mock<() => void>;
  };
  let schema:{ name:string; allowedValues?:{ $link:{ href:string } } };

  const allowedValues = { $link: { href: '/api/v3/work_packages/1/available_projects' } };

  function changeset() {
    return {
      projectedResource: resource,
      schema: { ofProperty: () => schema, mappedName: (name:string) => name },
      state: { values$: () => values$ },
      value: () => typeValue,
      getForm,
    };
  }

  function refresh() {
    values$.next(changeset());
    fixture.detectChanges();
  }

  async function configure(options:{ isNew?:boolean; withAllowedValues?:boolean; project?:unknown } = {}) {
    const { isNew = false, withAllowedValues = true, project = null } = options;
    schema = { name: 'Project', ...(withAllowedValues && { allowedValues }) };

    await TestBed.configureTestingModule({
      imports: [TestProjectEditFieldComponent],
      providers: [
        States,
        provideHttpClient(),
        provideHttpClientTesting(),
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: OpEditingPortalHandlerToken, useValue: handler },
        { provide: OpEditingPortalSchemaToken, useFactory: () => schema },
        { provide: OpEditingPortalChangesetToken, useFactory: changeset },
      ],
    }).compileComponents();

    http = TestBed.inject(HttpTestingController);
    resource = TestBed.inject(HalResourceService).createHalResource({
      _links: { self: { href: isNew ? null : '/api/v3/work_packages/1' } },
    });
    resource.project = project;
    fixture = TestBed.createComponent(TestProjectEditFieldComponent);
    fixture.nativeElement.classList.add('op-wide-autocomplete-wrapper');
    fixture.detectChanges();
  }

  async function openWithApollo() {
    await vi.waitFor(() => {
      fixture.detectChanges();
      http.match(() => true).forEach((request) => request.flush({
        _type: 'Collection',
        total: 1,
        count: 1,
        pageSize: 1,
        offset: 1,
        _embedded: {
          elements: [{
            id: 7,
            name: 'Apollo',
            identifier: 'apollo',
            _type: 'Project',
            _links: { self: { href: '/api/v3/projects/7' }, ancestors: [] },
          }],
        },
      }));
      fixture.detectChanges();
      expect(screen.getByRole('option', { name: /Apollo/ })).toBeTruthy();
    });
  }

  async function chooseApollo() {
    screen.getByRole('option', { name: /Apollo/ }).click();
    fixture.detectChanges();
    await fixture.whenStable();
  }

  beforeEach(() => {
    vi.stubGlobal('ErrorReporter', { captureMessage: vi.fn() });
    values$ = new Subject();
    typeValue = null;
    getForm = vi.fn(() => new Promise<void>((resolve) => { resolveForm = resolve; }));
    handler = {
      fieldName: 'project',
      htmlId: 'wp-project',
      inEditMode: false,
      handleUserSubmit: vi.fn(() => Promise.resolve()),
      handleUserCancel: vi.fn(),
      deactivate: vi.fn(),
    };
  });

  afterEach(() => {
    fixture.destroy();
    vi.unstubAllGlobals();
  });

  describe('with an existing resource', () => {
    beforeEach(async () => {
      await configure();
      await openWithApollo();
    });

    it('submits a project resource once when an option is selected', async () => {
      await chooseApollo();

      expect(handler.handleUserSubmit).toHaveBeenCalledOnce();
      const project = resource.project as HalResource;
      expect(project).toBeInstanceOf(HalResource);
      expect(project.$halType).toBe('project');
      expect(project.href).toBe('/api/v3/projects/7');
      expect(project.name).toBe('Apollo');
    });

    it('reloads the selection only when the field value changes', () => {
      const load = vi.spyOn(fixture.componentInstance.selection.bridge, 'load');

      refresh();

      expect(load).not.toHaveBeenCalled();
      expect(handler.handleUserSubmit).not.toHaveBeenCalled();

      const other = { id: 8, name: 'Gemini', href: '/api/v3/projects/8' };
      resource.project = other;
      refresh();

      expect(load).toHaveBeenCalledExactlyOnceWith(other);
      expect(handler.handleUserSubmit).not.toHaveBeenCalled();
    });

    it('shows an alert for a malformed change and recovers on a valid choice', async () => {
      const autocompleter = fixture.debugElement.query(By.directive(ProjectAutocompleterComponent))
        .componentInstance as ProjectAutocompleterComponent;

      autocompleter.changed({ id: '99', name: 99 });
      fixture.detectChanges();

      expect(screen.getByRole('alert').textContent).toContain('js.autocompleter.invalid_selection');
      expect(handler.handleUserSubmit).not.toHaveBeenCalled();

      await chooseApollo();

      expect(screen.queryByRole('alert')).toBeNull();
      expect(handler.handleUserSubmit).toHaveBeenCalledOnce();
    });

    it('clears a malformed change from the autocompleter', async () => {
      const autocompleter = fixture.debugElement.query(By.directive(ProjectAutocompleterComponent))
        .componentInstance as ProjectAutocompleterComponent;

      autocompleter.changed({ id: {}, name: 'Rejected' });
      await fixture.whenStable();

      expect(screen.queryByText('Rejected')).toBeNull();
      expect(screen.getByRole('alert')).toBeTruthy();
    });

    it('loads an empty relationship as an empty selection', () => {
      resource.project = { href: null };
      refresh();

      expect(fixture.componentInstance.selection.state()).toEqual({ kind: 'ready', value: null });
      expect(screen.queryByRole('alert')).toBeNull();
    });

    it('keeps the active filter only for an existing resource', () => {
      typeValue = { href: '/api/v3/types/3' };

      expect(fixture.componentInstance.APIFilters).toEqual([
        { name: 'active', operator: '=', values: ['t'] },
      ]);
    });
  });

  describe('with a link-only reference as the initial value', () => {
    beforeEach(async () => {
      await configure({ project: { id: 7, href: '/api/v3/projects/7' } });
      await openWithApollo();
    });

    it('does not submit when loading options reconciles the value', async () => {
      await fixture.whenStable();
      fixture.detectChanges();

      expect(handler.handleUserSubmit).not.toHaveBeenCalled();
      expect(screen.queryByRole('alert')).toBeNull();
    });
  });

  describe('with a new resource', () => {
    beforeEach(async () => {
      await configure({ isNew: true, withAllowedValues: false });
    });

    it('loads the form before setting the url', async () => {
      expect(getForm).toHaveBeenCalledOnce();
      expect(fixture.componentInstance.url).toBeUndefined();

      schema.allowedValues = allowedValues;
      resolveForm();
      await vi.waitFor(() => {
        expect(fixture.componentInstance.url).toBe(allowedValues.$link.href);
      });
    });

    it('adds the type filter', () => {
      typeValue = { href: '/api/v3/types/3' };

      expect(fixture.componentInstance.APIFilters).toEqual([
        { name: 'active', operator: '=', values: ['t'] },
        { name: 'type_id', operator: '=', values: ['3'] },
      ]);
    });
  });
});
