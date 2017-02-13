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

import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {DurationDisplayField} from './wp-display-duration-field.module';

export class SpentTimeDisplayField extends DurationDisplayField {
  public template: string = '/components/wp-display/field-types/wp-display-spent-time-field.directive.html';
  public text: any;
  public timeEntriesLink: string;
  private PathHelper:any;

  constructor(public resource: WorkPackageResourceInterface,
              public name: string,
              public schema:op.FieldSchema) {
    super(resource, name, schema);

    this.PathHelper = this.$injector.get('PathHelper');

    this.text = {
      linkTitle: this.I18n.t('js.work_packages.message_view_spent_time')
    };
  }

  public render(element: HTMLElement, displayText:string): void {
    if (!this.value) {
      return;
    }

    const link = document.createElement('a');
    link.textContent = displayText;
    link.setAttribute('title', this.text.linkTitle);

    if (this.resource.project) {
      this.resource.project.$load().then((project:any) => {
        const href = URI(this.PathHelper.projectTimeEntriesPath(project.identifier))
          .search({ work_package_id: this.resource.id })
          .toString();

          link.href = href;
      });
    }

    element.innerHTML = '';
    element.appendChild(link);
  }

}
