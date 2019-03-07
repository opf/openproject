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


export type WorkPackageTableConfigurationObject = Partial<{ [field in keyof WorkPackageTableConfiguration]:string|boolean }>;

export class WorkPackageTableConfiguration {
  /** Render the table results, set to false when only wanting the table initialization */
  public tableVisible:boolean = true;

  /** Render the action column (last column) with the actions defined in the TableActionsService */
  public actionsColumnEnabled:boolean = true;

  /** Whether the work package context menu is enabled*/
  public contextMenuEnabled:boolean = true;

  /** Whether the column dropdown menu is enabled*/
  public columnMenuEnabled:boolean = true;

  /** Whether the query should be resolved using the current project identifier */
  public projectContext:boolean = true;

  /** Whether the embedded table should live within a specific project context (e.g., given by its parent) */
  public projectIdentifier:string|null = null;

  /** Whether inline create is enabled*/
  public inlineCreateEnabled:boolean = true;

  /** Whether the hierarchy toggler item in the subject column is enabled */
  public hierarchyToggleEnabled:boolean = true;

  /** Whether this table is in an embedded context*/
  public isEmbedded:boolean = false;

  /** Whether the number of shown WP per page shall be calculated based on the available height */
  public forcePerPageOption:number|false = false;

  /** Whether this table provides a UI for filters*/
  public withFilters:boolean = false;

  /** Whether the button to open filters shall be visible*/
  public showFilterButton:boolean = false;
  /** Whether the filters shall be visible*/
  public showFilters:boolean = false;

  /** Whether this table provides a UI for filters*/
  public filterButtonText:string = I18n.t("js.button_filter");

  constructor(private providedConfig:WorkPackageTableConfigurationObject) {
    _.each(providedConfig, (value, k) => {
      let key = (k as keyof WorkPackageTableConfiguration);
      this[key] = value as any;
    });
  }
}
