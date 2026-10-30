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
import { Component, inject, NgModule, signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { HttpClient } from '@angular/common/http';
import { config, EMPTY, of, Subject } from 'rxjs';
import { FormsModule } from '@angular/forms';
import { By } from '@angular/platform-browser';
import { userEvent } from 'vitest/browser';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { SpotCheckboxComponent } from 'core-app/spot/components/checkbox/checkbox.component';
import { SpotTooltipComponent } from 'core-app/spot/components/tooltip/tooltip.component';
import { SpotTextFieldComponent } from 'core-app/spot/components/text-field/text-field.component';
import { SpotToggleComponent } from 'core-app/spot/components/toggle/toggle.component';
import { OpSharedModule } from 'core-app/shared/shared.module';
import { OpSearchHighlightDirective } from 'core-app/shared/directives/search-highlight.directive';
import { IProjectData } from 'core-app/shared/components/searchable-project-list/project-data';
import { SearchableProjectListService } from 'core-app/shared/components/searchable-project-list/searchable-project-list.service';
import { OpProjectIncludeListComponent } from './list/project-include-list.component';

import { OpProjectIncludeComponent } from './project-include.component';
import { SpotDropModalComponent } from 'core-app/spot/components/drop-modal/drop-modal.component';
import { OpLoadingProjectListComponent } from 'core-app/shared/components/searchable-project-list/loading-project-list.component';
import { IconModule } from 'core-app/shared/components/icon/icon.module';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { WorkPackageViewIncludeSubprojectsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-include-subprojects.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';

function project(id:string, children:IProjectData[] = [], disabled = false):IProjectData {
  return { id, href: `/api/v3/projects/${id}`, identifier: id, name: id, _type: 'Project', disabled, children, position: 0 };
}

@Component({
  template: `
    <div data-searchable-list-parent="true">
      <input aria-label="Search projects" (keydown)="service.onKeydown($event, projects)">
      <ul op-project-include-list data-list-root="true" [projects]="projects"
          [selected]="selected()" [includeSubprojects]="includeSubprojects()"
          (update)="selected.set($event)"></ul>
    </div>
  `,
  providers: [SearchableProjectListService],
  standalone: false,
})
class ProjectIncludeHostComponent {
  service = inject(SearchableProjectListService);
  projects = [project('parent', [project('child'), project('disabled', [], true)]), project('last')];
  selected = signal<string[]>([]);
  includeSubprojects = signal(false);
}

@NgModule({
  imports: [OpSharedModule],
  declarations: [ProjectIncludeHostComponent],
})
class ProjectIncludeTestModule {}

describe('project inclusion interaction', () => {
  let fixtures:ComponentFixture<ProjectIncludeHostComponent>[];

  beforeEach(async () => {
    fixtures = [];
    TestBed.overrideModule(ProjectIncludeTestModule, {
      set: {
        imports: [CommonModule, FormsModule, IconModule],
        declarations: [ProjectIncludeHostComponent, OpProjectIncludeComponent, OpProjectIncludeListComponent,
          OpSearchHighlightDirective, OpLoadingProjectListComponent, SpotCheckboxComponent, SpotTooltipComponent,
          SpotTextFieldComponent, SpotToggleComponent, SpotDropModalComponent],
        exports: [OpProjectIncludeListComponent],
        providers: [],
      },
    });
    TestBed.overrideComponent(SpotDropModalComponent, { set: { template: '<ng-content />' } });
    await TestBed.configureTestingModule({
      imports: [ProjectIncludeTestModule],
      providers: [
        { provide: IsolatedQuerySpace, useValue: { query: { values$: () => EMPTY } } },
        { provide: WorkPackageViewFiltersService, useValue: { live$: () => of([]) } },
        { provide: WorkPackageViewIncludeSubprojectsService, useValue: {} },
        { provide: HalResourceService, useValue: {} },
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: CurrentProjectService, useValue: {} },
        { provide: PathHelperService, useValue: {} },
        { provide: HttpClient, useValue: {} },
        { provide: ConfigurationService, useValue: { maximumApiV3PageSize: 1000 } },
        { provide: ApiV3Service, useValue: { projects: { signalled: () => of({ _embedded: { elements: [] } }) } } },
      ],
    }).compileComponents();
  });

  afterEach(() => fixtures.forEach((fixture) => fixture.destroy()));

  function mount(projects?:IProjectData[]):ComponentFixture<ProjectIncludeHostComponent> {
    const fixture = TestBed.createComponent(ProjectIncludeHostComponent);
    fixtures.push(fixture);
    if (projects) fixture.componentInstance.projects = projects;
    fixture.detectChanges();
    fixture.componentInstance.service.resetActiveResult(fixture.componentInstance.projects);
    fixture.detectChanges();
    return fixture;
  }

  function label(fixture:ComponentFixture<ProjectIncludeHostComponent>, id:string):HTMLLabelElement {
    const element = (fixture.nativeElement as HTMLElement)
      .querySelector(`[data-qa-project-include-id="${id}"]`)?.closest('label');
    if (!element) throw new Error(`Missing label for ${id}`);
    return element;
  }

  function checkbox(fixture:ComponentFixture<ProjectIncludeHostComponent>, id:string):HTMLInputElement {
    return label(fixture, id).querySelector('input')!;
  }

  function key(fixture:ComponentFixture<ProjectIncludeHostComponent>, value:string):KeyboardEvent {
    const event = new KeyboardEvent('keydown', { key: value, bubbles: true, cancelable: true });
    (fixture.nativeElement as HTMLElement).querySelector('input')!.dispatchEvent(event);
    fixture.detectChanges();
    return event;
  }

  it('highlights the exact nested selection while arrows skip disabled entries in list order', () => {
    const fixture = mount();
    expect(label(fixture, 'parent')).toHaveClass('spot-list--item-action_active');
    key(fixture, 'ArrowDown');
    expect(fixture.componentInstance.service.selectedItemID$.value).toBe('child');
    expect(label(fixture, 'child')).toHaveClass('spot-list--item-action_active');
    expect(label(fixture, 'parent')).not.toHaveClass('spot-list--item-action_active');
    key(fixture, 'ArrowDown');
    expect(fixture.componentInstance.service.selectedItemID$.value).toBe('last');
    expect(label(fixture, 'last')).toHaveClass('spot-list--item-action_active');
    key(fixture, 'ArrowUp');
    expect(fixture.componentInstance.service.selectedItemID$.value).toBe('child');
    expect(label(fixture, 'child')).toHaveClass('spot-list--item-action_active');
  });

  it.each([
    { name: 'first root', projects: [project('parent'), project('last')], active: 'parent', expected: 'parent' },
    { name: 'first nested sibling', projects: [project('parent', [project('child')])], active: 'child', expected: 'parent' },
    { name: 'child of a disabled first parent', projects: [project('parent', [project('child')], true)], active: 'child', expected: 'child' },
  ])('handles ArrowUp at the $name without an async exception', async ({ projects, active, expected }) => {
    const fixture = mount(projects);
    fixture.componentInstance.service.selectedItemID$.next(active);
    fixture.detectChanges();
    const previousHandler = config.onUnhandledError;
    const onUnhandledError = vi.fn();
    config.onUnhandledError = onUnhandledError;
    try {
      key(fixture, 'ArrowUp');
      await new Promise((resolve) => window.setTimeout(resolve));
      expect(onUnhandledError).not.toHaveBeenCalled();
      expect(fixture.componentInstance.service.selectedItemID$.value).toBe(expected);
      expect(label(fixture, expected)).toHaveClass('spot-list--item-action_active');
    } finally {
      config.onUnhandledError = previousHandler;
    }
  });

  it('activates the nested selected project with Enter only in its own view and restores search focus', () => {
    const other = mount();
    const fixture = mount();
    key(fixture, 'ArrowDown');
    const search = (fixture.nativeElement as HTMLElement).querySelector('input')!;
    search.focus();
    const event = key(fixture, 'Enter');
    expect(event.defaultPrevented).toBe(true);
    expect(fixture.componentInstance.selected()).toEqual(['/api/v3/projects/child']);
    expect(checkbox(fixture, 'child')).toBeChecked();
    expect(other.componentInstance.selected()).toEqual([]);
    expect(checkbox(other, 'child')).not.toBeChecked();
    expect(document.activeElement).toBe(search);
  });

  it('toggles nested list labels with Space and pointer input without selecting disabled entries', () => {
    const fixture = mount();
    label(fixture, 'child').dispatchEvent(new KeyboardEvent('keydown', { key: ' ', bubbles: true }));
    fixture.detectChanges();
    expect(fixture.componentInstance.selected()).toEqual(['/api/v3/projects/child']);
    expect(checkbox(fixture, 'child')).toBeChecked();
    checkbox(fixture, 'child').click();
    fixture.detectChanges();
    expect(fixture.componentInstance.selected()).toEqual([]);
    label(fixture, 'disabled').dispatchEvent(new KeyboardEvent('keydown', { key: ' ', bubbles: true }));
    checkbox(fixture, 'disabled').click();
    fixture.detectChanges();
    expect(checkbox(fixture, 'disabled')).toBeDisabled();
    expect(fixture.componentInstance.selected()).toEqual([]);
  });

  it('leaves Space in the search input available for text entry', async () => {
    const fixture = mount();
    expect(key(fixture, ' ').defaultPrevented).toBe(false);
    const search = (fixture.nativeElement as HTMLElement).querySelector('input')!;
    search.focus();
    await userEvent.keyboard('a b');
    expect(search).toHaveValue('a b');
    expect(fixture.componentInstance.selected()).toEqual([]);
  });

  it('shows nested inherited inclusion without changing explicit selection membership', () => {
    const fixture = mount();
    fixture.componentInstance.selected.set(['/api/v3/projects/parent']);
    fixture.componentInstance.includeSubprojects.set(true);
    fixture.detectChanges();
    expect(checkbox(fixture, 'parent')).toBeChecked();
    expect(checkbox(fixture, 'child')).toBeChecked();
    expect(fixture.componentInstance.selected()).toEqual(['/api/v3/projects/parent']);
    fixture.componentInstance.includeSubprojects.set(false);
    fixture.detectChanges();
    expect(checkbox(fixture, 'child')).not.toBeChecked();
  });

  it('toggles once when Space bubbles from a focused native checkbox', async () => {
    const fixture = mount();
    const input = checkbox(fixture, 'child');
    await userEvent.click(label(fixture, 'child'));
    input.focus();
    fixture.detectChanges();
    expect(fixture.componentInstance.selected()).toEqual(['/api/v3/projects/child']);
    expect(document.activeElement).toBe(input);
    const updates = vi.fn();
    fixture.debugElement.query(By.directive(OpProjectIncludeListComponent)).componentInstance.update.subscribe(updates);
    await userEvent.keyboard(' ');
    fixture.detectChanges();
    expect(fixture.componentInstance.selected()).toEqual([]);
    expect(input).not.toBeChecked();
    expect(updates).toHaveBeenCalledExactlyOnceWith([]);
  });

  it('passes false for unresolved subproject inclusion and follows boolean emissions', () => {
    const fixture = TestBed.createComponent(OpProjectIncludeComponent);
    const includeSubprojects$ = new Subject<boolean>();
    Object.defineProperty(fixture.componentInstance, 'includeSubprojects$', { value: includeSubprojects$ });
    fixture.componentInstance.projects$ = of([project('parent', [project('child')])]);
    fixture.componentInstance.selectedProjects = ['/api/v3/projects/parent'];
    fixture.detectChanges();
    const list = fixture.debugElement.query(By.directive(OpProjectIncludeListComponent)).componentInstance as OpProjectIncludeListComponent;
    expect(list.includeSubprojects).toBe(false);
    includeSubprojects$.next(true);
    fixture.detectChanges();
    expect(list.includeSubprojects).toBe(true);
    expect((fixture.nativeElement as HTMLElement).querySelector('[data-qa-project-include-id="child"] input')).toBeChecked();
    includeSubprojects$.next(false);
    fixture.detectChanges();
    expect(list.includeSubprojects).toBe(false);
    expect((fixture.nativeElement as HTMLElement).querySelector('[data-qa-project-include-id="child"] input')).not.toBeChecked();
    fixture.destroy();
  });
});
