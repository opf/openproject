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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { Injectable } from '@angular/core';
import { StateService } from '@uirouter/core';

@Injectable()
export class StaticQueriesService {
  constructor(
    private readonly I18n:I18nService,
    private readonly $state:StateService,
  ) {
  }

  public text = {
    work_packages: this.I18n.t('js.label_work_package_plural'),
    all_open: this.I18n.t('js.work_packages.default_queries.all_open'),
  };

  public getStaticName(query:QueryResource):string {
    if (this.$state.params.query_props) {
      const nameKey = this.$state.params.name as string;
      if (nameKey) {
        return this.I18n.t(`js.work_packages.default_queries.${nameKey}`);
      }
    }

    // Try to detect the all open filter
    if (query.filters.length === 1 // Only one filter
      && query.filters[0].id === 'status' // that is status
      && query.filters[0].operator.id === 'o') { // and is open
      return this.text.all_open;
    }

    // Otherwise, fall back to work packages
    return this.text.work_packages;
  }
}
