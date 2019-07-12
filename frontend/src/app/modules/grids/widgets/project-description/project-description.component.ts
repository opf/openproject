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

import {Component, OnInit, ChangeDetectionStrategy, ChangeDetectorRef} from '@angular/core';
import {AbstractWidgetComponent} from "app/modules/grids/widgets/abstract-widget.component";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {ProjectDmService} from "core-app/modules/hal/dm-services/project-dm.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";

@Component({
  templateUrl: './project-description.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class WidgetProjectDescriptionComponent extends AbstractWidgetComponent implements OnInit {
  public description:string;

  constructor(protected readonly i18n:I18nService,
              protected readonly projectDm:ProjectDmService,
              protected readonly currentProject:CurrentProjectService,
              protected readonly cdr:ChangeDetectorRef) {
    super(i18n);
  }

  ngOnInit() {
    this.setDescription();
  }

  private setDescription() {
    this
      .loadCurrentProject()
      .then(project => {
        this.description = project.description.html;
        this.cdr.detectChanges();
      });
  }

  private loadCurrentProject() {
    return this.projectDm.load(this.currentProject.id as string);
  }
}
