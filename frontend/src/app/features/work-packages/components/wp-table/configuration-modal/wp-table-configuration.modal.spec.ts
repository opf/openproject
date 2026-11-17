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

import { AsyncPipe, NgClass, NgComponentOutlet } from '@angular/common';
import { ApplicationRef, Component, input, output } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { fireEvent, within } from '@testing-library/dom';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';
import { States } from 'core-app/core/states/states.service';
import { QueryFormResource } from 'core-app/features/hal/resources/query-form-resource';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { WorkPackageStatesInitializationService } from 'core-app/features/work-packages/components/wp-list/wp-states-initialization.service';
import { buildQuery } from 'core-app/features/work-packages/components/wp-fast-table/testing/table-harness';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { DraggableOption } from 'core-app/shared/components/autocompleter/draggable-autocomplete/draggable-autocomplete.component';
import { OpModalLocalsToken, OpModalService } from 'core-app/shared/components/modal/modal.service';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { ScrollableTabsComponent } from 'core-app/shared/components/tabs/scrollable-tabs/scrollable-tabs.component';
import { TabCountComponent } from 'core-app/shared/components/tabs/tab-badges/tab-count.component';
import { Subject } from 'rxjs';
import { page } from 'vitest/browser';
import { TabComponent, TabInterface } from './tab-portal-outlet';
import { WpTableConfigurationColumnsTabComponent } from './tabs/columns-tab.component';
import { WpTableConfigurationModalComponent } from './wp-table-configuration.modal';
import { WpTableConfigurationService } from './wp-table-configuration.service';

@Component({
  selector: 'op-draggable-autocompleter',
  template: `
    <ul [attr.aria-label]="dragAreaLabel()">
      @for (column of selected(); track column.id) {
        <li>{{ column.name }}</li>
      }
    </ul>
    @for (column of options(); track column.id) {
      <button (click)="onChange.emit([...selected(), column])">Add {{ column.name }}</button>
    }
  `,
})
class ColumnsPickerStubComponent {
  options = input.required<DraggableOption[]>();
  selected = input.required<DraggableOption[]>();
  inputLabel = input.required<string>();
  inputPlaceholder = input.required<string>();
  dragAreaLabel = input.required<string>();
  id = input.required<string>();
  // eslint-disable-next-line @angular-eslint/no-output-on-prefix
  onChange = output<DraggableOption[]>();
}

@Component({ template: '<input aria-label="Draft filter">' })
class FiltersTabStubComponent implements TabComponent {
  onSave = vi.fn();
}

describe('table configuration modal', () => {
  const tabs:TabInterface[] = [
    { id: 'columns', name: 'Columns', componentClass: WpTableConfigurationColumnsTabComponent },
    { id: 'filters', name: 'Filters', componentClass: FiltersTabStubComponent },
    { id: 'sorting', name: 'Sorting', componentClass: FiltersTabStubComponent, disable: 'Unavailable' },
  ];

  let form$:Subject<[QueryFormResource, QueryResource]>;
  let query:QueryResource;
  let columns:WorkPackageViewColumnsService;
  let close:ReturnType<typeof vi.fn<OpModalService['close']>>;
  let initialTab:string;
  let loadPromise:Promise<unknown>;

  beforeEach(async () => {
    await page.viewport(1280, 800);
    form$ = new Subject();
    query = buildQuery(['subject'], null, false, false);
    close = vi.fn();
    initialTab = 'columns';

    await TestBed.configureTestingModule({
      imports: [AsyncPipe, NgClass, NgComponentOutlet, OpTooltipDirective, ColumnsPickerStubComponent, FiltersTabStubComponent],
      declarations: [
        WpTableConfigurationModalComponent,
        WpTableConfigurationColumnsTabComponent,
        ScrollableTabsComponent,
        TabCountComponent,
      ],
      providers: [
        States,
        IsolatedQuerySpace,
        WorkPackageViewColumnsService,
        { provide: ApiV3Service, useValue: { queries: { form: { load: () => form$ } } } },
        { provide: ConfigurationService, useValue: {} },
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: OpModalLocalsToken, useFactory: () => ({ initialTab, service: { close } }) },
        { provide: WpTableConfigurationService, useValue: { tabs } },
        { provide: WorkPackageNotificationService, useValue: { handleRawError: vi.fn() } },
        { provide: WorkPackageStatesInitializationService, useValue: { updateStatesFromForm: vi.fn() } },
        {
          provide: LoadingIndicatorService,
          useValue: { indicator: () => ({ set promise(value:Promise<unknown>) { loadPromise = value; } }) },
        },
      ],
    }).compileComponents();

    const querySpace = TestBed.inject(IsolatedQuerySpace);
    querySpace.query.putValue(query);
    querySpace.available.columns.putValue(buildQuery(['subject', 'status'], null, false, false).columns);
    columns = TestBed.inject(WorkPackageViewColumnsService);
    columns.initialize(query, query.results);
  });

  function resolveForm() {
    const form = new QueryFormResource(TestBed.inject(ApplicationRef).injector, {}, true, () => undefined, 'Form');
    form$.next([form, query]);
    form$.complete();
    return loadPromise;
  }

  it('selects the requested tab after loading, preserves visited roots and applies column edits', async () => {
    initialTab = 'filters';
    const fixture = TestBed.createComponent(WpTableConfigurationModalComponent);
    const modal = within(fixture.nativeElement);
    const update = vi.fn(() => columns.getColumns().map((column) => column.id));
    fixture.componentInstance.onDataUpdated.subscribe(update);
    await fixture.whenStable();

    const filters = modal.getByRole('tab', { name: 'Filters' });
    expect(filters).toHaveAttribute('aria-selected', 'false');
    await resolveForm();
    await fixture.whenStable();

    expect(filters).toHaveAttribute('aria-selected', 'true');
    const draftFilter = modal.getByRole('textbox', { name: 'Draft filter' });
    fireEvent.input(draftFilter, { target: { value: 'Edited' } });

    const columnsTab = modal.getByRole('tab', { name: 'Columns' });
    fireEvent.click(columnsTab);
    await fixture.whenStable();
    expect(columnsTab).toHaveAttribute('aria-selected', 'true');
    const selected = modal.getByRole('list', { name: 'js.label_manage_columns' });
    expect(selected).toHaveTextContent('subject');

    fireEvent.click(modal.getByRole('button', { name: 'Add status' }));
    await fixture.whenStable();
    expect(within(selected).getByText('status')).toBeVisible();
    expect(columns.getColumns()).toEqual(query.columns);

    fireEvent.click(modal.getByRole('tab', { name: 'Sorting' }));
    await fixture.whenStable();
    expect(columnsTab).toHaveAttribute('aria-selected', 'true');

    fireEvent.click(filters);
    await fixture.whenStable();
    expect(draftFilter).toHaveValue('Edited');
    expect(draftFilter).toBeVisible();
    expect(selected).not.toBeInTheDocument();

    fireEvent.click(columnsTab);
    await fixture.whenStable();
    expect(selected).toBeVisible();
    expect(within(selected).getByText('status')).toBeVisible();

    fireEvent.click(modal.getByRole('button', { name: 'js.modals.button_apply' }));
    expect(update).toHaveReturnedWith(['subject', 'status']);
    expect(close).toHaveBeenCalledOnce();

    fixture.destroy();
    expect(selected).not.toBeInTheDocument();
    expect(draftFilter).not.toBeInTheDocument();
  });

  it('discards local column changes on Cancel', async () => {
    const fixture = TestBed.createComponent(WpTableConfigurationModalComponent);
    const modal = within(fixture.nativeElement);
    const update = vi.fn();
    fixture.componentInstance.onDataUpdated.subscribe(update);
    await fixture.whenStable();
    await resolveForm();
    await fixture.whenStable();

    fireEvent.click(modal.getByRole('button', { name: 'Add status' }));
    await fixture.whenStable();
    fireEvent.click(modal.getByRole('button', { name: 'js.modals.button_cancel' }));

    expect(close).toHaveBeenCalledOnce();
    expect(update).not.toHaveBeenCalled();
    expect(columns.getColumns()).toEqual(query.columns);
  });

  it('does not create a tab if cancelled while the form is loading', async () => {
    const app = TestBed.inject(ApplicationRef);
    const viewCount = app.viewCount;
    const fixture = TestBed.createComponent(WpTableConfigurationModalComponent);
    const modal = within(fixture.nativeElement);
    close.mockImplementation(() => fixture.destroy());
    await fixture.whenStable();

    fireEvent.click(modal.getByRole('button', { name: 'js.modals.button_cancel' }));
    expect(close).toHaveBeenCalledOnce();
    expect(fixture.componentRef.hostView.destroyed).toBe(true);
    expect(app.viewCount).toBe(viewCount);
    await resolveForm();

    expect(app.viewCount).toBe(viewCount);
    expect(modal.queryByRole('list', { name: 'js.label_manage_columns' })).not.toBeInTheDocument();
  });
});
