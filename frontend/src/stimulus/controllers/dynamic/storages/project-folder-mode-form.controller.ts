/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2023 the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { Controller } from '@hotwired/stimulus';

export default class ProjectFolderModeForm extends Controller {
  static targets = [
    'projectFolderSection',
    'selectProjectFolderButton',
    'selectedFolderLabel',
    'storageLoginButton',
  ];

  static values = {
    projectFolderMode: String,
  };

  declare readonly projectFolderSectionTarget:HTMLElement;
  declare readonly selectProjectFolderButtonTarget:HTMLElement;
  declare readonly selectedFolderLabelTarget:HTMLElement;
  declare readonly storageLoginButtonTarget:HTMLElement;

  declare readonly hasProjectFolderSectionTarget:boolean;

  declare projectFolderModeValue:string;

  connect():void {
    // On first load if projectFolderModeValue is manual, show the projectFolderSection
    this.toggleFolderDisplay(this.projectFolderModeValue);
  }

  updateForm(evt:InputEvent):void {
    const projectFolderMode = (evt.target as HTMLInputElement).value;

    this.toggleFolderDisplay(projectFolderMode);
  }

  private toggleFolderDisplay(value:string):void {
    // If the manual radio button is selected, show the manual folder selection section
    if (this.hasProjectFolderSectionTarget && value === 'manual') {
      this.projectFolderSectionTarget.classList.remove('d-none');
    } else {
      this.projectFolderSectionTarget.classList.add('d-none');
    }
  }
}
