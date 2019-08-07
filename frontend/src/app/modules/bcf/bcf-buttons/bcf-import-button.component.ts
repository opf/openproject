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

import {Component} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {BcfPathHelperService} from "core-app/modules/bcf/helper/bcf-path-helper.service";

@Component({
  template: `
    <a [title]="text.import" class="button import-bcf-button" (click)="handleClick()">
      <op-icon icon-classes="button--icon icon-import"></op-icon>
      <span class="button--text"> {{text.import}} </span>
    </a>
  `,
  selector: 'bcf-import-button',
})
export class BcfImportButtonComponent {
  public text = {
    import: this.I18n.t('js.bcf.import')
  };

  constructor(readonly I18n:I18nService,
              readonly currentProject:CurrentProjectService,
              readonly bcfPathHelper:BcfPathHelperService) {
  }

  public handleClick() {
    var projectIdentifier = this.currentProject.identifier;
    if (projectIdentifier) {
      var url = this.bcfPathHelper.projectImportIssuePath(projectIdentifier);
      window.location.href = url;
    }
  }
}

DynamicBootstrapper.register({ selector: 'bcf-import-button', cls: BcfImportButtonComponent });
