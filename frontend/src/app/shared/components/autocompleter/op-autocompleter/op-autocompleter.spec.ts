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

import { expectTypeOf, type Mock } from 'vitest';
import { AutocompleterLabelContext, AutocompleterOptionContext } from './typings';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { States } from 'core-app/core/states/states.service';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { ChangeDetectionStrategy, Component, EventEmitter, ViewChild } from '@angular/core';
import { Observable, of, map, throwError } from 'rxjs';
import { OpenprojectAutocompleterModule } from '../openproject-autocompleter.module';
import { NgSelectConfig } from '@ng-select/ng-select';
import { screen } from '@testing-library/dom';

import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { UserAutocompleterComponent } from '../user-autocompleter/user-autocompleter.component';
import { OpAutocompleterComponent } from './op-autocompleter.component';
import { By } from '@angular/platform-browser';
import { provideHttpClient, withInterceptorsFromDi, withXhr } from '@angular/common/http';

@Component({
  selector: 'op-test-autocompleter',
  template: '',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
class TestAutocompleterComponent extends OpAutocompleterComponent {
}

@Component({
  imports: [OpenprojectAutocompleterModule],
  template: `
    <op-autocompleter
      #select
      [items]="items"
      [addTag]="addTag"
      [groupBy]="groupBy"
      [searchFn]="searchFn"
      [trackByFn]="trackByFn"
      bindLabel="name"
      [multiple]="true"
      [multipleAsSeparateInputs]="false"
      [closeOnSelect]="false"
      [clearSearchOnAdd]="false"
      [virtualScroll]="false"
    >
      <ng-template op-autocompleter-option-tmp let-item let-search="search" let-index="index">
        <span class="projected-option">{{ isOption(item) ? item.name : optionText(item) }}|{{ search }}|{{ index }}</span>
      </ng-template>
      <ng-template op-autocompleter-label-tmp let-item let-clear="clear">
        <button type="button" class="projected-label" (click)="clear(item)">
          @if (isOption(item)) {
            {{ item.name }}
          }
        </button>
      </ng-template>
      <ng-template op-autocompleter-footer-tmp let-search="search">
        <span class="projected-footer">{{ search }}</span>
      </ng-template>
    </op-autocompleter>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
class TestProjectedTemplatesComponent {
  @ViewChild(OpAutocompleterComponent) autocompleter:OpAutocompleterComponent;

  items = [{ id: 1, name: 'Needle', href: null }, { id: 2, name: 'Thread', href: null }];

  addTag:boolean|((term:string) => unknown) = false;

  groupBy:((item:unknown) => unknown)|undefined;

  searchFn = vi.fn((_term:string, _item:unknown) => true);

  trackByFn = vi.fn((item:unknown) => item);

  optionText(value:unknown):string {
    return typeof value === 'object' && value !== null && 'name' in value && typeof value.name === 'string'
      ? value.name
      : 'synthetic';
  }

  isOption(value:unknown):value is typeof this.items[number] {
    return this.items.some(item => item === value);
  }
}

interface CompleteOption {
  id:number;
  name:string;
  href:string;
}

expectTypeOf<OpAutocompleterComponent<CompleteOption>['model']>().toBeUnknown();
expectTypeOf<OpAutocompleterComponent<CompleteOption>['changed']>().parameter(0).toBeUnknown();
expectTypeOf<AutocompleterLabelContext['$implicit']>().not.toExtend<CompleteOption>();
expectTypeOf<OpAutocompleterComponent<CompleteOption>['items']>().toEqualTypeOf<CompleteOption[]|undefined>();
expectTypeOf<AutocompleterOptionContext['$implicit']>().toBeUnknown();
expectTypeOf<OpAutocompleterComponent<CompleteOption>['searched']>().parameter(0).toEqualTypeOf<{ term:string, items:unknown[] }>();
expectTypeOf<OpAutocompleterComponent<CompleteOption>['searchFn']>().parameter(1).toBeUnknown();
expectTypeOf<NonNullable<OpAutocompleterComponent<CompleteOption>['trackByFn']>>().parameter(0).toBeUnknown();
expectTypeOf<Exclude<OpAutocompleterComponent<CompleteOption>['groupBy'], string|undefined>>().parameter(0).toEqualTypeOf<CompleteOption|HalResource>();
expectTypeOf<OpAutocompleterComponent<CompleteOption>['getOptionsFn']>().returns.toEqualTypeOf<Observable<CompleteOption[]>>();
expectTypeOf<OpAutocompleterComponent['focus']>().toEqualTypeOf<EventEmitter<FocusEvent>>();
expectTypeOf<OpAutocompleterComponent['blur']>().toEqualTypeOf<EventEmitter<FocusEvent>>();
expectTypeOf<OpAutocompleterComponent['cancel']>().toEqualTypeOf<EventEmitter<Event|undefined>>();
expectTypeOf<OpAutocompleterComponent['scrollToEnd']>().toEqualTypeOf<EventEmitter<void>>();


describe('projected autocompleter templates', () => {
  it.each(['default', 'custom'] as const)('renders and searches an inserted %s tag with its original value', async (kind) => {
    await TestBed.configureTestingModule({
      imports: [TestProjectedTemplatesComponent],
      providers: [States, provideHttpClient(withXhr(), withInterceptorsFromDi()), provideHttpClientTesting()],
    }).compileComponents();
    const fixture = TestBed.createComponent(TestProjectedTemplatesComponent);
    const host = fixture.componentInstance;
    const tag = { token: 'custom' };
    host.addTag = kind === 'default' ? true : () => Promise.resolve(tag);
    const rendered = vi.spyOn(host, 'optionText');
    fixture.detectChanges();
    await new Promise(resolve => setTimeout(resolve, 50));
    await fixture.whenStable();
    const select = host.autocompleter.ngSelectInstance;
    const searched = vi.fn();
    const rawSearch = vi.fn();
    const changed = vi.fn();
    host.autocompleter.change.subscribe(changed);
    host.autocompleter.search.subscribe(searched);
    select.searchEvent.subscribe(rawSearch);
    select.open();
    select.filter('Added');
    select.selectTag();
    await fixture.whenStable();
    fixture.detectChanges();
    const inserted:unknown = select.itemsList.items.at(-1)?.value;
    expect(inserted).toEqual(kind === 'custom' ? tag : { name: 'Added' });
    expect(changed.mock.lastCall?.[0][0]).toBe(inserted);
    expect(rendered).toHaveBeenCalledWith(inserted);
    expect(host.trackByFn).toHaveBeenCalledWith(inserted);
    expect(document.querySelector('.ng-dropdown-panel')?.textContent).toContain(kind === 'custom' ? 'synthetic' : 'Added');
    select.filter('again');
    fixture.detectChanges();
    await fixture.whenStable();
    expect(host.searchFn).toHaveBeenCalledWith('again', inserted);
    expect(searched.mock.lastCall?.[0]).toBe(rawSearch.mock.lastCall?.[0]);
    expect(searched.mock.lastCall?.[0].items.at(-1)).toBe(inserted);
    expect(host.items).toHaveLength(2);
  });

  it('forwards grouped search headers and tracks their primitive values', async () => {
    await TestBed.configureTestingModule({
      imports: [TestProjectedTemplatesComponent],
      providers: [States, provideHttpClient(withXhr(), withInterceptorsFromDi()), provideHttpClientTesting()],
    }).compileComponents();
    const fixture = TestBed.createComponent(TestProjectedTemplatesComponent);
    const host = fixture.componentInstance;
    const group = { value: false };
    host.groupBy = vi.fn(() => group);
    fixture.detectChanges();
    await new Promise(resolve => setTimeout(resolve, 50));
    await fixture.whenStable();
    const searched = vi.fn();
    const rawSearch = vi.fn();
    const select = host.autocompleter.ngSelectInstance;
    host.autocompleter.search.subscribe(searched);
    select.searchEvent.subscribe(rawSearch);
    select.filter('Need');
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();
    expect(searched.mock.lastCall?.[0]).toBe(rawSearch.mock.lastCall?.[0]);
    expect(searched.mock.lastCall?.[0].items).toEqual([false, ...host.items]);
    expect(searched.mock.lastCall?.[0].items[1]).toBe(host.items[0]);
    expect(host.trackByFn).toHaveBeenCalledWith(false);
    expect(host.groupBy).toHaveBeenCalledWith(host.items[0]);
    expect(host.groupBy).toHaveBeenCalledWith(host.items[1]);
  });

  it('renders option, label and footer contexts and clears the selected item', async () => {
    await TestBed.configureTestingModule({
      imports: [TestProjectedTemplatesComponent],
      providers: [States, provideHttpClient(withXhr(), withInterceptorsFromDi()), provideHttpClientTesting()],
    }).compileComponents();
    const fixture = TestBed.createComponent(TestProjectedTemplatesComponent);
    fixture.detectChanges();
    await new Promise(resolve => setTimeout(resolve, 50));
    await fixture.whenStable();
    const select = fixture.componentInstance.autocompleter.ngSelectInstance;
    select.open();
    select.filter('Need');
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    expect(document.querySelector('.projected-option')?.textContent?.trim()).toBe('Needle|Need|0');
    expect(document.querySelector('.projected-footer')?.textContent?.trim()).toBe('Need');

    select.select(select.itemsList.filteredItems[0]);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();
    const label = (fixture.nativeElement as HTMLElement).querySelector<HTMLButtonElement>('.projected-label');
    expect(label?.textContent?.trim()).toBe('Needle');
    expect(select.selectedItems.map(item => item.value)).toEqual([fixture.componentInstance.items[0]]);

    label!.click();
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    expect(select.selectedItems).toHaveLength(0);
    expect((fixture.nativeElement as HTMLElement).querySelector('.projected-label')).toBeNull();
    expect(document.querySelector('.projected-footer')?.textContent?.trim()).toBe('Need');
  });
});

describe('autocompleter form boundary', () => {
  const items = [{ id: 1, name: 'Needle', classes: 'decorated' }, { id: 2, name: 'Thread' }, { id: 0, name: 'Unassigned' }];
  let fixture:ComponentFixture<OpAutocompleterComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [OpenprojectAutocompleterModule],
      providers: [States, provideHttpClient(withXhr(), withInterceptorsFromDi()), provideHttpClientTesting()],
    }).compileComponents();
    fixture = TestBed.createComponent<OpAutocompleterComponent>(OpAutocompleterComponent);
  });

  afterEach(() => vi.restoreAllMocks());

  async function initialize(model:unknown, multiple = false, separate = true):Promise<void> {
    const dataset = (fixture.nativeElement as HTMLElement).dataset;
    Object.entries({
      items, model, multiple, multipleAsSeparateInputs: separate, inputName: 'automation[ids]',
      bindLabel: 'name', bindValue: 'id', defaultData: false, focusDirectly: false,
      additionalClassProperty: 'classes', classes: { 'form-options': true, inactive: false },
    }).forEach(([key, value]) => { dataset[key] = JSON.stringify(value); });
    fixture.detectChanges();
    await new Promise(resolve => setTimeout(resolve, 50));
    await fixture.whenStable();
    fixture.detectChanges();
  }

  function submitted():string[] {
    return Array.from((fixture.nativeElement as HTMLElement).querySelectorAll<HTMLInputElement>('input[type=hidden]'), input => input.value);
  }

  it('retains an unresolved ID alongside unrelated options and raw changes', async () => {
    const tracker = vi.fn((item:unknown) => item);
    fixture.componentRef.setInput('trackByFn', tracker);
    fixture.componentRef.setInput('items', []);
    fixture.componentRef.setInput('model', [7]);
    fixture.componentRef.setInput('multiple', true);
    fixture.componentRef.setInput('bindLabel', 'name');
    fixture.componentRef.setInput('bindValue', 'id');
    fixture.componentRef.setInput('inputName', 'automation[ids]');
    fixture.componentRef.setInput('focusDirectly', false);
    fixture.detectChanges();
    await new Promise(resolve => setTimeout(resolve, 50));
    await fixture.whenStable();
    fixture.detectChanges();
    const component = fixture.componentInstance;
    const select = component.ngSelectInstance;
    const unresolved:unknown = select.selectedItems[0].value;
    expect(unresolved).toEqual({ name: null, id: 7 });
    expect(tracker).toHaveBeenCalledWith(unresolved);
    expect((fixture.nativeElement as HTMLElement).querySelector('.ng-value')).not.toBeNull();
    expect(submitted()).toEqual(['7']);

    fixture.componentRef.setInput('items', items);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();
    expect(select.selectedItems[0].value).toBe(unresolved);
    const changed = vi.fn();
    const touched = vi.fn();
    const emitted = vi.fn();
    component.registerOnChange(changed);
    component.registerOnTouched(touched);
    component.change.subscribe(emitted);
    select.select(select.itemsList.items[1]);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();
    expect(changed).toHaveBeenLastCalledWith([unresolved, items[1]]);
    expect(changed.mock.lastCall?.[0][0]).toBe(unresolved);
    expect(emitted.mock.lastCall?.[0]).toBe(changed.mock.lastCall?.[0]);
    expect(touched.mock.lastCall?.[0]).toBe(changed.mock.lastCall?.[0]);
    expect(submitted()).toEqual(['7', '2']);
    select.handleClearClick();
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();
    expect(changed).toHaveBeenLastCalledWith([]);
    expect(submitted()).toEqual(['']);
  });

  it('retains an unbound scalar and a custom asynchronous tag result', async () => {
    const tag = { token: 'custom-tag' };
    fixture.componentRef.setInput('items', []);
    fixture.componentRef.setInput('model', [7]);
    fixture.componentRef.setInput('multiple', true);
    fixture.componentRef.setInput('addTag', () => Promise.resolve(tag));
    fixture.componentRef.setInput('focusDirectly', false);
    fixture.detectChanges();
    await new Promise(resolve => setTimeout(resolve, 50));
    await fixture.whenStable();
    fixture.detectChanges();
    const component = fixture.componentInstance;
    const select = component.ngSelectInstance;
    expect(select.selectedItems[0].value).toBe(7);
    const changed = vi.fn();
    component.registerOnChange(changed);
    select.filter('custom');
    select.selectTag();
    await fixture.whenStable();
    fixture.detectChanges();
    expect(changed).toHaveBeenLastCalledWith([7, tag]);
    expect(changed.mock.lastCall?.[0][1]).toBe(tag);
  });

  it('retains user tracking keys for empty href/name and synthetic values', () => {
    const user = TestBed.createComponent(UserAutocompleterComponent).componentInstance;
    expect(user.trackByFn?.({ href: '/users/1', name: 'User' })).toBe('/users/1');
    expect(user.trackByFn?.({ href: '', name: 'User' })).toBe('User');
    expect(user.trackByFn?.({ href: null, name: '' })).toBe('');
    expect(user.trackByFn?.({ token: 'custom' })).toBeUndefined();
    expect(user.trackByFn?.(false)).toBeUndefined();
  });

  it('preserves a primitive value from an object group key', async () => {
    fixture.componentRef.setInput('items', items);
    fixture.componentRef.setInput('groupBy', () => ({ value: false }));
    fixture.componentRef.setInput('selectableGroup', true);
    fixture.componentRef.setInput('focusDirectly', false);
    fixture.detectChanges();
    await new Promise(resolve => setTimeout(resolve, 50));
    await fixture.whenStable();
    fixture.detectChanges();
    const component = fixture.componentInstance;
    const changed = vi.fn();
    component.registerOnChange(changed);
    const select = component.ngSelectInstance;
    select.select(select.itemsList.items[0]);
    fixture.detectChanges();
    await fixture.whenStable();
    expect(changed).toHaveBeenLastCalledWith(false);
    expect(component.model).toBe(false);
  });

  it('preserves a zero ID placeholder with dynamic binding keys', async () => {
    fixture.componentRef.setInput('items', []);
    fixture.componentRef.setInput('model', [0]);
    fixture.componentRef.setInput('multiple', true);
    fixture.componentRef.setInput('bindLabel', 'title');
    fixture.componentRef.setInput('bindValue', 'key');
    fixture.componentRef.setInput('inputBindValue', 'key');
    fixture.componentRef.setInput('inputName', 'automation[ids]');
    fixture.componentRef.setInput('focusDirectly', false);
    fixture.detectChanges();
    await new Promise(resolve => setTimeout(resolve, 50));
    await fixture.whenStable();
    fixture.detectChanges();
    const select = fixture.componentInstance.ngSelectInstance;
    expect(select.selectedItems[0].value).toEqual({ title: null, key: 0 });
    expect(submitted()).toEqual(['0']);
  });

  it('retains an incomplete DTO by reference and reconciles a later matching option', async () => {
    const incomplete = { id: 7, href: '/items/7' };
    const complete = { ...incomplete, name: 'Later option' };
    fixture.componentRef.setInput('items', []);
    fixture.componentRef.setInput('model', incomplete);
    fixture.componentRef.setInput('bindLabel', 'name');
    fixture.componentRef.setInput('compareWith', (a:{ id:number }, b:{ id:number }) => a.id === b.id);
    fixture.componentRef.setInput('inputName', 'automation[ids]');
    fixture.componentRef.setInput('focusDirectly', false);
    fixture.detectChanges();
    await new Promise(resolve => setTimeout(resolve, 50));
    await fixture.whenStable();
    fixture.detectChanges();
    const select = fixture.componentInstance.ngSelectInstance;
    expect(select.selectedItems[0].value).toBe(incomplete);
    expect(submitted()).toEqual(['7']);
    fixture.componentRef.setInput('items', items);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();
    expect(select.selectedItems[0].value).toBe(incomplete);
    fixture.componentRef.setInput('items', [complete, ...items]);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();
    expect(select.selectedItems[0].value).toBe(complete);
    expect(submitted()).toEqual(['7']);
    const changed = vi.fn();
    fixture.componentInstance.registerOnChange(changed);
    select.handleClearClick();
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();
    expect(changed).toHaveBeenLastCalledWith(undefined);
    expect(submitted()).toEqual(['']);
  });

  it.each([1, items[0], 0, items[2]])('submits an initial scalar or decorated object model %j', async (model) => {
    await initialize(model);
    const id = typeof model === 'number' ? model : model.id;
    expect(submitted()).toEqual([String(id)]);
    expect(fixture.componentInstance.ngSelectInstance.selectedItems[0].value).toEqual(items.find(item => item.id === id));
    expect((fixture.nativeElement as HTMLElement).querySelector('ng-select')?.classList.contains('form-options')).toBe(true);
    expect(fixture.componentInstance.typeahead).toBeNull();
  });

  it('preserves raw option changes and undefined single clear through the wrapper CVA', async () => {
    await initialize(null);
    const component = fixture.componentInstance;
    const changed = vi.fn();
    const touched = vi.fn();
    const emitted = vi.fn();
    component.registerOnChange(changed);
    component.registerOnTouched(touched);
    component.change.subscribe(emitted);
    const hiddenInput = (fixture.nativeElement as HTMLElement).querySelector<HTMLInputElement>('input[type=hidden]')!;
    const hiddenChanged = vi.fn();
    hiddenInput.addEventListener('change', hiddenChanged);
    const select = component.ngSelectInstance;
    select.select(select.itemsList.items[1]);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();
    expect(changed).toHaveBeenLastCalledWith(items[1]);
    expect(emitted).toHaveBeenLastCalledWith(items[1]);
    expect(touched).toHaveBeenLastCalledWith(items[1]);
    expect(submitted()).toEqual(['2']);
    select.handleClearClick();
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();
    expect(changed).toHaveBeenLastCalledWith(undefined);
    expect(emitted).toHaveBeenLastCalledWith(undefined);
    expect(submitted()).toEqual(['']);
    expect(hiddenChanged).toHaveBeenCalledTimes(2);
  });

  it.each([true, false])('submits multiple IDs and the empty sentinel with separate inputs=%s', async (separate) => {
    const warn = vi.spyOn(console, 'warn');
    await initialize([1], true, separate);
    expect(submitted()).toEqual(['1']);
    const component = fixture.componentInstance;
    const changed = vi.fn();
    component.registerOnChange(changed);
    const select = component.ngSelectInstance;
    select.select(select.itemsList.items[1]);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();
    expect(changed).toHaveBeenLastCalledWith(items.slice(0, 2));
    expect(submitted()).toEqual(separate ? ['1', '2'] : ['1,2']);
    select.handleClearClick();
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();
    expect(changed).toHaveBeenLastCalledWith([]);
    expect(submitted()).toEqual(['']);
    select.select(select.itemsList.items[0]);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();
    expect(submitted()).toEqual(['1']);
    select.handleClearClick();
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();
    expect(submitted()).toEqual(['']);
    expect(warn.mock.calls.flat().some(message => typeof message === 'string' && message.includes('NG0956'))).toBe(false);
  });
});

describe('autocompleter', () => {
  let fixture:ComponentFixture<OpAutocompleterComponent>;
  let getOptionsFnSpy:Mock;
  const workPackagesStub = [
    {
      id: 1,
      subject: 'Workpackage 1',
      name: 'Workpackage 1',
      formattedId: '#1',
      author: {
        href: '/api/v3/users/1',
        name: 'Author1',
      },
      type: { id: 1, name: 'Task' },
      status: { id: 1, name: 'Open' },
      project: { name: 'My Project' },
      description: {
        format: 'markdown',
        raw: 'Description of WP1',
        html: '<p>Description of WP1</p>',
      },
      createdAt: '2021-03-26T10:42:14Z',
      updatedAt: '2021-03-26T10:42:14Z',
      dueDate: '2021-03-26T10:42:14Z',
      startDate: '2021-03-26T10:42:14Z',
    },
    {
      id: 2,
      subject: 'Workpackage 2',
      name: 'Workpackage 2',
      formattedId: 'PROJ-2',
      author: {
        href: null,
        name: 'Deleted user',
      },
      type: { id: 2, name: 'Bug' },
      status: { id: 2, name: 'Closed' },
      project: { name: 'My Project' },
      description: {
        format: 'markdown',
        raw: 'Description of WP2',
        html: '<p>Description of WP2</p>',
      },
      createdAt: '2021-03-26T10:42:14Z',
      updatedAt: '2021-03-26T10:42:14Z',
      dueDate: '2021-03-26T10:42:14Z',
      startDate: '2021-03-26T10:42:14Z',
    },
  ];

  type WindowWithOpenProject = Omit<Window, 'OpenProject'> & {
    OpenProject?:{
      environment:string;
    };
  };

  beforeEach(() => {
    (window as WindowWithOpenProject).OpenProject = { environment: 'test' };
  });

  afterEach(() => {
    delete (window as WindowWithOpenProject).OpenProject;
    vi.restoreAllMocks();
  });

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [OpenprojectAutocompleterModule],
      providers: [States, provideHttpClient(withXhr(), withInterceptorsFromDi()), provideHttpClientTesting()],
    }).compileComponents();

    fixture = TestBed.createComponent<OpAutocompleterComponent>(OpAutocompleterComponent);
    getOptionsFnSpy = vi.fn().mockImplementation((searchTerm:string) => {
      return of(workPackagesStub).pipe(map((wps) => wps.filter((wp) => searchTerm !== '' && wp.subject.includes(searchTerm))));
    });

    fixture.componentInstance.resource = 'work_packages';
    fixture.componentInstance.filters = [];
    fixture.componentInstance.searchKey = 'typeahead';
    fixture.componentInstance.appendTo = 'body';
    fixture.componentInstance.multiple = false;
    fixture.componentInstance.closeOnSelect = true;
    fixture.componentInstance.virtualScroll = true;
    fixture.componentInstance.classes = 'wp-relations-autocomplete';
    fixture.componentInstance.getOptionsFn = getOptionsFnSpy;
    fixture.componentInstance.debounceTimeMs = 0;
  });

  it('should load the ng-select correctly', () => {
    vi.useFakeTimers();
    try {
      fixture.detectChanges();
      vi.advanceTimersByTime(0);

      const autocompleter = document.querySelector('.ng-select-container');

      expect(document.contains(autocompleter)).toBeTruthy();
    }
    finally {
      vi.useRealTimers();
    }
  });

  it('falls back to the ng-select configuration when optional inputs are unset', async () => {
    TestBed.inject(NgSelectConfig).clearAllText = 'Configured clear';
    fixture.componentInstance.model = workPackagesStub[0];
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    const container = (fixture.nativeElement as HTMLElement).querySelector('.ng-select-container');
    expect(container).not.toHaveClass('ng-appearance-outline');
    expect(container).not.toHaveClass('ng-appearance-fill');
    expect(screen.getByRole('button', { name: 'Configured clear' })).toBeInTheDocument();
  });

  describe('initial loading', () => {
    it('should query options without interaction by default', () => {
      vi.useFakeTimers();
      try {
        fixture.detectChanges();
        vi.advanceTimersByTime(1000);
        fixture.detectChanges();

        expect(getOptionsFnSpy).toHaveBeenCalledWith('');
      }
      finally {
        vi.useRealTimers();
      }
    });

    describe('with deferFetchUntilOpened', () => {
      beforeEach(() => {
        fixture.componentInstance.deferFetchUntilOpened = true;
      });

      it('should not query options before the dropdown is opened', () => {
        vi.useFakeTimers();
        try {
          fixture.detectChanges();
          vi.advanceTimersByTime(1000);
          fixture.detectChanges();

          expect(getOptionsFnSpy).not.toHaveBeenCalled();

          fixture.componentInstance.ngSelectInstance.open();
          fixture.detectChanges();
          vi.advanceTimersByTime(0);

          expect(getOptionsFnSpy).toHaveBeenCalledWith('');
        }
        finally {
          vi.useRealTimers();
        }
      });

      it('should query options for a term typed while closed', () => {
        vi.useFakeTimers();
        try {
          fixture.detectChanges();
          vi.advanceTimersByTime(1000);
          fixture.detectChanges();

          fixture.componentInstance.ngSelectInstance.filter('Workpackage 2');
          fixture.detectChanges();
          vi.advanceTimersByTime(0);

          expect(getOptionsFnSpy).toHaveBeenCalledWith('Workpackage 2');
          expect(getOptionsFnSpy).not.toHaveBeenCalledWith('');
        }
        finally {
          vi.useRealTimers();
        }
      });
    });
  });

  describe('without debounce', () => {
    it('should load items', () => {
      vi.useFakeTimers();
      try {
        fixture.detectChanges();
        vi.advanceTimersByTime(1000);
        fixture.detectChanges();
        const select = fixture.componentInstance.ngSelectInstance;

        expect(select.isOpen()).toBe(false);
        select.open();
        select.focus();

        expect(select.isOpen()).toBe(true);

        expect(select.itemsList.items.length).toEqual(0);

        const inputDebugElement = fixture.debugElement.query(By.css('input[role=combobox]'));
        const inputElement = inputDebugElement.nativeElement as HTMLInputElement;

        fixture.detectChanges();
        vi.advanceTimersByTime(0);

        expect(getOptionsFnSpy).toHaveBeenCalledWith('');

        inputElement.value = 'Wor';
        inputElement.dispatchEvent(new Event('input'));
        fixture.detectChanges();
        vi.advanceTimersByTime(0);

        expect(getOptionsFnSpy).toHaveBeenCalledWith('Wor');

        fixture.detectChanges();

        expect(select.itemsList.items.length).toEqual(2);

        inputElement.value = 'package 2';
        inputElement.dispatchEvent(new Event('input'));
        fixture.detectChanges();
        vi.advanceTimersByTime(0);

        expect(getOptionsFnSpy).toHaveBeenCalledWith('package 2');

        fixture.detectChanges();

        expect(select.itemsList.items.length).toEqual(1);
      }
      finally {
        vi.useRealTimers();
      }
    });

    it.each([
      { action: 'select', closeOnSelect: true, clearSearchOnAdd: true, expectedCount: 2 },
      { action: 'select', closeOnSelect: false, clearSearchOnAdd: true, expectedCount: 2 },
      { action: 'close', closeOnSelect: true, clearSearchOnAdd: true, expectedCount: 2 },
      { action: 'select', closeOnSelect: false, clearSearchOnAdd: false, expectedCount: 1 },
    ])('keeps options in sync after $action with closeOnSelect=$closeOnSelect and clearSearchOnAdd=$clearSearchOnAdd', ({
      action, closeOnSelect, clearSearchOnAdd, expectedCount,
    }) => {
      vi.useFakeTimers();
      try {
        fixture.componentInstance.closeOnSelect = closeOnSelect;
        fixture.componentInstance.clearSearchOnAdd = clearSearchOnAdd;
        getOptionsFnSpy.mockImplementation((searchTerm:string) => of(
          workPackagesStub.filter((wp) => !searchTerm || wp.subject.includes(searchTerm)),
        ));
        fixture.detectChanges();
        vi.advanceTimersByTime(1000);
        fixture.detectChanges();

        const select = fixture.componentInstance.ngSelectInstance;
        select.filter('package 2');
        fixture.detectChanges();
        vi.advanceTimersByTime(0);
        fixture.detectChanges();
        expect(select.itemsList.items).toHaveLength(1);

        if (action === 'select') {
          select.select(select.itemsList.items[0]);
        } else {
          select.close();
        }
        fixture.detectChanges();
        vi.advanceTimersByTime(0);
        fixture.detectChanges();
        select.open();
        fixture.detectChanges();

        expect(select.searchTerm || '').toBe(expectedCount === 2 ? '' : 'package 2');
        expect(select.itemsList.items).toHaveLength(expectedCount);
        expect(getOptionsFnSpy).not.toHaveBeenCalledWith(null);
      }
      finally {
        vi.useRealTimers();
      }
    });

    it('should recover and keep loading results after a lookup fails', () => {
      const consoleError = vi.spyOn(console, 'error').mockImplementation(() => undefined);
      const lookupError = new Error('backend rejected the query');
      vi.useFakeTimers();
      try {
        getOptionsFnSpy.mockImplementation((searchTerm:string) => {
          if (searchTerm === 'bad') {
            return throwError(() => lookupError);
          }

          return of(workPackagesStub).pipe(map((wps) => wps.filter((wp) => searchTerm !== '' && wp.subject.includes(searchTerm))));
        });

        fixture.detectChanges();
        vi.advanceTimersByTime(1000);
        fixture.detectChanges();
        const select = fixture.componentInstance.ngSelectInstance;

        select.open();
        select.focus();

        const inputDebugElement = fixture.debugElement.query(By.css('input[role=combobox]'));
        const inputElement = inputDebugElement.nativeElement as HTMLInputElement;

        inputElement.value = 'bad';
        inputElement.dispatchEvent(new Event('input'));
        fixture.detectChanges();
        vi.advanceTimersByTime(0);
        fixture.detectChanges();

        expect(getOptionsFnSpy).toHaveBeenCalledWith('bad');
        expect(consoleError).toHaveBeenCalledWith(lookupError);
        expect(select.itemsList.items.length).toEqual(0);

        inputElement.value = 'Wor';
        inputElement.dispatchEvent(new Event('input'));
        fixture.detectChanges();
        vi.advanceTimersByTime(0);
        fixture.detectChanges();

        expect(getOptionsFnSpy).toHaveBeenCalledWith('Wor');
        expect(select.itemsList.items.length).toEqual(2);
      }
      finally {
        vi.useRealTimers();
      }
    });
  });

  describe('work package option rendering', () => {
    it('should display formattedId in dropdown options', () => {
      vi.useFakeTimers();
      try {
        fixture.detectChanges();
        vi.advanceTimersByTime(1000);
        fixture.detectChanges();
        const select = fixture.componentInstance.ngSelectInstance;

        select.open();
        select.focus();

        const inputDebugElement = fixture.debugElement.query(By.css('input[role=combobox]'));
        const inputElement = inputDebugElement.nativeElement as HTMLInputElement;

        inputElement.value = 'Wor';
        inputElement.dispatchEvent(new Event('input'));
        fixture.detectChanges();
        vi.advanceTimersByTime(0);
        fixture.detectChanges();

        const wpIdElements = document.querySelectorAll('.op-autocompleter--wp-id');

        expect(wpIdElements.length).toBeGreaterThanOrEqual(1);
        // Verify at least one rendered option displays formattedId
        const renderedIds = Array.from(wpIdElements).map(el => el.textContent?.trim());

        expect(renderedIds).toContain('#1');
      }
      finally {
        vi.useRealTimers();
      }
    });

    it('should display classic formattedId in selected value label', () => {
      silenceDestroyedOutputWarning();
      vi.useFakeTimers();
      try {
        fixture.detectChanges();
        vi.advanceTimersByTime(1000);
        fixture.detectChanges();
        const select = fixture.componentInstance.ngSelectInstance;

        select.open();
        select.focus();

        const inputDebugElement = fixture.debugElement.query(By.css('input[role=combobox]'));
        const inputElement = inputDebugElement.nativeElement as HTMLInputElement;

        inputElement.value = 'Wor';
        inputElement.dispatchEvent(new Event('input'));
        fixture.detectChanges();
        vi.advanceTimersByTime(0);
        fixture.detectChanges();

        // Select the first item (classic mode: #1)
        select.select(select.itemsList.items[0]);
        fixture.detectChanges();

        const labelElement = document.querySelector('.ng-value-label');

        expect(labelElement).toBeTruthy();
        expect(labelElement!.textContent).toContain('#1');
        expect(labelElement!.textContent).toContain('Workpackage 1');
      }
      finally {
        vi.useRealTimers();
      }
    });

    it('should display semantic formattedId in selected value label', () => {
      silenceDestroyedOutputWarning();
      vi.useFakeTimers();
      try {
        fixture.detectChanges();
        vi.advanceTimersByTime(1000);
        fixture.detectChanges();
        const select = fixture.componentInstance.ngSelectInstance;

        select.open();
        select.focus();

        const inputDebugElement = fixture.debugElement.query(By.css('input[role=combobox]'));
        const inputElement = inputDebugElement.nativeElement as HTMLInputElement;

        inputElement.value = 'package 2';
        inputElement.dispatchEvent(new Event('input'));
        fixture.detectChanges();
        vi.advanceTimersByTime(0);
        fixture.detectChanges();

        // Select the semantic mode item (PROJ-2)
        select.select(select.itemsList.items[0]);
        fixture.detectChanges();

        const labelElement = document.querySelector('.ng-value-label');

        expect(labelElement).toBeTruthy();
        expect(labelElement!.textContent).toContain('PROJ-2');
        expect(labelElement!.textContent).not.toContain('#PROJ-2');
        expect(labelElement!.textContent).toContain('Workpackage 2');
      }
      finally {
        vi.useRealTimers();
      }
    });
  });

  describe('with debounce', () => {
    beforeEach(() => {
      fixture.componentInstance.debounceTimeMs = 50;
    });

    it('should load items with debounce', async () => {
      silenceDestroyedOutputWarning();
      fixture.detectChanges();

      // Wait for ngAfterViewInit's internal setTimeout(25ms) and debounce to fire.
      await new Promise(resolve => setTimeout(resolve, 100));
      fixture.detectChanges();
      const select = fixture.componentInstance.ngSelectInstance;

      expect(select.isOpen()).toBe(false);
      select.open();
      select.focus();

      expect(select.isOpen()).toBe(true);

      expect(select.itemsList.items.length).toEqual(0);

      const inputDebugElement = fixture.debugElement.query(By.css('input[role=combobox]'));
      const inputElement = inputDebugElement.nativeElement as HTMLInputElement;

      fixture.detectChanges();

      // Wait for the initial '' search to fire via debounce.
      await new Promise(resolve => setTimeout(resolve, 100));

      expect(getOptionsFnSpy).toHaveBeenCalledWith('');
      getOptionsFnSpy.mockClear();

      inputElement.value = 'Wor';
      inputElement.dispatchEvent(new Event('input'));
      fixture.detectChanges();

      expect(getOptionsFnSpy).not.toHaveBeenCalled();

      // Wait for debounce (debounceTimeMs=50, but 0 in test env).
      await new Promise(resolve => setTimeout(resolve, 100));

      expect(getOptionsFnSpy).toHaveBeenCalledWith('Wor');
    });
  });
});

// NG0953 ("Unexpected emit for destroyed OutputRef") comes from ng-select's
// dropdown panel: `_measureDimensions` retries through a Promise and
// requestAnimationFrame chain with no destroyed guard, so it emits after the
// panel is torn down (https://github.com/ng-select/ng-select/issues/2869).
// Silencing is a stopgap until ng-select guards that chain; it passes every
// other warning through. Do not promote this to a global filter.
function silenceDestroyedOutputWarning():void {
  const originalWarn = console.warn.bind(console);

  vi.spyOn(console, 'warn').mockImplementation((message?:unknown, ...args:unknown[]) => {
    if (typeof message === 'string' && message.startsWith('NG0953: Unexpected emit for destroyed `OutputRef`')) {
      return;
    }

    originalWarn(message, ...args);
  });
}

describe('derived autocompleter', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [TestAutocompleterComponent],
      providers: [States, provideHttpClient(withXhr(), withInterceptorsFromDi()), provideHttpClientTesting()],
    }).compileComponents();
  });

  it('provides shared autocompleter dependencies to subclasses', () => {
    const fixture = TestBed.createComponent(TestAutocompleterComponent);

    expect(fixture.componentInstance.opAutocompleterService).toBeDefined();
  });
});
