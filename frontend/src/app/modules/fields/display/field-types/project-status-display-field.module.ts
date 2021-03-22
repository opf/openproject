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

import { DisplayField } from "core-app/modules/fields/display/display-field.module";
import { projectStatusCodeCssClass, projectStatusI18n } from "core-app/modules/fields/helpers/project-status-helper";


export class ProjectStatusDisplayField extends DisplayField {
  public render(element:HTMLElement, displayText:string):void {
    const code = this.value;

    const bulb = document.createElement('span');
    bulb.classList.add('project-status--bulb', projectStatusCodeCssClass(code));

    const name = document.createElement('span');
    name.classList.add('project-status--name',  projectStatusCodeCssClass(code));
    name.textContent = projectStatusI18n(code, this.I18n);

    element.innerHTML = '';
    element.appendChild(bulb);
    element.appendChild(name);

    if (this.writable) {
      const pulldown = document.createElement('span');
      pulldown.classList.add('project-status--pulldown-icon', 'icon', 'icon-pulldown');

      element.appendChild(pulldown);
    }
  }
}
