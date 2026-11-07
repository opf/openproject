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

import { ChangeDetectionStrategy, Component, computed, inject, Injector, input } from '@angular/core';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';
import { KeepTabService } from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { WorkPackageIdDisplayField } from 'core-app/shared/components/fields/display/field-types/wp-id-display-field.module';
import { TemplateWorkPackageRow } from './template-row';
import { UiStateLinkBuilder } from '../builders/ui-state-link-builder';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'td[opWpTableIdCell], th[opWpTableIdCell]',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    class: 'wp-table--cell-td id wp-table--navigable-cell',
    '[attr.data-row-header-name]': 'value().text',
  },
  template: `
    <span class="wp-table--cell-container inline-edit--container id">
      <span class="inline-edit--display-field id -read-only"
        data-field-name="id"
        [class.-required]="value().required"
        [attr.title]="value().title"
        [attr.aria-label]="value().label"
      >
        @if (value().href; as href) {
          <a class="__ui-state-link" [href]="href" tabindex="-1" title=""
            [attr.data-work-package-id]="row().workPackage.id" data-wp-state="show"
          >{{ value().text }}</a>
        }
      </span>
    </span>
  `,
})
export class WorkPackageTableIdCellComponent {
  readonly row = input.required<Pick<TemplateWorkPackageRow, 'workPackage'|'revision'>>();
  private readonly injector = inject(Injector);
  private readonly schemaCache = inject(SchemaCacheService);
  private readonly links = new UiStateLinkBuilder(inject(KeepTabService), inject(CurrentProjectService), inject(PathHelperService), inject(UrlParamsService));

  readonly value = computed(() => {
    const { workPackage } = this.row();
    const field = new WorkPackageIdDisplayField('id', { injector: this.injector, container: 'table', options: { tabbable: false } });
    const schema = this.schemaCache.of(workPackage).ofProperty('id');
    if (!schema) return { text: '', title: null, label: null, required: false, href: null };
    field.apply(workPackage, schema);
    const text = field.value ? field.valueString : '';
    return {
      text,
      title: field.title === '' ? null : field.title,
      label: `${field.displayName} ${field.valueString}`,
      required: field.required,
      href: field.value ? this.links.hrefFor(workPackage.id!, 'show', field.valueString) : null,
    };
  });
}
