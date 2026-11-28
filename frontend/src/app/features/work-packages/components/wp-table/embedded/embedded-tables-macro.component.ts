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

import { Component, computed, input } from '@angular/core';
import {
  WorkPackageTableConfigurationObject,
} from 'core-app/features/work-packages/components/wp-table/wp-table-configuration';
import { QueryRequestParams } from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { jsonAttribute } from 'core-app/shared/helpers/angular/attribute-inputs';

@Component({
  template: `
    <wp-embedded-table-entry [queryProps]="effectiveQueryProps()"
                             [configuration]="configuration" />
  `,
  standalone: false,
})
export class EmbeddedTablesMacroComponent {
  readonly queryProps = input<Partial<QueryRequestParams>|null>(null, { transform: jsonAttribute<Partial<QueryRequestParams>|null>(null) });

  // Fallback for HTML rendered before the macro filter wrote query-props.
  readonly dataQueryProps = input<Partial<QueryRequestParams>|null>(null, { transform: jsonAttribute<Partial<QueryRequestParams>|null>(null) });

  protected readonly effectiveQueryProps = computed(() => this.queryProps() ?? this.dataQueryProps() ?? {});

  readonly configuration:WorkPackageTableConfigurationObject = {
    actionsColumnEnabled: false,
    columnMenuEnabled: false,
    contextMenuEnabled: false,
  };
}
