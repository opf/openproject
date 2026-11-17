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

import { NgClass } from '@angular/common';
import { Component, ElementRef, EventEmitter, Input, Output, inject, signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { FormsModule } from '@angular/forms';
import { AlertIconComponent } from '@openproject/octicons-angular';
import { fireEvent, within } from '@testing-library/dom';
import { finalize } from 'rxjs';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { States } from 'core-app/core/states/states.service';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { QueryOperatorResource } from 'core-app/features/hal/resources/query-operator-resource';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { validDate } from 'core-app/shared/components/datepicker/helpers/date-modal.helpers';
import { OpIconComponent } from 'core-app/shared/components/icon/icon.component';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { AutofocusDirective } from 'core-app/shared/directives/focus/autofocus.directive';
import { FilterDateTimeValueComponent } from '../filter-date-time-value/filter-date-time-value.component';
import { FilterDateTimesValueComponent } from '../filter-date-times-value/filter-date-times-value.component';
import { FilterDateValueComponent } from '../filter-date-value/filter-date-value.component';
import { FilterDatesValueComponent } from '../filter-dates-value/filter-dates-value.component';
import { FilterIntegerValueComponent } from '../filter-integer-value/filter-integer-value.component';
import { FilterStringValueComponent } from '../filter-string-value/filter-string-value.component';
import { QueryFilterComponent } from './query-filter.component';

@Component({
  selector: 'op-basic-single-date-picker, op-basic-single-datetime-picker',
  template: `
    <input [attr.aria-label]="label" [id]="id" [name]="name" [required]="required"
      [value]="value" (input)="valueChange.emit($event.target.value)" />
  `,
})
class SinglePickerStubComponent {
  @Input() id = '';
  @Input() name = '';
  @Input() required:string|boolean = false;
  @Input() value = '';
  @Output() readonly valueChange = new EventEmitter<string>();

  private readonly element = inject<ElementRef<HTMLElement>>(ElementRef).nativeElement;

  get label():string {
    if (this.element.localName === 'op-basic-single-date-picker') return 'Date';
    if (this.id.endsWith('-begin')) return 'Start date and time';
    if (this.id.endsWith('-end')) return 'End date and time';

    return 'Date and time';
  }
}

@Component({
  selector: 'op-basic-range-date-picker',
  template: `
    <input aria-label="Date range" [id]="id" [name]="name" [value]="draft"
      (input)="edit($event.target.value)" />
  `,
})
class RangePickerStubComponent {
  @Input() id = '';
  @Input() name = '';
  @Input() set value(dates:string[]) {
    this.draft = dates.join(' to ');
  }

  @Output() readonly valueChange = new EventEmitter<string[]>();

  protected draft = '';

  protected edit(value:string):void {
    this.draft = value;
    const dates = value.split(' to ');
    if (dates.every(validDate)) {
      this.valueChange.emit(dates);
    }
  }
}

@Component({
  selector: 'op-filter-boolean-value, op-filter-project, op-filter-toggled-multiselect-value, op-filter-searchable-multiselect-value',
  template: '',
})
class OtherFilterStubComponent {
  @Input() filter:QueryFilterInstanceResource;
  @Input() shouldFocus = false;
  @Output() readonly filterChanged = new EventEmitter<QueryFilterInstanceResource>();
}

const hostTemplate = `
  @if (filter(); as activeFilter) {
    <div query-filter [filter]="activeFilter" (filterChanged)="changed()" (deactivateFilter)="removed($event)"></div>
  }
`;

@Component({
  template: '',
  standalone: false,
})
class HostComponent {
  readonly filter = signal<QueryFilterInstanceResource|undefined>(undefined);
  readonly changed = vi.fn<() => void>();
  readonly removed = vi.fn<(filter:QueryFilterInstanceResource) => void>();
}

function buildFilter(type:string|Record<string, string>, values:string[], operatorIds:string[] = ['=']) {
  const operators:QueryOperatorResource[] = operatorIds.map((id) => Object.assign(
    Object.create(QueryOperatorResource.prototype) as QueryOperatorResource,
    { $source: { id }, name: id, $links: { self: { $link: { href: `/operators/${encodeURIComponent(id)}` } } } },
  ));
  const filter = Object.assign(
    Object.create(QueryFilterInstanceResource.prototype) as QueryFilterInstanceResource,
    { filter: { id: 'field', name: 'Field' }, values, operator: operators[0] },
  );
  Object.defineProperty(filter, 'currentSchema', {
    get: () => ({
      values: filter.operator.id === '*' ? null : { type: typeof type === 'string' ? type : type[filter.operator.id] },
      isValueRequired: () => filter.operator.id !== '*',
    }),
  });
  return { filter, operators };
}

describe('work package filter inputs', () => {
  let fixture:ComponentFixture<HostComponent>;
  let filters:WorkPackageViewFiltersService;
  let availableOperators:QueryOperatorResource[];

  const view = () => within(fixture.nativeElement as HTMLElement);

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [
        HostComponent, QueryFilterComponent, FilterIntegerValueComponent, FilterStringValueComponent,
        FilterDateValueComponent, FilterDatesValueComponent, FilterDateTimeValueComponent, FilterDateTimesValueComponent,
        AutofocusDirective, OpIconComponent,
      ],
      imports: [FormsModule, NgClass, AlertIconComponent, OpTooltipDirective, SinglePickerStubComponent, RangePickerStubComponent, OtherFilterStubComponent],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: ConfigurationService, useValue: { isTimezoneSet: () => true, timezone: () => 'UTC' } },
        { provide: CurrentProjectService, useValue: {} },
        IsolatedQuerySpace,
        States,
        WorkPackageViewFiltersService,
        { provide: WorkPackageViewBaselineService, useValue: { isActive: () => false } },
        { provide: SchemaCacheService, useValue: { of: () => ({ availableOperators }) } },
      ],
    })
      .overrideComponent(HostComponent, { set: { template: hostTemplate } })
      .compileComponents();
    filters = TestBed.inject(WorkPackageViewFiltersService);
    fixture = TestBed.createComponent(HostComponent);
  });

  async function renderFilter(type:string, values:string[], operatorIds?:string[]) {
    const { filter, operators } = buildFilter(type, values, operatorIds);
    availableOperators = operators;
    fixture.componentInstance.filter.set(filter);
    await fixture.whenStable();
    return filter;
  }

  function selectOperator(name:string) {
    const option = view().getByRole<HTMLOptionElement>('option', { name });
    fireEvent.change(view().getByRole('combobox'), { target: { value: option.value } });
  }

  it('updates the integer units when the operator changes without replacing the filter', async () => {
    const filter = await renderFilter('[1]Integer', ['4'], ['=', 't+']);
    expect(view().getByRole('spinbutton')).toHaveValue(4);

    selectOperator('t+');
    await fixture.whenStable();

    const input = view().getByRole('spinbutton', { name: 'js.work_packages.time_relative.days' });
    fireEvent.input(input, { target: { value: '7' } });

    expect(filter.operator.id).toBe('t+');
    expect(filter.values).toEqual(['7']);
  });

  it('switches the single datetime editor when the operator changes', async () => {
    const filter = await renderFilter('[1]DateTime', ['2026-01-01T00:00:00Z'], ['=d', '>d']);
    expect(view().getByRole('textbox', { name: 'Date' })).toHaveValue('2026-01-01');

    selectOperator('>d');
    await fixture.whenStable();

    const input = view().getByRole('textbox', { name: 'Date and time' });
    expect(input).toHaveValue('2026-01-01T00:00:00Z');
    fireEvent.input(input, { target: { value: '2026-02-01T04:00:00Z' } });
    expect(filter.values).toEqual(['2026-02-01T04:00:00Z']);
  });

  it('updates both datetime range values independently', async () => {
    const filter = await renderFilter('[2]DateTime', ['2026-01-01T00:00:00Z', '2026-01-15T00:00:00Z']);
    const start = view().getByRole('textbox', { name: 'Start date and time' });
    const end = view().getByRole('textbox', { name: 'End date and time' });
    expect(start).toHaveValue('2026-01-01T00:00:00Z');
    expect(end).toHaveValue('2026-01-15T00:00:00Z');

    fireEvent.input(start, { target: { value: '2026-01-02T00:00:00Z' } });
    fireEvent.input(end, { target: { value: '2026-01-16T00:00:00Z' } });
    expect(filter.values).toEqual(['2026-01-02T00:00:00Z', '2026-01-16T00:00:00Z']);
  });

  it('renders and edits a date', async () => {
    const filter = await renderFilter('[1]Date', ['2026-01-01']);
    const date = view().getByRole('textbox', { name: 'Date' });
    expect(date).toHaveValue('2026-01-01');

    fireEvent.input(date, { target: { value: '2026-02-01' } });
    expect(filter.values).toEqual(['2026-02-01']);
    await vi.waitFor(() => expect(fixture.componentInstance.changed).toHaveBeenCalledTimes(1));
  });

  it('renders and edits a date range', async () => {
    const filter = await renderFilter('[2]Date', ['2026-01-01', '2026-01-15']);
    const range = view().getByRole('textbox', { name: 'Date range' });
    expect(range).toHaveValue('2026-01-01 to 2026-01-15');

    fireEvent.input(range, { target: { value: '2026-02-01 to 2026-02-15' } });
    expect(filter.values).toEqual(['2026-02-01', '2026-02-15']);
    await fixture.whenStable();

    filters.update([filter]);
    filters.modify(filter.id, (sharedFilter) => {
      sharedFilter.values[1] = '2026-02-20';
    });
    await fixture.whenStable();

    expect(range).toHaveValue('2026-02-01 to 2026-02-20');
  });

  it('restores the saved range after replacing its values with an equivalent array', async () => {
    const dates = ['2026-01-01', '2026-01-15'];
    const filter = await renderFilter('[2]Date', dates);
    const range = view().getByRole('textbox', { name: 'Date range' });
    filters.update([filter]);
    await fixture.whenStable();

    fireEvent.input(range, { target: { value: 'invalid' } });
    await fixture.whenStable();
    expect(range).toHaveValue('invalid');
    expect(filter.values).toBe(dates);

    filters.modify(filter.id, (sharedFilter) => {
      sharedFilter.values = [...dates];
    });
    await fixture.whenStable();

    expect(range).toHaveValue('2026-01-01 to 2026-01-15');
  });

  it('renders and edits a string', async () => {
    const filter = await renderFilter('[1]String', ['original']);
    const input = view().getByRole('textbox', { name: 'js.work_packages.description_enter_text' });
    expect(input).toHaveValue('original');

    fireEvent.input(input, { target: { value: 'edited' } });
    expect(filter.values).toEqual(['edited']);
  });

  it('renders service updates to a shared value and operator and accepts a replacement filter', async () => {
    const filter = await renderFilter('[1]Integer', ['4'], ['=', 't+', '*']);
    expect(view().getByRole('spinbutton')).toHaveValue(4);

    filters.update([filter]);
    filters.modify(filter.id, (sharedFilter) => {
      sharedFilter.values[0] = '8';
      sharedFilter.operator = availableOperators[1];
    });
    await fixture.whenStable();

    expect(view().getByRole('spinbutton', { name: 'js.work_packages.time_relative.days' })).toHaveValue(8);
    filters.modify(filter.id, (sharedFilter) => {
      sharedFilter.operator = availableOperators[2];
    });
    await fixture.whenStable();

    expect(view().queryByRole('spinbutton')).not.toBeInTheDocument();
    const replacement = buildFilter('[1]String', ['replacement'], ['**']);
    availableOperators = replacement.operators;
    fixture.componentInstance.filter.set(replacement.filter);
    await fixture.whenStable();

    expect(view().getByRole('option', { name: '**', selected: true })).toBeInTheDocument();
    expect(view().getByRole('textbox')).toHaveValue('replacement');

    fireEvent.click(view().getByRole('button', { name: 'js.button_delete' }));
    expect(fixture.componentInstance.removed).toHaveBeenCalledWith(replacement.filter);
  });

  it('refreshes the active editor after an operator switches its type and unsubscribes when removed', async () => {
    const disconnected = vi.fn<() => void>();
    vi.spyOn(filters, 'live$').mockReturnValue(filters.live$().pipe(finalize(disconnected)));
    const { filter, operators } = buildFilter({ '=': '[1]Integer', '=d': '[1]Date' }, ['4'], ['=', '=d']);
    availableOperators = operators;
    fixture.componentInstance.filter.set(filter);
    await fixture.whenStable();
    expect(view().getByRole('spinbutton')).toHaveValue(4);

    filter.values[0] = '2026-01-01';
    selectOperator('=d');
    await fixture.whenStable();
    expect(view().getByRole('textbox', { name: 'Date' })).toHaveValue('2026-01-01');

    filters.update([filter]);
    filters.modify(filter.id, (sharedFilter) => {
      sharedFilter.values[0] = '2026-02-01';
    });
    await fixture.whenStable();
    expect(view().getByRole('textbox', { name: 'Date' })).toHaveValue('2026-02-01');

    fixture.componentInstance.filter.set(undefined);
    await fixture.whenStable();
    expect(view().queryByRole('textbox')).not.toBeInTheDocument();
    expect(disconnected).toHaveBeenCalledOnce();
  });
});
