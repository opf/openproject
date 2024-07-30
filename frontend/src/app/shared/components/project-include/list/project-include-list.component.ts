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
  EventEmitter,
  HostBinding,
  Input,
  Output,
} from '@angular/core';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import SpotDropAlignmentOption from 'core-app/spot/drop-alignment-options';
import { IProjectData } from 'core-app/shared/components/searchable-project-list/project-data';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import {
  SearchableProjectListService,
} from 'core-app/shared/components/searchable-project-list/searchable-project-list.service';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: '[op-project-include-list]',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './project-include-list.component.html',
  styleUrls: ['./project-include-list.component.sass'],
})
export class OpProjectIncludeListComponent {
  @HostBinding('class.spot-list') classNameList = true;

  @HostBinding('class.op-project-include-list') className = true;

  @Output() update = new EventEmitter<string[]>();

  @Input() @HostBinding('class.op-project-include-list--root') root = false;

  @Input() projects:IProjectData[] = [];

  @Input() selected:string[] = [];

  @Input() searchText = '';

  @Input() includeSubprojects = false;

  @Input() parentChecked = false;

  public get currentProjectHref():string|null {
    return this.currentProjectService.apiv3Path;
  }

  public text = {
    does_not_match_search: this.I18n.t('js.include_projects.tooltip.does_not_match_search'),
    include_all_selected: this.I18n.t('js.include_projects.tooltip.include_all_selected'),
    current_project: this.I18n.t('js.include_projects.tooltip.current_project'),
  };

  constructor(
    readonly I18n:I18nService,
    readonly currentProjectService:CurrentProjectService,
    readonly pathHelper:PathHelperService,
    readonly searchableProjectListService:SearchableProjectListService,
  ) { }

  public updateList(selected:string[]):void {
    this.update.emit(selected);
  }

  public isChecked(href:string):boolean {
    return this.selected.includes(href);
  }

  public changeSelected(project:IProjectData):void {
    if (project.disabled) {
      return;
    }

    const { href } = project;
    const checked = this.isChecked(href);

    if (checked) {
      this.updateList(this.selected.filter((selectedHref) => selectedHref !== href));
    } else {
      this.updateList([
        ...this.selected,
        href,
      ]);
    }
  }

  public getTooltipAlignment(project:IProjectData):SpotDropAlignmentOption {
    if (project.position <= 1) {
      return SpotDropAlignmentOption.BottomLeft;
    }

    return SpotDropAlignmentOption.TopLeft;
  }

  extendedProjectUrl(projectId:string):string {
    const currentMenuItem = document.querySelector('meta[name="current_menu_item"]') as HTMLMetaElement;
    const url = this.pathHelper.projectPath(projectId);

    if (!currentMenuItem) {
      return url;
    }

    return `${url}?jump=${encodeURIComponent(currentMenuItem.content)}`;
  }
}
