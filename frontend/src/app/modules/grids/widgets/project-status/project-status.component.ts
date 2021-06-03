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

import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Injector,
  OnInit,
  ViewChild
} from '@angular/core';
import { AbstractWidgetComponent } from "app/modules/grids/widgets/abstract-widget.component";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { CurrentProjectService } from "core-components/projects/current-project.service";
import { ProjectResource } from "core-app/modules/hal/resources/project-resource";
import { WorkPackageViewHighlightingService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-highlighting.service";
import { IsolatedQuerySpace } from "core-app/modules/work_packages/query-space/isolated-query-space";
import { Observable } from "rxjs";
import { HalResourceEditingService } from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";

@Component({
  templateUrl: './project-status.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    WorkPackageViewHighlightingService,
    IsolatedQuerySpace,
    HalResourceEditingService
  ]
})
export class WidgetProjectStatusComponent extends AbstractWidgetComponent implements OnInit {

  @ViewChild('contentContainer', { static: true }) readonly contentContainer:ElementRef;

  public currentStatusCode = 'not set';
  public explanation = '';
  public project$:Observable<ProjectResource>;

  constructor(protected readonly i18n:I18nService,
              protected readonly injector:Injector,
              protected readonly apiV3Service:APIV3Service,
              protected readonly currentProject:CurrentProjectService,
              protected readonly cdRef:ChangeDetectorRef) {
    super(i18n, injector);
  }

  ngOnInit() {
    this.project$ = this
      .apiV3Service
      .projects
      .id(this.currentProject.id!)
      .get();

    this.cdRef.detectChanges();
  }

  public get isEditable() {
    return false;
  }
}
