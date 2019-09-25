// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {Component, OnInit, ChangeDetectionStrategy, ChangeDetectorRef, Injector, ViewChild, ElementRef} from '@angular/core';
import {AbstractWidgetComponent} from "app/modules/grids/widgets/abstract-widget.component";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {ProjectDmService} from "core-app/modules/hal/dm-services/project-dm.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {SchemaResource} from "core-app/modules/hal/resources/schema-resource";
import {ProjectResource} from "core-app/modules/hal/resources/project-resource";
import {PortalCleanupService} from 'core-app/modules/fields/display/display-portal/portal-cleanup.service';
import {WorkPackageViewHighlightingService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-highlighting.service";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {ProjectCacheService} from "core-components/projects/project-cache.service";

export const emptyPlaceholder = '-';

@Component({
  templateUrl: './project-status.component.html',
  styleUrls: ['./project-status.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    // required by the displayField service to render the fields
    PortalCleanupService,
    WorkPackageViewHighlightingService,
    IsolatedQuerySpace
  ]
})
export class WidgetProjectStatusComponent extends AbstractWidgetComponent implements OnInit {
  @ViewChild('contentContainer', { static: true }) readonly contentContainer:ElementRef;

  public currentStatusCode:string = 'not_set';
  public explanation:String = '';
  public availableStatuses:any = {
    on_track: this.i18n.t('js.grid.widgets.project_status.on_track'),
    off_track: this.i18n.t('js.grid.widgets.project_status.off_track'),
    at_risk: this.i18n.t('js.grid.widgets.project_status.at_risk'),
    not_set: this.i18n.t('js.grid.widgets.project_status.not_set')
  };

  constructor(protected readonly i18n:I18nService,
              protected readonly injector:Injector,
              protected readonly projectDm:ProjectDmService,
              protected readonly projectCache:ProjectCacheService,
              protected readonly currentProject:CurrentProjectService,
              protected readonly cdr:ChangeDetectorRef) {
    super(i18n, injector);
  }

  ngOnInit() {
    this.loadAndRender();
  }

  public get isEditable() {
    return false;
  }

  private loadAndRender() {
    Promise.all(
        [this.loadCurrentProject(),
        this.loadProjectSchema()]
      )
      .then(([project, schema]) => {
        if (project.status) {
          this.currentStatusCode = project.status.code;
          this.explanation = project.status.explanation.html;
        } else {
          this.currentStatusCode = 'not_set';
          this.explanation = '';
        }
        this.redraw();
      });
  }

  private loadCurrentProject() {
    return this.projectCache.require(this.currentProject.id as string);
  }

  public get isLoaded() {
    return this.projectCache.state(this.currentProject.id as string).value;
  }

  private loadProjectSchema() {
    return this.projectDm.schema();
  }

  private redraw() {
    this.cdr.detectChanges();
  }
}
