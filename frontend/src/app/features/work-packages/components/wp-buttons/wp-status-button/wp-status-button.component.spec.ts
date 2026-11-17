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
import { Directive, input } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { screen, waitFor } from '@testing-library/dom';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { States } from 'core-app/core/states/states.service';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { StatusResource } from 'core-app/features/hal/resources/status-resource';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { OpIconComponent } from 'core-app/shared/components/icon/icon.component';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { ToolTipElement } from 'core-app/shared/components/primer/tool-tip-element';
import { WorkPackageStatusButtonComponent } from './wp-status-button.component';

@Directive({
  // eslint-disable-next-line @angular-eslint/directive-selector -- Matches the production child.
  selector: '[wpStatusDropdown]',
})
class StatusDropdownStubDirective {
  // eslint-disable-next-line @angular-eslint/no-input-rename -- Matches the production child input.
  readonly workPackage = input.required<WorkPackageResource>({ alias: 'wpStatusDropdown-workPackage' });
}

const translations:Record<string, string> = {
  'js.work_packages.properties.status': 'Status',
  'js.work_packages.message_work_package_read_only': 'Work package is locked',
};
const schemaPath = '/api/v3/work_packages/schemas/1-1';
const waiting = 'Waiting for customer feedback';

function statusSource(id:number, name:string, readonly = false) {
  return {
    _type: 'Status',
    name,
    isReadonly: readonly,
    _links: { self: { href: `/api/v3/statuses/${id}` } },
  };
}

describe('WorkPackageStatusButtonComponent', () => {
  let fixture:ComponentFixture<WorkPackageStatusButtonComponent>;
  let hal:HalResourceService;
  let api:ApiV3Service;
  let http:HttpTestingController;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [CommonModule, OpTooltipDirective, StatusDropdownStubDirective],
      declarations: [WorkPackageStatusButtonComponent, OpIconComponent],
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        States,
        SchemaCacheService,
        HalResourceEditingService,
        { provide: I18nService, useValue: { t: (key:string) => translations[key] ?? key } },
      ],
    }).compileComponents();
    hal = TestBed.inject(HalResourceService);
    hal.registerResource('WorkPackage', { cls: WorkPackageResource, attrTypes: { status: 'Status' } });
    hal.registerResource('Status', { cls: StatusResource });
    api = TestBed.inject(ApiV3Service);
    http = TestBed.inject(HttpTestingController);
    await TestBed.inject(SchemaCacheService).updateValue(schemaPath, hal.createHalResourceOfClass(SchemaResource, {
      _links: { self: { href: schemaPath } },
      status: { name: 'Status', type: 'Status', writable: true },
    }, true));
  });

  afterEach(() => http.verify());

  function workPackage(id = 1, status = statusSource(1, waiting), { linked = false, readonly = false } = {}) {
    return hal.createHalResource<WorkPackageResource>({
      _type: 'WorkPackage',
      readonly,
      _links: {
        self: { href: `/api/v3/work_packages/${id}` },
        schema: { href: schemaPath },
        update: { href: `/api/v3/work_packages/${id}/form`, method: 'post' },
        status: { href: status._links.self.href, title: status.name },
      },
      ...(!linked && { _embedded: { status } }),
    });
  }

  async function render(resource = workPackage(), width = '') {
    await api.work_packages.cache.updateWorkPackage(resource);
    fixture = TestBed.createComponent(WorkPackageStatusButtonComponent);
    fixture.componentRef.setInput('workPackage', resource);
    const host = fixture.nativeElement as HTMLElement;
    host.style.display = 'block';
    host.style.width = width;
    await fixture.whenStable();
    return resource;
  }

  function observerCounts(resource:WorkPackageResource) {
    return [
      resource.state.getSubscriberCount(),
      TestBed.inject(HalResourceEditingService).typedState(resource).getSubscriberCount(),
    ];
  }

  function tooltip() {
    const element = (fixture.nativeElement as HTMLElement).querySelector<ToolTipElement>('tool-tip');
    if (!element) throw new Error('Status tooltip was not rendered');
    return element;
  }

  it('shows the full status in a tooltip while the status is cut off', async () => {
    await render(workPackage(), '60px');

    screen.getByRole('button', { name: `Status ${waiting}` }).focus();

    await waitFor(() => expect(tooltip().matches(':popover-open')).toBe(true));
    expect(tooltip()).toHaveTextContent(`Status ${waiting}`);
  });

  it('shows no tooltip while the status fits', async () => {
    await render();

    screen.getByRole('button', { name: `Status ${waiting}` }).focus();
    await new Promise((resolve) => { setTimeout(resolve, 100); });

    expect(tooltip().matches(':popover-open')).toBe(false);
  });

  it('describes a locked status by its reason even when the status fits', async () => {
    await render(workPackage(1, statusSource(1, waiting), { readonly: true }));

    const button = screen.getByRole('button', { name: `Status ${waiting}` });
    expect(button).toHaveAccessibleDescription('Work package is locked');

    button.focus();
    await waitFor(() => expect(tooltip().matches(':popover-open')).toBe(true));
  });

  it('renders a new status when the same work package is republished', async () => {
    const resource = await render();
    expect(screen.getByRole('button', { name: `Status ${waiting}` })).toBeInTheDocument();

    resource.status = hal.createHalResource<StatusResource>(statusSource(2, 'Resolved'));
    await api.work_packages.cache.updateWorkPackage(resource);

    expect(await screen.findByRole('button', { name: 'Status Resolved' })).toHaveClass('__hl_background', '__hl_status_2');
  });

  it('renders a projected status and restores the pristine status after cancelling the edit', async () => {
    const resource = await render();
    const editing = TestBed.inject(HalResourceEditingService);
    const change = editing.changeFor(resource);
    change.projectedResource.status = hal.createHalResource<StatusResource>(statusSource(2, 'Projected status'));
    change.push();

    expect(await screen.findByRole('button', { name: 'Status Projected status' })).toBeInTheDocument();
    expect(resource.status.name).toBe(waiting);

    editing.reset(change);
    expect(await screen.findByRole('button', { name: `Status ${waiting}` })).toBeInTheDocument();
  });

  it('updates the name and lock description after the linked status finishes loading', async () => {
    const resource = await render(workPackage(1, statusSource(2, 'Initial title'), { linked: true }));
    const status = resource.status;
    const button = screen.getByRole('button', { name: 'Status Initial title' });
    expect(button).not.toHaveAccessibleDescription('Work package is locked');

    http.expectOne('/api/v3/statuses/2').flush(statusSource(2, 'Locked after loading', true));

    expect(await screen.findByRole('button', { name: 'Status Locked after loading' }))
      .toHaveAccessibleDescription('Work package is locked');
    expect(resource.status).toBe(status);
  });

  it('keeps the linked title after a failed details request and renders a later successful load', async () => {
    const resource = await render(workPackage(1, statusSource(2, 'Initial title'), { linked: true }));

    http.expectOne('/api/v3/statuses/2').flush(
      { _type: 'Error', message: 'Status details unavailable' },
      { status: 500, statusText: 'Internal Server Error' },
    );
    await waitFor(() => expect(resource.status.state.hasActivePromiseRequest()).toBe(false));
    expect(screen.getByRole('button', { name: 'Status Initial title' })).toBeInTheDocument();

    await api.work_packages.cache.updateWorkPackage(workPackage(1, statusSource(2, 'Retry title'), { linked: true }));
    http.expectOne('/api/v3/statuses/2').flush(statusSource(2, 'Recovered status', true));

    expect(await screen.findByRole('button', { name: 'Status Recovered status' }))
      .toHaveAccessibleDescription('Work package is locked');
  });

  it.each([
    {
      outcome: 'succeeds',
      response: statusSource(2, 'Obsolete locked status', true),
      options: undefined,
    },
    {
      outcome: 'fails',
      response: { _type: 'Error', message: 'Status details unavailable' },
      options: { status: 500, statusText: 'Internal Server Error' },
    },
  ])('ignores a pending status request that $outcome after replacement', async ({ response, options }) => {
    const original = await render(workPackage(1, statusSource(2, 'Original status'), { linked: true }));
    const request = http.expectOne('/api/v3/statuses/2');
    const replacement = workPackage(2, statusSource(3, 'Current status'));
    await api.work_packages.cache.updateWorkPackage(replacement);
    fixture.componentRef.setInput('workPackage', replacement);
    await screen.findByRole('button', { name: 'Status Current status' });

    request.flush(response, options);
    await waitFor(() => expect(original.status.state.hasActivePromiseRequest()).toBe(false));
    await fixture.whenStable();
    expect(screen.getByRole('button', { name: 'Status Current status' }))
      .not.toHaveAccessibleDescription('Work package is locked');

    await api.work_packages.cache.updateWorkPackage(workPackage(2, statusSource(4, 'Current update', true)));
    expect(await screen.findByRole('button', { name: 'Status Current update' }))
      .toHaveAccessibleDescription('Work package is locked');
  });

  it('follows a replacement work package and releases the previous cache and changeset', async () => {
    const original = workPackage();
    const initialCounts = observerCounts(original);
    await render(original);
    const change = TestBed.inject(HalResourceEditingService).changeFor(original);
    const rebase = vi.spyOn(change, 'updatePristineResource');
    expect(observerCounts(original)).toEqual(initialCounts.map((count) => count + 1));

    const replacement = workPackage(2, statusSource(2, 'In progress'));
    await api.work_packages.cache.updateWorkPackage(replacement);
    fixture.componentRef.setInput('workPackage', replacement);
    expect(await screen.findByRole('button', { name: 'Status In progress' })).toBeInTheDocument();

    await api.work_packages.cache.updateWorkPackage(workPackage(1, statusSource(3, 'Old update'), { linked: true }));
    await fixture.whenStable();
    http.expectNone('/api/v3/statuses/3');
    expect(screen.getByRole('button', { name: 'Status In progress' })).toBeInTheDocument();

    await api.work_packages.cache.updateWorkPackage(workPackage(2, statusSource(4, 'New update')));
    expect(await screen.findByRole('button', { name: 'Status New update' })).toBeInTheDocument();
    expect(rebase).not.toHaveBeenCalled();
    expect(observerCounts(original)).toEqual(initialCounts);
  });

  it('releases the work package cache and changeset when destroyed', async () => {
    const resource = workPackage();
    const initialCounts = observerCounts(resource);
    await render(resource);
    const change = TestBed.inject(HalResourceEditingService).changeFor(resource);
    const rebase = vi.spyOn(change, 'updatePristineResource');

    fixture.destroy();
    expect(observerCounts(resource)).toEqual(initialCounts);

    await api.work_packages.cache.updateWorkPackage(workPackage(1, statusSource(2, 'Update after teardown'), { linked: true }));
    http.expectNone('/api/v3/statuses/2');
    expect(rebase).not.toHaveBeenCalled();
  });
});
