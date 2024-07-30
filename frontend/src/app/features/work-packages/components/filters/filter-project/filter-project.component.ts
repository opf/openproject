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

import { ChangeDetectionStrategy, Component, Input, OnInit, Output } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { DebouncedEventEmitter } from 'core-app/shared/helpers/rxjs/debounced-event-emitter';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { componentDestroyed } from '@w11k/ngx-componentdestroyed';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import {
  IProjectAutocompleteItem,
} from 'core-app/shared/components/autocompleter/project-autocompleter/project-autocomplete-item';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { firstValueFrom } from 'rxjs';

@Component({
  selector: 'op-filter-project',
  templateUrl: './filter-project.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FilterProjectComponent extends UntilDestroyedMixin implements OnInit {
  @Input() public shouldFocus = false;

  @Input() public filter:QueryFilterInstanceResource;

  @Output() public filterChanged = new DebouncedEventEmitter<QueryFilterInstanceResource>(componentDestroyed(this), 0);

  additionalProjectApiFilters:IAPIFilter[] = [];

  constructor(
    readonly I18n:I18nService,
    readonly apiV3Service:ApiV3Service,
    readonly currentProjectService:CurrentProjectService,
  ) {
    super();
  }

  ngOnInit():void {
    const projectID = this.currentProjectService.id;

    this.additionalProjectApiFilters.push({ name: 'active', operator: '=', values: ['t'] });

    if (projectID && (this.filter.id === 'subprojectId' || this.filter.id === 'onlySubproject')) {
      this.additionalProjectApiFilters.push({ name: 'ancestor', operator: '=', values: [projectID] });
    }
  }

  async onChange(val:HalResource[]|IProjectAutocompleteItem[]):Promise<void> {
    if (val === this.filter.values || val === undefined) {
      return;
    }

    if (!val || (val && val.length === 0)) {
      this.filter.values.length = 0;
      this.filterChanged.emit(this.filter);
      return;
    }

    // The project autocompleter does not return HalResources, but most filters want them.
    // Here we change from one to the other
    const projects = await firstValueFrom(
      this.apiV3Service.projects.list({
        filters: [
          ['id', '=', val.map((p:HalResource|IProjectAutocompleteItem) => String(p.id) || '')],
        ],
      }),
    );

    this.filter.values = projects.elements;
    this.filterChanged.emit(this.filter);
  }
}
