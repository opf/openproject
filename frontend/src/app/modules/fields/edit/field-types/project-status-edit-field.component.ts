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

import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {Component, OnInit, ViewChild} from "@angular/core";
import {EditFieldComponent} from "core-app/modules/fields/edit/edit-field.component";
import {NgSelectComponent} from "@ng-select/ng-select";
import {projectStatusCodeCssClass, projectStatusI18n} from "core-app/modules/fields/helpers/project-status-helper";

@Component({
  templateUrl: './project-status-edit-field.component.html',
  styleUrls: ['./project-status-edit-field.component.sass']
})
export class ProjectStatusEditFieldComponent extends EditFieldComponent implements OnInit {
  @ViewChild(NgSelectComponent, { static: true }) public ngSelectComponent:NgSelectComponent;

  readonly I18n:I18nService = this.injector.get(I18nService);

  private _availableStatusCodes:string[] = ['not set', 'off track', 'at risk', 'on track'];

  public availableStatuses:any[] = this._availableStatusCodes.map((code:string):any => {
    return {
      code: code,
      name: projectStatusI18n(code, this.I18n),
      colorClass: projectStatusCodeCssClass(code),
      value: code === 'not set' ? null : code,
    };
  });

  public hiddenOverflowContainer = 'body';

  ngOnInit() {
    // The timeout takes care that the opening is added to the end of the current call stack.
    // Thus we can be sure that the autocompleter is rendered and ready to be opened.
    let that = this;
    window.setTimeout(function () {
      that.ngSelectComponent.open();
    }, 0);
  }

  public onOpen() {
    jQuery(this.hiddenOverflowContainer).one('scroll', () => {
      this.ngSelectComponent.close();
    });
  }

  public onClose() {
    // Nothing to do
  }
}
