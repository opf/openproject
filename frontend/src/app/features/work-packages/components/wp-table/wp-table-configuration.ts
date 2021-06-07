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


export type WorkPackageTableConfigurationObject = Partial<{ [field in keyof WorkPackageTableConfiguration]:string|boolean }>;

export class WorkPackageTableConfiguration {
  /** Render the table results, set to false when only wanting the table initialization */
  public tableVisible = true;

  /** Render the table as compact style */
  public compactTableStyle = false;

  /** Render the action column (last column) with the actions defined in the TableActionsService */
  public actionsColumnEnabled = true;

  /** Whether the work package context menu is enabled*/
  public contextMenuEnabled = true;

  /** Whether the column dropdown menu is enabled*/
  public columnMenuEnabled = true;

  /** Whether the query should be resolved using the current project identifier */
  public projectContext = true;

  /** Whether the embedded table should live within a specific project context (e.g., given by its parent) */
  public projectIdentifier:string|null = null;

  /** Whether inline create is enabled*/
  public inlineCreateEnabled = true;

  /** Whether the hierarchy toggler item in the subject column is enabled */
  public hierarchyToggleEnabled = true;

  /** Whether this table supports drag and drop */
  public dragAndDropEnabled = false;

  /** Whether this table is in an embedded context*/
  public isEmbedded = false;

  /** Whether the work packages shall be shown in cards instead of a table */
  public isCardView = false;

  /** Whether this table provides a UI for filters*/
  public withFilters = false;

  /** Whether the filters are expanded */
  public filtersExpanded = false;

  /** Whether the button to open filters shall be visible*/
  public showFilterButton = false;

  /** Whether this table provides a UI for filters*/
  public filterButtonText:string = I18n.t("js.button_filter");

  constructor(providedConfig:WorkPackageTableConfigurationObject) {
    _.each(providedConfig, (value, k) => {
      const key = (k as keyof WorkPackageTableConfiguration);
      (this as any)[key] = value;
    });
  }
}
