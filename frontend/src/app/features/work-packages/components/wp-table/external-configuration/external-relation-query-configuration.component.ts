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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  ChangeDetectionStrategy,
  Component,
} from '@angular/core';
import { WpTableConfigurationService } from 'core-app/features/work-packages/components/wp-table/configuration-modal/wp-table-configuration.service';
import { RestrictedWpTableConfigurationService } from 'core-app/features/work-packages/components/wp-table/external-configuration/restricted-wp-table-configuration.service';
import { WpTableConfigurationRelationSelectorComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/wp-table-configuration-relation-selector';
import { WpTableConfigurationModalPrependToken } from 'core-app/features/work-packages/components/wp-table/configuration-modal/wp-table-configuration.modal';
import { ExternalQueryConfigurationComponent } from 'core-app/features/work-packages/components/wp-table/external-configuration/external-query-configuration.component';

@Component({
  templateUrl: './external-query-configuration.template.html',
  providers: [
    [
      { provide: WpTableConfigurationService, useClass: RestrictedWpTableConfigurationService },
    ],
    { provide: WpTableConfigurationModalPrependToken, useValue: WpTableConfigurationRelationSelectorComponent },
  ],
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class ExternalRelationQueryConfigurationComponent extends ExternalQueryConfigurationComponent {
}
