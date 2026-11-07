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

import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { NgClass } from '@angular/common';
import { Component, Directive, input, output } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { FormsModule } from '@angular/forms';
import { fireEvent, screen, waitFor } from '@testing-library/dom';
import { ReplaySubject, Subject } from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { WorkPackageInlineCreateComponent } from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.component';
import { WorkPackageInlineCreateService } from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.service';
import { UrlParamsHelperService } from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { WorkPackageRelationsTabComponent } from 'core-app/features/work-packages/components/wp-single-view-tabs/relations-tab/relations-tab.component';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { OpIconComponent } from 'core-app/shared/components/icon/icon.component';
import { IAPIFilter } from 'core-app/shared/components/autocompleter/op-autocompleter/typings';
import { WpRelationInlineAddExistingComponent } from './embedded/inline/add-existing/wp-relation-inline-add-existing.component';
import { WpRelationInlineCreateServiceInterface } from './embedded/wp-relation-inline-create.service.interface';
import { WorkPackageRelationsService } from './wp-relations.service';
import { WorkPackageRelationsComponent } from './wp-relations.component';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'wp-relations-autocomplete',
  template: '<button type="button" (click)="change.emit(candidate)">Select work package</button>',
})
class AutocompleteStubComponent {
  readonly workPackage = input.required<WorkPackageResource>();
  readonly selectedRelationType = input<string>();
  readonly filterCandidatesFor = input<string>();
  readonly hiddenOverflowContainer = input.required<string>();
  readonly filters = input<IAPIFilter[]>();
  // eslint-disable-next-line @angular-eslint/no-output-native -- Matches the autocomplete contract.
  readonly change = output<WorkPackageResource>();
  // eslint-disable-next-line @angular-eslint/no-output-native -- Matches the autocomplete contract.
  readonly cancel = output<void>();

  candidate:WorkPackageResource;
}

@Directive({
  selector: '[opTooltip]',
  host: { '[attr.aria-label]': 'label()' },
})
class TooltipStubDirective {
  readonly label = input.required<string>();
}

@Component({
  selector: 'op-content-loader',
  template: '<ng-content />',
})
class ContentLoaderStubComponent {}

function deferred<T>() {
  let resolve!:(value:T) => void;
  let reject!:(error:unknown) => void;
  const promise = new Promise<T>((resolvePromise, rejectPromise) => {
    resolve = resolvePromise;
    reject = rejectPromise;
  });
  return { promise, resolve, reject };
}

describe('work package relation interactions', () => {
  const notification = {
    showSave: vi.fn<(wp:WorkPackageResource) => void>(),
    handleRawError: vi.fn<(error:unknown, wp:WorkPackageResource) => void>(),
  };
  const relations = {
    addCommonRelation: vi.fn<WorkPackageRelationsService['addCommonRelation']>(),
    updateCounter: vi.fn<WorkPackageRelationsService['updateCounter']>(),
    updateRelation: vi.fn<WorkPackageRelationsService['updateRelation']>(),
    updateRelationType: vi.fn<WorkPackageRelationsService['updateRelationType']>(),
    removeRelation: vi.fn<WorkPackageRelationsService['removeRelation']>(),
  };
  const resetRow = vi.fn<WorkPackageInlineCreateComponent['resetRow']>();
  const refresh = vi.fn<() => Promise<WorkPackageResource>>();
  const updateWorkPackage = vi.fn<(wp:WorkPackageResource) => Promise<void>>();
  let hal:HalResourceService;
  let streams:Map<string, Subject<WorkPackageResource>>;
  let schemaChanges:ReplaySubject<SchemaResource>;
  let inlineCreate:Pick<WpRelationInlineCreateServiceInterface, 'referenceTarget'|'relationType'|'newInlineWorkPackageReferenced'|'add'>;

  beforeEach(() => {
    vi.resetAllMocks();
    streams = new Map();
    schemaChanges = new ReplaySubject(1);
    TestBed.configureTestingModule({
      declarations: [
        OpIconComponent, WorkPackageRelationsTabComponent,
        WpRelationInlineAddExistingComponent, WorkPackageRelationsComponent,
      ],
      imports: [
        NgClass, FormsModule, AutocompleteStubComponent, TooltipStubDirective, ContentLoaderStubComponent,
      ],
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        { provide: CurrentProjectService, useValue: {} },
        { provide: CurrentUserService, useValue: {} },
        {
          provide: ApiV3Service,
          useValue: {
            work_packages: {
              cache: { updateWorkPackage },
              id: (wp:WorkPackageResource|string) => ({
                requireAndStream: () => streams.get(typeof wp === 'string' ? wp : wp.id!),
                refresh,
              }),
            },
          },
        },
        {
          provide: SchemaCacheService,
          useValue: {
            getSchemaHref: () => '/api/v3/work_packages/schemas/1-1',
            requireAndStream: () => schemaChanges,
            of: () => ({ isMilestone: false }),
            proxied: () => ({ isMilestone: false }),
          },
        },
        { provide: PathHelperService, useValue: { staticBase: '', workPackagePath: () => '/work_packages', genericWorkPackagePath: () => '/work_packages' } },
        { provide: TurboRequestsService, useValue: {} },
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: WorkPackageRelationsService, useValue: relations },
        { provide: WorkPackageNotificationService, useValue: notification },
        { provide: WorkPackageInlineCreateComponent, useValue: { resetRow } },
        { provide: WorkPackageInlineCreateService, useFactory: () => inlineCreate },
        { provide: UrlParamsHelperService, useValue: {} },
        IsolatedQuerySpace,
      ],
    });
    hal = TestBed.inject(HalResourceService);
    hal.registerResource('WorkPackage', { cls: WorkPackageResource });
  });

  function workPackage(id:number, subject:string) {
    streams.set(String(id), new Subject());
    return hal.createHalResource<WorkPackageResource>({
      _type: 'WorkPackage',
      subject,
      _links: {
        self: { href: `/api/v3/work_packages/${id}` },
        project: { href: '/api/v3/projects/1' },
        type: { href: '/api/v3/types/1', title: 'Task' },
      },
    });
  }

  function selectWorkPackage(candidate:WorkPackageResource, autocomplete:AutocompleteStubComponent) {
    autocomplete.candidate = candidate;
    fireEvent.click(screen.getByRole('button', { name: 'Select work package' }));
  }

  it.each([true, false])('settles the add-existing autocomplete (success=%s)', async (success) => {
    const wp = workPackage(1, 'Current');
    const related = workPackage(2, 'Related');
    const { promise, resolve, reject } = deferred<unknown>();
    inlineCreate = {
      referenceTarget: wp,
      relationType: 'children',
      newInlineWorkPackageReferenced: new Subject<string>(),
      add: vi.fn<WpRelationInlineCreateServiceInterface['add']>().mockReturnValue(promise),
    };
    const fixture = TestBed.createComponent(WpRelationInlineAddExistingComponent);
    const referenced = vi.fn<(id:string) => void>();
    const referencedSubscription = inlineCreate.newInlineWorkPackageReferenced.subscribe(referenced);
    await fixture.whenStable();
    const autocomplete = fixture.debugElement.query(
      (node) => node.componentInstance instanceof AutocompleteStubComponent,
    ).componentInstance as AutocompleteStubComponent;
    expect(autocomplete.filterCandidatesFor()).toBe('children');
    expect(screen.getByRole('button', { name: 'js.relation_buttons.abort' })).toBeInTheDocument();
    selectWorkPackage(related, autocomplete);
    expect(inlineCreate.add).toHaveBeenCalledWith(wp, '2');

    const error = new Error('Association failed');
    if (success) {
      resolve(undefined);
    } else {
      reject(error);
    }

    await waitFor(() => expect(resetRow).toHaveBeenCalledOnce());
    expect(refresh).toHaveBeenCalledTimes(success ? 1 : 0);
    expect(referenced.mock.calls).toEqual(success ? [['2']] : []);
    expect(notification.handleRawError.mock.calls).toEqual(success ? [] : [[error, wp]]);
    referencedSubscription.unsubscribe();
  });

  it('forwards the replacement work package to the relations tab and tears down both subscriptions', async () => {
    const first = workPackage(1, 'Current');
    const second = workPackage(2, 'Replacement');
    const fetchController = new AbortController();
    document.addEventListener('turbo:before-fetch-request', (event) => event.preventDefault(), { signal: fetchController.signal });
    const fixture = TestBed.createComponent(WorkPackageRelationsTabComponent);
    fixture.componentRef.onDestroy(() => fetchController.abort());
    const frame = () => (fixture.nativeElement as HTMLElement).querySelector('turbo-frame');
    fixture.componentRef.setInput('workPackage', first);
    await fixture.whenStable();
    const originalFrame = frame();
    expect(originalFrame).toHaveAttribute('src', '/work_packages/1/relations_tab');

    fixture.componentRef.setInput('workPackage', second);
    await fixture.whenStable();
    const replacementFrame = frame();
    expect(replacementFrame).toHaveAttribute('src', '/work_packages/2/relations_tab');
    expect(replacementFrame).not.toBe(originalFrame);
    expect(streams.get('1')!.observed).toBe(false);

    const updated = hal.createHalResource<WorkPackageResource>({ ...second.$source, subject: 'Loaded replacement' });
    const current = streams.get('2')!;
    current.next(updated);
    await fixture.whenStable();
    expect(fixture.componentInstance.workPackage).toBe(updated);
    expect(frame()).toBe(replacementFrame);

    fixture.destroy();
    expect(current.observed).toBe(false);
  });
});
