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

import {
  ChangeDetectionStrategy,
  Component,
  HostBinding,
  Input,
  OnInit,
} from '@angular/core';
import { BehaviorSubject, combineLatest } from 'rxjs';
import {
  debounceTime,
  distinctUntilChanged,
  filter,
  map,
  mergeMap,
  shareReplay,
  take,
} from 'rxjs/operators';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import {
  WorkPackageViewFiltersService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import {
  WorkPackageViewIncludeSubprojectsService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-include-subprojects.service';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { IProject } from 'core-app/core/state/projects/project.model';
import {
  SearchableProjectListService,
} from 'core-app/shared/components/searchable-project-list/searchable-project-list.service';
import { IProjectData } from 'core-app/shared/components/searchable-project-list/project-data';

import { insertInList } from './insert-in-list';
import { recursiveSort } from './recursive-sort';
import { calculatePositions } from 'core-app/shared/components/project-include/calculate-positions';

@Component({
  selector: 'op-project-include-modal',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './project-include-modal.component.html',
  providers: [
    SearchableProjectListService,
  ],
})
export class OpProjectIncludeModalComponent {
  @HostBinding('class.op-project-include') className = true;

  @Input() public count?:number;

  public text = {
    toggle_title: this.I18n.t('js.include_projects.toggle_title'),
    title: this.I18n.t('js.include_projects.title'),
  };

  public opened = false;

  constructor(
    readonly I18n:I18nService,
  ) {
  }

  public toggleOpen():void {
    this.opened = !this.opened;
  }
}
