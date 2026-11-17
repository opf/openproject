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

import '@openproject/primer-view-components/app/components/primer/alpha/tool_tip.js';
import { CommonModule } from '@angular/common';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { Component, input, output } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { fireEvent, screen, waitFor, within } from '@testing-library/dom';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { WorkPackageRelationsHierarchyService } from 'core-app/features/work-packages/components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { OpIconComponent } from 'core-app/shared/components/icon/icon.component';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { WorkPackageBreadcrumbParentComponent } from './wp-breadcrumb-parent.component';
import { WorkPackageBreadcrumbComponent } from './wp-breadcrumb.component';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector -- Matches the production child.
  selector: 'wp-relations-autocomplete',
  template: '<input [attr.aria-label]="placeholder()" (keydown.escape)="cancel.emit()" />',
})
class RelationsAutocompleteStubComponent {
  readonly workPackage = input.required<WorkPackageResource>();
  readonly placeholder = input.required<string>();
  readonly filterCandidatesFor = input.required<string>();
  // eslint-disable-next-line @angular-eslint/no-output-native -- Matches the production child output.
  readonly cancel = output<void>();
  // eslint-disable-next-line @angular-eslint/no-output-native -- Matches the production child output.
  readonly change = output<WorkPackageResource|null>();
}

const translations:Record<string, string> = {
  'js.relation_buttons.change_parent': 'Change parent',
  'js.relation_buttons.remove_parent': 'Remove parent',
  'js.relation_buttons.set_parent': 'Set parent',
  'js.relations_autocomplete.parent_placeholder': 'Search for a parent',
  'js.relations_hierarchy.parent_headline': 'Parent',
  'js.relations_hierarchy.hierarchy_headline': 'Hierarchy',
};

const workPackagePath = '/api/v3/work_packages/1';
const parentPath = '/api/v3/work_packages/2';
const grandparentPath = '/api/v3/work_packages/3';

function source({ hasParent = true, canChangeParent = true } = {}) {
  return {
    _type: 'WorkPackage',
    subject: 'Current package',
    lockVersion: 4,
    _links: {
      self: { href: workPackagePath },
      parent: { href: hasParent ? parentPath : null, title: 'Parent package' },
      ancestors: hasParent ? [
        { href: grandparentPath, title: 'Grandparent package' },
        { href: parentPath, title: 'Parent package' },
      ] : [],
      ...(canChangeParent && { changeParent: { href: workPackagePath, method: 'patch' } }),
    },
  };
}

describe('Work-package breadcrumb', () => {
  let hal:HalResourceService;
  let api:ApiV3Service;
  let http:HttpTestingController;
  const notifications = {
    handleRawError: vi.fn<WorkPackageNotificationService['handleRawError']>(),
    showSave: vi.fn<WorkPackageNotificationService['showSave']>(),
  };

  beforeEach(async () => {
    vi.clearAllMocks();
    await TestBed.configureTestingModule({
      imports: [CommonModule, OpTooltipDirective, RelationsAutocompleteStubComponent],
      declarations: [WorkPackageBreadcrumbParentComponent, WorkPackageBreadcrumbComponent, OpIconComponent],
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        States,
        SchemaCacheService,
        WorkPackageRelationsHierarchyService,
        { provide: I18nService, useValue: { t: (key:string) => translations[key] ?? key } },
        { provide: WorkPackageNotificationService, useValue: notifications },
      ],
    }).compileComponents();
    hal = TestBed.inject(HalResourceService);
    hal.registerResource('WorkPackage', {
      cls: WorkPackageResource,
      attrTypes: { parent: 'WorkPackage', ancestors: 'WorkPackage' },
    });
    api = TestBed.inject(ApiV3Service);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => http.verify());

  async function renderParent(options?:Parameters<typeof source>[0]) {
    const workPackage = hal.createHalResource<WorkPackageResource>(source(options));
    const fixture = TestBed.createComponent(WorkPackageBreadcrumbParentComponent);
    fixture.componentRef.setInput('workPackage', workPackage);
    await fixture.whenStable();
    return { fixture, workPackage };
  }

  it('labels the icon-only parent buttons with tooltips and links to the parent', async () => {
    await renderParent();

    expect(screen.getByRole('link', { name: 'Parent package' }))
      .toHaveAttribute('href', '/work_packages/2/activity' + window.location.search);
    expect(screen.getByRole('button', { name: 'Change parent' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Remove parent' })).toBeInTheDocument();
    expect(screen.getAllByRole('tooltip', { hidden: true })).toHaveLength(2);
  });

  it('names the set parent button by its text when there is no parent', async () => {
    await renderParent({ hasParent: false });

    expect(screen.getByRole('button', { name: 'Set parent' })).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: 'Remove parent' })).not.toBeInTheDocument();
    expect(screen.queryByRole('tooltip', { hidden: true })).not.toBeInTheDocument();
  });

  it('links to the parent without edit controls when the change-parent link is missing', async () => {
    await renderParent({ canChangeParent: false });

    expect(screen.getByRole('link', { name: 'Parent package' })).toBeInTheDocument();
    expect(screen.queryByRole('button')).not.toBeInTheDocument();
  });

  it('clears the saving flag after publishing a successful removal', async () => {
    const { fixture } = await renderParent();

    fireEvent.click(screen.getByRole('button', { name: 'Remove parent' }));
    expect(fixture.componentInstance.isSaving).toBe(true);
    const request = http.expectOne({ url: workPackagePath, method: 'PATCH' });
    expect(request.request.body).toEqual({ lockVersion: 4, _links: { parent: { href: null } } });
    request.flush(source({ hasParent: false }));

    await waitFor(() => expect(fixture.componentInstance.isSaving).toBe(false));
    expect(api.work_packages.cache.current('1')?.parent).toBeNull();
  });

  it('clears the saving flag and retains the current parent when removal fails', async () => {
    const { fixture, workPackage } = await renderParent();

    fireEvent.click(screen.getByRole('button', { name: 'Remove parent' }));
    expect(fixture.componentInstance.isSaving).toBe(true);
    http.expectOne({ url: workPackagePath, method: 'PATCH' }).flush(
      { _type: 'Error', message: 'Parent could not be removed' },
      { status: 422, statusText: 'Unprocessable Entity' },
    );

    await waitFor(() => expect(fixture.componentInstance.isSaving).toBe(false));
    expect(notifications.handleRawError).toHaveBeenCalledWith(expect.anything(), workPackage);
    expect(screen.getByRole('link', { name: 'Parent package' })).toBeInTheDocument();
  });

  it('changes the parent to the chosen work package', async () => {
    const { fixture } = await renderParent();
    const chosen = hal.createHalResource<WorkPackageResource>({
      _type: 'WorkPackage',
      id: 3,
      _links: { self: { href: grandparentPath } },
    });

    fireEvent.click(screen.getByRole('button', { name: 'Change parent' }));
    await screen.findByRole('textbox', { name: 'Search for a parent' });
    const autocomplete = fixture.debugElement.query(By.directive(RelationsAutocompleteStubComponent));
    (autocomplete.componentInstance as RelationsAutocompleteStubComponent).change.emit(chosen);

    const request = http.expectOne({ url: workPackagePath, method: 'PATCH' });
    expect(request.request.body).toEqual({ lockVersion: 4, _links: { parent: { href: grandparentPath } } });
    request.flush(source());
    await waitFor(() => expect(fixture.componentInstance.isSaving).toBe(false));
  });

  it('ignores a native change event that carries no work package', async () => {
    await renderParent();

    fireEvent.click(screen.getByRole('button', { name: 'Change parent' }));
    fireEvent.change(await screen.findByRole('textbox', { name: 'Search for a parent' }));

    http.expectNone({ url: workPackagePath, method: 'PATCH' });
  });

  it('hides the ancestor links while the parent selector is open and restores them on cancel', async () => {
    const workPackage = hal.createHalResource<WorkPackageResource>(source());
    const fixture = TestBed.createComponent(WorkPackageBreadcrumbComponent);
    fixture.componentRef.setInput('workPackage', workPackage);
    await fixture.whenStable();
    const breadcrumb = within(screen.getByRole('list'));

    expect(breadcrumb.getByText('Hierarchy:')).toBeInTheDocument();
    expect(breadcrumb.getByRole('link', { name: 'Grandparent package' }))
      .toHaveAttribute('href', '/work_packages/3/activity' + window.location.search);
    fireEvent.click(breadcrumb.getByRole('button', { name: 'Change parent' }));
    const selector = await breadcrumb.findByRole('textbox', { name: 'Search for a parent' });
    expect(breadcrumb.queryByRole('link', { name: 'Grandparent package' })).not.toBeInTheDocument();

    fireEvent.keyDown(selector, { key: 'Escape' });
    expect(await breadcrumb.findByRole('link', { name: 'Grandparent package' })).toBeInTheDocument();
    expect(breadcrumb.getByRole('link', { name: 'Parent package' })).toBeInTheDocument();
  });

  it('refreshes the hierarchy and current parent after the cache republishes the same work package', async () => {
    const workPackage = hal.createHalResource<WorkPackageResource>(source());
    await api.work_packages.cache.updateWorkPackage(workPackage, true);
    const fixture = TestBed.createComponent(WorkPackageBreadcrumbComponent);
    fixture.componentRef.setInput('workPackage', workPackage);
    await fixture.whenStable();
    expect(screen.getByRole('link', { name: 'Grandparent package' })).toBeInTheDocument();
    expect(screen.getByRole('link', { name: 'Parent package' })).toBeInTheDocument();

    workPackage.$initialize(source({ hasParent: false }));
    await api.work_packages.cache.updateWorkPackage(workPackage);

    expect(await screen.findByRole('button', { name: 'Set parent' })).toBeInTheDocument();
    expect(screen.queryByRole('link')).not.toBeInTheDocument();
    expect(screen.queryByText('Hierarchy:')).not.toBeInTheDocument();
  });
});
