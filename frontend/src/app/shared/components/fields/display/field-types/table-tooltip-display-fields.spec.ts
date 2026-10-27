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
import { ProviderToken } from '@angular/core';
import { within, waitFor } from '@testing-library/dom';
import { Subject } from 'rxjs';
import { DisplayFieldRenderer } from '../display-field-renderer';
import { DisplayFieldService } from '../display-field.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { DisplayFieldContext } from 'core-app/shared/components/fields/display/display-field.service';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';
import { KeepTabService } from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';
import { LinkedWorkPackageDisplayField } from './linked-work-package-display-field.module';
import { WorkDisplayField } from './work-display-field.module';
import { CompoundProgressDisplayField } from './compound-progress-display-field.module';
import { WorkPackageSpentTimeDisplayField } from './wp-spent-time-display-field.module';
import { HierarchyQueryLinkHelperService } from './hierarchy-query-link-helper.service';
import { ExcludedIconHelperService } from './excluded-icon-helper.service';

const translations:Record<string, string> = {
  'js.label_value_derived_from_children': 'Value derived from children',
  'js.work_packages.message_view_spent_time': 'View spent time',
  'js.button_log_time': 'Log time',
  'js.work_packages.message_successful_show_in_fullscreen': 'Open full view',
};

describe('table field tooltips', () => {
  let container:HTMLElement;
  let project:Subject<ProjectResource>;
  let refresh:ReturnType<typeof vi.fn>;
  let context:DisplayFieldContext;

  beforeEach(() => {
    container = document.body.appendChild(document.createElement('div'));
    project = new Subject<ProjectResource>();
    refresh = vi.fn();

    const services = new Map<unknown, unknown>([
      [I18nService, { t: (key:string) => translations[key] ?? key }],
      [TimezoneService, { formattedChronicDuration: () => '4 h' }],
      [KeepTabService, { currentShowTab: 'activity' }],
      [CurrentProjectService, { identifier: 'demo' }],
      [UrlParamsService, { basePathWithoutDetails: () => '/work_packages' }],
      [
        PathHelperService,
        {
          genericWorkPackagePath: (_project:string, id:string) => `/work_packages/${id}`,
          projectTimeEntriesPath: () => '/projects/demo/time_entries',
          timeEntryWorkPackageDialog: () => '/work_packages/42/time_entry',
        },
      ],
      [
        ApiV3Service,
        { projects: { id: () => ({ get: () => project }) }, work_packages: { id: () => ({ refresh }) } },
      ],
      [
        HierarchyQueryLinkHelperService,
        { addHref: (link:HTMLAnchorElement) => { link.href = '/children'; } },
      ],
      [ExcludedIconHelperService, { addIconIfExcludedFromTotals: vi.fn() }],
    ]);

    context = { injector: { get: (token:unknown) => services.get(token) ?? {} }, options: {} } as unknown as DisplayFieldContext;
  });

  afterEach(() => { container.remove(); project.complete(); });

  it.each([WorkDisplayField, CompoundProgressDisplayField])('describes derived values with %s', (FieldClass) => {
    const field = new FieldClass('work', context);
    field.apply({ work: 40, derivedWork: 60, children: [] } as unknown as HalResource, {} as IFieldSchema);
    field.render(container, '40');

    const link = within(container).getByRole('link');
    expect(link).toHaveAccessibleName(FieldClass === WorkDisplayField ? 'Σ 4 h' : 'Σ 60%');
    expect(link).toHaveAccessibleDescription('Value derived from children');
    expect(link).toHaveAttribute('href', '/children');
    expect(link).toHaveClass('-derived-value', '__ui-state-link');
    expect(link).toHaveAttribute('title', '');
    expect(field.title).toBeNull();
    expect(container.title).toBe('');
    expect(container.querySelector('tool-tip')).toHaveTextContent(/^Value derived from children$/);
  });


  it('does not restore a compound container title through DisplayFieldRenderer', () => {
    const field = new CompoundProgressDisplayField('work', context);
    const schema = { ofProperty: () => ({}), isAttributeEditable: () => false };
    const services = new Map<unknown, unknown>([
      [DisplayFieldService, { getField: () => field }],
      [SchemaCacheService, { of: () => schema }],
      [HalResourceEditingService, { typedState: () => ({ hasValue: () => false }) }],
    ]);

    const injector = { get: (token:ProviderToken<unknown>) => services.get(token) ?? context.injector.get(token) };
    const renderer = new DisplayFieldRenderer(injector, 'table');
    const [, span] = renderer.renderFieldValue({ work: 40, derivedWork: 60, children: [] } as unknown as HalResource, 'work', null);
    container.append(span);

    expect(span).not.toHaveAttribute('title');
    expect(within(span).getByRole('link')).toHaveAttribute('title', '');
  });


  it('disconnects spent-time tooltip listeners when its field rerenders', async () => {
    const field = new WorkPackageSpentTimeDisplayField('spentTime', context);
    field.apply({ spentTime: 'PT4H' } as unknown as HalResource, {} as IFieldSchema);
    field.render(container, '4 h');

    const oldLink = container.querySelector('a')!;
    const oldTooltip = container.querySelector<InstanceType<typeof window.ToolTipElement>>('tool-tip')!;
    oldLink.dispatchEvent(new MouseEvent('mouseenter'));
    await waitFor(() => expect(oldTooltip.matches(':popover-open')).toBe(true));

    const oldHandler = vi.spyOn(oldTooltip, 'handleEvent');
    field.render(container, '8 h');

    expect(oldTooltip).not.toBeInTheDocument();
    expect(container.querySelectorAll('tool-tip')).toHaveLength(1);
    oldLink.dispatchEvent(new MouseEvent('mouseenter'));

    expect(oldHandler).not.toHaveBeenCalled();

    const newLink = container.querySelector('a')!;
    const newTooltip = container.querySelector('tool-tip')!;
    newLink.dispatchEvent(new MouseEvent('mouseenter'));
    await waitFor(() => expect(newTooltip.matches(':popover-open')).toBe(true));
  });

  it('retains linked work-package routing and its visible ID', () => {
    const field = new LinkedWorkPackageDisplayField('parent', context);
    field.apply({ parent: { id: '42', displayId: 'DEMO-7', formattedId: 'DEMO-7', name: 'Parent subject', $loaded: true } } as unknown as HalResource, {} as IFieldSchema);
    field.render(container, '');

    const link = within(container).getByRole('link', { name: 'DEMO-7' });
    expect(link).toHaveAccessibleDescription('Open full view');
    expect(link).toHaveAttribute('title', '');
    expect(link).toHaveAttribute('data-work-package-id', '42');
    expect(link).toHaveAttribute('href', expect.stringContaining('/work_packages/DEMO-7'));
    expect(container).toHaveTextContent('Parent subject');
  });


  it('preserves asynchronous spent-time href and clickable log-time dialog refresh', () => {
    const field = new WorkPackageSpentTimeDisplayField('spentTime', context);
    field.apply({ id: '42', project: {}, spentTime: 'PT4H', logTime: {} } as unknown as HalResource, {} as IFieldSchema);
    field.render(container, '4 h');

    const value = container.querySelector<HTMLAnchorElement>('.time-logging--value')!;
    expect(value).toHaveAttribute('title', '');
    expect(value).not.toHaveAttribute('href');

    project.next({ identifier: 'demo' } as ProjectResource);

    expect(value).toHaveAccessibleName('4 h');
    expect(value).toHaveAccessibleDescription('View spent time');
    expect(value.href).toContain('/projects/demo/time_entries?');
    expect(value.href).toContain('values[WorkPackageId]=42');

    const log = within(container).getByRole('link', { name: 'Log time' });
    expect(log).toHaveAccessibleDescription('');
    expect(log).toHaveAttribute('data-turbo-stream', 'true');
    expect(log).toHaveClass('icon', 'icon-time');

    log.addEventListener('click', (event) => event.preventDefault());
    log.click();

    expect(log).toHaveAttribute('href', expect.stringMatching(/^\/work_packages\/42\/time_entry\?date=/));

    document.dispatchEvent(new CustomEvent('dialog:close', { detail: { dialog: { id: 'time-entry-dialog' }, submitted: true } }));

    expect(refresh).toHaveBeenCalledOnce();
  });
});
