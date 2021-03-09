//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++


import { QueryFilterResource } from 'core-app/modules/hal/resources/query-filter-resource';
import { QueryFilterInstanceResource } from 'core-app/modules/hal/resources/query-filter-instance-resource';
import { Component, Input, Output } from '@angular/core';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { DebouncedEventEmitter } from 'core-components/angular/debounced-event-emitter';
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";
import { componentDestroyed } from "@w11k/ngx-componentdestroyed";
import { SchemaCacheService } from "core-components/schemas/schema-cache.service";

@Component({
  selector: 'filter-integer-value',
  templateUrl: './filter-integer-value.component.html'
})
export class FilterIntegerValueComponent extends UntilDestroyedMixin {
  @Input() public shouldFocus = false;
  @Input() public filter:QueryFilterInstanceResource;
  @Output() public filterChanged = new DebouncedEventEmitter<QueryFilterInstanceResource>(componentDestroyed(this));

  constructor(readonly I18n:I18nService,
              readonly schemaCache:SchemaCacheService) {
    super();
  }

  public get value() {
    return parseInt(this.filter.values[0] as string);
  }

  public set value(val) {
    if (typeof (val) === 'number') {
      this.filter.values = [val.toString()];
    } else {
      this.filter.values = [];
    }

    this.filterChanged.emit(this.filter);
  }

  public get unit() {
    switch ((this.schema.filter.allowedValues as QueryFilterResource[])[0].id) {
    case 'startDate':
    case 'dueDate':
    case 'updatedAt':
    case 'createdAt':
      return this.I18n.t('js.work_packages.time_relative.days');
    default:
      return '';
    }
  }

  private get schema() {
    return this.schemaCache.of(this.filter);
  }
}
