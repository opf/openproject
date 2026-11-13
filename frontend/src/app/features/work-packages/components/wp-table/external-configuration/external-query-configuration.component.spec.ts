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

import { Component, input, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { fireEvent, waitFor, within } from '@testing-library/dom';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { QueryRequestParams, UrlParamsHelperService } from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { WpTableConfigurationRelationSelectorComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/wp-table-configuration-relation-selector';
import { WpTableConfigurationModalPrependToken } from 'core-app/features/work-packages/components/wp-table/configuration-modal/wp-table-configuration.modal';
import { WpTableConfigurationService } from 'core-app/features/work-packages/components/wp-table/configuration-modal/wp-table-configuration.service';
import { WorkPackageTableConfigurationObject } from 'core-app/features/work-packages/components/wp-table/wp-table-configuration';
import { nextTask } from 'core-common/testing/timing';
import { ExternalQueryConfigurationComponent, QueryConfigurationLocals } from './external-query-configuration.component';
import { OpQueryConfigurationLocalsToken } from './external-query-configuration.constants';
import { ExternalQueryConfigurationService } from './external-query-configuration.service';
import { ExternalRelationQueryConfigurationComponent } from './external-relation-query-configuration.component';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'wp-embedded-table',
  template: `
    <output>Query page {{ queryProps().page }}</output>
    @if (configuration().tableVisible === false && applyCallback()) {
      <button (click)="apply()">Apply configured query</button>
    }
  `,
})
class EmbeddedTableStubComponent {
  queryProps = input.required<Partial<QueryRequestParams>>();
  configuration = input.required<WorkPackageTableConfigurationObject>();
  applyCallback = signal<(() => void)|undefined>(undefined);
  private page = 1;

  openConfigurationModal(onUpdated:() => void):Promise<void> {
    this.applyCallback.set(onUpdated);
    return Promise.resolve();
  }

  buildQueryProps():object {
    return { page: this.page };
  }

  buildUrlParams():string {
    return `page=${this.page}`;
  }

  apply():void {
    this.applyCallback()?.();
    queueMicrotask(() => { this.page = 8; });
  }
}

describe.each([
  { component: ExternalQueryConfigurationComponent, urlParams: false, prepend: null },
  { component: ExternalRelationQueryConfigurationComponent, urlParams: true, prepend: WpTableConfigurationRelationSelectorComponent },
])('$component.name', ({ component, urlParams, prepend }) => {
  let callback:ReturnType<typeof vi.fn<QueryConfigurationLocals['callback']>>;
  let detach:ReturnType<typeof vi.fn<ExternalQueryConfigurationService['detach']>>;
  let parse:ReturnType<typeof vi.fn<UrlParamsHelperService['buildV3GetQueryFromJsonParams']>>;

  beforeEach(async () => {
    callback = vi.fn();
    detach = vi.fn();
    parse = vi.fn().mockReturnValue({ page: 4 });
    await TestBed.configureTestingModule({
      declarations: [ExternalQueryConfigurationComponent, ExternalRelationQueryConfigurationComponent],
      imports: [EmbeddedTableStubComponent],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: UrlParamsHelperService, useValue: { buildV3GetQueryFromJsonParams: parse } },
        {
          provide: OpQueryConfigurationLocalsToken,
          useValue: {
            callback,
            currentQuery: urlParams ? 'page=4' : { page: 4 },
            disabledTabs: ['sort-by'],
            hideDisabledTabs: true,
            service: { detach },
            urlParams,
          },
        },
      ],
    }).compileComponents();
  });

  it('passes the initial query to the hidden table and returns the applied query after its state settles', async () => {
    const fixture = TestBed.createComponent(component);
    const body = within(fixture.nativeElement);
    const apply = await body.findByRole('button', { name: 'Apply configured query' });

    expect(body.getByRole('status')).toHaveTextContent('Query page 4');
    expect(parse.mock.calls).toEqual(urlParams ? [['page=4']] : []);
    const injector = fixture.debugElement.injector;
    expect(injector.get(WpTableConfigurationModalPrependToken, null)).toBe(prepend);
    expect(injector.get(WpTableConfigurationService).tabs.map((tab) => tab.id)).not.toContain('sort-by');

    fireEvent.click(apply);
    expect(callback).not.toHaveBeenCalled();

    await waitFor(() => expect(callback).toHaveBeenCalledExactlyOnceWith(urlParams ? 'page=8' : { page: 8 }));
    expect(detach).toHaveBeenCalledBefore(callback);
  });

  it('ignores a queued Apply after its configuration view has been destroyed', async () => {
    const fixture = TestBed.createComponent(component);
    const body = within(fixture.nativeElement);
    fireEvent.click(await body.findByRole('button', { name: 'Apply configured query' }));
    fixture.destroy();

    await nextTask();

    expect(detach).not.toHaveBeenCalled();
    expect(callback).not.toHaveBeenCalled();
  });
});
